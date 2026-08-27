---@class BitForge.EUI
local ns = select(2, ...)

-- English is the base; a locale table overrides it key by key.
--
-- Subcommand keywords (ui, apply, capture, list, reset, rl) are
-- deliberately NOT translated. The player types them.

---@class BitForge.EUI.Locale
local L = ns.locale

L["cmd:help"] = "Commands: ui, apply, capture, list, reset, rl"
L["cmd:helpUi"] = "ui -- open the layout editor"
L["cmd:helpApply"] = "apply -- push the saved layout to EllesmereUI"
L["cmd:helpCapture"] = "capture -- save EllesmereUI's current geometry"
L["cmd:helpList"] = "list [-u] [text] -- list positionable elements"
L["cmd:helpListUnmanaged"] = "  -u -- only elements the saved layout does not manage"
L["cmd:helpReset"] = "reset [anchors] -- discard the saved layout"
L["cmd:deprecated"] = "/bfeui is deprecated -- use /bitforge eui instead"

L["error:noEllesmere"] = "EllesmereUI is not loaded"
L["error:noRegistry"] = "EllesmereUI's element list is unavailable"

L["apply:applied"] = "Applied %d, unchanged %d"
L["apply:anchorOwned"] = "%d element(s) positioned by an anchor (coordinates ignored)"
L["apply:unknownKeys"] = "%d unknown key(s): %s"
L["apply:unknownHint"] = "Use 'list' to see registered keys"
L["apply:failedKeys"] = "%d failed: %s"
L["apply:badAnchors"] = "%d anchor(s) not applied:"
L["apply:badAnchorLine"] = "  %s -> %s (%s)"
L["apply:badAnchorHint"] = "An anchor target is an element key. For screen-relative placement use point/relPoint"
L["apply:resolved"] = "%d anchor(s) resolved by BitForge (EllesmereUI cannot express them)"

L["reason:unknown"] = "no such target"
L["reason:self"] = "anchored to itself"
L["reason:cycle"] = "circular reference"
L["reason:halfpair"] = "needs both point and relPoint"
L["reason:badpoint"] = "not an anchor point name"
L["reason:notarget"] = "nothing may anchor to that element"
L["reason:noanchor"] = "that element cannot be anchored"
L["reason:norect"] = "the target has no position on screen yet"
L["reason:notextended"] = "no point and relPoint to resolve"

L["list:none"] = "No matching elements"
L["list:count"] = "%d shown, %d/%d unmanaged"
L["list:unmanaged"] = "[unmanaged]"
L["list:anchored"] = "[anchor -> %s %s]"
L["list:noPosition"] = "no position"
L["list:readFailed"] = "%s (read failed)"

L["capture:result"] = "Captured %d element(s)"
L["capture:seeded"] = "First run: saved your current layout (%d elements). Nothing was moved."

L["unlock:attachedWarning"] = "%d element(s) are attached. Dragging them here will detach them."
L["unlock:noLongerAttached"] = "No longer attached: %s"

L["reset:confirm"] = "This discards your saved layout. Run 'reset confirm' to proceed."
L["reset:done"] = "Saved layout discarded. It will be rebuilt from EllesmereUI on next login."
L["reset:anchorsConfirm"] = "This also deletes your anchor definitions, which CANNOT be recovered. Run 'reset anchors confirm' to proceed."
L["reset:anchorsDone"] = "Saved layout and anchor definitions discarded."

L["anchor:badTable"] = "anchor '%s' is not a table"
L["anchor:badSize"] = "anchor '%s' needs a positive w and h; it has no edges without them"
L["anchor:collides"] = "anchor '%s' collides with an existing EllesmereUI element (%s); rename it"

L["ui:title"] = "BitForge Layout"
L["ui:filter"] = "Search"
L["ui:notReady"] = "Still reading your layout -- try again in a moment"
L["ui:markAttachedEui"] = "[anchored]"
L["ui:markAttachedBitForge"] = "[attached]"
L["ui:markHidden"] = "[hidden]"
L["ui:anchorGroup"] = "Anchor frames"
L["ui:anchorNew"] = "+ New anchor frame"
L["ui:target"] = "Anchor to"
L["ui:targetScreen"] = "Screen"
L["ui:myPoint"] = "My corner"
L["ui:theirPoint"] = "Their corner"
L["ui:offsetX"] = "X offset"
L["ui:offsetY"] = "Y offset"
L["ui:width"] = "Width"
L["ui:height"] = "Height"
L["ui:label"] = "Label"
L["ui:key"] = "Key"
L["ui:channelScreen"] = "Positioned against the screen"
L["ui:channelEui"] = "EllesmereUI anchor (side = %s)"
L["ui:channelBitForge"] = "BitForge anchor -- EllesmereUI cannot express this pair"
L["ui:noResize"] = "This element cannot be resized"
L["ui:hiddenNote"] = "Registered, but its frame is not currently shown"
L["ui:pendingNone"] = "No unsaved changes"
L["ui:pending"] = "%d unsaved change(s)"
L["ui:save"] = "Save & Reload"
L["ui:revert"] = "Revert"
L["ui:saveCombat"] = "Cannot reload in combat"
L["ui:invalid"] = "%d problem(s) to fix before saving"
L["ui:anchorDelete"] = "Delete"
L["ui:anchorDeleteConfirm"] = "Delete anchor frame '%s'? Anchor definitions exist only here and CANNOT be recovered."
L["ui:anchorKeyEmpty"] = "An anchor frame needs a key"
L["ui:anchorKeyTaken"] = "An anchor frame named '%s' already exists"

-- Added beyond the source's 81 keys for the combat retry (decision 4.2): a
-- deferred apply must tell the player why nothing happened yet, and confirm
-- the outcome once combat ends and the retry runs.
L["apply:deferredCombat"] = "In combat -- the layout will be applied when you leave it"
L["apply:deferredDone"] = "Combat ended: applied %d, unchanged %d"
