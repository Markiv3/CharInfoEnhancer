local addonName, addon = ...
local L = addon.L

local function checkboxSetChecked(self)
	self:SetChecked(self:GetValue())
end

local function checkboxOnClick(self)
	local checked = self:GetChecked()
	self:SetValue(checked)
end

local function newCheckbox(parent, name, label)

	label = label or L[name]
	
	local check = CreateFrame("CheckButton", "CIECheck_" .. name, parent, "InterfaceOptionsCheckButtonTemplate")

	check:SetScript('OnShow', function(self)
		self:SetChecked(CharInfoEnhancerOption[name])
	end
	)

	check.label = _G[check:GetName() .. "Text"]
	check.label:SetText(label)
	check.tooltipText = label
	check:SetScript('OnClick', function(self)
		CharInfoEnhancerOption[name] = self:GetChecked()
	end
	)

	return check
end

local CIEOptions = CreateFrame('Frame', nil, InterfaceOptionsFramePanelContainer)
CIEOptions:Hide()
CIEOptions:SetAllPoints()
CIEOptions.name = addonName
local title = CIEOptions:CreateFontString(null, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(CIEOptions.name)

local subText = CIEOptions:CreateFontString(null, "ARTWORK", "GameFontHighlightSmall")
subText:SetMaxLines(3)
subText:SetNonSpaceWrap(true)
subText:SetJustifyV('TOP')
subText:SetJustifyH('LEFT')
subText:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
subText:SetPoint('RIGHT', -32, 0)
subText:SetText(L["notes"] .. "\n" .. L["version"] .. " " .. GetAddOnMetadata(addonName, "Version"))

local tooltipInspect = newCheckbox(CIEOptions, "TooltipInspect")
tooltipInspect:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -8)
local statPrecision = newCheckbox(CIEOptions, "StatPrecision")
statPrecision:SetPoint("TOPLEFT", tooltipInspect, "BOTTOMLEFT", 0, -8)
local avgILvlPrecision = newCheckbox(CIEOptions, "AvgItemLevelPrecision")
avgILvlPrecision:SetPoint("TOPLEFT", statPrecision, "BOTTOMLEFT", 0, -8)
local iLvlQualityColor = newCheckbox(CIEOptions, "ItemLevelQualityColor")
iLvlQualityColor:SetPoint("TOPLEFT", avgILvlPrecision, "BOTTOMLEFT", 0, -8)
InterfaceOptions_AddCategory(CIEOptions, addonName)

addon.OptionPanel = CIEOptions