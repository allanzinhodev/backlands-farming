function onUpdateDatabase()
	logMigration("Updating database to version 50 (player_weekly_tasks table)")

	return db.query([[
		CREATE TABLE IF NOT EXISTS `player_weekly_tasks` (
			`player_id` INT NOT NULL,
			`has_expansion` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`any_creature_total` INT UNSIGNED NOT NULL DEFAULT 0,
			`any_creature_current` INT UNSIGNED NOT NULL DEFAULT 0,
			`completed_kill_tasks` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`completed_delivery_tasks` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`kill_task_reward_exp` INT UNSIGNED NOT NULL DEFAULT 0,
			`delivery_task_reward_exp` INT UNSIGNED NOT NULL DEFAULT 0,
			`reward_hunting_points` INT UNSIGNED NOT NULL DEFAULT 0,
			`reward_soulseals` INT UNSIGNED NOT NULL DEFAULT 0,
			`soulseals_points` INT UNSIGNED NOT NULL DEFAULT 0,
			`needs_reward` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`weekly_progress_finished` TINYINT UNSIGNED NOT NULL DEFAULT 0,
			`kill_tasks` TEXT NOT NULL,
			`delivery_tasks` TEXT NOT NULL,
			`last_week` VARCHAR(10) NOT NULL DEFAULT '',
			`last_item_notify` BIGINT NOT NULL DEFAULT 0,
			PRIMARY KEY (`player_id`),
			FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8
	]])
end
