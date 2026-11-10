function onUpdateDatabase()
	logMigration("Updating database to version 41 (Reset System: verify resets column)")

	local resultId = db.storeQuery(
		"SELECT COUNT(*) AS `cnt` FROM `information_schema`.`COLUMNS`"
		.. " WHERE `TABLE_SCHEMA` = DATABASE()"
		.. "   AND `TABLE_NAME`   = 'players'"
		.. "   AND `COLUMN_NAME`  = 'reset'"
	)
	local exists = false
	if resultId then
		exists = result.getNumber(resultId, "cnt") > 0
		result.free(resultId)
	end

	if not exists then
		local success = db.query("ALTER TABLE `players` ADD COLUMN `reset` int(11) NOT NULL DEFAULT 0 AFTER `level`")
		if not success then
			logMigration("Failed to add `reset` column to `players` table")
			return false
		end
	end

	return true
end
