// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "luascript.h"
#include "script.h"
#include "scriptmanager.h"
#include "talkaction.h"

namespace {
using namespace Lua;

// TalkAction
int luaCreateTalkaction(lua_State* L)
{
	// TalkAction(words)
	if (LuaScriptInterface::getScriptEnv()->getScriptInterface() != &g_scripts->getScriptInterface()) {
		reportErrorFunc(L, "TalkActions can only be registered in the Scripts interface.");
		lua_pushnil(L);
		return 1;
	}

	auto talk = std::make_unique<TalkAction>(LuaScriptInterface::getScriptEnv()->getScriptInterface());
	for (int i = 2; i <= lua_gettop(L); i++) {
		talk->setWords(getString(L, i));
	}
	talk->fromLua = true;
	pushOwnedUserdata<TalkAction>(L, std::move(talk));
	setMetatable(L, -1, "TalkAction");
	return 1;
}

int luaTalkactionOnSay(lua_State* L)
{
	// talkAction:onSay(callback)
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (!talk->loadCallback()) {
			pushBoolean(L, false);
			return 1;
		}
		pushBoolean(L, true);
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionRegister(lua_State* L)
{
	// talkAction:register()
	if (auto talk = getUserdata<TalkAction>(L, 1)) {
		if (!talk->isScripted()) {
			pushBoolean(L, false);
			return 1;
		}

		pushBoolean(L, g_talkActions->registerLuaEvent(releaseOwnedUserdataPtr<TalkAction>(L, 1)));
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionGetWords(lua_State* L)
{
	// talkAction:words()
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		pushString(L, talk->getWords());
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionSeparator(lua_State* L)
{
	// get: talkAction:separator() set: talkAction:separator(sep)
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (lua_gettop(L) == 1) {
			pushString(L, talk->getSeparator());
		} else {
			talk->setSeparator(getString(L, 2));
			pushBoolean(L, true);
		}
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionAccess(lua_State* L)
{
	// get: talkAction:access() set: talkAction:access(needAccess = false)
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (lua_gettop(L) == 1) {
			pushBoolean(L, talk->getNeedAccess());
		} else {
			talk->setNeedAccess(getBoolean(L, 2));
			pushBoolean(L, true);
		}
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionAccountType(lua_State* L)
{
	// get: talkAction:accountType() set: talkAction:accountType(AccountType_t = ACCOUNT_TYPE_NORMAL)
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (lua_gettop(L) == 1) {
			lua_pushinteger(L, talk->getRequiredAccountType());
		} else {
			talk->setRequiredAccountType(getInteger<AccountType_t>(L, 2));
			pushBoolean(L, true);
		}
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionExhaustion(lua_State* L)
{
	// get: talkAction:exhaustion() set: talkAction:exhaustion(timeMs or bool)
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (lua_gettop(L) == 1) {
			lua_pushinteger(L, talk->getExhaustion());
		} else {
			if (lua_isboolean(L, 2)) {
				talk->setExhaustion(getBoolean(L, 2) ? -1 : 0);
			} else {
				talk->setExhaustion(getInteger<int32_t>(L, 2));
			}
			pushBoolean(L, true);
		}
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaTalkactionExhaustionMessage(lua_State* L)
{
	// get: talkAction:exhaustionMessage() set: talkAction:exhaustionMessage(msg, [msgType = MESSAGE_STATUS_SMALL])
	TalkAction* talk = getUserdata<TalkAction>(L, 1);
	if (talk) {
		if (lua_gettop(L) == 1) {
			pushString(L, talk->getExhaustionMessage());
		} else {
			talk->setExhaustionMessage(getString(L, 2));
			if (lua_gettop(L) >= 3) {
				talk->setExhaustionMessageType(getInteger<MessageClasses>(L, 3));
			} else {
				talk->setExhaustionMessageType(MESSAGE_STATUS_SMALL);
			}
			pushBoolean(L, true);
		}
	} else {
		lua_pushnil(L);
	}
	return 1;
}

int luaDeleteTalkAction(lua_State* L)
{
	return deleteOwnedUserdata(L);
}
} // namespace

void LuaScriptInterface::registerTalkActions()
{
	// TalkAction
	registerClass("TalkAction", "", luaCreateTalkaction);
	registerMetaMethod("TalkAction", "__gc", luaDeleteTalkAction);
	registerMetaMethod("TalkAction", "__close", luaDeleteTalkAction);
	registerMethod("TalkAction", "delete", luaDeleteTalkAction);

	registerMethod("TalkAction", "onSay", luaTalkactionOnSay);
	registerMethod("TalkAction", "register", luaTalkactionRegister);
	registerMethod("TalkAction", "getWords", luaTalkactionGetWords);
	registerMethod("TalkAction", "separator", luaTalkactionSeparator);
	registerMethod("TalkAction", "access", luaTalkactionAccess);
	registerMethod("TalkAction", "accountType", luaTalkactionAccountType);
	registerMethod("TalkAction", "exhaustion", luaTalkactionExhaustion);
	registerMethod("TalkAction", "exhaustionMessage", luaTalkactionExhaustionMessage);
}
