---@class BitForge.AzerothPrime
local ns = select(2, ...)

-- The three optional fields are populated by DisenchantData.lua, which loads
-- after this file, so the literal below cannot define them.
---@class BitForge.AzerothPrime.Enum
---@field NON_DISENCHANTABLE_IDS? table<number, boolean>
---@field CLASS_PREFS? table<string, table>
---@field SLOT_LOOKUP? table<string, number[]>
local enum = {
    -- Ranking priorities, highest first. Reversed from upstream's PRI_* order:
    -- what the player can learn from is permanent and easy to forget, while a
    -- quest item is already held on the button by its own gate and a container
    -- keeps until it is opened. Surfacing the perishable knowledge first is what
    -- the button is for.
    --
    -- USE is last, below even QUEST, for a second reason. Every other tier is
    -- something the player would want reminding of; a merely usable item is
    -- only "the client says this does something", which is what the weakest
    -- two accept branches produce -- a plain Use: line, and the fallback that
    -- matched no typed line at all. That makes it the tier a misclassification
    -- lands in, and the button shows one item, so the tier most likely to be
    -- wrong is the one everything else has to outrank.
    --
    -- The four original values stay where they are rather than being spread to
    -- make room. Nothing stores a priority and nothing reads one except by
    -- comparison, so renumbering would buy nothing and would silently rewrite
    -- every diagnostic report and issue that quotes a number.
    PRIORITY = {
        LEARN = 40, -- recipes, toys, transmog, other learnables
        TOKEN = 30, -- reputation and currency tokens
        OPEN  = 20, -- containers, caches, lockboxes
        QUEST = 10, -- quest-gated items, while the gate still permits them
        USE   = 5,  -- merely usable: a Use: effect that teaches nothing
    },

    -- Why detector.Classify surfaced an item. Carried on the candidate purely
    -- as diagnostics -- nothing in the pipeline branches on it -- so the debug
    -- tooltip can explain a surprising pick without re-deriving the decision.
    REASON = {
        QUEST_GATE   = "QUEST_GATE",   -- quest-gated item, gate still open; detail is the questID
        ALLOW_LIST   = "ALLOW_LIST",   -- hand-listed in OpenableData.lua
        LOCKED_BOX   = "LOCKED_BOX",   -- Locked tooltip line, and an unlock spell is known
        HAS_LOOT     = "HAS_LOOT",     -- ContainerItemInfo.hasLoot: the client says it holds loot
        OPENABLE_LINE = "OPENABLE_LINE", -- the client's own "right click to open" line
        TOOLTIP_LINE = "TOOLTIP_LINE", -- a typed tooltip line accepted it; detail is that line type
        ITEM_SPELL   = "ITEM_SPELL",   -- no typed line matched; GetItemSpell/IsUsableItem accepted it
        UNCOLLECTED_APPEARANCE = "UNCOLLECTED_APPEARANCE", -- cosmetic item, appearance not in the collection
    },

    -- Why detector.Classify turned an item away. Returned alongside the nil
    -- priority, so nothing in the pipeline sees it -- callers test the priority
    -- and stop. It exists for the debug dump, which is otherwise left asking why
    -- an item that plainly looks openable never reaches the button.
    REJECTED = {
        BLACKLIST       = "BLACKLIST",       -- permanently blacklisted by the player
        SESSION_SKIP    = "SESSION_SKIP",    -- right-clicked away for this session
        DENY_LIST       = "DENY_LIST",       -- hand-listed in OpenableData.lua
        SHORT_STACK     = "SHORT_STACK",     -- STACK_GATED, and fewer carried than the threshold
        WRONG_ZONE      = "WRONG_ZONE",      -- ZONE_GATED, and the player is somewhere else
        QUEST_TAKEN     = "QUEST_TAKEN",     -- QUEST_GATED, and the quest is on or completed
        NO_UNLOCK       = "NO_UNLOCK",       -- a locked box, but no unlock spell is known
        REJECT_LINE     = "REJECT_LINE",     -- a typed line said it cannot be used; detail is that line
        UNUSABLE        = "UNUSABLE",        -- IsUsableItem says no; detail is the line type for a
                                              -- UsageRequirement line, nil for the plain-Use guard
        DENIED_CLASS    = "DENIED_CLASS",    -- whole item class is never openable
        ON_USE_ARMOR    = "ON_USE_ARMOR",    -- on-use armor accepted on a plain Use: line
        ON_USE_MISC     = "ON_USE_MISC",     -- Miscellaneous/Other accepted on a plain Use: line
        PROFESSION_TOOL = "PROFESSION_TOOL", -- Consumable/Other used under a met trade skill
        HOLIDAY         = "HOLIDAY",         -- Miscellaneous/Holiday
        QUESTLESS_ITEM  = "QUESTLESS_ITEM",  -- a quest item that starts no quest
        NO_TOOLTIP      = "NO_TOOLTIP",      -- no tooltip came back, so no tooltip rung has run
        NO_EVIDENCE     = "NO_EVIDENCE",     -- nothing accepted it: no typed line, no usable spell
    },

    -- Spells that can open a locked container.
    SPELL_PICK_LOCK = 1804,
    SPELL_SKELETON_PINKIE = 312370,

    BUTTON_SIZE_MIN = 24,
    BUTTON_SIZE_MAX = 64,
    BUTTON_SIZE_STEP = 2,

    -- Debounce window for rescans, in seconds. Zero coalesces to end of frame.
    RESCAN_DELAY = 0,

    -- Where an item belongs. These strings are persisted as the `bank` field
    -- of a db[scope].itemOverrides record, so changing a value orphans every
    -- override a user has set.
    DESTINATION = {
        WARBAND = "warband",
        PRIVATE = "private",
        IGNORE  = "ignore",
    },

    -- Offered in a private item's target-quantity submenu. Round numbers a
    -- player would actually pick, with anything else reachable through
    -- "Other...", because a menu listing every plausible quantity is unusable.
    TARGET_PRESETS = { 5, 20, 40, 100, 200 },

    -- Item classes whose members are crafting reagents. classID comes from
    -- C_Item.GetItemInfoInstant return 6 of 7 (ItemDocumentation.lua).
    REAGENT_CLASSES = {
        [Enum.ItemClass.Tradegoods] = true,
        [Enum.ItemClass.Reagent]    = true,
    },

    -- Which profession a recipe teaches, keyed by subClassID -- GetItemInfoInstant
    -- return 7 of 7. Enum.ItemRecipeSubclass has 12 values
    -- (ItemConstantsDocumentation.lua) and this covers 10 of them.
    --
    -- Book and FirstAid are omitted rather than mapped: Book is a subclass of
    -- reference items, not profession recipes, and FirstAid is not a profession a
    -- modern client can learn. An unmapped subclass makes WantedByAlt return false,
    -- so both fall through to ignore, which is the safe direction for an item kind
    -- no alt can ever want.
    RECIPE_PROFESSION = {
        [Enum.ItemRecipeSubclass.Leatherworking] = Enum.Profession.Leatherworking,
        [Enum.ItemRecipeSubclass.Tailoring]      = Enum.Profession.Tailoring,
        [Enum.ItemRecipeSubclass.Engineering]    = Enum.Profession.Engineering,
        [Enum.ItemRecipeSubclass.Blacksmithing]  = Enum.Profession.Blacksmithing,
        [Enum.ItemRecipeSubclass.Cooking]        = Enum.Profession.Cooking,
        [Enum.ItemRecipeSubclass.Alchemy]        = Enum.Profession.Alchemy,
        [Enum.ItemRecipeSubclass.Enchanting]     = Enum.Profession.Enchanting,
        [Enum.ItemRecipeSubclass.Fishing]        = Enum.Profession.Fishing,
        [Enum.ItemRecipeSubclass.Jewelcrafting]  = Enum.Profession.Jewelcrafting,
        [Enum.ItemRecipeSubclass.Inscription]    = Enum.Profession.Inscription,
    },

    -- The current character's carried bags. Fixed by the game, unlike bank tabs,
    -- which are enumerated at runtime because only purchased ones exist.
    BAG_INDICES = {
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
        Enum.BagIndex.ReagentBag,
    },

    DECISION = {
        SELL = "SELL",
        KEEP = "KEEP",
    },

    -- What model.arbiter.Resolve awards one item: at most one claimant's
    -- disposition, or KEEP when nobody claimed it. Unlike DESTINATION and
    -- LIST_STATUS, nothing stores a claim -- these strings never reach a
    -- saved variable -- so they are free to renumber or rename.
    CLAIM = {
        OPEN            = "OPEN",
        DEPOSIT_WARBAND = "DEPOSIT_WARBAND",
        DEPOSIT_PRIVATE = "DEPOSIT_PRIVATE",
        SELL            = "SELL",
        KEEP            = "KEEP",
    },

    -- Which step of the cascade produced the decision. Returned alongside the
    -- verdict so a test can assert the ordering, not just the outcome.
    RULE = {
        TEMP_EXCLUDED     = "TEMP_EXCLUDED",
        BLACKLISTED       = "BLACKLISTED",
        LOCKED            = "LOCKED",
        EQUIPMENT_SET     = "EQUIPMENT_SET",
        NO_SELL_PRICE     = "NO_SELL_PRICE",
        REFUNDABLE        = "REFUNDABLE",
        WHITELISTED       = "WHITELISTED",
        TEMP_INCLUDED     = "TEMP_INCLUDED",
        JUNK              = "JUNK",
        JUNK_SOLD         = "JUNK_SOLD",
        ABOVE_EPIC        = "ABOVE_EPIC",
        BIND_ON_ACCOUNT   = "BIND_ON_ACCOUNT",
        DISENCHANTABLE    = "DISENCHANTABLE",
        -- Per-class terminals. Each criterion names its own outcome so a
        -- tooltip can say what actually happened rather than "this kind of
        -- item is kept".
        BAG_KEPT              = "BAG_KEPT",
        PROFESSION_GEAR_KEPT  = "PROFESSION_GEAR_KEPT",
        -- One terminal, not one per role: with a mask there is no difference
        -- between keeping the current expansion's and keeping a named past
        -- one, and a terminal called LAST_EXPANSION would be lying the moment
        -- a player ticks the expansion before it.
        ENHANCEMENT_EXPANSION      = "ENHANCEMENT_EXPANSION",
        CONSUMABLE_EXPANSION      = "CONSUMABLE_EXPANSION",
        CONSUMABLE_REAGENT        = "CONSUMABLE_REAGENT",
        GEM_EXPANSION             = "GEM_EXPANSION",
        GEM_REAGENT               = "GEM_REAGENT",
        GEM_ARTIFACT_RELIC_KEPT   = "GEM_ARTIFACT_RELIC_KEPT",
        TRADE_GOOD_SPARED         = "TRADE_GOOD_SPARED",
        -- The shared sale terminal for every per-class criterion above:
        -- nothing kept the item, and that is the same sentence whichever
        -- class asked -- naming the class here would only repeat what the
        -- tooltip it is attached to already shows.
        NOT_WANTED                = "NOT_WANTED",
        REAGENT_WANTED    = "REAGENT_WANTED",
        NOT_EQUIPPABLE    = "NOT_EQUIPPABLE",
        EQUIPPABLE        = "EQUIPPABLE",
        OUTCLASSED        = "OUTCLASSED",
        OUTDATED_EXPAC    = "OUTDATED_EXPAC",
        BIND_ON_EQUIP        = "BIND_ON_EQUIP",
        ARMOR_RELIC          = "ARMOR_RELIC",
        RECIPE_LEARNABLE  = "RECIPE_LEARNABLE",
        HOLIDAY_ITEM      = "HOLIDAY_ITEM",
        MOUNT_EQUIPMENT   = "MOUNT_EQUIPMENT",
        -- Shared across mounts, pets, housing decor, cosmetic armor and
        -- recipes: whether the collection or profession catalogue already
        -- has it, and whether an unbound piece can still reach someone who
        -- wants it. One sentence per outcome, not one per class.
        ALREADY_COLLECTED = "ALREADY_COLLECTED",
        NOT_COLLECTED     = "NOT_COLLECTED",
        STILL_TRADEABLE   = "STILL_TRADEABLE",
        ALREADY_LEARNED   = "ALREADY_LEARNED",
        -- The global fallthrough, and a routine outcome rather than a
        -- defensive tail: every abstaining criterion lands on it, as does
        -- model.Decide's unread-quality guard. Its reason string is
        -- player-facing, so it has to read as an answer and not as a gap.
        DEFAULT           = "DEFAULT",
    },

    -- bindType values returned by C_Item.GetItemInfo, read off Enum.ItemBind
    -- rather than written out. A hand-copied number is exactly what went wrong
    -- before: ON_ACCOUNT was 4, which is Quest, so the account rules matched
    -- quest items and never fired on warbound gear.
    BIND_TYPE = {
        NONE                        = Enum.ItemBind.None,
        ON_PICKUP                   = Enum.ItemBind.OnAcquire,
        ON_EQUIP                    = Enum.ItemBind.OnEquip,
        ON_USE                      = Enum.ItemBind.OnUse,
        QUEST                       = Enum.ItemBind.Quest,
        TO_WOW_ACCOUNT              = Enum.ItemBind.ToWoWAccount,
        TO_BNET_ACCOUNT             = Enum.ItemBind.ToBnetAccount,
        TO_BNET_ACCOUNT_UNTIL_EQUIP = Enum.ItemBind.ToBnetAccountUntilEquipped,
    },

    -- The bind types that make an item another character's to use: warband,
    -- Battle.net account, and the until-equipped variant of the latter. Used
    -- only as the fallback in control.sellScanner -- C_Item.IsItemBindToAccount is
    -- the authority wherever there is an item to ask about.
    BIND_TYPE_ACCOUNT = {
        [Enum.ItemBind.ToWoWAccount]              = true,
        [Enum.ItemBind.ToBnetAccount]             = true,
        [Enum.ItemBind.ToBnetAccountUntilEquipped] = true,
    },

    -- The same subclass -> profession question RECIPE_PROFESSION above answers,
    -- with FirstAid mapped: this table serves facts.recipeProfession, where an
    -- unmappable subclass must abstain rather than read as a profession nobody
    -- has. Enum.Profession rather than a skill-line ID or a trade-skill slot
    -- index -- confirmed by tracing BitForge/control/control.lua's
    -- ReadProfessions (which resolves GetProfessionInfo's skillLine through
    -- C_TradeSkillUI.GetProfessionInfoBySkillLineID().profession) and
    -- BitForge/model.lua's GetAccountProfessions, which builds its mask with
    -- lshift(1, profession) against that same enum.
    --
    -- Mining, Herbalism, Skinning and Archaeology have no entry because
    -- Enum.ItemRecipeSubclass defines none for them -- no recipe item can
    -- represent what they teach. Book (0) it does define, and the omission is
    -- deliberate rather than an oversight: a generic pattern is tied to no
    -- profession, so a recipe filed there leaves facts.recipeProfession nil and
    -- the criterion abstains.
    RECIPE_SUBCLASS_PROFESSION = {
        [Enum.ItemRecipeSubclass.Leatherworking] = Enum.Profession.Leatherworking,
        [Enum.ItemRecipeSubclass.Tailoring]      = Enum.Profession.Tailoring,
        [Enum.ItemRecipeSubclass.Engineering]    = Enum.Profession.Engineering,
        [Enum.ItemRecipeSubclass.Blacksmithing]  = Enum.Profession.Blacksmithing,
        [Enum.ItemRecipeSubclass.Cooking]        = Enum.Profession.Cooking,
        [Enum.ItemRecipeSubclass.Alchemy]        = Enum.Profession.Alchemy,
        [Enum.ItemRecipeSubclass.FirstAid]       = Enum.Profession.FirstAid,
        [Enum.ItemRecipeSubclass.Enchanting]     = Enum.Profession.Enchanting,
        [Enum.ItemRecipeSubclass.Fishing]        = Enum.Profession.Fishing,
        [Enum.ItemRecipeSubclass.Jewelcrafting]  = Enum.Profession.Jewelcrafting,
        [Enum.ItemRecipeSubclass.Inscription]    = Enum.Profession.Inscription,
    },

    -- The status one item holds within one scope. A scope stores a single value per
    -- item, which is what makes blacklist and whitelist mutually exclusive: there is
    -- no second flag left to contradict the first.
    LIST_STATUS = {
        BLACKLIST = "blacklist",
        WHITELIST = "whitelist",
    },

    -- Which of the two lists an item belongs to. The values match the db proxy key
    -- names deliberately, so a scope indexes the database directly:
    -- db[scope].itemOverrides.
    LIST_SCOPE = {
        GLOBAL = "global",
        CHAR   = "char",
    },

    -- Glyph prefixed to a merchant row carrying a character override. Punctuation
    -- rather than prose, so it is a constant and not a locale string; the sentence
    -- explaining it lives in L["tooltip:charOverride"].
    CHAR_OVERRIDE_MARK = "!",

    -- The quality margin's slider position above its 0-30 range, and not a
    -- number of item levels: model.compareToSlot reads it as the step
    -- unbounded, which keeps any higher quality whatever its item level and
    -- lets no item level buy a lower one back. Stored as the position rather
    -- than as a large number so the track's own arithmetic stays honest.
    QUALITY_MARGIN_ALWAYS = 32,

    -- An expansion selection is a bitmask, not a table keyed by expansion.
    -- Core's SeedDefaults fills in every key a saved table is missing and its
    -- logout prune deletes a table once it empties, so a selection expressed by
    -- key presence is silently undone on the next login -- unticking the
    -- current expansion would come back, and unticking everything would be
    -- re-seeded from the default. A number compares by equality and survives,
    -- and 0 is a real value rather than an absence. tradeGoods.professions
    -- already stores its picker this way, and KIND.professions already reads it.
    --
    -- Bit N is expansion N in LE_EXPANSION_* numbering, so bit 9 is Dragonflight.
    -- The two roles take high bits because they are not expansions: they have to
    -- keep following the game, while a past expansion never moves. 29 and 30
    -- rather than 30 and 31 -- bit 31 makes the stored number negative under a
    -- 32-bit signed bit library, and a negative rule setting is a bug nobody
    -- would think to look for.
    EXPANSION_ALL     = bit.lshift(1, 29),
    EXPANSION_CURRENT = bit.lshift(1, 30),

    COLOR = {
        -- Marks a curation row whose destination the user set by hand, so a
        -- chosen destination is distinguishable at a glance from one a rule
        -- produced. Without the distinction the window cannot answer the only
        -- question curation ever raises: "did I already decide this one?"
        OVERRIDE = CreateColor(1, 0.82, 0),
        -- Marks a merchant row whose character status contradicts its warband status.
        CHAR_OVERRIDE = CreateColor(1, 0.5, 0.25),
        -- The debug scan-result block on item tooltips. Grey, so it reads as
        -- an annotation rather than as part of the item's own tooltip.
        DEBUG = CreateColor(0.55, 0.55, 0.55),
        -- The player-facing verdict on an item tooltip.
        SELL = CreateColor(1, 0.35, 0.35),
        KEEP = CreateColor(0.4, 0.9, 0.4),
    },

    -- Bumped whenever the stored shape changes incompatibly. Every version
    -- needs a migration step registered in control/control.lua; core refuses to
    -- start the module against a shape nothing converted.
    --
    -- Version 1 is the adoption, which is why spec.adopts exists: without it
    -- core reads a brand-new module as having nothing to convert and skips the
    -- step for everybody, and this module's first act is to take over the saved
    -- data of the three it replaces. Version 2 copies the open blacklist, the
    -- two sell lists and the bank destinations into one itemOverrides record
    -- per item; version 3 drops the three originals. Version 3 is the first
    -- step here that destroys data -- a profile it has run cannot be read by
    -- any earlier build. Version 4 drops the curation review store, which
    -- accumulated on every profile and which nothing in game ever read.
    -- Version 5 adopts the whole profile a build still called Dispatch
    -- stored, once that build is no longer loaded -- see spec.adopts above
    -- and control/control.lua's StillInstalled for the disable that makes
    -- "no longer loaded" true.
    SCHEMA_VERSION = 5,
}
ns.enum = enum

---@class BitForge.AzerothPrime.Locale
ns.locale = {}

---@class BitForge.AzerothPrime.Model
ns.model = {}

---@class BitForge.AzerothPrime.View
ns.view = {}

---@class BitForge.AzerothPrime.Control
ns.control = {}
