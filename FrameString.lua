local addonName = ...

_G[addonName .. "_OPTION_TITLE"] = GetAddOnMetadata(addonName, "Title")
_G[addonName .. "_OPTION_SUBTEXT"] = GetAddOnMetadata(addonName, "Notes") .. "\n버전 " .. GetAddOnMetadata(addonName, "Version")

_G[addonName .. "_OPTION_TOOLTIPINSPECT"] = "캐릭터 툴팁에 아이템 평균 레벨 표시"
_G[addonName .. "_OPTION_STATPRECISION"] = "캐릭터 정보창 2차 스탯 소수점 표시"
_G[addonName .. "_OPTION_AVGITEMLEVELPRECISION"] = "평균 아이템 레벨 소수점 표시"
_G[addonName .. "_OPTION_ITEMLEVELQUALITYCOLOR"] = "아이템 아이콘 레벨 표시에 등급별 색상 적용"