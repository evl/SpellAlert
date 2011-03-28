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
	["Mind Spike"] = true,

	-- Druid
	["Entangling Roots"] = true,
	["Cyclone"] = true,
	["Wrath"] = true,
	["Starfire"] = true,
	
	-- Hunter
	["Aimed Shot"] = true,
	["Steady Shot"] = true,
	["Cobra Shot"] = true,
	
	-- Mage
	["Polymorph"] = true,
	["Frostbolt"] = true,
	["Fireball"] = true,
	["Arcane Blast"] = true,
	["Pyroblast"] = true,
	["Flamestrike"] = true,
	
	-- Shaman
	["Lightning Bolt"] = true,
	["Chain Lightning"] = true,
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
	
	-- Paladin
	["Exorcism"] = true,
}

local HEALING_SPELLS = {
	-- Priest
	["Flash Heal"] = true,
	["Resurrection"] = true,
	["Heal"] = true,
	["Greater Heal"] = true,
	["Binding Heal"] = true,
	
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
}

local BUFF_SPELLS = {
	["Bloodlust"] = true,
	["Time Warp"] = true,
	["Adrenaline Rush"] = true,
	["Avenging Wrath"] = true,
	["Hand of Freedom"] = true,
	["Hand of Protection"] = true,
	["Death Wish"] = true,
	["Deterrence"] = true,	
	["Divine Shield"] = true,
	["Divine Protection"] = true,
	["Evasion"] = true,
	["Heroism"] = true,
	["Pain Suppression"] = true,
	["Recklessness"] = true,
	["Spell Reflection"] = true,
	--["Stealth"] = true,
	["Stoneform"] = true,
	["The Beast Within"] = true,
	["Icebound Fortitude"] = true,
	["Anti-Magic Shell"] = true,
	["Unholy Frenzy"] = true,
	["Barkskin"] = true,
	["Shield Wall"] = true,
	["Tree of Life"] = true,
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
		newDestName = destName
		local destNameEnd = (strfind(destName, "-"))
		if destNameEnd then
			destNameEnd = destNameEnd - 1
			newDestName = strsub(destName, 1, destNameEnd)
		end
			
		local _, destClass = GetPlayerInfoByGUID(destGUID)
		local destColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[destClass] or RAID_CLASS_COLORS[destClass]
		destColor = decimalToHex(destColor.r, destColor.g, destColor.b)
		newDestName = colorize(newDestName, destColor)
		
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
			
			if sourceName then
				newSourceName = sourceName
				local sourceNameEnd = (strfind(sourceName, "-"))
				if sourceNameEnd then
					sourceNameEnd = sourceNameEnd - 1
					newSourceName = strsub(sourceName, 1, sourceNameEnd)
				end
					
				local _, sourceClass = GetPlayerInfoByGUID(sourceGUID)
				local sourceColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[sourceClass] or RAID_CLASS_COLORS[sourceClass]
				sourceColor = decimalToHex(sourceColor.r, sourceColor.g, sourceColor.b)
				newSourceName = colorize(newSourceName, sourceColor)
			end
			
			if destName then
				newDestName = destName
				local destNameEnd = (strfind(destName, "-"))
				if destNameEnd then
					destNameEnd = destNameEnd - 1
					newDestName = strsub(destName, 1, destNameEnd)
				end
					
				local _, destClass = GetPlayerInfoByGUID(destGUID)
				local destColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[destClass] or RAID_CLASS_COLORS[destClass]
				destColor = decimalToHex(destColor.r, destColor.g, destColor.b)
				newDestName = colorize(newDestName, destColor)
			end
			
			
			if sourceName and destName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT_NO_SOURCE
			elseif sourceName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT_NO_DEST
			elseif destName then
				template = ACTION_SPELL_CAST_START_FULL_TEXT
			end
			
			spellFrame:AddMessage(format(template, newSourceName and newSourceName or sourceName, colorize(spellName, color), nil, newDestName and newDestName or destName))
		end
	end
end
