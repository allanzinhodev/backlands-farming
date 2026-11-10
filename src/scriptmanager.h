// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_SCRIPTMANAGER_H
#define FS_SCRIPTMANAGER_H

#include <memory>

// Forward declarations
class Actions;
class Chat;
class CreatureEvents;
class Events;
class GlobalEvents;
class MoveEvents;
class Scripts;
class Spells;
class TalkActions;
class Weapons;

// Centralized extern declarations — owned by ScriptingManager via unique_ptr
extern std::unique_ptr<Actions> g_actions;
extern Chat *g_chat;
extern CreatureEvents *g_creatureEvents;
extern Events *g_events;
extern GlobalEvents *g_globalEvents;
extern std::unique_ptr<MoveEvents> g_moveEvents;
extern std::unique_ptr<Scripts> g_scripts;
extern std::unique_ptr<Spells> g_spells;
extern std::unique_ptr<TalkActions> g_talkActions;
extern Weapons *g_weapons;

class ScriptingManager
{
public:
	ScriptingManager() = default;
	~ScriptingManager();

	// non-copyable
	ScriptingManager(const ScriptingManager&) = delete;
	ScriptingManager& operator=(const ScriptingManager&) = delete;

	static ScriptingManager& getInstance();

	bool loadPreItems();
	bool loadScriptSystems();

private:
	// Ownership via unique_ptr — declared in reverse destruction order
	// (members are destroyed in reverse declaration order)
	std::unique_ptr<GlobalEvents> globalEvents_;
	std::unique_ptr<CreatureEvents> creatureEvents_;
	std::unique_ptr<Chat> chat_;
	std::unique_ptr<Weapons> weapons_;
	std::unique_ptr<Events> events_;
};

#endif
