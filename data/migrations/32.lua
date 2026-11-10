function onUpdateDatabase()
	logMigration("> Updating database to version 33 (guild war kills system update)")
	
	-- Check if old table exists
	local resultId = db.storeQuery("SHOW TABLES LIKE 'guildwar_kills'")
	if resultId then
		result.free(resultId)
		-- Backup old table
		db.query("CREATE TABLE IF NOT EXISTS `guildwar_kills_backup` LIKE `guildwar_kills`")
		db.query("INSERT INTO `guildwar_kills_backup` SELECT * FROM `guildwar_kills`")
		-- Drop old table
		db.query("DROP TABLE IF EXISTS `guildwar_kills`")
	end
	
	-- Create new table with correct structure
	db.query([[
		CREATE TABLE IF NOT EXISTS `guild_war_kills` (
			`id` int NOT NULL AUTO_INCREMENT,
			`war_id` int NOT NULL,
			`killer_guild` int NOT NULL,
			`killer` int NOT NULL,
			`victim` int NOT NULL,
			`time` bigint NOT NULL,
			PRIMARY KEY (`id`),
			KEY `war_id` (`war_id`),
			KEY `killer_guild` (`killer_guild`),
			FOREIGN KEY (`war_id`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])
	
	return true
end
