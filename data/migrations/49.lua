function onUpdateDatabase()
	logMigration("Updating database to version 49 (player_bounty_tasks table)")

	return db.query([[
		CREATE TABLE IF NOT EXISTS `player_bounty_tasks` (
			`player_id` INT NOT NULL,
			`state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`bounty_points` INT UNSIGNED NOT NULL DEFAULT 0,
			`reroll_tokens` TINYINT UNSIGNED NOT NULL DEFAULT 3,
			`free_reroll` BIGINT NOT NULL DEFAULT 0,
			`active_raceid` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
			`active_kills` INT UNSIGNED NOT NULL DEFAULT 0,
			`active_required` INT UNSIGNED NOT NULL DEFAULT 0,
			`active_reward_exp` INT UNSIGNED NOT NULL DEFAULT 0,
			`active_reward_pts` INT UNSIGNED NOT NULL DEFAULT 0,
			`active_grade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`active_difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`active_index` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`active_claim_state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_damage` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_lifeleech` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_loot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_bestiary` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_damage_upgrade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_lifeleech_upgrade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_loot_upgrade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`talisman_bestiary_upgrade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`preferred_lists` TEXT NOT NULL,
			`creatures_list` TEXT NOT NULL,
			`reroll_mode` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`upgrade` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])
end