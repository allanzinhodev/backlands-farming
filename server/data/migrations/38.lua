function onUpdateDatabase()
	logMigration("> Updating database to version 39 (prey free list reroll marker)")

	local resultId = db.storeQuery(
		"SELECT COUNT(*) AS `count` FROM `information_schema`.`COLUMNS`"
		.. " WHERE `TABLE_SCHEMA` = DATABASE()"
		.. " AND `TABLE_NAME` = 'player_prey'"
		.. " AND `COLUMN_NAME` = 'list_reroll_used'"
	)
	local exists = false
	if resultId then
		exists = result.getNumber(resultId, "count") > 0
		result.free(resultId)
	end

	if not exists then
		db.query("ALTER TABLE `player_prey` ADD `list_reroll_used` TINYINT(1) NOT NULL DEFAULT 0")
	end

	db.query([[
		UPDATE `player_prey`
		SET `reroll_at` = 0
		WHERE `list_reroll_used` = 0
			AND `state` = 1
			AND `monster_name` = ''
	]])

	return true
end
