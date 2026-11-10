// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "baseevents.h"

#include "tools.h"
#include "logger.h"
#include <fmt/format.h>

extern LuaEnvironment g_luaEnvironment;

bool BaseEvents::loadFromXml()
{
	if (loaded) {
		LOG_ERROR("[Error - BaseEvents::loadFromXml] It's already loaded.");
		return false;
	}

	auto scriptsName = std::string{getScriptBaseName()};
	std::string basePath = "data/" + scriptsName + "/";
	getScriptInterface().loadFile(basePath + "lib/" + scriptsName + ".lua");

	loaded = true;

	return true;
}

bool BaseEvents::reload()
{
	loaded = false;
	clear(false);
	return loadFromXml();
}

void BaseEvents::reInitState(bool fromLua)
{
	if (!fromLua) {
		getScriptInterface().reInitState();
	}
}

Event::Event(ObserverPtr<LuaScriptInterface> interface) : scriptInterface(interface) {}

bool Event::loadCallback()
{
	if (!scriptInterface || scriptId != 0) {
		LOG_ERROR(fmt::format("Failure: [Event::loadCallback] scriptInterface == " "nullptr. scriptid = {}", scriptId));
		return false;
	}

	int32_t id = scriptInterface->getEvent();
	if (id == -1) {
		LOG_WARN(fmt::format("[Warning - Event::loadCallback] Event {} not found.", getScriptEventName()));
		return false;
	}

	scripted = true;
	scriptId = id;
	return true;
}

bool Event::loadScript(const std::string& scriptFile)
{
	if (!scriptInterface || scriptId != 0) {
		LOG_ERROR(fmt::format("Failure: [Event::loadScript] scriptInterface == " "nullptr. scriptid = {}", scriptId));
		return false;
	}

	if (scriptInterface->loadFile(scriptFile) == -1) {
		LOG_WARN(fmt::format("[Warning - Event::loadScript] Can not load script: {}", scriptFile));
		return false;
	}

	int32_t id = scriptInterface->getEvent(getScriptEventName());
	if (id == -1) {
		LOG_WARN(fmt::format("[Warning - Event::loadScript] Event {} not found for script: {}", getScriptEventName(), scriptFile));
		return false;
	}

	scripted = true;
	scriptId = id;
	return true;
}

bool CallBack::loadCallBack(ObserverPtr<LuaScriptInterface> interface, std::string_view name)
{
	if (!interface) {
		LOG_ERROR(fmt::format("Failure: [CallBack::loadCallBack] scriptInterface == nullptr"));
		return false;
	}

	scriptInterface = interface;

	int32_t id = scriptInterface->getEvent(name);
	if (id == -1) {
		LOG_WARN(fmt::format("[Warning - CallBack::loadCallBack] Event {} not found.", name));
		return false;
	}

	scriptId = id;
	loaded = true;
	return true;
}

bool CallBack::loadCallBack(ObserverPtr<LuaScriptInterface> interface)
{
	if (!interface) {
		LOG_ERROR("Failure: [CallBack::loadCallBack] scriptInterface == nullptr");
		return false;
	}

	scriptInterface = interface;

	int32_t id = scriptInterface->getEvent();
	if (id == -1) {
		LOG_WARN("[Warning - CallBack::loadCallBack] Event not found.");
		return false;
	}

	scriptId = id;
	loaded = true;
	return true;
}
