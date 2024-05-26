local addonName, addon = ...
local frame = _G[addonName]
local L = addon.L

local ITEM_LEVEL_STR_1 = string.gsub(ITEM_LEVEL, "%%d", "(.+)")
local ITEM_LEVEL_STR_2 = string.gsub(ITEM_LEVEL, "%%d", "(.+) \((.+)\)")
local ENCHANT_REQ_STR = L["canenchant"]
--local ENCHANT_REQ_STR = "마법부여가 가능한 부위입니다."
local ADDSLOT_REQ_STR = L["cangem"]
--local ADDSLOT_REQ_STR = "보석홈을 추가 가능한 부위입니다."

local MAX_DETAIL_ICON = 3
local MAX_DETAIL_ICON_LINE = 2
local DETAIL_ICON_SIZE = 12

local _, _, ENCHANT_ICON = GetSpellInfo(28029)

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

local function ParseItemLink(itemLink)
	if not itemLink then return nil end

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if not itemString then return nil end

	local elements = {}
	local idx = 1
	local from, to = string.find(itemString, ":", idx)
	while from do
		table.insert(elements, tonumber(string.sub(itemString, idx, from-1)) or 0)
		idx = to + 1
		from, to = string.find(itemString, ":", idx)
	end
	table.insert(elements, tonumber(string.sub(itemString, idx)) or 0)

	-- 이제 elements에 존재하는 모든 값은 number이며, 0은 유효하지 않은 값이다.

	-- item : itemID : enchantID : gemID1 : gemID2 : gemID3 : gemID4 : suffixID : uniqueID : linkLevel : specializationID : modifiersMask : itemContext : numBonusIDs[:bonusID1:bonusID2:...] : numModifiers[:modifierType1:modifierValue1:...] : relic1NumBonusIDs[:relicBonusID1:relicBonusID2:...] : relic2NumBonusIDs[...] : relic3NumBonusIDs[...] : crafterGUID : extraEnchantID

	local itemLinkData = {}
	itemLinkData.itemID = elements[2]
	itemLinkData.gemCount = 0

	for i = 4, 6 do
		local gemID = elements[i]
		if gemID > 0 then
			itemLinkData.gems = itemLinkData.gems or {}
			itemLinkData.gems[i-3] = {}
			itemLinkData.gems[i-3].gemID = gemID
			itemLinkData.gemCount = itemLinkData.gemCount + 1
		end
	end
	
	local it = 14
	if table.getn(elements) > it then
		local numberOfBonusIDs = elements[it]
		it = it + 1
		if numberOfBonusIDs > 0 then
			itemLinkData.bonusIDs = {}
			for i = it, it + numberOfBonusIDs - 1 do
				table.insert(itemLinkData.bonusIDs, elements[i])
				it = it + 1
			end
		end
	end

	if table.getn(elements) > it then
		local numberOfModifiers = elements[it]
		it = it + 1
		if numberOfModifiers > 0 then
			itemLinkData.modifiers = {}
			for i = it, it + (numberOfModifiers * 2) - 1, 2 do
				table.insert(itemLinkData.modifiers, elements[i], elements[i+1])
				it = it + 2
			end
		end
	end

	for gemIdx = 1, 3 do
		if table.getn(elements) > it then
			local numberOfGemBonusIDs = elements[it]
			it = it + 1
			if numberOfGemBonusIDs > 0 and itemLinkData.gems[gemIdx] then
				itemLinkData.gems[gemIdx].bonusIDs = {}
				for i = it, it + numberOfGemBonusIDs - 1 do
					table.insert(itemLinkData.gems[gemIdx].bonusIDs, elements[i])
					it = it + 1
				end
			end
		end
	end
	
	return itemLinkData
end

local function MakeItemLinkWithBonusID(itemID, bonusIDs)
	local numberOfBonusIDs = bonusIDs and #bonusIDs or 0

	if numberOfBonusIDs == 0 then
		return select(2, GetItemInfo(itemID))	
	end

	local bonusIDsStr = ""
	for _, v in pairs(bonusIDs) do
		bonusIDsStr = bonusIDsStr .. ":" .. v
	end

	local newItemLink = ("item:%d::::::::::::%d%s"):format(itemID, numberOfBonusIDs, bonusIDsStr)
	return newItemLink
end

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

-- 아이템 정보 관리
local EquipItemMixin = {}

function EquipItemMixin:SetSlot(bag, slot)
	self.bag = bag
	self.slotID = slot
	self.itemLevel = nil
	self.tooltipData = nil
end

function EquipItemMixin:IsPlayerItem()
	return (self:GetUnit() == "player")
end

function EquipItemMixin:UpdateItemLevel()
	self.itemLevel = self:GetItemLevel()
end

function EquipItemMixin:GetItemLevel()
	if not self:IsEquipped() then return nil end
	for _, line in pairs(self.tooltipData.lines) do
		local text = line.leftText
		local iLevel = string.match(text, ITEM_LEVEL_STR_1)
		if iLevel ~= nil then
			local retval = tonumber(iLevel)
			if(retval ~= nil) then
				return retval
			else
				local iLevel2 = string.match(text, ITEM_LEVEL_STR_2)
				if iLevel2 ~= nil then
					local retval2 = tonumber(iLevel2)
					if(retval2 ~= nil) then
						return retval2
					end
				end				
			end
		end
	end
	return nil
end

function EquipItemMixin:IsEquipped()
	return (self.tooltipData ~= nil)
end

function EquipItemMixin:GetItemLink()
	if self.tooltipData.guid then
		return C_Item.GetItemLinkByGUID(self.tooltipData.guid)
	elseif self.tooltipData.hyperlink then
		return self.tooltipData.hyperlink
	elseif self.tooltipData.id then
		return select(2, GetItemInfo(self.tooltipData.id))
	end
	return nil
end

function EquipItemMixin:CreateItemMixinBySlot()
	if not self:IsPlayerItem() then
		return nil
	end
	if self.bag then
		return Item:CreateFromBagAndSlot(self.bag, self.slotID)
	else
		return Item:CreateFromEquipmentSlot(self.slotID)
	end
end

function EquipItemMixin:CreateItemLocationMixinBySlot()
	if not self:IsPlayerItem() then
		return nil
	end
	if self.bag then
		return ItemLocation:CreateFromBagAndSlot(self.bag, self.slotID)
	else
		return ItemLocation:CreateFromEquipmentSlot(self.slotID)
	end
end

function EquipItemMixin:SetTooltipData()	
	self.tooltipData = nil
	if self:IsPlayerItem() and self.bag then
		self.tooltipData = C_TooltipInfo.GetBagItem(self.bag, self.slotID)
	elseif self.slotID then
		self.tooltipData = C_TooltipInfo.GetInventoryItem(self:GetUnit(), self.slotID)
	end

	if self.tooltipData then
		self.itemLinkData = ParseItemLink(self:GetItemLink())
	end
end

function EquipItemMixin:GetEnchant()
	if not self:IsEquipped() then return nil end
	for _, line in pairs(self.tooltipData.lines) do
		if line.type == Enum.TooltipDataLineType.ItemEnchantmentPermanent then
			return line.leftText
		end
	end
	return nil
end

function EquipItemMixin:CanEnchant()
	if not self:IsEquipped() then return false end
	if not self:GetItemLink() then return false end
	
	local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, itemClassID, itemSubClassID, _, expID, _, _ = GetItemInfo(self:GetItemLink())
	local profEnchant = false

	if self:IsPlayerItem() then
		local prof1, prof2 = GetProfessions()
		if prof1 == 8 or prof2 == 8 then
			profEnchant = true
		end
	end

	-- 격아 이후 확팩만 고려한다.
	-- 판다리아 리믹스 캐릭터는 마부 불가능하다
	if (PlayerGetTimerunningSeasonID() ~= nil) then
		return false
	end

	-- 용군단 혹은 346렙 이상 템 (무기/반지/다리/손목/발/가슴/망토/허리 + 머리)
	if (expID == LE_EXPANSION_DRAGONFLIGHT) or (self.itemLevel >= 346) then
		if itemClassID == Enum.ItemClass.Weapon or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_LEGS" or itemEquipLoc == "INVTYPE_WRIST" or itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_WAIST" or itemEquipLoc == "INVTYPE_HEAD" then
			return true
		end
	-- 어둠땅 혹은 158렙 이상 템 (무기/반지/장갑/손목/발/가슴/망토)
	elseif (expID == LE_EXPANSION_SHADOWLANDS) or (self.itemLevel >= 158) then
		if itemClassID == Enum.ItemClass.Weapon or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_HAND" or itemEquipLoc == "INVTYPE_WRIST" or itemEquipLoc == "INVTYPE_FEET" or itemEquipLoc == "INVTYPE_CHEST" or itemEquipLoc == "INVTYPE_ROBE" or itemEquipLoc == "INVTYPE_CLOAK" then
			return true
		end 
	-- 격아 (무기/반지/장갑/손목(마부사))
	elseif expID == LE_EXPANSION_BATTLE_FOR_AZEROTH then
		if itemClassID == Enum.ItemClass.Weapon or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_HAND" then
			return true
		end
		if profEnchant and itemEquipLoc == INVTYPE_WRIST then
			return true
		end
	end

	return false
end

function EquipItemMixin:CanAddSlot()
	if not self:IsEquipped() then return false end
	if not self:GetItemLink() then return false end
	
	local _, _, itemQuality, _, _, _, _, _, itemEquipLoc, _, _, itemClassID, itemSubClassID, _, expID, _, _ = GetItemInfo(self:GetItemLink())
	local sockets = self:GetSockets()
	local gems = self.itemLinkData.gems
	local slotCount = (sockets and #sockets or 0) + (self.itemLinkData.gemCount)

	-- 용군단 혹은 346렙 이상 에픽 템 (슬롯이 3개 미만인 목) / Dragonflight, ilvl 346 or higher, and epic quality (less than 3 slots)
	if ((expID == LE_EXPANSION_DRAGONFLIGHT) or (self.itemLevel >= 346)) and (itemQuality == Enum.ItemQuality.Epic) then
		if itemEquipLoc == "INVTYPE_NECK" and slotCount < 3 then
			return true
		end
	end

	return false
end

function EquipItemMixin:GetSockets()
	if not self:IsEquipped() then return nil end	
	local sockets = nil
	for _, line in pairs(self.tooltipData.lines) do
		if line.type == Enum.TooltipDataLineType.GemSocket and not line.gemIcon then
			sockets = sockets and sockets or {}
			table.insert(sockets, {socketType = line.socketType, socketName = line.leftText})
		end
	end
	return sockets
end

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

-- EquipItemMixin + 캐릭창에 뜰 정보 관리
local EquipItemUIMixin = {}

function EquipItemUIMixin:SetUpUI(slotFrame)
	self.slotFrame = slotFrame

	local font, _, flags = NumberFontNormal:GetFont()

	-- Ilvl string
	self.UpperStr = self.slotFrame:CreateFontString(nil, "OVERLAY")
	self.UpperStr:SetFont(font, 14, flags)
	self.UpperStr:SetPoint("TOP", self.slotFrame, "TOP", 0, -3)
	self.UpperStr:SetTextColor(1,1,1)
	self.UpperStr:Hide()

	-- Durability string
	self.BottomStr = self.slotFrame:CreateFontString(nil, "OVERLAY")
	self.BottomStr:SetFont(font, 10, flags)
	self.BottomStr:SetPoint("BOTTOM", self.slotFrame, "BOTTOM", 0, 3)
	self.BottomStr:SetTextColor(1,1,1)
	self.BottomStr:Hide()

	self.DetailIcon = {}
	local index = 0
	for line = 1, MAX_DETAIL_ICON_LINE do
		for i = 1, MAX_DETAIL_ICON do
			index = index + 1
			local detailIcon = CreateFrame("Button", addonName..slotFrame:GetName().."DetailIcon"..index, self.slotFrame)
			detailIcon:EnableMouse(true)
			--detailIcon:RegisterForClicks("AnyUp")
			--detailIcon:RegisterForDrag("LeftButton", "RightButton")
			detailIcon:SetScript("OnEnter", function(self) if self.DetailIcon_OnEnter then self:DetailIcon_OnEnter() end end)
			detailIcon:SetScript("OnLeave", function(self) if self.DetailIcon_OnLeave then self:DetailIcon_OnLeave() end end)
			detailIcon:SetScript("OnClick", function(self) if self.DetailIcon_OnClick then self:DetailIcon_OnClick() end end)
			detailIcon:SetWidth(DETAIL_ICON_SIZE)
			detailIcon:SetHeight(DETAIL_ICON_SIZE)
			local icon = detailIcon:CreateTexture(nil, "BORDER")
			icon:SetAllPoints(detailIcon)
			icon:Show()
			detailIcon.icon = icon
			detailIcon.line = line
			detailIcon.indexInLine = i
			self.DetailIcon[index] = detailIcon
		end
	end
end

function EquipItemUIMixin:ShowItemLevelStr(bShow)
	if not bShow then
		self.UpperStr:Hide()
		return
	end

	self:UpdateItemLevel()
	if self.itemLevel and self.itemLevel > 0 then
		local itemQuality = CharInfoEnhancerOption.ItemLevelQualityColor and select(3, GetItemInfo(self:GetItemLink())) or 1
		self.UpperStr:SetText(ITEM_QUALITY_COLORS[itemQuality or 1].hex .. self.itemLevel .. FONT_COLOR_CODE_CLOSE)
		self.UpperStr:Show()
	else
		self.UpperStr:Hide()
	end
end

function EquipItemUIMixin:ShowDurabilityStr(bShow)
	if not bShow then
		self.BottomStr:Hide()
		return
	end

	local current, maximum
	if self:IsPlayerItem() and self.bag then
		current, maximum = C_Container.GetContainerItemDurability(self.bag, self.slotID);
	else
		current, maximum = GetInventoryItemDurability(self.slotID);
	end
	--print(self.slotFrame:GetName(), current, maximum)

	if (not current) or (not maximum) or (maximum == 0) then
		self.BottomStr:Hide()
		return
	end
	
	local rate = current / maximum
	local percent = floor(rate * 100 + 0.5)

	if percent > 0 then
		self.BottomStr:SetText(format("|cff%.2x%.2x%.2x%d%%|r", 1*255, rate*255, rate*255, percent))
	else
		self.BottomStr:SetText("|cffFF00000|r")
	end

	self.BottomStr:Show()
end

function EquipItemUIMixin:GetNextDetailIcon()
	local detailIconIndex, detailIcon = next(self.DetailIcon, self.detailIconIndex)
	self.detailIconIndex = detailIconIndex
	--print(detailIconIndex, detailIcon:GetName())
	return detailIcon
end

function EquipItemUIMixin:GetSecondLineDetailIcon()
	self.detailIconIndex = MAX_DETAIL_ICON + 1
	return self.DetailIcon[self.detailIconIndex]
end

function EquipItemUIMixin:UpdateDetailIcon(bBag)
	-- 전체 초기화
	self.detailIconIndex = nil
	for _, detailIcon in pairs(self.DetailIcon) do
		detailIcon.icon:SetTexture(nil)
		detailIcon.DetailIcon_OnEnter = nil
		detailIcon.DetailIcon_OnLeave = nil
		detailIcon.DetailIcon_OnClick = nil

		--detailIcon.icon:SetTexture("Interface/Icons/Inv_eyeofnzothpet")
		--detailIcon.DetailIcon_OnEnter = function(detailIcon) print(detailIcon:GetName() .." : OnEnter") end
		--detailIcon.DetailIcon_OnLeave = function(detailIcon) print(detailIcon:GetName() .." : OnLeaver") end
		--detailIcon.DetailIcon_OnClick = function(detailIcon) print(detailIcon:GetName() .." : OnClick") end

		-- 위치 설정
		if (self:IsPlayerItem() and self.bag) or bBag then
			detailIcon:SetPoint("TOPLEFT", self.slotFrame, "TOPRIGHT", 4 + DETAIL_ICON_SIZE*(detailIcon.indexInLine-1), -6 - DETAIL_ICON_SIZE*(detailIcon.line-1))
		else
			-- 우측에 아이콘
			if self.slotID == INVSLOT_HEAD or self.slotID == INVSLOT_NECK or self.slotID == INVSLOT_SHOULDER or self.slotID == INVSLOT_BACK or self.slotID == INVSLOT_CHEST or self.slotID == INVSLOT_WRIST then
				detailIcon:SetPoint("TOPLEFT", self.slotFrame, "TOPRIGHT", 7 + DETAIL_ICON_SIZE*(detailIcon.indexInLine-1), -6 - DETAIL_ICON_SIZE*(detailIcon.line-1))
			elseif self.slotID == INVSLOT_OFFHAND then
				detailIcon:SetPoint("TOPLEFT", self.slotFrame, "TOPRIGHT", 4 + DETAIL_ICON_SIZE*(detailIcon.indexInLine-1), -6 - DETAIL_ICON_SIZE*(detailIcon.line-1))
			-- 좌측에 아이콘
			elseif self.slotID == INVSLOT_HAND or self.slotID == INVSLOT_WAIST or self.slotID == INVSLOT_LEGS or self.slotID == INVSLOT_FEET or self.slotID == INVSLOT_FINGER1 or self.slotID == INVSLOT_FINGER2 or self.slotID == INVSLOT_TRINKET1 or self.slotID == INVSLOT_TRINKET2 then
				detailIcon:SetPoint("TOPRIGHT", self.slotFrame, "TOPLEFT", -8 - DETAIL_ICON_SIZE*(detailIcon.indexInLine-1), -6 - DETAIL_ICON_SIZE*(detailIcon.line-1))
			elseif self.slotID ==  INVSLOT_MAINHAND then
				detailIcon:SetPoint("TOPRIGHT", self.slotFrame, "TOPLEFT", -5 - DETAIL_ICON_SIZE*(detailIcon.indexInLine-1), -6 - DETAIL_ICON_SIZE*(detailIcon.line-1))
			end	
		end
	end
	
	self:UpdateDetailIcon_AzeriteEmpowered()
	if self.detailIconIndex then return end

	self:UpdateDetailIcon_AzeriteEssence()
	if self.detailIconIndex then return end

	self:UpdateDetailIcon_Gem()
	self:UpdateDetailIcon_Enchant()
end

function EquipItemUIMixin:UpdateDetailIcon_Gem()
	if not self:IsEquipped() then return end
	if not self.itemLinkData then return end

	-- 판다리아 리믹스 캐릭터는 보석 및 홈 정보를 표시하지 않는다
	-- 기본 UI에 포함되어 있다
	if (PlayerGetTimerunningSeasonID() ~= nil) then return end

	local gems = self.itemLinkData.gems
	if gems then
		for _, v in pairs(gems) do
			local detailIcon = self:GetNextDetailIcon()	
			local itemLink = MakeItemLinkWithBonusID(v.gemID, v.bonusIDs)
			detailIcon.icon:SetTexture(GetItemIcon(v.gemID))
			detailIcon.DetailIcon_OnEnter = function(detailIcon)
				GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(itemLink)
				GameTooltip:Show()
			end
			detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
		end
	end

	local sockets = self:GetSockets()
	if sockets then
		for _, socketInfo in pairs(sockets) do
			local detailIcon = self:GetNextDetailIcon()	
			local texture = string.format("Interface\\ItemSocketingFrame\\UI-EmptySocket-%s", socketInfo.socketType);
			detailIcon.icon:SetTexture(texture)
			detailIcon.DetailIcon_OnEnter = function(detailIcon)
				GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
				GameTooltip:AddLine(socketInfo.socketName, nil, nil, nil, true)
				GameTooltip:Show()
			end
			detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
		end
	end
end

function EquipItemUIMixin:UpdateDetailIcon_Enchant()
	if not self:IsEquipped() then return end

	local enchantStr = self:GetEnchant()
	if enchantStr then 
		local detailIcon = self:GetSecondLineDetailIcon()
		detailIcon.icon:SetTexture(ENCHANT_ICON)
		detailIcon.DetailIcon_OnEnter = function(detailIcon)
			GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
			GameTooltip:AddLine(enchantStr, nil, nil, nil, true)
			GameTooltip:Show()
		end
		detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
	elseif self:CanEnchant() then		
		local detailIcon = self:GetSecondLineDetailIcon()
		detailIcon.icon:SetTexture(GetItemIcon(6218))
		detailIcon.DetailIcon_OnEnter = function(detailIcon)
			GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
			GameTooltip:AddLine(ENCHANT_REQ_STR, nil, nil, nil, true)
			GameTooltip:Show()
		end
		detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
	elseif self:CanAddSlot() then		
		local detailIcon = self:GetSecondLineDetailIcon()
		detailIcon.icon:SetTexture(GetItemIcon(192992))
		detailIcon.DetailIcon_OnEnter = function(detailIcon)
			GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
			GameTooltip:AddLine(ADDSLOT_REQ_STR, nil, nil, nil, true)
			GameTooltip:Show()
		end
		detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
	end
end

function EquipItemUIMixin:UpdateDetailIcon_AzeriteEmpowered()
	if not self:IsEquipped() or not self:IsPlayerItem() then return end

	local itemLocation = self:CreateItemLocationMixinBySlot() 

	if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then	
		local azeriteItemDataSource = AzeriteEmpoweredItemDataSource:CreateEmpty()
		azeriteItemDataSource:SetSourceFromItemLocation(itemLocation)
		--local item = azeriteItemDataSource:GetItem()
		local allTierInfo = azeriteItemDataSource:GetAllTierInfo();

		for i = 1, #allTierInfo do
			local powerID = AzeriteUtil.GetSelectedAzeritePowerInTier(azeriteItemDataSource, i)
			if powerID then
				local detailIcon = (i == 3) and self:GetSecondLineDetailIcon() or self:GetNextDetailIcon()				
				local texture = GetSpellTexture(azeriteItemDataSource:GetPowerSpellID(powerID))
				if texture then detailIcon.icon:SetTexture(texture)					
				else detailIcon.icon:SetAtlas("Azerite-CenterTrait-On", true) end
				detailIcon.DetailIcon_OnEnter = function(detailIcon)
					local item = self:CreateItemMixinBySlot()
					GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
					GameTooltip:SetAzeritePower(item:GetItemID(), item:GetCurrentItemLevel(), powerID, item:GetItemLink())
					GameTooltip:Show()
				end
				detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
			end
		end
	end
end

function EquipItemUIMixin:UpdateDetailIcon_AzeriteEssence()
	if not self:IsEquipped() or not self:IsPlayerItem() then return end

	local item = self:CreateItemMixinBySlot()

	 -- 아제로스의 심장이며, 정수 기능이 활성화 되었을때
	if item:GetItemID() == 158075 and C_AzeriteEssence.CanOpenUI() then
		local milestones = C_AzeriteEssence.GetMilestones()
		local count = 0
		for i, milestoneInfo in pairs(milestones) do
			if milestoneInfo.unlocked and milestoneInfo.slot then
				local essenceID = C_AzeriteEssence.GetMilestoneEssence(milestoneInfo.ID)
				if essenceID then
					count = count + 1
					local detailIcon = (count == 2) and self:GetSecondLineDetailIcon() or self:GetNextDetailIcon()
					local essenceInfo = C_AzeriteEssence.GetEssenceInfo(essenceID)
					detailIcon.icon:SetTexture(essenceInfo.icon)
					detailIcon.DetailIcon_OnEnter = function(detailIcon)
						GameTooltip:SetOwner(detailIcon, "ANCHOR_RIGHT")
						GameTooltip:SetAzeriteEssenceSlot(milestoneInfo.slot)
						GameTooltip:Show()
					end	
					detailIcon.DetailIcon_OnLeave = function(detailIcon) GameTooltip:Hide() end
				end
			end
		end
	end
end

function EquipItemUIMixin:ShowDetailIcon(bShow)
	for _, detailIcon in pairs(self.DetailIcon) do
		if bShow and detailIcon.icon:GetTexture() then
			detailIcon:Show()
		else
			detailIcon:Hide()
		end
	end
end

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

function frame:CreateEquipItemUIMixin()
	return CreateFromMixins(EquipItemUIMixin, EquipItemMixin)
end

function frame:CreateEquipItemMixin()
	return CreateFromMixins(EquipItemMixin)
end