function onUpdateDatabase()
	logMigration("> Updating database to version 37 (player prey system)")

	db.query([[
		CREATE TABLE IF NOT EXISTS `player_prey` (
			`player_id` INT(11) NOT NULL,
			`slot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`monster_name` VARCHAR(255) NOT NULL DEFAULT '',
			`bonus_type` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`bonus_value` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
			`time_left` INT UNSIGNED NOT NULL DEFAULT 0,
			`list_monsters` VARCHAR(1024) NOT NULL DEFAULT '',
			`reroll_at` BIGINT UNSIGNED NOT NULL DEFAULT 0,
			`wildcards` INT UNSIGNED NOT NULL DEFAULT 0,

			PRIMARY KEY (`player_id`, `slot`),

			CONSTRAINT `fk_player_prey_player_id`
				FOREIGN KEY (`player_id`)
				REFERENCES `players` (`id`)
				ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
	]])

	return true
end
