local addonName, addon = ...
local L = addon.L

local frame = CreateFrame("Frame", addonName)
frame:SetScript("OnUpdate", function(self, elapsed) self:OnUpdate(elapsed) end)
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...); end)
frame:Show()

frame.OptionFrame = addon.OptionPanel

local EquipSlot = {
	[1]	 = "HeadSlot",
	[2]	 = "NeckSlot",
	[3]	 = "ShoulderSlot",
	--[4]	 = "ShirtSlot",
	[5]	 = "ChestSlot",
	[6]	 = "WaistSlot",
	[7]	 = "LegsSlot",
	[8]	 = "FeetSlot",
	[9]	 = "WristSlot",
	[10] = "HandsSlot",
	[11] = "Finger0Slot",
	[12] = "Finger1Slot",
	[13] = "Trinket0Slot",
	[14] = "Trinket1Slot",
	[15] = "BackSlot",
	[16] = "MainHandSlot",
	[17] = "SecondaryHandSlot",
	--[19] = "TabardSlot",
}

local AVG_ITEM_LEVEL_STR = L["avgilvl"] .. ": %s"
local REFRESH_RATE = 1

frame.lastRefreshTimePlayer = 0
frame.lastRefreshTimeInspect = 0
frame.PaperDollFrameShow = false

local OPTION_INIT_LIST = {
	["ShowDurability"] = true,
	["ShowDetailIcon"] = true,
	["TooltipInspect"] = true,
	["StatPrecision"] = true,
	["AvgItemLevelPrecision"] = true,
	["ItemLevelQualityColor"] = false,
}

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

frame:RegisterEvent("PLAYER_LOGIN")
function frame:PLAYER_LOGIN()
	-- 옵션 초기값 설정
	if not CharInfoEnhancerOption then CharInfoEnhancerOption = {} end
	for k, v in pairs(OPTION_INIT_LIST) do
		if CharInfoEnhancerOption[k] == nil then CharInfoEnhancerOption[k] = v end
	end

	-- 아이템 레벨 표시 제한 레벨을 해제한다.
	MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY = 1

	-- 이동 속도 표시
	table.insert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "MOVESPEED" })

	-- EquipitemMixin 생성
	self.PlayerEquipUI = {}
	for slotID, slotName in pairs(EquipSlot) do
		self.PlayerEquipUI[slotID] = self:CreateEquipItemUIMixin()
		self.PlayerEquipUI[slotID]:SetSlot(nil, slotID)
		self.PlayerEquipUI[slotID]:SetUpUI(_G["Character"..slotName])
		self.PlayerEquipUI[slotID].GetUnit = function(self) return "player" end
	end

	self.MouseOverEquip = {}
	for slotID, slotName in pairs(EquipSlot) do
		self.MouseOverEquip[slotID] = self:CreateEquipItemMixin()
		self.MouseOverEquip[slotID]:SetSlot(nil, slotID)
		self.MouseOverEquip[slotID].GetUnit = function(self) return frame.InspectInfo.unit end
	end

	-- 각종 함수 hook, override
	PaperDollFrame_SetItemLevel = OverridePaperDollFrame_SetItemLevel

	hooksecurefunc("PaperDollFrame_SetLabelAndText", function (statFrame, label, text, isPercentage, numericValue)
		frame:OnPaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
		end)

	_G["PaperDollFrame"]:HookScript("OnShow", function(self, ...)
		frame:UpdatePlayerEquipItem()
		frame:UpdatePlayerDurability()
		frame.PaperDollFrameShow = true

		frame:RegisterEvent("UNIT_INVENTORY_CHANGED")		
		frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
		frame:RegisterEvent("PLAYER_DEAD")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("PLAYER_UNGHOST")
		frame:RegisterEvent("MERCHANT_UPDATE")
		frame:RegisterEvent("MERCHANT_CLOSED")		
		frame:RegisterEvent("SOCKET_INFO_UPDATE")
		frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		frame:RegisterEvent("AZERITE_ESSENCE_CHANGED")
		frame:RegisterEvent("AZERITE_ESSENCE_UPDATE")
		frame:RegisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")			
		frame:RegisterEvent("BAG_UPDATE")	
		frame:RegisterEvent("VOID_STORAGE_UPDATE")	
	end)

	_G["PaperDollFrame"]:HookScript("OnHide", function(self, ...)		
		frame.PaperDollFrameShow = false
		frame:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		frame:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
		frame:UnregisterEvent("PLAYER_DEAD")
		frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
		frame:UnregisterEvent("PLAYER_UNGHOST")
		frame:UnregisterEvent("MERCHANT_UPDATE")
		frame:UnregisterEvent("MERCHANT_CLOSED")
		frame:UnregisterEvent("SOCKET_INFO_UPDATE")
		frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
		frame:UnregisterEvent("AZERITE_ESSENCE_CHANGED")
		frame:UnregisterEvent("AZERITE_ESSENCE_UPDATE")
		frame:UnregisterEvent("AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED")
		frame:UnregisterEvent("BAG_UPDATE")	
		frame:UnregisterEvent("VOID_STORAGE_UPDATE")	
	end)

	-- TooltipInspect.lua 관련
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, tooltipData) frame:OnTooltipSetUnit(tooltip, tooltipData) end)

	hooksecurefunc("InspectUnit", function (unit)
		frame:OnInspectUnit(unit)
		end)

	-- 캐릭창 UI 추가
	local font, _, flags = NumberFontNormal:GetFont()
	local durCheck = CreateFrame("CheckButton", addonName.."DurCheckButton", _G["PaperDollFrame"], "UICheckButtonTemplate")
	durCheck:SetSize(16,16)
	_G[durCheck:GetName() .. "Text"]:SetFont(font, 10, flags)
	_G[durCheck:GetName() .. "Text"]:SetTextColor(1,1,1)
	_G[durCheck:GetName() .. "Text"]:SetText(L["durability"])
	_G[durCheck:GetName() .. "Text"]:ClearAllPoints()
	_G[durCheck:GetName() .. "Text"]:SetPoint("LEFT", durCheck, "RIGHT", 0, 1)
	durCheck:SetChecked(CharInfoEnhancerOption.ShowDurability)
	durCheck:SetPoint("BOTTOMLEFT", _G["PaperDollFrame"], "BOTTOMLEFT", 6, 4)
	durCheck:SetScript("OnClick", function (self)
		CharInfoEnhancerOption.ShowDurability = self:GetChecked() and true or false
		frame:UpdatePlayerDurability()
		frame:RefreshEquipmentFlyoutUI()
	end)

	local detailCheck = CreateFrame("CheckButton", addonName.."DetailCheckButton", _G["PaperDollFrame"], "UICheckButtonTemplate")
	detailCheck:SetSize(16,16)
	_G[detailCheck:GetName() .. "Text"]:SetFont(font, 10, flags)
	_G[detailCheck:GetName() .. "Text"]:SetTextColor(1,1,1)
	_G[detailCheck:GetName() .. "Text"]:SetText(L["details"])
	_G[detailCheck:GetName() .. "Text"]:ClearAllPoints()
	_G[detailCheck:GetName() .. "Text"]:SetPoint("LEFT", detailCheck, "RIGHT", 0, 0)
	detailCheck:SetChecked(CharInfoEnhancerOption.ShowDetailIcon)
	detailCheck:SetPoint("BOTTOMLEFT", _G["PaperDollFrame"], "BOTTOMLEFT", 6, 18)
	detailCheck:SetScript("OnClick", function (self)
		CharInfoEnhancerOption.ShowDetailIcon = self:GetChecked() and true or false
		frame:UpdatePlayerEquipItem()
		frame:RefreshEquipmentFlyoutUI()
	end)

	frame:PLAYER_LOGIN_EquipmentFlyout()

	-- 초기화
	self.IsShowEquipmentFlyoutFrame = false

	-- 옵션 초기값 설정
	if not CharInfoEnhancerOption then CharInfoEnhancerOption = {} end
	for k, v in pairs(OPTION_INIT_LIST) do
		if CharInfoEnhancerOption[k] == nil then CharInfoEnhancerOption[k] = v end
	end

	-- 옵션 UI에 값 적용. 이것도 xml로 빼고 싶은데...
	for k, v in pairs(CharInfoEnhancerOption) do
		if self.OptionFrame[k] then self.OptionFrame[k]:SetChecked(v) end
	end
end

frame:RegisterEvent("ADDON_LOADED")
function frame:ADDON_LOADED(addon)
	-- 살펴보기 창은 처음 띄울때에 UI가 로드되기 때문에 그때에 별도로 초기화를 해야 한다.
	if addon == "Blizzard_InspectUI" then
		-- EquipitemMixin 생성
		self.InspectEquipUI = {}
		for slotID, slotName in pairs(EquipSlot) do
			self.InspectEquipUI[slotID] = self:CreateEquipItemUIMixin()
			self.InspectEquipUI[slotID]:SetSlot(nil, slotID)
			self.InspectEquipUI[slotID]:SetUpUI(_G["Inspect"..slotName])
			self.InspectEquipUI[slotID].GetUnit = function(self)
				if not frame:IsInspectFrameOpen() then return nil end
				return InspectFrame.unit
			end
		end

		-- 각종 함수 hook
		hooksecurefunc("InspectFrame_UpdateTabs", function()
			frame:UpdateInspectEquipItem()
			end)

		hooksecurefunc("InspectSwitchTabs", function(newwID)
			if newwID == 1 then self.InspectItemLevelStr:Show() 
			else self.InspectItemLevelStr:Hide() end	 
			end)		

			-- 살펴보기창 UI 추가
		local font, _, flags = NumberFontNormal:GetFont()
		self.InspectItemLevelStr = InspectFrame:CreateFontString(nil, "OVERLAY")
		self.InspectItemLevelStr:SetFont(font, 12, flags)
		self.InspectItemLevelStr:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 8, 14)
		self.InspectItemLevelStr:SetTextColor(1,1,1)
	end
end

frame:RegisterEvent("INSPECT_READY");
function frame:INSPECT_READY(guid)
	self:OnInspectReady(guid)
end

function frame:UNIT_INVENTORY_CHANGED(unit)
	if (unit == "player") then
		self:UpdatePlayerEquipItem()
		self:RefreshEquipmentFlyoutUI()
	end
end

function frame:UPDATE_INVENTORY_DURABILITY()
	self:UpdatePlayerDurability()
end

function frame:PLAYER_DEAD()
	self:UpdatePlayerDurability()
end

function frame:PLAYER_REGEN_ENABLED()
	self:UpdatePlayerDurability()
end

function frame:PLAYER_UNGHOST()
	self:UpdatePlayerDurability()
end

function frame:MERCHANT_UPDATE()
	self:UpdatePlayerDurability()
end

function frame:MERCHANT_CLOSED()
	self:UpdatePlayerDurability()
end

function frame:SOCKET_INFO_UPDATE()
	self:UpdatePlayerEquipItem()
end

function frame:ITEM_UPGRADE_MASTER_UPDATE()
	self:UpdatePlayerEquipItem()
end

function frame:PLAYER_EQUIPMENT_CHANGED()
	self:UpdatePlayerEquipItem()
end

function frame:AZERITE_ESSENCE_CHANGED()
	self:UpdatePlayerEquipItem()
end

function frame:AZERITE_ESSENCE_UPDATE()
	self:UpdatePlayerEquipItem()
end

function frame:AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED()
	self:UpdatePlayerEquipItem()
end

function frame:BAG_UPDATE()
	self:RefreshEquipmentFlyoutUI()
end

function frame:VOID_STORAGE_UPDATE()
	self:RefreshEquipmentFlyoutUI()
end

--[[-----------------------------------------------------------------------------
-------------------------------------------------------------------------------]]

function OverridePaperDollFrame_SetItemLevel(statFrame, unit)
	if ( unit ~= "player" ) then
		statFrame:Hide();
		return;
	end

	local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel();
	local minItemLevel = C_PaperDollInfo.GetMinItemLevel();

	local displayItemLevel = math.max(minItemLevel or 0, avgItemLevelEquipped);

	displayItemLevel = floor(displayItemLevel * 100) / 100;
	avgItemLevel = floor(avgItemLevel * 100) / 100;
	avgItemLevelPvP = floor(avgItemLevelPvP * 100) / 100;

	PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, frame:MakeItemLevelStr(displayItemLevel), false, displayItemLevel);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVERAGE_ITEM_LEVEL).." "..avgItemLevel;
	if ( displayItemLevel ~= avgItemLevel ) then
		statFrame.tooltip = statFrame.tooltip .. "  " .. format(string.gsub(STAT_AVERAGE_ITEM_LEVEL_EQUIPPED, "%%d", "%%.2f"), avgItemLevelEquipped);
	end
	statFrame.tooltip = statFrame.tooltip .. FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP;

	if ( avgItemLevel ~= avgItemLevelPvP ) then
		statFrame.tooltip2 = statFrame.tooltip2.."\n\n"..string.gsub(STAT_AVERAGE_PVP_ITEM_LEVEL, "%%d", "%%.2f"):format(avgItemLevelPvP);
	end
end

function frame:IsPaperDollFrameOpen()
	return self.PaperDollFrameShow
end

function frame:IsInspectFrameOpen()
	return (InspectFrame and InspectFrame:IsShown())
end

function frame:OnPaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
	if not CharInfoEnhancerOption.StatPrecision then 
		return
	end

	if isPercentage or label == STAT_HASTE then
		text = format("%.2f%%", numericValue);
		statFrame.Value:SetText(text);
	end
end

function frame:UpdatePlayerEquipItem()
	for _, equipItem in pairs(self.PlayerEquipUI) do
		equipItem:SetTooltipData()
		equipItem:ShowItemLevelStr(true)

		if CharInfoEnhancerOption.ShowDetailIcon then
			equipItem:UpdateDetailIcon(false)
			equipItem:ShowDetailIcon(true)
		else
			equipItem:ShowDetailIcon(false)
		end
	end

	self.lastRefreshTimePlayer = GetTime()
end

function frame:UpdateInspectEquipItem()
	if not self:IsInspectFrameOpen() or self.InspectEquipUI == nil then
		return
	end

	for _, equipItem in pairs(self.InspectEquipUI) do
		equipItem:SetTooltipData()
		equipItem:ShowItemLevelStr(true)
		equipItem:UpdateDetailIcon(false)
		equipItem:ShowDetailIcon(true)
	end

	local calcAvgLevel = frame:GetAvgItemLevel(self.InspectEquipUI)
	self.InspectItemLevelStr:SetText(string.format(AVG_ITEM_LEVEL_STR, self:MakeItemLevelStr(calcAvgLevel)))

	self.lastRefreshTimeInspect = GetTime()
end

function frame:UpdatePlayerDurability()
	for _, equipItem in pairs(self.PlayerEquipUI) do
		equipItem:ShowDurabilityStr(CharInfoEnhancerOption.ShowDurability)
	end
end

function frame:GetAvgItemLevel(equipTable)
	local sum = 0
	local count = 0
	for slotID, equipItem in pairs(equipTable) do
		-- 무기는 별도 처리
		if slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND then
			-- not to do
		else
			sum = sum + (equipItem:IsEquipped() and equipItem.itemLevel or 0)
			count = count + 1
		end
	end

	-- 각종 문서들에는 양손무기면 보조를 빼고 계산한다던데, 실제론 아니다.
	-- 양손 무기를 어느 한쪽 손에 장착했을때, 그것이 다른쪽 손의 템렙보다 높다면, 그걸 쌍수로 낀걸로 처리한다. 그렇지 않다면 양쪽 손의 템렙을 각각 더한다- 라는 규칙을 적용해야 API와 동일한 평균템렙이 나온다.
	function CheckTwoHand(unit, slotID)
		local itemLink = GetInventoryItemLink(unit, slotID)
		if not itemLink then return nil end
		local itemEquipLoc = select(9, GetItemInfo(itemLink))
		return ("INVTYPE_2HWEAPON" == itemEquipLoc or "INVTYPE_RANGED" == itemEquipLoc or "INVTYPE_RANGEDRIGHT" == itemEquipLoc)
	end
	local mainHandLevel = equipTable[INVSLOT_MAINHAND]:IsEquipped() and equipTable[INVSLOT_MAINHAND].itemLevel or 0
	local isMainHandTwoHand = equipTable[INVSLOT_MAINHAND]:IsEquipped() and CheckTwoHand(equipTable[INVSLOT_MAINHAND]:GetUnit(), INVSLOT_MAINHAND) or false
	local offHandLevel = equipTable[INVSLOT_OFFHAND]:IsEquipped() and equipTable[INVSLOT_OFFHAND].itemLevel or 0
	local isOffHandTwoHand = equipTable[INVSLOT_OFFHAND]:IsEquipped() and CheckTwoHand(equipTable[INVSLOT_OFFHAND]:GetUnit(), INVSLOT_OFFHAND) or false

	if isMainHandTwoHand and mainHandLevel >= offHandLevel then
		sum = sum + (mainHandLevel * 2)
	elseif isOffHandTwoHand and offHandLevel >= mainHandLevel then
		sum = sum + (offHandLevel * 2)		
	else
		sum = sum + mainHandLevel + offHandLevel
	end
	count = count + 2

	return sum / count
end

function frame:OnUpdate(elapsed)
	self:OnUpdate_TooltipInspect(elapsed)

	if self.IsShowEquipmentFlyoutFrame == false and EquipmentFlyoutFrame:IsShown() then
		self:RefreshEquipmentFlyoutUI()
		self.IsShowEquipmentFlyoutFrame = true
	end

	if self.IsShowEquipmentFlyoutFrame == true and EquipmentFlyoutFrame:IsShown() == false then
		self.IsShowEquipmentFlyoutFrame = false
	end

	if self:IsPaperDollFrameOpen() then
		if self.lastRefreshTimePlayer + REFRESH_RATE < GetTime() then
			frame:UpdatePlayerEquipItem()
		end
	end

	if self:IsInspectFrameOpen() then
		if self.lastRefreshTimeInspect + REFRESH_RATE < GetTime() then
			frame:UpdateInspectEquipItem()
		end
	end
end

function frame:MakeItemLevelStr(itemLevel)
	if CharInfoEnhancerOption.AvgItemLevelPrecision then
		return format("%.2f", itemLevel)
	else
		return format("%d", itemLevel)
	end
end