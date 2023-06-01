local _, addon = ...

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

addon.L = L
local locale = GetLocale()

if locale == "koKR" then
    L["notes"] = "캐릭터창 정보 및 캐릭터 아이템 레벨 관련 기능 강화";
    L["version"] = "버전"
    L["TooltipInspect"] = "캐릭터 툴팁에 아이템 평균 레벨 표시"
    L["StatPrecision"] = "캐릭터 정보창 2차 스탯 소수점 표시"
    L["AvgItemLevelPrecision"] = "평균 아이템 레벨 소수점 표시"
    L["ItemLevelQualityColor"] = "아이템 아이콘 레벨 표시에 등급별 색상 적용"
    L["canenchant"] = "마법부여가 가능한 부위입니다."
    L["cangem"] = "보석홈을 추가 가능한 부위입니다."
    L["itemlevel"] = "아이템 레벨"
    L["avgilvl"] = "평균"
    L["durability"] = "내구도"
    L["details"] = "자세히"
    return
else
    L["notes"] = "Enhanced character window and item level display"
    L["version"] = "Version"
    L["TooltipInspect"] = "Show average level of items in character tooltip"
    L["StatPrecision"] = "Display decimal point value in character window"
    L["AvgItemLevelPrecision"] = "Display average item level as decimal"
    L["ItemLevelQualityColor"] = "Apply rank-specific color to item level display"
    L["canenchant"] = "Missing Enchant"
    L["cangem"] = "Missing Gem"
    L["itemlevel"] = "Item Level"
    L["avgilvl"] = "ILvl"
    L["durability"] = "Durability"
    L["details"] = "Item Details"
    return
end
