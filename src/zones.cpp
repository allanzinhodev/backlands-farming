// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "zones.h"

#include "game.h"
#include "logger.h"
#include "tile.h"

#include <algorithm>

extern Game g_game;

namespace {
std::map<ZoneId, Zones::ZonePtr> g_zones;
std::multimap<Position, ZoneId> g_positionZones;

std::vector<ZoneId> normalizeZoneIds(std::vector<ZoneId> zoneIds)
{
	zoneIds.erase(std::remove(zoneIds.begin(), zoneIds.end(), ZoneId{}), zoneIds.end());
	std::sort(zoneIds.begin(), zoneIds.end());
	zoneIds.erase(std::unique(zoneIds.begin(), zoneIds.end()), zoneIds.end());
	return zoneIds;
}
}

Zone::Zone(ZoneId id, std::vector<Position> positions) : id(id), positions(std::move(positions)) {}

void Zone::addPosition(const Position& position)
{
	if (std::find(positions.begin(), positions.end(), position) == positions.end()) {
		positions.emplace_back(position);
	}
}

void Zone::removePosition(const Position& position)
{
	positions.erase(std::remove(positions.begin(), positions.end(), position), positions.end());
}

Zones::ZonePtr Zones::getOrCreateZone(ZoneId id)
{
	if (id == 0) {
		return nullptr;
	}

	if (const auto zone = getZone(id)) {
		return zone;
	}

	auto zone = std::make_shared<Zone>(id);
	g_zones.emplace(id, zone);
	return zone;
}

bool Zones::load()
{
	LOG_INFO(">> Native OTBM zone metadata will be indexed while loading the map.");
	return true;
}

void Zones::clear()
{
	g_zones.clear();
	g_positionZones.clear();
}

bool Zones::reload()
{
	LOG_WARN("[Warning - Zones::reload] XML zone reload is deprecated. Native zones are rebuilt when the OTBM map is loaded.");
	return true;
}

size_t Zones::count() { return g_zones.size(); }

std::vector<Zones::ZonePtr> Zones::getAll()
{
	std::vector<Zones::ZonePtr> zones;
	zones.reserve(g_zones.size());

	for (const auto& [id, zone] : g_zones) {
		(void)id;
		zones.emplace_back(zone);
	}

	return zones;
}

Zones::ZonePtr Zones::getZone(ZoneId id)
{
	if (const auto it = g_zones.find(id); it != g_zones.end()) {
		return it->second;
	}
	return nullptr;
}

Zones::ZonePtr Zones::createZone(ZoneId id, std::vector<Position> positions)
{
	if (id == 0) {
		LOG_WARN("[Warning - Zones::createZone] Zone id 0 is not allowed.");
		return nullptr;
	}

	if (const auto existingZone = getZone(id)) {
		return existingZone;
	}

	if (positions.empty()) {
		LOG_WARN("[Warning - Zones::createZone] Zone {} has no positions and was skipped.", id);
		return nullptr;
	}

	const auto zone = getOrCreateZone(id);
	for (const Position& position : positions) {
		std::vector<ZoneId> zoneIds = getZonesByPosition(position);
		zoneIds.emplace_back(id);

		if (Tile* tile = g_game.map.getTile(position)) {
			tile->addZoneId(id);
			zoneIds = tile->getZoneIds();
		}

		registerPositionZones(position, std::move(zoneIds));
	}

	return zone;
}

std::vector<ZoneId> Zones::getZonesByPosition(const Position& position)
{
	std::vector<ZoneId> zoneIds;
	const auto [begin, end] = g_positionZones.equal_range(position);
	for (auto it = begin; it != end; ++it) {
		zoneIds.emplace_back(it->second);
	}

	std::sort(zoneIds.begin(), zoneIds.end());
	zoneIds.erase(std::unique(zoneIds.begin(), zoneIds.end()), zoneIds.end());
	return zoneIds;
}

void Zones::unregisterPosition(const Position& position)
{
	std::vector<ZoneId> previousZoneIds;
	const auto [begin, end] = g_positionZones.equal_range(position);
	for (auto it = begin; it != end; ++it) {
		previousZoneIds.emplace_back(it->second);
	}

	if (previousZoneIds.empty()) {
		return;
	}

	g_positionZones.erase(begin, end);
	for (ZoneId zoneId : previousZoneIds) {
		if (const auto it = g_zones.find(zoneId); it != g_zones.end()) {
			it->second->removePosition(position);
			if (it->second->getPositions().empty()) {
				g_zones.erase(it);
			}
		}
	}
}

void Zones::registerPositionZones(const Position& position, std::vector<ZoneId> zoneIds)
{
	zoneIds = normalizeZoneIds(std::move(zoneIds));
	unregisterPosition(position);

	for (ZoneId zoneId : zoneIds) {
		const auto zone = getOrCreateZone(zoneId);
		if (!zone) {
			continue;
		}

		zone->addPosition(position);
		g_positionZones.emplace(position, zoneId);
	}
}
