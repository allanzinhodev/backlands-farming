-- Spy PM Logger - Keywords to monitor private messages
-- Edit the list below without recompiling the server

local config = {
	logDir = "data/log/spy/",
	keywords = {
		"pix", "cpf", "chave", "transfere", "transferencia",
		"deposita", "pagamento", "real", "reais", "conta", "banco",
		"paypal", "mercadopago", "nubank", "picpay",
		"dinheiro", "boleto", "cartao", "credito", "debito",
	},
}

local function normalize(text)
	if not text then return "" end
	text = text:lower()
	local map = {
		["á"] = "a", ["à"] = "a", ["ã"] = "a", ["â"] = "a",
		["é"] = "e", ["è"] = "e", ["ê"] = "e",
		["í"] = "i", ["ì"] = "i", ["î"] = "i",
		["ó"] = "o", ["ò"] = "o", ["õ"] = "o", ["ô"] = "o",
		["ú"] = "u", ["ù"] = "u", ["û"] = "u",
		["ç"] = "c", ["ñ"] = "n",
	}
	for accent, plain in pairs(map) do
		text = text:gsub(accent, plain)
	end
	return text
end

function checkPrivateMessage(senderName, receiverName, text)
	local normalized = normalize(text)

	local matched = false
	for _, kw in ipairs(config.keywords) do
		if normalized:find(kw, 1, true) then
			matched = true
			break
		end
	end

	if not matched then
		return
	end

	local date = os.date("%Y-%m-%d")
	local time = os.date("%H:%M:%S")
	local logPath = config.logDir .. "private_" .. date .. ".log"

	os.execute("mkdir -p '" .. config.logDir .. "'")

	local file = io.open(logPath, "a")
	if file then
		file:write(string.format("[%s %s] [PRIVATE] %s -> %s: \"%s\"\n",
			date, time, senderName, receiverName, text))
		file:close()
	end
end
