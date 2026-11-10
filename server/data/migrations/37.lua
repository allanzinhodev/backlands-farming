function onUpdateDatabase()
	logMigration("> Updating database to version 38 (player prey cards and charm points)")

	local function columnExists(tableName, columnName)
		local resultId = db.storeQuery(
			"SELECT COUNT(*) AS `count` FROM `information_schema`.`COLUMNS`"
			.. " WHERE `TABLE_SCHEMA` = DATABASE()"
			.. " AND `TABLE_NAME` = " .. db.escapeString(tableName)
			.. " AND `COLUMN_NAME` = " .. db.escapeString(columnName)
		)
		if not resultId then
			return false
		end

		local exists = result.getNumber(resultId, "count") > 0
		result.free(resultId)
		return exists
	end

	if not columnExists("players", "bonus_rerolls") then
		db.query("ALTER TABLE `players` ADD `bonus_rerolls` BIGINT UNSIGNED NOT NULL DEFAULT 0")
	end

	if not columnExists("players", "charmpoints") then
		db.query("ALTER TABLE `players` ADD `charmpoints` INT UNSIGNED NOT NULL DEFAULT 0")
	end

	db.query([[
		UPDATE `players` p
		INNER JOIN `player_prey` pp
			ON pp.`player_id` = p.`id` AND pp.`slot` = 0
		SET p.`bonus_rerolls` = pp.`wildcards`
		WHERE p.`bonus_rerolls` = 0 AND pp.`wildcards` > 0
	]])

	return true
end
