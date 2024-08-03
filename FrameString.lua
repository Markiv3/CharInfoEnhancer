local addonName, addonTable = ...

_G[addonName .. "_OPTION_TITLE"] = C_AddOns.GetAddOnMetadata(addonName, "Title")
_G[addonName .. "_OPTION_SUBTEXT"] = C_AddOns.GetAddOnMetadata(addonName, "Notes") .. "\n" .. addonTable.Strings["Version"] .. " " .. C_AddOns.GetAddOnMetadata(addonName, "Version")
_G[addonName .. "_OPTION_TOOLTIPINSPECT"] = addonTable.Strings["TooltipInspect"]
_G[addonName .. "_OPTION_STATPRECISION"] = addonTable.Strings["StatPrecision"]
_G[addonName .. "_OPTION_AVGITEMLEVELPRECISION"] = addonTable.Strings["AvgItemLevelPrecision"]
_G[addonName .. "_OPTION_ITEMLEVELQUALITYCOLOR"] = addonTable.Strings["ItemLevelQualityColor"]