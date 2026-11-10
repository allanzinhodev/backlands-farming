// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_THING_H
#define FS_THING_H

#include "position.h"

#include <memory>

class Tile;
class Cylinder;
class Item;
class Creature;
class Container;
class Player;

using TilePtr = std::shared_ptr<Tile>;
using TileWeakPtr = std::weak_ptr<Tile>;
using ItemPtr = std::shared_ptr<Item>;
using ItemWeakPtr = std::weak_ptr<Item>;
using ContainerPtr = std::shared_ptr<Container>;
using ContainerWeakPtr = std::weak_ptr<Container>;
using PlayerPtr = std::shared_ptr<Player>;
using PlayerWeakPtr = std::weak_ptr<Player>;

class Thing
{
public:
	constexpr Thing() = default;
	virtual ~Thing() = default;

	// non-copyable
	Thing(const Thing&) = delete;
	Thing& operator=(const Thing&) = delete;

	virtual Cylinder* getParent() const { return nullptr; }
	virtual Cylinder* getRealParent() const { return getParent(); }

	virtual void setParent(Cylinder*)
	{
		//
	}

	virtual const Position& getPosition() const;
	virtual int32_t getThrowRange() const = 0;
	virtual bool isPushable() const = 0;

	virtual Tile* getTile() { return nullptr; }
	virtual const Tile* getTile() const { return nullptr; }
	virtual Item* getItem() { return nullptr; }
	virtual const Item* getItem() const { return nullptr; }
	virtual Creature* getCreature() { return nullptr; }
	virtual const Creature* getCreature() const { return nullptr; }

	virtual bool isRemoved() const { return true; }

	uint32_t getInstanceID() const { return instanceID; }
	void setInstanceID(uint32_t id) { instanceID = id; }
	bool compareInstance(uint32_t id) const { return instanceID == id; }

private:
	uint32_t instanceID = 0;
};

#endif
