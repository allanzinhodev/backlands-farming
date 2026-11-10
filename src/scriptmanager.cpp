// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "scriptmanager.h"

#include "actions.h"
#include "chat.h"
#include "events.h"
#include "globalevent.h"
#include "movement.h"
#include "npc.h"
#include "script.h"
#include "spells.h"
#include "talkaction.h"
#include "weapons.h"
#include "logger.h"

ScriptingManager& ScriptingManager::getInstance()
{
	static ScriptingManager instance;
	return instance;
}

std::unique_ptr<Actions> g_actions = nullptr;
CreatureEvents* g_creatureEvents = nullptr;
Chat* g_chat = nullptr;
Events* g_events = nullptr;
GlobalEvents* g_globalEvents = nullptr;
std::unique_ptr<Spells> g_spells = nullptr;
std::unique_ptr<TalkActions> g_talkActions = nullptr;
std::unique_ptr<MoveEvents> g_moveEvents = nullptr;
Weapons* g_weapons = nullptr;
std::unique_ptr<Scripts> g_scripts = nullptr;

extern LuaEnvironment g_luaEnvironment;

ScriptingManager::~ScriptingManager()
{
	g_events = nullptr;
	events_.reset();
	g_weapons = nullptr;
	weapons_.reset();
	g_spells.reset();
	g_actions.reset();
	g_talkActions.reset();
	g_moveEvents.reset();
	g_chat = nullptr;
	chat_.reset();
	g_creatureEvents = nullptr;
	creatureEvents_.reset();
	g_globalEvents = nullptr;
	globalEvents_.reset();
	g_scripts.reset();
}

bool ScriptingManager::loadPreItems()
{
	// Ensure g_luaEnvironment is properly initialized
	if (!g_luaEnvironment.getLuaState()) {
		if (!g_luaEnvironment.initState()) {
			LOG_ERROR("> ERROR: Failed to initialize Lua environment!");
			return false;
		}
	}

	if (!weapons_) {
		weapons_ = std::make_unique<Weapons>();
		g_weapons = weapons_.get();
	}
	if (!g_moveEvents) {
		g_moveEvents = std::make_unique<MoveEvents>();
	}

	return true;
}

bool ScriptingManager::loadScriptSystems()
{
	// Ensure g_luaEnvironment is properly initialized
	if (!g_luaEnvironment.getLuaState()) {
		if (!g_luaEnvironment.initState()) {
			LOG_ERROR("> ERROR: Failed to initialize Lua environment!");
			return false;
		}
	}

	if (g_luaEnvironment.loadFile("data/lib/lib.lua") == -1) {
		LOG_WARN("[Warning - ScriptingManager::loadScriptSystems] Can not load " "data/lib/lib.lua");
	}

	if (g_luaEnvironment.loadFile("data/anti_advertising.lua") == -1) {
		LOG_WARN("[Warning - ScriptingManager::loadScriptSystems] Can not load " "data/anti_advertising.lua");
	}

#if defined(LUAJIT_VERSION)
	LOG_INFO(fmt::format(">> Using {}", LUAJIT_VERSION));
#else
	LOG_INFO(fmt::format(">> Using {}", LUA_VERSION));
#endif

	g_scripts = std::make_unique<Scripts>();
	LOG_INFO(">> Loading lua libs");
	if (!g_scripts->loadScripts("scripts/lib", true, false)) {
		LOG_ERROR("> ERROR: Unable to load lua libs!");
		return false;
	}

	chat_ = std::make_unique<Chat>();
	g_chat = chat_.get();

	if (!g_scripts->loadScripts("items", false, false)) {
		LOG_ERROR("> ERROR: Unable to load items (LUA)!");
		return false;
	}

	if (!weapons_) {
		weapons_ = std::make_unique<Weapons>();
		g_weapons = weapons_.get();
	}
	g_weapons->loadDefaults();
	g_spells = std::make_unique<Spells>();
	g_actions = std::make_unique<Actions>();
	g_talkActions = std::make_unique<TalkActions>();
	if (!g_moveEvents) {
		g_moveEvents = std::make_unique<MoveEvents>();
	}
	creatureEvents_ = std::make_unique<CreatureEvents>();
	g_creatureEvents = creatureEvents_.get();
	globalEvents_ = std::make_unique<GlobalEvents>();
	g_globalEvents = globalEvents_.get();

	events_ = std::make_unique<Events>();
	g_events = events_.get();
	if (!g_events->load()) {
		LOG_ERROR("> ERROR: Unable to load events!");
		return false;
	}

	Npcs::load();

	return true;
}
