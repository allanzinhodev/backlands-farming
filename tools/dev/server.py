#!/usr/bin/env python3
"""Start the isolated local farming server and its development database."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import secrets
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
STATE = ROOT / "out" / "dev-server"
NETWORK = "bl-test"
DATABASE = "backlandsofc-db"
SERVER = "backlandsofc-server"
LABEL = "com.backlands.workspace=" + hashlib.sha256(str(ROOT).casefold().encode()).hexdigest()[:16]
TEST_ACCOUNT = "fazenda"
TEST_PASSWORD = "fazenda"
TEST_CHARACTER = "Fazendeiro"


def docker(*args, data=None, check=True):
    result = subprocess.run(["docker", *args], input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        error = result.stderr.decode("utf-8", errors="replace")
        credentials = STATE / "credentials.json"
        if credentials.is_file():
            for key, value in json.loads(credentials.read_text()).items():
                if "password" in key:
                    error = error.replace(value, "[redacted]")
        raise RuntimeError(error.strip() or f"Docker exited with {result.returncode}")
    return result


def owned(name):
    result = docker("inspect", name, check=False)
    if result.returncode:
        return None
    container = json.loads(result.stdout)[0]
    key, value = LABEL.split("=", 1)
    if container["Config"].get("Labels", {}).get(key) != value:
        raise ValueError(f"Container {name} belongs to another workspace; choose a different name.")
    return container


def credentials():
    STATE.mkdir(parents=True, exist_ok=True)
    path = STATE / "credentials.json"
    if not path.exists():
        path.write_text(json.dumps({"root_password": secrets.token_hex(24),
                                    "password": secrets.token_hex(24)}, indent=2), encoding="utf-8")
    return json.loads(path.read_text(encoding="utf-8"))


def sql(statement, database=None):
    command = ['sh', '-c', 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --batch --skip-column-names "$@"', 'db']
    if database:
        command.append(database)
    return docker("exec", "-i", DATABASE, *command, data=statement.encode("utf-8")).stdout.decode("utf-8").strip()


def wait_database():
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        result = docker("exec", DATABASE, "sh", "-c",
                        'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -uroot -e "SELECT 1" >/dev/null 2>&1', check=False)
        if result.returncode == 0:
            return
        time.sleep(1)
    raise RuntimeError("The development database did not become ready; inspect docker logs backlandsofc-db.")


def seed_test_account():
    account_exists = sql(f"SELECT COUNT(*) FROM accounts WHERE name='{TEST_ACCOUNT}';", "backlands")
    if account_exists != "0":
        print("Existing development account preserved (password and player state unchanged).")
        return
    password_hash = hashlib.sha1(TEST_PASSWORD.encode()).hexdigest()
    # This seed belongs only to the isolated local development database. The
    # distributable schema intentionally has no default account or player.
    statement = f"""START TRANSACTION;
INSERT INTO accounts(name,password,type,premium_ends_at,creation)
VALUES('{TEST_ACCOUNT}','{password_hash}',1,UNIX_TIMESTAMP()+31536000,UNIX_TIMESTAMP());
SET @backlands_account=LAST_INSERT_ID();
INSERT INTO players(name,account_id,group_id,vocation,level,health,healthmax,mana,manamax,
experience,town_id,posx,posy,posz,looktype,lookhead,lookbody,looklegs,lookfeet,sex,cap,balance)
VALUES('{TEST_CHARACTER}',@backlands_account,1,0,8,185,185,90,90,4200,1,100,100,7,128,78,68,58,76,1,470,1000);
COMMIT;"""
    sql(statement, "backlands")
    print(f"Created development account {TEST_ACCOUNT} / {TEST_PASSWORD}, character {TEST_CHARACTER}.")


def start(image):
    image_id = docker("image", "inspect", image, "--format", "{{.Id}}").stdout.decode().strip()
    secret = credentials()
    if docker("network", "inspect", NETWORK, check=False).returncode:
        docker("network", "create", NETWORK)
    container = owned(DATABASE)
    if container is None:
        environment = STATE / "database.env"
        environment.write_text("\n".join((f"MARIADB_ROOT_PASSWORD={secret['root_password']}",
                                          "MARIADB_DATABASE=backlands", "MARIADB_USER=backlands",
                                          f"MARIADB_PASSWORD={secret['password']}")) + "\n", encoding="utf-8")
        docker("run", "-d", "--name", DATABASE, "--label", LABEL, "--network", NETWORK,
               "--env-file", str(environment), "--mount", "type=volume,source=backlandsofc-dev-db,target=/var/lib/mysql",
               "mariadb:11")
    elif not container["State"]["Running"]:
        docker("start", DATABASE)
    wait_database()
    tables = sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='backlands' AND table_name='accounts';")
    if tables == "0":
        schema = (ROOT / "server/schema.sql").read_bytes()
        docker("exec", "-i", DATABASE, "sh", "-c",
               'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot backlands', data=schema)
    seed_test_account()
    config = (ROOT / "server/config.lua.dist").read_text(encoding="utf-8")
    replacements = {"mysqlHost": DATABASE, "mysqlUser": "backlands", "mysqlPass": secret["password"],
                    "mysqlDatabase": "backlands", "ip": "127.0.0.1"}
    for key, value in replacements.items():
        config, count = re.subn(rf'(?m)^{key}\s*=.*$', f'{key} = "{value}"', config)
        if count != 1:
            raise ValueError(f"Expected exactly one {key} setting.")
    config_path = STATE / "config.lua"
    config_path.write_text(config, encoding="utf-8")
    container = owned(SERVER)
    if container is not None and container["Image"] != image_id:
        docker("stop", SERVER)
        docker("rm", SERVER)
        container = None
    if container is None:
        docker("run", "-d", "--name", SERVER, "--label", LABEL, "--network", NETWORK,
               "--mount", f"type=bind,source={ROOT / 'server/data'},target=/srv/data",
               "--mount", f"type=bind,source={config_path},target=/srv/config.lua,readonly",
               image)
    else:
        docker("restart", SERVER)
    print(f"Started {SERVER}; TCP ports 7171/7172 are private on Docker network {NETWORK}.")
    print("Use the Astra web launcher for browser access. Logs: docker logs -f backlandsofc-server")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("start", "stop", "status"), nargs="?", default="start")
    parser.add_argument("--image", default="backlands-server:dev")
    args = parser.parse_args()
    if args.action == "start":
        start(args.image)
    elif args.action == "stop":
        for name in (SERVER, DATABASE):
            if owned(name):
                docker("stop", name)
        print("Development containers stopped; database volume preserved.")
    else:
        for name in (SERVER, DATABASE):
            item = owned(name)
            print(name, item["State"]["Status"] if item else "not created")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
