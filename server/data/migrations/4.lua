function onUpdateDatabase()
	logMigration("> Updating database to version 5 (black skull & guild wars)")
	db.query("ALTER TABLE `players` CHANGE `redskull` `skull` TINYINT NOT NULL DEFAULT '0', CHANGE `redskulltime` `skulltime` INT NOT NULL DEFAULT '0'")
	db.query("CREATE TABLE IF NOT EXISTS `guild_wars` ( `id` int NOT NULL AUTO_INCREMENT, `guild1` int NOT NULL DEFAULT '0', `guild2` int NOT NULL DEFAULT '0', `name1` varchar(255) NOT NULL, `name2` varchar(255) NOT NULL, `status` tinyint NOT NULL DEFAULT '0', `started` bigint NOT NULL DEFAULT '0', `ended` bigint NOT NULL DEFAULT '0', PRIMARY KEY (`id`), KEY `guild1` (`guild1`), KEY `guild2` (`guild2`)) ENGINE=InnoDB")
	db.query("CREATE TABLE IF NOT EXISTS `guild_war_kills` (`id` int NOT NULL AUTO_INCREMENT, `war_id` int NOT NULL, `killer_guild` int NOT NULL, `killer` int NOT NULL, `victim` int NOT NULL, `time` bigint NOT NULL, PRIMARY KEY (`id`), KEY `war_id` (`war_id`), KEY `killer_guild` (`killer_guild`), FOREIGN KEY (`war_id`) REFERENCES `guild_wars`(`id`) ON DELETE CASCADE) ENGINE=InnoDB")
	return true
end

