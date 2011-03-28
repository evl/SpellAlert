local bit_band = bit.band
local bit_bor = bit.bor

local ENEMY_PLAYER = bit_bor(COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_TYPE_PLAYER)

local HARMFUL_SPELLS = {
	-- Druid
	["Entangling Roots"] = true,
	["Cyclone"] = true,
	["Wrath"] = true,
	["Starfire"] = true,
	["Hibernate"] = true,
	["Starsurge"] = true,

	-- Hunter
	["Aimed Shot"] = true,
	["Steady Shot"] = true,
	["Cobra Shot"] = true,
	["Scare Beast"] = true,

	-- Mage
	["Polymorph"] = true,
	["Frostbolt"] = true,
	["Fireball"] = true,
	["Arcane Blast"] = true,
	["Pyroblast"] = true,
	["Flamestrike"] = true,
	["Scorch"] = true,
	["Frostfire Bolt"] = true,

	-- Paladin
	["Exorcism"] = true,

	-- Priest
	["Mind Control"] = true,
	["Mind Blast"] = true,
	["Mana Burn"] = true,
	["Smite"] = true,
	["Holy Fire"] = true,
	["Vampiric Touch"] = true,
	["Mind Spike"] = true,
	["Mass Dispel"] = true,
	
	-- Shaman
	["Lightning Bolt"] = true,
	["Chain Lightning"] = true,
	["Lava Burst"] = true,
	["Hex"] = true,
	
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
	["Hand of Gul'dan"] = true,
	["Immolate"] = true,
	["Haunt"] = true,
	["Chaos Bolt"] = true,
	["Searing Pain"] = true,
	["Banish"] = true,

	-- Warrior
	["Shattering Throw"] = true,
}

local HEALING_SPELLS = {
	-- Priest
	["Flash Heal"] = true,
	["Resurrection"] = true,
	["Heal"] = true,
	["Greater Heal"] = true,
	["Binding Heal"] = true,
	["Penance"] = true,
	["Prayer of Healing"] = true,

	-- Druid
	["Healing Touch"] = true,
	["Regrowth"] = true,
	["Nourish"] = true,
	["Revive"] = true,
	
	-- Paladin
	["Flash of Light"] = true,
	["Holy Light"] = true,
	["Divine Light"] = true,
	["Redemption"] = true,
		
	-- Shaman
	["Chain Heal"] = true,	
	["Healing Wave"] = true,
	["Healing Surge"] = true,
	["Greater Healing Wave"] = true,
	["Ancestral Spirit"] = true,

	-- Hunter
	["Revive Pet"] = true,
}

local BUFF_SPELLS = {
	-- Death Knight
	["Icebound Fortitude"] = true,
	["Anti-Magic Shell"] = true,
	["Lichborne"] = true,
	["Pillar of Frost"] = true,
	["Unholy Frenzy"] = true,
	
	-- Druid
	["Innervate"] = true,
	["Frenzied Regeneration"] = true,
	["Nature's Grasp"] = true,
	["Barkskin"] = true,
	["Nature's Swiftness"] = true,
	["Tree of Life"] = true,
	["Tranquility"] = true,

	-- Hunter
	["Feign Death"] = true,
	["Rapid Fire"] = true,
	["Deterrence"] = true,
	["The Beast Within"] = true,

	-- Mage
	["Ice Block"] = true,
	["Time Warp"] = true,
	["Presence of Mind"] = true,
	["Arcane Power"] = true,
	["Icy Veins"] = true,
	["Evocation"] = true,

	-- Paladin
	["Hand of Protection"] = true,
	["Divine Protection"] = true,
	["Divine Plea"] = true,
	["Divine Shield"] = true,
	["Hand of Freedom"] = true,
	["Avenging Wrath"] = true,
	["Hand of Sacrifice"] = true,
	["Aura Mastery"] = true,
	["Ardent Defender"] = true,
	["Zealotry"] = true,

	-- Priest
	["Fear Ward"] = true,
	["Hymn of Hope"] = true,
	["Pain Suppression"] = true,
	["Dispersion"] = true,

	-- Rogue
	["Evasion"] = true,
	["Vanish"] = true,
	["Cloak of Shadows"] = true,
	["Combat Readiness"] = true,
	["Adrenaline Rush"] = true,
	["Shadow Dance"] = true,

	-- Shaman
	["Bloodlust"] = true,
	["Heroism"] = true,
	["Spiritwalker's Grace"] = true,
	["Shamanistic Rage"] = true,
	
	-- Warlock
	["Metamorphosis"] = true,
	
	-- Warrior
	["Shield Wall"] = true,
	["Recklessness"] = true,
	["Spell Reflection"] = true,
	["Death Wish"] = true,
	["Deadly Calm"] = true,

	-- Other
	["Stoneform"] = true,
}

local function hasFlag(flags, flag)
	return bit_band(flags, flag) == flag
end

local function colorize(value, color)
	return "|cff" .. color .. value .. "|r"
end

local function decimalToHex(r,g,b)
    return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local function nameFormat(orgName, GUID)
	local newName = orgName
	if orgName then
		newName = orgName
		local orgNameEnd = (strfind(orgName, "-"))
		if orgNameEnd then
			orgNameEnd = orgNameEnd - 1
			newName = strsub(orgName, 1, orgNameEnd)
		end
			
		local _, playerClass = GetPlayerInfoByGUID(GUID)
		local classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[playerClass] or RAID_CLASS_COLORS[playerClass]
		classColor = decimalToHex(classColor.r, classColor.g, classColor.b)
		newName = colorize(newName, classColor)
	end
	return newName
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
		local newDestName = nameFormat(destName, destGUID)
		
		buffFrame:AddMessage(format(ACTION_SPELL_AURA_APPLIED_BUFF_FULL_TEXT_NO_SOURCE, nil, colorize(spellName, "00ff00"), nil, newDestName))
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
			
			local newSourceName = nameFormat(sourceName, sourceGUID)
			local newDestName = nameFormat(destName, destGUID)
			
			spellFrame:AddMessage(format(template, newSourceName, colorize(spellName, color), nil, newDestName))
		end
	end
end
