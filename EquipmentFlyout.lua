local addonName, addon = ...
local frame = _G[addonName]
local L = addon.L

local LASTLOCATION_NIL = -1

function frame:PLAYER_LOGIN_EquipmentFlyout()
	self.EquipmentFlyoutUI = {}

	hooksecurefunc("EquipmentFlyout_CreateButton", function()	
		frame:OnEquipmentFlyout_CreateButton()
		end)

	hooksecurefunc("EquipmentFlyout_DisplayButton", function(button, paperDollItemSlot)		
		frame:OnEquipmentFlyout_DisplayButton(button, paperDollItemSlot)
		end)		
end

function frame:RefreshEquipmentFlyoutUI()
	for _, equipItem in pairs(self.EquipmentFlyoutUI) do
		equipItem.lastLocation = LASTLOCATION_NIL
	end
end

function frame:OnEquipmentFlyout_CreateButton()
	local buttons = EquipmentFlyoutFrame.buttons
	local buttonID = #buttons
	local button = buttons[buttonID]

	--print("EquipmentFlyout_CreateButton : "..buttonID)
	
	button.buttonID = buttonID

	self.EquipmentFlyoutUI[buttonID] = self:CreateEquipItemUIMixin(nil, slotID)
	self.EquipmentFlyoutUI[buttonID]:SetUpUI(button)
	self.EquipmentFlyoutUI[buttonID].GetUnit = function(self) return "player" end
	self.EquipmentFlyoutUI[buttonID].lastLocation = LASTLOCATION_NIL
	self.EquipmentFlyoutUI[buttonID].lastDisplayTime = 0

	hooksecurefunc(button, "SetItemLocation", function(self, ...)	
		frame:OnButtonSetItemLocation(self)
	end)
end

function frame:OnEquipmentFlyout_DisplayButton(button, paperDollItemSlot)	
	local equipItem = self.EquipmentFlyoutUI[button.buttonID]
	if equipItem.lastLocation == button.location then return end
	if equipItem.lastDisplayTime + 0.5 > GetTime() then return end

	equipItem.lastLocation = button.location
	equipItem.lastDisplayTime = GetTime()

	if button.location >= EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION then
		equipItem:SetTooltipData()
		equipItem:ShowItemLevelStr(false)
		equipItem:ShowDurabilityStr(false)
		equipItem:ShowDetailIcon(false)
		return
	end

	local player, bank, bags, voidStorage, slot, bag, tab, voidSlot = EquipmentManager_UnpackLocation(button.location);

	equipItem:SetSlot(bag, slot)
	equipItem:SetTooltipData()
	equipItem:ShowItemLevelStr(true)
	equipItem:ShowDurabilityStr(CharInfoEnhancerOption.ShowDurability)

	-- to do : 아이콘 배치를 어떻게 해야 깔끔할까...가 답이 안나와서 일단 적용 보류
--	if CharInfoEnhancerOption.ShowDetailIcon then
--		equipItem:UpdateDetailIcon(true)
--		equipItem:ShowDetailIcon(true)
--	else
--		equipItem:ShowDetailIcon(false)
--	end
end

function frame:OnButtonSetItemLocation(button)
	local itemLocation = button:GetItemLocation();
	local equipItem = self.EquipmentFlyoutUI[button.buttonID]

	if itemLocation:IsBagAndSlot() then
		local bag, slot = itemLocation:GetBagAndSlot();
		equipItem:SetSlot(bag, slot)
	elseif itemLocation:IsEquipmentSlot() then
		local slot = itemLocation:GetEquipmentSlot();
		equipItem:SetSlot(nil, slot)
	end

	equipItem:SetTooltipData()
	equipItem:ShowItemLevelStr(true)
	equipItem:ShowDurabilityStr(CharInfoEnhancerOption.ShowDurability)
end