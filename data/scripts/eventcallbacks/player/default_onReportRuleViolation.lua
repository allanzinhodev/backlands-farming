local function hasPendingReport(name, targetName, reportType)
	local f = io.open(string.format("data/reports/players/%s-%s-%d.txt", name,
	                                targetName, reportType), "r")
	if f then
		f:close()
		return true
	else
		return false
	end
end

local reportTypeNames = {
	[REPORT_TYPE_NAME] = "Name report",
	[REPORT_TYPE_STATEMENT] = "Statement report",
	[REPORT_TYPE_BOT] = "Player behavior report"
}

local reportReasonNames = {
	[REPORT_REASON_NAMEINAPPROPRIATE] = "Inappropriate name",
	[REPORT_REASON_NAMEPOORFORMATTED] = "Invalid name format",
	[REPORT_REASON_NAMEADVERTISING] = "Advertising in name",
	[REPORT_REASON_NAMEUNFITTING] = "Unsuitable name",
	[REPORT_REASON_NAMERULEVIOLATION] = "Name inciting rule violation",
	[REPORT_REASON_INSULTINGSTATEMENT] = "Offensive statement",
	[REPORT_REASON_SPAMMING] = "Spamming",
	[REPORT_REASON_ADVERTISINGSTATEMENT] = "Advertising statement",
	[REPORT_REASON_UNFITTINGSTATEMENT] = "Off-topic statement",
	[REPORT_REASON_LANGUAGESTATEMENT] = "Language violation",
	[REPORT_REASON_DISCLOSURE] = "Private data disclosure",
	[REPORT_REASON_RULEVIOLATION] = "Rule violation or abusive behavior",
	[REPORT_REASON_STATEMENT_BUGABUSE] = "Bug abuse",
	[REPORT_REASON_UNOFFICIALSOFTWARE] = "Unofficial software, bot or hack",
	[REPORT_REASON_PRETENDING] = "Pretending to influence rule enforcement",
	[REPORT_REASON_HARASSINGOWNERS] = "Threatening staff",
	[REPORT_REASON_FALSEINFO] = "False information or false report",
	[REPORT_REASON_ACCOUNTSHARING] = "Account sharing or trading",
	[REPORT_REASON_STEALINGDATA] = "Attempt to steal data",
	[REPORT_REASON_SERVICEATTACKING] = "Service attack",
	[REPORT_REASON_SERVICEAGREEMENT] = "Service agreement violation"
}

local function getReportTypeName(reportType)
	return reportTypeNames[reportType] or string.format("Unknown report type (%d)", reportType)
end

local function getReportReasonName(reportReason)
	return reportReasonNames[reportReason] or string.format("Unknown report reason (%d)", reportReason)
end

local event = Event()

event.onReportRuleViolation = function(self, targetName, reportType,
                                       reportReason, comment, translation)
	local name = self:getName()
	if hasPendingReport(name, targetName, reportType) then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your report is being processed.")
		return
	end

	local file = io.open(string.format("data/reports/players/%s-%s-%d.txt", name,
	                                   targetName, reportType), "a")
	if not file then
		self:sendTextMessage(MESSAGE_EVENT_ADVANCE,
		                     "There was an error when processing your report, please contact a gamemaster.")
		return
	end

	local position = self:getPosition()
	file:write("------------------------------\n")
	file:write("Player report submitted for staff review\n")
	file:write("Reported by: " .. name .. "\n")
	file:write(string.format("Reporter position: %d, %d, %d\n", position.x, position.y, position.z))
	file:write("Reported player: " .. targetName .. "\n")
	file:write(string.format("Report type: %s [%d]\n", getReportTypeName(reportType), reportType))
	file:write(string.format("Reason: %s [%d]\n", getReportReasonName(reportReason), reportReason))
	file:write("Comment: " .. comment .. "\n")
	if translation ~= "" then
		file:write("Statement/translation: " .. translation .. "\n")
	end
	file:write("------------------------------\n")
	file:close()
	self:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
		                     "Thank you for reporting %s. Your report will be processed by %s team as soon as possible.",
		                     targetName,
		                     configManager.getString(configKeys.SERVER_NAME)))
end

event:register()
