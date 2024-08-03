local addonName, addonTable = ...

-- koKR에서 지정된 값을 새 값으로 덮어씌운다.
-- 번역 안된거 있으면 한국어로 나오겠지 그럼

-- override koKR strings
-- when there is not translate, then show korean strings

L = addonTable.Strings
if L and GetLocale() ~= "koKR" then

	L["Version"] = "Version"
    L["TooltipInspect"] = "Show average level of items in character tooltip"
    L["StatPrecision"] = "Display decimal point value in character window"
    L["AvgItemLevelPrecision"] = "Display average item level as decimal"
    L["ItemLevelQualityColor"] = "Apply rank-specific color to item level display"
	L["CanEnchant"] = "Missing Enchant"
	L["CanAddSlot"] = "Missing Slot"
    L["Durability"] = "Durability"
    L["Details"] = "Item Details"
	L["ItemLevel"] = "Item Level"
	L["AvgItemLevel"] = "ILvl"
end