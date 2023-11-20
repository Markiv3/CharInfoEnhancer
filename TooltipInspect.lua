local addonName, addon = ...
local frame = _G[addonName]
local L = addon.L

local TOOLTIPINSPECT_DELAY = 1.0
local TOOLTIPINSPECT_LASTINSPECT_DELAY = 2.0
--local ITEMLEVEL_PREFIX_STR = "아이템 레벨:|cffffffff"
local ITEMLEVEL_PREFIX_STR = L["itemlevel"] .. ":|cffffffff"

frame.InspectInfo = nil
frame.lastInspectUnitTime = 0

function DebugPrint(...)
	--print(...)
end

function frame:OnInspectUnit(unit)	
	DebugPrint("OnInspectUnit")
	if CanInspect(unit) then
		self.lastInspectUnitTime = GetTime()
	end
end

function frame:OnTooltipSetUnit(tooltip, tooltipData)
	if not CharInfoEnhancerOption.TooltipInspect then 
		return
	end

	if not tooltip then
		return
	end

	-- TipTacTalents 애드온 구조 참고

	-- Get the unit -- Check the UnitFrame unit if this tip is from a concated unit, such as "targettarget".
	local _, unit = tooltip:GetUnit();
	if (not unit) then
		local mFocus = GetMouseFocus();
		if (mFocus) and (mFocus.unit) then
			unit = mFocus.unit;
		end
	end

	-- No Unit or not a Player
	if (not unit) or (not UnitIsPlayer(unit)) then
		return;
	end

	-- No need for inspection on the player
	if (UnitIsUnit(unit, "player")) then
		local _, avgItemLevelEquipped = GetAverageItemLevel()
		local avgItemLevelStr = format("%s %s", L["itemlevel"] .. ":|cffffffff", self:MakeItemLevelStr(avgItemLevelEquipped));
		GameTooltip:AddLine(avgItemLevelStr)
		GameTooltip:Show()
		return;
	end
	if InCombatLockdown() or not CanInspect(unit) or not CheckInteractDistance(unit, 1) or self:IsInspectFrameOpen() then
		return
	end

	-- 같은 guid로 재설정 된 경우
	if self.InspectInfo and self.InspectInfo.guid == UnitGUID(unit) then
		if self.InspectInfo.ready then
			self:UpdateMouseOverEquipItem()
		end
		return
	end

	self.InspectInfo = {}
	self.InspectInfo.unit = unit
	self.InspectInfo.guid = UnitGUID(unit)
	self.InspectInfo.time = math.max(GetTime() + TOOLTIPINSPECT_DELAY, frame.lastInspectUnitTime + TOOLTIPINSPECT_LASTINSPECT_DELAY)
	self.InspectInfo.request = false
	self.InspectInfo.ready = false
	
	DebugPrint(GetTime(), "OnTooltipSetUnit", self.InspectInfo.unit, self.InspectInfo.guid, self.InspectInfo.time)
end

function frame:OnUpdate_TooltipInspect(elapsed)
	if not CharInfoEnhancerOption.TooltipInspect then 
		return
	end

---	if self.bInspectFrame and not self:IsInspectFrameOpen() then
---		self:OnInspectFrame(false)
---	end

	if self.InspectInfo then
		if self.InspectInfo.time < GetTime() and self.InspectInfo.request == false then
			if (UnitGUID("mouseover") == self.InspectInfo.guid) and (not self:IsInspectFrameOpen()) then
				DebugPrint(GetTime(), "NotifyInspect", self.InspectInfo.unit, self.InspectInfo.guid)
				NotifyInspect(self.InspectInfo.unit);
				self.InspectInfo.request = true
			end
		end
	end
end

function frame:OnInspectReady(guid)
	if not CharInfoEnhancerOption.TooltipInspect then 
		return
	end

	if self.InspectInfo then
		if guid == self.InspectInfo.guid then
			DebugPrint("OnInspectReady", self.InspectInfo.unit, self.InspectInfo.guid)
			self.InspectInfo.ready = true
			self:UpdateMouseOverEquipItem()
		end
	end
end

function frame:UpdateMouseOverEquipItem()
	if not CharInfoEnhancerOption.TooltipInspect then 
		return
	end
	
	if (UnitGUID("mouseover") == self.InspectInfo.guid) and (not self:IsInspectFrameOpen()) then
		DebugPrint("UpdateMouseOverEquipItem")

		for _, equipItem in pairs(self.MouseOverEquip) do
			equipItem:SetTooltipData()
			equipItem:UpdateItemLevel()
		end
		
		local calcAvgLevel = frame:GetAvgItemLevel(self.MouseOverEquip)
		local avgItemLevelStr = format("%s %s", L["itemlevel"] .. ":|cffffffff", self:MakeItemLevelStr(calcAvgLevel));
		GameTooltip:AddLine(avgItemLevelStr)
		GameTooltip:Show()
	end
end



