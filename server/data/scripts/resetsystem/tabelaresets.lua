ResetLevelTable = {
	useFormula = false,

	formula = {
		baseLevel     = 350,
		levelPerReset = 5,
	},

	table = {
		{ minReset =   0, maxReset =   4, levelVIP =  330, levelFree =  350 },
		{ minReset =   5, maxReset =   9, levelVIP =  340, levelFree =  355 },
		{ minReset =  10, maxReset =  14, levelVIP =  355, levelFree =  360 },
		{ minReset =  15, maxReset =  19, levelVIP =  360, levelFree =  365 },
		{ minReset =  20, maxReset =  24, levelVIP =  370, levelFree =  380 },
		{ minReset =  25, maxReset =  29, levelVIP =  380, levelFree =  390 },
		{ minReset =  30, maxReset =  34, levelVIP =  400, levelFree =  410 },
		{ minReset =  35, maxReset =  39, levelVIP =  420, levelFree =  430 },
		{ minReset =  40, maxReset =  44, levelVIP =  440, levelFree =  450 },
		{ minReset =  45, maxReset =  49, levelVIP =  470, levelFree =  480 },
		{ minReset =  50, maxReset =  54, levelVIP =  500, levelFree =  510 },
		{ minReset =  55, maxReset =  59, levelVIP =  540, levelFree =  550 },
		{ minReset =  60, maxReset =  64, levelVIP =  580, levelFree =  590 },
		{ minReset =  65, maxReset =  69, levelVIP =  620, levelFree =  630 },
		{ minReset =  70, maxReset =  74, levelVIP =  670, levelFree =  680 },
		{ minReset =  75, maxReset =  79, levelVIP =  720, levelFree =  730 },
		{ minReset =  80, maxReset =  84, levelVIP =  770, levelFree =  780 },
		{ minReset =  85, maxReset =  89, levelVIP =  840, levelFree =  860 },
		{ minReset =  90, maxReset =  94, levelVIP =  910, levelFree =  930 },
		{ minReset =  95, maxReset =  99, levelVIP =  990, levelFree = 1010 },
		{ minReset = 100, maxReset = 104, levelVIP = 1090, levelFree = 1130 },
		{ minReset = 105, maxReset = 109, levelVIP = 1190, levelFree = 1230 },
		{ minReset = 110, maxReset = 114, levelVIP = 1290, levelFree = 1330 },
		{ minReset = 115, maxReset = 119, levelVIP = 1490, levelFree = 1530 },
		{ minReset = 120, maxReset = 129, levelVIP = 1690, levelFree = 1730 },
		{ minReset = 130, maxReset = 139, levelVIP = 1890, levelFree = 1990 },
		{ minReset = 140, maxReset = 149, levelVIP = 2100, levelFree = 2200 },
		{ minReset = 150, maxReset = 160, levelVIP = 2275, levelFree = 2450 },
		{ minReset = 161, maxReset = 165, levelVIP = 2465, levelFree = 2700 },
		{ minReset = 166, maxReset = 175, levelVIP = 2675, levelFree = 2800 },
		{ minReset = 176, maxReset = 185, levelVIP = 2885, levelFree = 2950 },
		{ minReset = 186, maxReset = 190, levelVIP = 2950, levelFree = 3000 },
		{ minReset = 191, maxReset = 210, levelVIP = 3001, levelFree = 3001 },
		{ minReset = 211, maxReset = 220, levelVIP = 3100, levelFree = 3150 },
		{ minReset = 221, maxReset = 225, levelVIP = 3150, levelFree = 3250 },
	},
}

function ResetLevelTable.getRequiredLevel(currentResets, isVip)
	if ResetLevelTable.useFormula then
		return ResetLevelTable.formula.baseLevel + (ResetLevelTable.formula.levelPerReset * currentResets)
	end

	for _, entry in ipairs(ResetLevelTable.table) do
		if currentResets >= entry.minReset and currentResets <= entry.maxReset then
			return isVip and entry.levelVIP or entry.levelFree
		end
	end
	local last = ResetLevelTable.table[#ResetLevelTable.table]
	return isVip and last.levelVIP or last.levelFree
end
