---@class BitForge.AzerothPrime
local ns = select(2, ...)
---@class BitForge.AzerothPrime.Enum
local enum = ns.enum
local PRIORITY = enum.PRIORITY

-- Items the typed-tooltip pipeline will not surface on its own, listed with the
-- priority to rank them at. The pipeline in control.lua is still the primary
-- path: graded against the upstream addon's 1252 curated items, it classified
-- 778 of them with no help from this table.
--
-- Two populations, both vetted by that upstream list, both with their priority
-- taken from its curation and mapped onto ours:
--
--   Items with no evidence to read -- pet supply bags, tomes, disenchant items
--   carrying no typed accept line, with GetItemSpell and IsUsableItem silent
--   too. No rule tuning reaches these.
--
--   Items a class rule deliberately suppresses but upstream surfaces anyway:
--   Miscellaneous/Other and on-use armor. Those rules exist because the same
--   class pairs are full of junk, and the rules stay -- naming the exceptions
--   here is what keeps the junk hidden while the known-good items still appear.
--
--   Only entries upstream categorized as PRI_OPEN, PRI_TOKEN or PRI_REP were
--   taken from that second group. Its PRI_REST bucket is documented as "all
--   remaining items" -- a catch-all, not a claim -- and the 26 entries it
--   contributed turned out to be Legion class-hall recruitment tokens and
--   novelty summons, exactly what the rules exist to hide. Items upstream
--   declines to surface at all (a nil priority, such as the Pocopoc assembly
--   parts) are likewise absent.
--
-- An entry here bypasses every tooltip and class rule, though blacklist,
-- session skip, DENY_LIST and STACK_GATED still apply. It is for items known
-- good by name, not for items a rule is merely being awkward about.
enum.ALLOW_LIST = {
    [69838] = PRIORITY.OPEN,   -- Chirping Box
    [89125] = PRIORITY.OPEN,   -- Sack of Pet Supplies
    [91086] = PRIORITY.OPEN,   -- Darkmoon Pet Supplies
    [93146] = PRIORITY.OPEN,   -- Pandaren Spirit Pet Supplies
    [93147] = PRIORITY.OPEN,   -- Pandaren Spirit Pet Supplies
    [93148] = PRIORITY.OPEN,   -- Pandaren Spirit Pet Supplies
    [93149] = PRIORITY.OPEN,   -- Pandaren Spirit Pet Supplies
    [94207] = PRIORITY.OPEN,   -- Fabled Pandaren Pet Supplies
    [98095] = PRIORITY.OPEN,   -- Brawler's Pet Supplies
    [104013] = PRIORITY.TOKEN, -- Timeless Cloth Armor Cache
    [111972] = PRIORITY.OPEN,  -- Enchanter's Study, Level 2
    [114171] = PRIORITY.OPEN,  -- Ancestral Talisman
    [115981] = PRIORITY.OPEN,  -- Abrogator Stone Cluster
    [122219] = PRIORITY.OPEN,  -- Music Roll: Way of the Monk
    [122514] = PRIORITY.OPEN,  -- Mission Completion Orders
    [122594] = PRIORITY.OPEN,  -- Rush Order: Tailoring Emporium
    [127413] = PRIORITY.OPEN,  -- Jeweled Arakkoa Effigy
    [127799] = PRIORITY.TOKEN, -- Baleful Pendant
    [128225] = PRIORITY.OPEN,  -- Empowered Apexis Fragment
    [128373] = PRIORITY.OPEN,  -- Rush Order: Shipyard
    [139879] = PRIORITY.OPEN,  -- Crate of Champion Equipment
    [140397] = PRIORITY.OPEN,  -- G'Hanir's Blossom
    [141028] = PRIORITY.OPEN,  -- Grimoire of Knowledge
    [141071] = PRIORITY.TOKEN, -- Badge of Honor
    [146748] = PRIORITY.OPEN,  -- Highmountain Tribute
    [151638] = PRIORITY.OPEN,  -- Leprous Sack of Pet Supplies
    [166999] = PRIORITY.OPEN,  -- Treasure Map
    -- Consumable/Generic, which the class rules deny wholesale: the client
    -- prints it "Explosives and Devices" and fills it with gadgets. These are
    -- upstream's openables in it, and the crest packs below need this entry
    -- rather than merely benefiting from it -- their Use: line collects a
    -- currency, so no loot window opens, hasLoot is false and no openable line
    -- is drawn.
    [170502] = PRIORITY.OPEN,  -- Waterlogged Toolbox
    [170505] = PRIORITY.OPEN,  -- Grimy Manaperal Bracelet
    [186520] = PRIORITY.OPEN,  -- Chest of Playtest Equipment
    [189707] = PRIORITY.OPEN,  -- Pocopoc's Bronze and Gold Body
    [193205] = PRIORITY.OPEN,  -- Ohuna Companion Color: Brown
    [194087] = PRIORITY.OPEN,  -- Ohuna Companion Color: Red
    [194088] = PRIORITY.OPEN,  -- Ohuna Companion Color: Dark
    [194089] = PRIORITY.OPEN,  -- Bakar Companion Color: Orange
    [194090] = PRIORITY.OPEN,  -- Bakar Companion Color: White
    [194091] = PRIORITY.OPEN,  -- Bakar Companion Color: Golden Brown
    [194093] = PRIORITY.OPEN,  -- Bakar Companion Color: Brown
    [194094] = PRIORITY.OPEN,  -- Bakar Companion Color: Black
    [194095] = PRIORITY.OPEN,  -- Ohuna Companion Color: Sepia
    [197124] = PRIORITY.TOKEN, -- Highland Drake: Swept Horns
    [200939] = PRIORITY.OPEN,  -- Chromatic Pocketwatch
    [200940] = PRIORITY.OPEN,  -- Everflowing Inkwell
    [200941] = PRIORITY.OPEN,  -- Seal of Order
    [200942] = PRIORITY.OPEN,  -- Vibrant Emulsion
    [200943] = PRIORITY.OPEN,  -- Whispering Band
    [200945] = PRIORITY.OPEN,  -- Valiant Hammer
    [200946] = PRIORITY.OPEN,  -- Thunderous Blade
    [200947] = PRIORITY.OPEN,  -- Carving of Awakening
    [203646] = PRIORITY.TOKEN, -- Primalist Cloak
    [205962] = PRIORITY.OPEN,  -- Echoing Storm Flightstone
    [207016] = PRIORITY.OPEN,  -- Rift-Mender's Tabard
    [207017] = PRIORITY.OPEN,  -- Rift-Mender's Cape
    [207018] = PRIORITY.OPEN,  -- Rift-Mender's Spaulders
    [208061] = PRIORITY.OPEN,  -- Quantum Headpiece
    [208062] = PRIORITY.OPEN,  -- Quantum Shoulders
    [208063] = PRIORITY.OPEN,  -- Quantum Gloves
    [208064] = PRIORITY.OPEN,  -- Quantum Chestpiece
    [208065] = PRIORITY.OPEN,  -- Quantum Legs
    [208125] = PRIORITY.OPEN,  -- Quantum Focus
    [208126] = PRIORITY.OPEN,  -- Quantum Shield
    [209837] = PRIORITY.OPEN,  -- Faint Whispers of Dreaming
    [210756] = PRIORITY.OPEN,  -- Gleaming Satchel of Drake's Dreaming Crests
    [210762] = PRIORITY.OPEN,  -- Shimmering Clutch of Wyrm's Dreaming Crests
    [210768] = PRIORITY.OPEN,  -- Viridescent Bouquet of Aspect's Dreaming Crests
    [210770] = PRIORITY.OPEN,  -- Satchel of Drake's Dreaming Crests
    [210871] = PRIORITY.TOKEN, -- Greater Ember of Fyr'alath
    [210917] = PRIORITY.OPEN,  -- Pouch of Whelpling's Dreaming Crests
    [210923] = PRIORITY.OPEN,  -- Clutch of Wyrm's Dreaming Crests
    [210982] = PRIORITY.OPEN,  -- Thread of Power
    [210983] = PRIORITY.OPEN,  -- Thread of Stamina
    [210984] = PRIORITY.OPEN,  -- Thread of Critical Strike
    [210985] = PRIORITY.OPEN,  -- Thread of Haste
    [210986] = PRIORITY.OPEN,  -- Thread of Speed
    [210987] = PRIORITY.OPEN,  -- Thread of Leech
    [210989] = PRIORITY.OPEN,  -- Thread of Mastery
    [211374] = PRIORITY.OPEN,  -- Tangled Yarn of Secrets
    [211950] = PRIORITY.OPEN,  -- Lively Clutch of Wyrm's Awakened Crests
    [211951] = PRIORITY.OPEN,  -- Pouch of Whelpling's Awakened Crests
    [212383] = PRIORITY.OPEN,  -- Yawning Basket of Aspect's Awakened Crests
    [212384] = PRIORITY.OPEN,  -- Restless Satchel of Drake's Awakened Crests
    [213175] = PRIORITY.OPEN,  -- Dusty Djaradin Tome
    [213176] = PRIORITY.OPEN,  -- Preserved Isles Tome
    [213177] = PRIORITY.OPEN,  -- Immaculate Tome
    [213185] = PRIORITY.OPEN,  -- Dusty Centaur Tome
    [213186] = PRIORITY.OPEN,  -- Dusty Niffen Tome
    [213187] = PRIORITY.OPEN,  -- Dusty Drakonid Tome
    [213188] = PRIORITY.OPEN,  -- Dusty Dracthyr Tome
    [213189] = PRIORITY.OPEN,  -- Preserved Dragonkin Tome
    [213190] = PRIORITY.OPEN,  -- Preserved Djaradin Tome
    [217242] = PRIORITY.OPEN,  -- Awakening Stone Wing
    [217722] = PRIORITY.OPEN,  -- Thread of Experience
    [218129] = PRIORITY.OPEN,  -- Porcelain Arrowhead Idol
    [219256] = PRIORITY.OPEN,  -- Temporal Thread of Power
    [219257] = PRIORITY.OPEN,  -- Temporal Thread of Stamina
    [219258] = PRIORITY.OPEN,  -- Temporal Thread of Critical Strike
    [219259] = PRIORITY.OPEN,  -- Temporal Thread of Haste
    [219260] = PRIORITY.OPEN,  -- Temporal Thread of Speed
    [219261] = PRIORITY.OPEN,  -- Temporal Thread of Leech
    [219262] = PRIORITY.OPEN,  -- Temporal Thread of Mastery
    [219263] = PRIORITY.OPEN,  -- Temporal Thread of Versatility
    [219264] = PRIORITY.OPEN,  -- Temporal Thread of Experience
    [219265] = PRIORITY.OPEN,  -- Perpetual Thread of Power
    [219266] = PRIORITY.OPEN,  -- Perpetual Thread of Stamina
    [219267] = PRIORITY.OPEN,  -- Perpetual Thread of Critical Strike
    [219268] = PRIORITY.OPEN,  -- Perpetual Thread of Haste
    [219269] = PRIORITY.OPEN,  -- Perpetual Thread of Speed
    [219270] = PRIORITY.OPEN,  -- Perpetual Thread of Leech
    [219271] = PRIORITY.OPEN,  -- Perpetual Thread of Mastery
    [219272] = PRIORITY.OPEN,  -- Perpetual Thread of Versatility
    [219273] = PRIORITY.OPEN,  -- Perpetual Thread of Experience
    [219274] = PRIORITY.OPEN,  -- Infinite Thread of Power
    [219275] = PRIORITY.OPEN,  -- Infinite Thread of Stamina
    [219276] = PRIORITY.OPEN,  -- Infinite Thread of Critical Strike
    [219277] = PRIORITY.OPEN,  -- Infinite Thread of Haste
    [219278] = PRIORITY.OPEN,  -- Infinite Thread of Speed
    [219279] = PRIORITY.OPEN,  -- Infinite Thread of Leech
    [219280] = PRIORITY.OPEN,  -- Infinite Thread of Mastery
    [219281] = PRIORITY.OPEN,  -- Infinite Thread of Versatility
    [219282] = PRIORITY.OPEN,  -- Infinite Thread of Experience
    [220767] = PRIORITY.OPEN,  -- Triumphant Satchel of Carved Harbinger Crests
    [220773] = PRIORITY.OPEN,  -- Celebratory Pack of Runed Harbinger Crests
    [220776] = PRIORITY.OPEN,  -- Glorious Cluster of Gilded Harbinger Crests
    [221268] = PRIORITY.OPEN,  -- Pouch of Weathered Harbinger Crests
    [221373] = PRIORITY.OPEN,  -- Satchel of Carved Harbinger Crests
    [221375] = PRIORITY.OPEN,  -- Pack of Runed Harbinger Crests
    [224982] = PRIORITY.TOKEN, -- Delver's Dirigible Schematic: Exhaust
    [225249] = PRIORITY.OPEN,  -- Rattling Bag o' Gold
    [225897] = PRIORITY.OPEN,  -- Brute Force Idol
    [225898] = PRIORITY.OPEN,  -- Idol of the Earthmother
    [225900] = PRIORITY.OPEN,  -- Light-Touched Idol
    [225901] = PRIORITY.OPEN,  -- Streamlined Relic
    [225902] = PRIORITY.OPEN,  -- Idol of Final Will
    [225903] = PRIORITY.OPEN,  -- Amorphous Relic
    [225904] = PRIORITY.OPEN,  -- Time Lost Relic
    [225905] = PRIORITY.OPEN,  -- Olden Seeker Relic
    [225906] = PRIORITY.OPEN,  -- Lifeless Necrotic Relic
    [225907] = PRIORITY.OPEN,  -- Relic of Sentience
    [225908] = PRIORITY.OPEN,  -- Relicblood of Zekvir
    [226142] = PRIORITY.OPEN,  -- Greater Spool of Eternal Thread
    [226143] = PRIORITY.OPEN,  -- Spool of Eternal Thread
    [226144] = PRIORITY.OPEN,  -- Lesser Spool of Eternal Thread
    [226145] = PRIORITY.OPEN,  -- Minor Spool of Eternal Thread
    [226258] = PRIORITY.OPEN,  -- Delver's Pouch of Reagents
    [229353] = PRIORITY.OPEN,  -- Rage-Filled Idol
    [231153] = PRIORITY.OPEN,  -- Triumphant Satchel of Carved Undermine Crests
    [231154] = PRIORITY.OPEN,  -- Celebratory Pack of Runed Undermine Crests
    [231264] = PRIORITY.OPEN,  -- Glorious Cluster of Gilded Undermine Crests
    [231267] = PRIORITY.OPEN,  -- Pouch of Weathered Undermine Crests
    [231269] = PRIORITY.OPEN,  -- Satchel of Carved Undermine Crests
    [231270] = PRIORITY.OPEN,  -- Pack of Runed Undermine Crests
    [232981] = PRIORITY.TOKEN, -- GNZ Airmaster 9000
}

-- Items the pipeline accepts but should not surface.
--
-- Deliberately not here: the Garrison and Dalaran hearthstones. Both became
-- toys, so an item still sitting in a bag is one the player has yet to learn,
-- and offering it is the whole point. Only the plain Hearthstone stays -- it is
-- a permanent bag item, never learnable, and using it from a button the player
-- reached for to open a cache would teleport them out of wherever they are.
enum.DENY_LIST = {
    [6948] = true, -- Hearthstone
    -- Consumable/Other with a plain Use: line and nothing else to go on -- the
    -- shape the class rules deliberately let through, since that pair also holds
    -- conduits and reputation tokens. It is spent on a Wildseed at a Night Fae
    -- Queen's Conservatory node, so away from that node the button offers a
    -- click that does nothing, and no API says so.
    [178880] = true, -- Superior Loyal Spirit
    -- Reported through #265, in one capture. Each carries a plain Use: line in
    -- a class pair the rules deliberately leave open -- Consumable/Other for
    -- the conduits and reputation tokens that live there, Miscellaneous/Junk
    -- and Tradegoods/Cloth for the same reason -- and nothing in the tooltip or
    -- in any API tells them apart from an openable. Two carry a reputation
    -- requirement rather than a trade skill one, so the profession-tool branch
    -- does not reach them either.
    --
    -- Data rather than a rule, and deliberately so: a rule wide enough to catch
    -- these would empty the pairs they sit in. Retire an entry when the
    -- detection improves enough to answer for it.
    [45896]  = true, -- Unbound Fragments of Val'anyr
    [63359]  = true, -- Banner of Cooperation
    [86425]  = true, -- Cooking School Bell
    [128503] = true, -- Master Hunter's Seeking Crystal
    [136856] = true, -- Songs of Peace
    [164733] = true, -- Synchronous Thread
    [181469] = true, -- Indelible Victory
    [182653] = true, -- Larion Treats
    [190644] = true, -- Vessel of Profound Possibilities
    [225692] = true, -- Glowglow Cap
    [226107] = true, -- Homebrewed Blink Vial
    [243144] = true, -- Reshii Crystal Fragments
    [244193] = true, -- L00T RAID-R Mini
}

-- [itemID] = minimum stack size. Some items do nothing until enough of them
-- accumulate -- the Use: line is present the whole time, but below the threshold
-- it is inert, so offering the item on the button is a wasted click.
--
-- No API reports the threshold, so it has to be data. Most of this is imported
-- from the upstream New Openables addon's count_to_use field
-- (github.com/cont1nuity/new-openables-continued, MIT), which it applies the
-- same way -- nop-item.lua:500 gates its own button on
-- GetItemCount(itemID) >= count. Three thresholds were observed in play before
-- that import; two of them turned out to match upstream exactly, which is the
-- reason the rest were trusted wholesale. Anything observed in play since says
-- so in its comment, upstream having no entry to check it against.
--
-- The count is a carried total across bags, not a single stack.
enum.STACK_GATED = {
    [2934] = 3,     -- Ruined Leather Scraps
    [25649] = 5,    -- Knothide Leather Scraps
    [33567] = 5,    -- Borean Leather Scraps
    [52977] = 5,    -- Savage Leather Scraps
    [72162] = 5,    -- Sha-Touched Leather
    [89112] = 10,   -- Mote of Harmony
    [97512] = 10,   -- Ghost Iron Nugget
    [97546] = 10,   -- Kyparite Fragment
    [97619] = 10,   -- Torn Green Tea Leaf
    [97620] = 10,   -- Rain Poppy Petal
    [97621] = 10,   -- Silkweed Stem
    [97622] = 10,   -- Snow Lily Petal
    [97623] = 10,   -- Fool's Cap Spores
    [108294] = 10,  -- Silver Ore Nugget
    [108295] = 10,  -- Tin Ore Nugget
    [108296] = 10,  -- Gold Ore Nugget
    [108297] = 10,  -- Iron Ore Nugget
    [108298] = 10,  -- Thorium Ore Nugget
    [108299] = 10,  -- Truesilver Ore Nugget
    [108300] = 10,  -- Mithril Ore Nugget
    [108301] = 10,  -- Fel Iron Ore Nugget
    [108302] = 10,  -- Adamantite Ore Nugget
    [108303] = 10,  -- Eternium Ore Nugget
    [108304] = 10,  -- Khorium Ore Nugget
    [108305] = 10,  -- Cobalt Ore Nugget
    [108306] = 10,  -- Saronite Ore Nugget
    [108307] = 10,  -- Obsidium Ore Nugget
    [108308] = 10,  -- Elementium Ore Nugget
    [108309] = 10,  -- Pyrite Ore Nugget
    [108318] = 10,  -- Mageroyal Petal
    [108319] = 10,  -- Earthroot Stem
    [108320] = 10,  -- Briarthorn Bramble
    [108321] = 10,  -- Swiftthistle Leaf
    [108322] = 10,  -- Bruiseweed Stem
    [108323] = 10,  -- Wild Steelbloom Petal
    [108324] = 10,  -- Kingsblood Petal
    [108325] = 10,  -- Liferoot Stem
    [108326] = 10,  -- Khadgar's Whisker Stem
    [108327] = 10,  -- Grave Moss Leaf
    [108328] = 10,  -- Fadeleaf Petal
    [108329] = 10,  -- Dragon's Teeth Stem
    [108330] = 10,  -- Stranglekelp Blade
    [108331] = 10,  -- Goldthorn Bramble
    [108332] = 10,  -- Firebloom Petal
    [108333] = 10,  -- Purple Lotus Petal
    [108334] = 10,  -- Arthas' Tears Petal
    [108335] = 10,  -- Sungrass Stalk
    [108336] = 10,  -- Blindweed Stem
    [108337] = 10,  -- Ghost Mushroom Cap
    [108338] = 10,  -- Gromsblood Leaf
    [108339] = 10,  -- Dreamfoil Blade
    [108340] = 10,  -- Golden Sansam Leaf
    [108341] = 10,  -- Mountain Silversage Stalk
    [108342] = 10,  -- Sorrowmoss Leaf
    [108343] = 10,  -- Icecap Petal
    [108344] = 10,  -- Felweed Stalk
    [108345] = 10,  -- Dreaming Glory Petal
    [108346] = 10,  -- Ragveil Cap
    [108347] = 10,  -- Terocone Leaf
    [108348] = 10,  -- Ancient Lichen Petal
    [108349] = 10,  -- Netherbloom Leaf
    [108350] = 10,  -- Nightmare Vine Stem
    [108351] = 10,  -- Mana Thistle Leaf
    [108352] = 10,  -- Goldclover Leaf
    [108353] = 10,  -- Adder's Tongue Stem
    [108354] = 10,  -- Tiger Lily Petal
    [108355] = 10,  -- Lichbloom Stalk
    [108356] = 10,  -- Icethorn Bramble
    [108357] = 10,  -- Talandra's Rose Petal
    [108358] = 10,  -- Deadnettle Bramble
    [108359] = 10,  -- Fire Leaf Bramble
    [108360] = 10,  -- Cinderbloom Petal
    [108361] = 10,  -- Stormvine Stalk
    [108362] = 10,  -- Azshara's Veil Stem
    [108363] = 10,  -- Heartblossom Petal
    [108364] = 10,  -- Twilight Jasmine Petal
    [108365] = 10,  -- Whiptail Stem
    [108391] = 10,  -- Titanium Ore Nugget
    [109624] = 10,  -- Broken Frostweed Stem
    [109625] = 10,  -- Broken Fireweed Stem
    [109626] = 10,  -- Gorgrond Flytrap Ichor
    [109627] = 10,  -- Starflower Petal
    [109628] = 10,  -- Nagrand Arrowbloom Petal
    [109629] = 10,  -- Talador Orchid Petal
    [109991] = 10,  -- True Iron Nugget
    [109992] = 10,  -- Blackrock Fragment
    [110610] = 10,  -- Raw Beast Hide Scraps
    [111589] = 5,   -- Small Crescent Saberfish
    [111595] = 5,   -- Crescent Saberfish
    [111601] = 5,   -- Enormous Crescent Saberfish
    [111650] = 5,   -- Small Jawless Skulker
    [111651] = 5,   -- Small Fat Sleeper
    [111652] = 5,   -- Small Blind Lake Sturgeon
    [111656] = 5,   -- Small Fire Ammonite
    [111658] = 5,   -- Small Sea Scorpion
    [111659] = 5,   -- Small Abyssal Gulper Eel
    [111662] = 5,   -- Small Blackwater Whiptail
    [111663] = 5,   -- Blackwater Whiptail
    [111664] = 5,   -- Abyssal Gulper Eel
    [111665] = 5,   -- Sea Scorpion
    [111666] = 5,   -- Fire Ammonite
    [111667] = 5,   -- Blind Lake Sturgeon
    [111668] = 5,   -- Fat Sleeper
    [111669] = 5,   -- Jawless Skulker
    [111670] = 5,   -- Enormous Blackwater Whiptail
    [111671] = 5,   -- Enormous Abyssal Gulper Eel
    [111672] = 5,   -- Enormous Sea Scorpion
    [111673] = 5,   -- Enormous Fire Ammonite
    [111674] = 5,   -- Enormous Blind Lake Sturgeon
    [111675] = 5,   -- Enormous Fat Sleeper
    [111676] = 5,   -- Enormous Jawless Skulker
    [112158] = 10,  -- Icy Dragonscale Fragment
    [112177] = 10,  -- Nerubian Chitin Fragment
    [112178] = 10,  -- Jormungar Scale Fragment
    [112179] = 10,  -- Patch of Thick Clefthoof Leather
    [112180] = 10,  -- Patch of Crystal-Infused Leather
    [112181] = 10,  -- Fel Scale Fragment
    [112182] = 10,  -- Patch of Fel Hide
    [112183] = 10,  -- Nether Dragonscale Fragment
    [112184] = 10,  -- Cobra Scale Fragment
    [112185] = 10,  -- Wind Scale Fragment
    [115504] = 10,  -- Fractured Temporal Crystal
    [115510] = 300, -- Elemental Rune
    [118592] = 2,   -- Partial Receipt: Gizmothingies
    [136342] = 100, -- Obliterum Ash
    [140767] = 5,   -- Pile of Bits and Bones
    [146757] = 10,  -- Prepared Ingredients
    [151653] = 10,  -- Broken Isles Recipe Scrap
    [169491] = 5,   -- Focused Life Essence; observed in play, the Use: line
                    -- names the threshold ("combine 5 to create ...")
    [174657] = 6,   -- unknown to wowhead; observed in play
    [174756] = 6,   -- Aqir Relic Fragment
    [190198] = 5,   -- Sandworn Chest Key Fragment
    [190315] = 10,  -- Rousing Earth
    [190320] = 10,  -- Rousing Fire
    [190322] = 10,  -- Rousing Order
    [190326] = 10,  -- Rousing Air
    [190328] = 10,  -- Rousing Frost
    [190330] = 10,  -- Rousing Decay
    [190451] = 10,  -- Rousing Ire
    [201437] = 5,   -- Slumbering Dream Fragment
    [204075] = 15,  -- Whelpling's Shadowflame Crest Fragment
    [204076] = 15,  -- Drake's Shadowflame Crest Fragment
    [204077] = 15,  -- Wyrm's Shadowflame Crest Fragment
    [204078] = 15,  -- Aspect's Shadowflame Crest Fragment
    [204717] = 2,   -- Splintered Spark of Shadowflame
    [208396] = 2,   -- Splintered Spark of Dreams
    [210681] = 3,   -- Chipped Quick Topaz
    [210714] = 3,   -- Chipped Deadly Sapphire
    [210715] = 3,   -- Chipped Masterful Amethyst
    [210716] = 3,   -- Chipped Swift Opal
    [210717] = 3,   -- Chipped Hungering Ruby
    [210718] = 3,   -- Hungering Ruby
    [211106] = 3,   -- Masterful Amethyst
    [211107] = 3,   -- Quick Topaz
    [211109] = 3,   -- Chipped Sustaining Emerald
    [211123] = 3,   -- Deadly Sapphire
    [211124] = 3,   -- Swift Opal
    [211125] = 3,   -- Sustaining Emerald
    [211297] = 2,   -- Fractured Spark of Omens
    [211515] = 2,   -- Splintered Spark of Awakening
    [216639] = 3,   -- Flawed Swift Opal
    [216640] = 3,   -- Flawed Masterful Amethyst
    [216641] = 3,   -- Flawed Hungering Ruby
    [216642] = 3,   -- Flawed Sustaining Emerald
    [216643] = 3,   -- Flawed Quick Topaz
    [216644] = 3,   -- Flawed Deadly Sapphire
    [217707] = 5,   -- Imperfect Null Stone
    [220367] = 3,   -- Chipped Stalwart Pearl
    [220368] = 3,   -- Flawed Stalwart Pearl
    [220370] = 3,   -- Stalwart Pearl
    [220371] = 3,   -- Chipped Versatile Diamond
    [220372] = 3,   -- Flawed Versatile Diamond
    [220374] = 3,   -- Versatile Diamond
    [229899] = 100, -- Coffer Key Shard
    [230905] = 2,   -- Fractured Spark of Fortunes
    [231757] = 2,   -- Fractured Spark of Starlight
    [236096] = 100, -- Coffer Key Shard
}

-- [itemID] = the places the item works. Some items do nothing outside one
-- zone, or one building inside one -- the Use: line is present everywhere, and
-- the client refuses the click anywhere else, so offering the item is a wasted
-- click exactly as a short stack is.
--
-- An entry is a list of places, and the item is offered where ANY of them
-- matches. Each place is a pair of uiMapID values:
--
--     [<itemID>] = {
--         { zoneID = <containing map>, subzoneIDs = { <map>, <map> } },
--     },
--
-- zoneID is the containing map -- what the client reports as the current map's
-- parent; subzoneIDs are the maps the client answers with while the player is
-- standing in them. Neither is an areaID; that id space is not read at all. The
-- two readings are made in model/zone.lua and nowhere else in this module,
-- which tests/test_azerothprime_zone.lua holds to by matching text -- so naming
-- that API here, even in a comment, turns its walk red.
--
-- subzoneIDs is ALWAYS a table, never a bare number, and its ids are siblings
-- sharing one parent rather than a hierarchy. Ids at different levels have
-- different containers, so they belong to separate entries.
--
-- An EMPTY subzoneIDs is the wildcard: any map whose parent is zoneID. That is
-- every map under the zone at once, without listing them. It is not the zone's
-- own map -- standing on zoneID itself reads some other parent -- so covering
-- a zone and its interiors takes two entries. A zoneID of 0 may not be paired
-- with it: 0 names the top of the hierarchy and an empty list names every
-- child, and together they constrain nothing an entry could be for.
-- tests/test_azerothprime_zone.lua walks this table and refuses the pair.
--
-- MAINTENANCE NOTE: the ids come from the live readout, not from memory or
-- from a wiki. `/bitforge dev zone` puts BitForge_Dev's block on screen, a
-- click on it collects wherever you are standing, and `/bfdump dev zone` emits
-- what you collected already grouped into the shape above.
--
-- Empty on purpose: the gate is a working feature that gates nothing until an
-- entry lands, which is what let it ship and be verified before a single item
-- depended on it.
--
-- Two assertions in tests/test_azerothprime_zone.lua state that emptiness, so the
-- first entry turns them red. That is the guard reporting itself rather than a
-- fault: replace them with the walk they describe.
enum.ZONE_GATED = {}

-- [itemID] = questID. Suppress the item once its quest is accepted or completed.
--
-- MAINTENANCE NOTE: no API maps an item to the quest it starts, so this table is
-- the one place in the module where hand-curation is unavoidable. Add entries only
-- for items that start or are consumed by a specific quest. Do not let this grow
-- into a general item database — that is what the typed-tooltip pipeline replaced.
--
-- Seeded from upstream T_ITEM_REQUIRE_QUEST_NOT_COMPLETED (The War Within treatises).
enum.QUEST_GATED = {
    [222546] = 83725, -- Algari Treatise on Alchemy
    [222554] = 83726, -- Algari Treatise on Blacksmithing
    [222550] = 83727, -- Algari Treatise on Enchanting
    [222621] = 83728, -- Algari Treatise on Engineering
    [222552] = 83729, -- Algari Treatise on Herbalism
    [222548] = 83730, -- Algari Treatise on Inscription
    [222551] = 83731, -- Algari Treatise on Jewelcrafting
    [222549] = 83732, -- Algari Treatise on Leatherworking
    [222553] = 83733, -- Algari Treatise on Mining
    [222649] = 83734, -- Algari Treatise on Skinning
    [222547] = 83735, -- Algari Treatise on Tailoring
}
