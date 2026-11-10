// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_TALKACTION_H
#define FS_TALKACTION_H

#include "baseevents.h"
#include "const.h"
#include "luascript.h"

class TalkAction;
using TalkAction_ptr = std::unique_ptr<TalkAction>;

enum class TalkActionResult
{
	CONTINUE,
	BREAK,
	FAILED,
};

class TalkAction : public Event
{
public:
	explicit TalkAction(LuaScriptInterface* interface) : Event(interface) {}

	std::string_view getWords() const { return words; }
	auto stealWordsMap()
	{
		std::vector<std::string> ret{};
		std::swap(wordsMap, ret);
		return ret;
	}
	void setWords(std::string_view word)
	{
		words = word;
		wordsMap.emplace_back(word);
	}
	std::string_view getSeparator() const { return separator; }
	void setSeparator(std::string_view sep) { separator = sep; }

	// scripting
	bool executeSay(Player* player, std::string_view words, std::string_view param, SpeakClasses type) const;

	AccountType_t getRequiredAccountType() const { return requiredAccountType; }

	void setRequiredAccountType(AccountType_t reqAccType) { requiredAccountType = reqAccType; }

	bool getNeedAccess() const { return needAccess; }

	void setNeedAccess(bool b) { needAccess = b; }

	int32_t getExhaustion() const { return exhaustion; }
	void setExhaustion(int32_t val) { exhaustion = val; }

	const std::string& getExhaustionMessage() const { return exhaustionMessage; }
	void setExhaustionMessage(std::string_view msg) { exhaustionMessage = msg; }
	MessageClasses getExhaustionMessageType() const { return exhaustionMessageType; }
	void setExhaustionMessageType(MessageClasses type) { exhaustionMessageType = type; }

private:
	std::string_view getScriptEventName() const override { return "onSay"; }

	std::string words;
	std::vector<std::string> wordsMap;
	std::string separator = "\"";
	bool needAccess = false;
	AccountType_t requiredAccountType = ACCOUNT_TYPE_NORMAL;
	int32_t exhaustion = -1;
	std::string exhaustionMessage;
	MessageClasses exhaustionMessageType = MESSAGE_STATUS_SMALL;
};

class TalkActions final : public BaseEvents
{
public:
	TalkActions();
	~TalkActions();

	// non-copyable
	TalkActions(const TalkActions&) = delete;
	TalkActions& operator=(const TalkActions&) = delete;

	TalkActionResult playerSaySpell(Player* player, SpeakClasses type, std::string_view words) const;

	bool registerLuaEvent(TalkAction_ptr event);
	void clear(bool fromLua) override final;

	const auto& getTalkactions() const { return talkActions; }

private:
	LuaScriptInterface& getScriptInterface() override;
	std::string_view getScriptBaseName() const override { return "talkactions"; }

	std::map<std::string, TalkAction> talkActions;

	LuaScriptInterface scriptInterface;
};

#endif
