function onUpdateDatabase()
	logMigration("> Updating database to version 36 (game store account update)")

	local resultId = db.storeQuery("SHOW COLUMNS FROM `accounts` LIKE 'points_second'")
	if resultId then
		result.free(resultId)
	else
		db.query("ALTER TABLE `accounts` ADD `points_second` int NOT NULL DEFAULT '0' AFTER `tibia_coins`")
	end

	db.query([[
		CREATE TABLE IF NOT EXISTS `shop_history` (
			`id` int(11) NOT NULL AUTO_INCREMENT,
			`account` int(11) NOT NULL,
			`player` int(11) NOT NULL,
			`date` datetime NOT NULL,
			`title` varchar(100) NOT NULL,
			`price` int(11) NOT NULL,
			`costSecond` int(11) NOT NULL,
			`count` int(11) NOT NULL DEFAULT '0',
			`target` varchar(255) DEFAULT NULL,
			PRIMARY KEY (`id`),
			FOREIGN KEY (`account`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
			FOREIGN KEY (`player`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])

	db.query([[
		CREATE TABLE IF NOT EXISTS `change_name_history` (
			`id` int(11) NOT NULL AUTO_INCREMENT,
			`player_id` int(11) NOT NULL,
			`last_name` varchar(30) NOT NULL,
			`current_name` varchar(30) NOT NULL,
			`changed_name_in` int(11) NOT NULL,
			PRIMARY KEY (`id`),
			FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
		) ENGINE=InnoDB
	]])

	db.query([[
		CREATE TABLE IF NOT EXISTS `player_deaths_backup` (
			`player_id` int NOT NULL,
			`time` bigint unsigned NOT NULL DEFAULT '0',
			`level` int NOT NULL DEFAULT '1',
			`killed_by` varchar(255) NOT NULL,
			`is_player` tinyint NOT NULL DEFAULT '1',
			`mostdamage_by` varchar(100) NOT NULL,
			`mostdamage_is_player` tinyint NOT NULL DEFAULT '0',
			`unjustified` tinyint NOT NULL DEFAULT '0',
			`mostdamage_unjustified` tinyint NOT NULL DEFAULT '0',
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE,
			KEY `killed_by` (`killed_by`),
			KEY `mostdamage_by` (`mostdamage_by`)
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])

	return true
end
