local bit_band = bit.band
local bit_bor = bit.bor

local ENEMY_PLAYER = bit_bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_TYPE_PLAYER)

local HARMFUL_SPELLS = {
	-- Priest
	["Mind Control"] = true,
	["Mind Blast"] = true,
	["Mana Burn"] = true,
	["Smite"] = true,
	["Holy Fire"] = true,
	["Vampiric Touch"] = true,

	-- Druid
	["Entangling Roots"] = true,
	["Cyclone"] = true,
	["Wrath"] = true,
	["Starfire"] = true,
	
	-- Hunter
	["Aimed Shot"] = true,
	
	-- Mage
	["Polymorph"] = true,
	["Polymorph: Pig"] = true,
	["Polymorph: Turtle"] = true,
	["Frostbolt"] = true,
	["Fireball"] = true,
	["Arcane Blast"] = true,
	["Pyroblast"] = true,
	["Flamestrike"] = true,
	
	-- Shaman
	["Lightning Bolt"] = true,
	["Chain Lightning"] = true,	
	
	-- Warlock
	["Fear"] = true,
	["Howl of Terror"] = true,
	["Seduction"] = true,
	["Shadow Bolt"] = true,
	["Seed of Corruption"] = true,
	["Ritual of Summoning"] = true,
	["Soul Fire"] = true,
	["Unstable Affliction"] = true,
	["Incinerate"] = true,
	["Shadowfury"] = true,
	
	-- Paladin
}

local HEALING_SPELLS = {
	-- Priest
	["Binding Heal"] = true,
	["Circle of Healing"] = true,
	["Flash Heal"] = true,
	["Greater Heal"] = true,
	["Heal"] = true,
	["Lesser Heal"] = true,	
	["Prayer of Healing"] = true,
	["Resurrection"] = true,
	
	-- Druid
	["Healing Touch"] = true,
	["Regrowth"] = true,
	
	-- Paladin
	["Flash of Light"] = true,
	["Holy Light"] = true,
	["Redemption"] = true,
		
	-- Shaman
	["Chain Heal"] = true,	
	["Healing Wave"] = true,
	["Lesser Healing Wave"] = true,
	["Ancestral Spirit"] = true,
}

local BUFF_SPELLS = {
	["Bloodlust"] = true,
	["Adrenaline Rush"] = true,
	["Avenging Wrath"] = true,
	["Blessing of Freedom"] = true,
	["Blessing of Protection"] = true,
	["Death Wish"] = true,
	["Deterrence"] = true,	
	["Divine Shield"] = true,
	["Divine Protection"] = true,
	["Evasion"] = true,
	["Heroism"] = true,
	["Pain Suppression"] = true,
	["Perception"] = true,
	["Recklessness"] = true,
	["Spell Reflection"] = true,
	--["Stealth"] = true,
	["Stoneform"] = true,
	["The Beast Within"] = true,
}

local function hasFlag(flags, flag)
	return bit_band(flags, flag) == flag
end

local function colorize(value, color)
	return "|cff" .. color .. value .. "|r"
end

local buffFrame, spellFrame
local name, unit, spell

local onEvent = function(self, event, ...)
	self[event](self, event, ...)
end

evl_SpellAlert = CreateFrame("Frame")
evl_SpellAlert:SetScript("OnEvent", onEvent)
evl_SpellAlert:RegisterEvent("PLAYER_LOGIN")

function evl_SpellAlert:PLAYER_LOGIN()
	spellFrame = self:CreateMessageFrame("SpellAlertFrame")
	spellFrame:SetPoint("TOP", 0, -200)
	buffFrame = self:CreateMessageFrame("BuffAlertFrame")
	buffFrame:SetPoint("BOTTOM", spellFrame, "TOP", 0, 2)
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:ZONE_CHANGED_NEW_AREA()
end

function evl_SpellAlert:CreateMessageFrame(name)
	local frame = CreateFrame("MessageFrame", name, UIParent)
	frame:SetPoint("LEFT", UIParent)
	frame:SetPoint("RIGHT", UIParent)
	frame:SetHeight(25)
	frame:SetInsertMode("TOP")
	frame:SetFrameStrata("HIGH")
	frame:SetTimeVisible(1)
	frame:SetFadeDuration(0.5)
	frame:SetFont(STANDARD_TEXT_FONT, 23, "OUTLINE")

	return frame
end

function evl_SpellAlert:ZONE_CHANGED_NEW_AREA()
	local pvpType = GetZonePVPInfo()
	
	if not pvpType or pvpType ~= "sanctuary" then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function evl_SpellAlert:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
	local spellId, spellName = ...
	
	if eventType == "SPELL_AURA_APPLIED" and hasFlag(destFlags, ENEMY_PLAYER) and BUFF_SPELLS[spellName] then
		buffFrame:AddMessage(format(ACTION_SPELL_AURA_APPLIED_BUFF_FULL_TEXT_NO_SOURCE, nil, colorize(spellName, "00ff00"), nil, destName))
	elseif eventType == "SPELL_CAST_START" and hasFlag(sourceFlags, ENEMY_PLAYER) then
		local color
		
		if HARMFUL_SPELLS[spellName] then
			color = "ff0000"
		elseif HEALING_SPELLS[spellName] then
			color = "ffff00"
		end
		
		--[[
			ACTION_SPELL_CAST_START_FULL_TEXT = "Something begins casting %2$s at %4$s.";
			ACTION_SPELL_CAST_START_FULL_TEXT_NO_DEST = "%1$s begins casting %2$s.";
			ACTION_SPELL_CAST_START_FULL_TEXT_NO_SOURCE = "%1$s begins casting %2$s at %4$s.";
		]]
		
		
		if color then
			local template
			
			if sourceName and destName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT_NO_SOURCE
			elseif sourceName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT_NO_DEST
			elseif destName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT
			end
					
			spellFrame:AddMessage(format(template, sourceName, colorize(spellName, color), nil, destName))
		end
	end
end
