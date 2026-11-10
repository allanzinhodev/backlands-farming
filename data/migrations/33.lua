function onUpdateDatabase()
	logMigration("> Updating database to version 34 (SHA-256 password hashing support)")
	db.query("ALTER TABLE `accounts` MODIFY `password` VARCHAR(105) NOT NULL")
	return true
end


