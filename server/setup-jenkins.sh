#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=== Instalando Jenkins ===${NC}"

sudo apt update
sudo apt install -y fontconfig openjdk-21-jre

sudo mkdir -p /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/jenkins.gpg

sudo GNUPGHOME=/root/.gnupg gpg --no-default-keyring \
    --keyring /etc/apt/keyrings/jenkins.gpg \
    --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo chmod a+r /etc/apt/keyrings/jenkins.gpg

sudo rm -f /etc/apt/sources.list.d/jenkins.list
echo "deb [signed-by=/etc/apt/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

echo -e "${YELLOW}Aguardando Jenkins inicializar...${NC}"
for _ in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|403"; then
        break
    fi
    sleep 2
done

INITIAL_PASS=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "N/A")
SERVER_IP=$(hostname -I | awk '{print $1}')

CRED_FILE="$(pwd)/jenkins-credentials.txt"
cat > "$CRED_FILE" <<EOF
========================================
  JENKINS - Credenciais
========================================
URL:       http://${SERVER_IP}:8080
Usuario:   admin
Senha:     ${INITIAL_PASS}
========================================
Configure estas credenciais no Jenkins:
  Manage Jenkins > Credentials > System > Global credentials
  Crie uma entrada "Username with password":
   ID:       tfs-deploy-creds
   Username: TFS
   Password: TFS123DEPLOY
========================================
EOF
chmod 600 "$CRED_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Jenkins instalado com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${CYAN}URL:${NC}       http://${SERVER_IP}:8080"
echo -e "${CYAN}Usuario:${NC}   admin"
echo -e "${CYAN}Senha:${NC}     ${INITIAL_PASS}"
echo -e "${GREEN}========================================${NC}"
echo -e "${CYAN}Credenciais salvas em:${NC} ${CRED_FILE}"
echo ""
echo -e "${YELLOW}Proximos passos:${NC}"
echo "  1. Acesse http://${SERVER_IP}:8080 no navegador"
echo "  2. Instale os plugins sugeridos"
echo "  3. Crie um Pipeline apontando para este repositorio"