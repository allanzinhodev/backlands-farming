// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "storeinbox.h"
#include "tools.h"

StoreInbox::StoreInbox(uint16_t type) : Container(type, 20) {}

ReturnValue StoreInbox::queryAdd(int32_t index, const Thing& thing, uint32_t count, uint32_t flags, Creature* actor) const
{
	if (actor) {
		return RETURNVALUE_NOTPOSSIBLE;
	}

	return Container::queryAdd(index, thing, count, flags, actor);
}

void StoreInbox::postAddNotification(Thing* thing, const Cylinder* oldParent, int32_t index, cylinderlink_t)
{
	Cylinder* parent = getParent();
	if (parent != nullptr) {
		parent->postAddNotification(thing, oldParent, index, LINK_PARENT);
	}
}

void StoreInbox::postRemoveNotification(Thing* thing, const Cylinder* newParent, int32_t index, cylinderlink_t)
{
	Cylinder* parent = getParent();
	if (parent != nullptr) {
		parent->postRemoveNotification(thing, newParent, index, LINK_PARENT);
	}
}
