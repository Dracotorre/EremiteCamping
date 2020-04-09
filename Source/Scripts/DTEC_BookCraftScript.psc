Scriptname DTEC_BookCraftScript extends ObjectReference

; ********************************
; book crafting enable toggle for
; Eremite Camping Skyrim mod 
; by DracoTorre
; version 2
; web page: http://www.dracotorre.com/mods/eremitecamping/
; https://github.com/Dracotorre/EremiteCamping
; requires Campfire DevKit CampUtil
;
; player character sits inside tent and reads book to toggle crafting enabled
; ********************************

Actor property PlayerREF auto
GlobalVariable property DTEC_SettingCraftingEnabled auto
Message property DTEC_CraftingDisabledMsg auto
Message property DTEC_CraftingEnabledMsg auto
 
 
 Event OnRead()
	ObjectReference campfireTent = CampUtil.GetCurrentTent()
	
	if (campfireTent != None)
		; inside tent; sitting?
		if (PlayerREF.GetSitState() >= 3)
			Utility.Wait(1.0)
			int craftVar = DTEC_SettingCraftingEnabled.GetValueInt()
			
			if (craftVar > 0)
				DTEC_SettingCraftingEnabled.SetValueInt(0)
				DTEC_CraftingDisabledMsg.Show()
			else
				DTEC_SettingCraftingEnabled.SetValueInt(2)			; 2 for enable all; 1 to display advanced items only
				DTEC_CraftingEnabledMsg.Show()
			endIf
		endIf	
	endIf
 EndEvent
