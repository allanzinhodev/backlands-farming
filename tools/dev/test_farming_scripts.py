"""Execute farm Lua hooks with a small engine fixture.

Run: python -m unittest discover -s tools/dev -p test_farming_scripts.py -v
Requires the optional validation package: python -m pip install lupa
The game itself does not depend on Python or Lupa.
"""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

try:
    from lupa.lua54 import LuaRuntime
except ImportError:
    LuaRuntime = None

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "server" / "data"

ENGINE = """
_events, _shops, _npcs, _created = {}, {}, {}, {}
FLUID_WATER, MESSAGE_STATUS_DEFAULT, MESSAGE_STATUS_CONSOLE_RED = 1, 1, 2
ITEM_REWARD_CONTAINER, CONST_ME_MAGIC_GREEN = 21584, 18
nextUseStaminaTime = {[1] = 100}
configKeys = {SERVER_NAME = 1}
configManager = {getString = function() return 'Backlands' end}
WorkbenchSessions = {clearOwner = function(id) assert(id == 1) end}
ImbuingWindow = {close = function(player) assert(player:getId() == 1) end}
table.contains = function(t, value)
    for _, entry in pairs(t) do if entry == value then return true end end
    return false
end
local function node()
    return setmetatable({}, {__index = function(_, key)
        return function(self, ...) return self end
    end})
end
CreatureEvent = function(name)
    local event = {register = function(self) _events[name] = self end}
    return event
end
MoveEvent = function()
    local event = node()
    event.register = function(self) _move = self end
    return event
end
Action = function()
    local action = node()
    action.register = function(self) _action = self end
    return action
end
Game = {
    createNpcType = function(name) _npcs[name] = node(); return _npcs[name] end,
    createItem = function(id, count)
        table.insert(_created, {id = id, count = count})
        return node()
    end
}
NpcsHandler = function() return node() end
NpcShop = function(name)
    local shop = {items = {}}
    shop.addItem = function(self, id, buy, sell)
        table.insert(self.items, {id = id, buy = buy, sell = sell})
    end
    _shops[name] = shop
    return shop
end
function playerFixture(lastLogin)
    local player = {items = {}, messages = {}, channels = {}, lastLogin = lastLogin}
    function player:getLastLoginSaved() return self.lastLogin end
    function player:addItem(id, count)
        table.insert(self.items, {id = id, count = count or 1})
        if id == 2854 then
            return {addItem = function(_, childId, childCount)
                table.insert(player.items, {id = childId, count = childCount})
            end}
        end
    end
    function player:sendTextMessage(kind, message) table.insert(self.messages, message) end
    function player:getRewardChest() return {getItems = function() return {} end} end
    function player:sendOutfitWindow() self.outfitOpened = true end
    function player:updateStamina() self.staminaUpdated = true end
    function player:registerEvent(name) self.registeredEvent = name end
    function player:openChannel(id) table.insert(self.channels, id) end
    function player:isTokenProtected() return false end
    function player:getId() return 1 end
    function player:addAchievementProgress() end
    return player
end
"""


@unittest.skipIf(LuaRuntime is None, "install optional validation dependency: lupa")
class FarmingScriptsTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(ENGINE)

    def execute(self, relative_path):
        self.lua.execute((DATA / relative_path).read_text(encoding="utf-8-sig"))

    def test_remaining_lua_has_valid_syntax(self):
        compile_lua = self.lua.eval(
            "function(source, name) local f, e = load(source, name); return f ~= nil, e end"
        )
        for path in DATA.rglob("*.lua"):
            with self.subTest(path=path.relative_to(DATA)):
                valid, error = compile_lua(path.read_text(encoding="utf-8-sig"), str(path))
                self.assertTrue(valid, error)

    def test_shops_trade_real_items_without_supply_resale_profit(self):
        self.execute("npc/lua/farming/seed_vendor.lua")
        self.execute("npc/lua/farming/harvest_buyer.lua")
        catalog = set()
        for item in ET.parse(DATA / "items/items.xml").getroot():
            if "id" in item.attrib:
                catalog.add(int(item.attrib["id"]))
            elif "fromid" in item.attrib:
                catalog.update(range(int(item.attrib["fromid"]), int(item.attrib["toid"]) + 1))
        shops = self.lua.globals()._shops
        vendor = {entry.id: entry for entry in shops["Seed Vendor"]["items"].values()}
        buyer = {entry.id: entry for entry in shops["Harvest Buyer"]["items"].values()}
        self.assertTrue({647, 306, 650, 3453, 3492}.issubset(vendor))
        self.assertTrue({3605, 3603, 3600, 3588, 3578}.issubset(buyer))
        for item_id, entry in vendor.items():
            self.assertIn(item_id, catalog)
            self.assertGreater(entry.buy, 0)
            self.assertEqual(entry.sell, 0)
            if item_id in buyer:
                self.assertLessEqual(buyer[item_id].sell, entry.buy)
        for item_id, entry in buyer.items():
            self.assertIn(item_id, catalog)
            self.assertEqual(entry.buy, 0)
            self.assertGreater(entry.sell, 0)

    def test_first_login_supplies_farming_and_relogin_does_not_duplicate(self):
        self.execute("scripts/creaturescripts/others/firstitems.lua")
        self.lua.execute("p = playerFixture(0); assert(_events.FirstItems.onLogin(p))")
        supplied = {entry.id: entry.count for entry in self.lua.globals().p["items"].values()}
        self.assertEqual(supplied[3492], 20)
        self.assertEqual(supplied[647], 10)
        self.assertEqual(supplied[2873], 1)
        self.assertTrue({2854, 3003, 3453, 3457, 3483, 650, 306}.issubset(supplied))
        self.lua.execute("p.lastLogin = 1; assert(_events.FirstItems.onLogin(p))")
        self.assertEqual(len(self.lua.globals().p["items"]), len(supplied))

    def test_farmer_login_and_logout_do_not_require_a_promotion(self):
        self.execute("scripts/creaturescripts/others/player_login_logout.lua")
        self.lua.execute("""
            p = playerFixture(0)
            assert(_events.loginMessage.onLogin(p))
            assert(p.outfitOpened and p.staminaUpdated)
            assert(p.registeredEvent == 'logoutMessage')
            assert(_events.logoutMessage.onLogout(p))
            assert(nextUseStaminaTime[1] == nil)
        """)

    def test_scythe_yields_wheat_and_restarts_growth(self):
        self.execute("scripts/lib/register_actions.lua")
        self.lua.execute("""
            local target = {itemid = 3653}
            function target:transform(id) self.itemid = id end
            function target:decay() self.decaying = true end
            assert(onUseScythe(playerFixture(1), {itemid = 3453}, {}, target, {}, false))
            assert(target.itemid == 3651 and target.decaying)
            assert(#_created == 1 and _created[1].id == 3605 and _created[1].count == 1)
        """)

    def test_pond_catch_can_be_sold_to_the_harvest_buyer(self):
        self.execute("npc/lua/farming/harvest_buyer.lua")
        self.execute("scripts/actions/tools/fishing.lua")
        self.lua.execute("""
            local player = playerFixture(1)
            player.worms = 20
            function player:addSkillTries(skill, count) self.skillTries = count end
            function player:getEffectiveSkillLevel(skill) return 10 end
            function player:removeItem(id, count)
                assert(id == 3492 and count == 1)
                self.worms = self.worms - count
                return true
            end
            -- Force a successful catch through the actual fishing hook.
            math.random = function() return 1 end
            local position = {sendMagicEffect = function() end}
            assert(_action.onUse(player, {itemid = 3483}, {}, {itemid = 4597}, position, false))
            assert(player.worms == 19 and player.skillTries == 1 and #player.items == 1)
            local caught = player.items[1]
            assert(caught.count == 1)
            local salePrice = 0
            for _, offer in ipairs(_shops['Harvest Buyer'].items) do
                if offer.id == caught.id then salePrice = offer.sell end
            end
            assert(salePrice > 0, 'The pond catch must have a buyer')
        """)

    def test_seeds_plant_a_pot_and_consume_one_seed(self):
        self.execute("scripts/movements/others/seeds.lua")
        self.lua.execute("""
            local seeds = {removed = 0}
            function seeds:getId() return 647 end
            function seeds:remove(count) self.removed = self.removed + count end
            local pot = {}
            function pot:transform(id) self.id = id end
            function pot:decay() self.decaying = true end
            local position = {sendMagicEffect = function() end}
            assert(_move.onAddItem(seeds, pot, position))
            assert(pot.id == 316 and pot.decaying and seeds.removed == 1)
        """)

    def test_startup_metadata_has_no_legacy_map_positions(self):
        for path in (DATA / "startup/tables").glob("*.lua"):
            if path.name != "load.lua":
                self.lua.execute(path.read_text(encoding="utf-8-sig"))
        self.lua.execute("""
            for _, name in ipairs({
                'ChestAction', 'ChestUnique', 'CorpseAction', 'CorpseUnique',
                'CreateItemOnMap', 'KeyDoorAction', 'LevelDoorAction',
                'QuestDoorAction', 'QuestDoorUnique', 'ItemAction', 'ItemUnique',
                'DailyRewardAction', 'ItemUnmoveableAction', 'LeverAction', 'LeverUnique',
                'TeleportAction', 'TeleportUnique', 'TeleportItemAction', 'TeleportItemUnique',
                'TileAction', 'TileUnique', 'TilePickAction', 'BookDocumentTable', 'QuestKeysUpdate'
            }) do
                assert(type(_G[name]) == 'table' and next(_G[name]) == nil, name)
            end
        """)


if __name__ == "__main__":
    unittest.main()
