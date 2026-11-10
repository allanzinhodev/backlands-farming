function onUpdateDatabase()
	logMigration("Updating database to version 42 (kv_store table)")
	local success = db.query([[
		CREATE TABLE IF NOT EXISTS `kv_store` (
			`key_name` varchar(191) NOT NULL,
			`timestamp` bigint NOT NULL,
			`value` longblob NOT NULL,
			PRIMARY KEY (`key_name`),
			KEY `timestamp` (`timestamp`)
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_bin;
	]])
	if not success then
		logMigration("Failed to create kv_store table")
		return false
	end
	return true
end
