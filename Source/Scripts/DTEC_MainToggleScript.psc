Scriptname DTEC_MainToggleScript extends ObjectReference 

; by DracoTorre
; toggles main quest

Actor property PlayerREF auto
Quest property DTEC_MainShelterQuestP auto
GlobalVariable property DTEC_SettingEnabled auto

Event OnEquipped(Actor akActor)
   if (akActor == PlayerREF)
		if (DTEC_SettingEnabled.GetValueInt() > 0)
			; disable
			(DTEC_MainShelterQuestP as DTEC_MainShelterQuestScript).StopAll()
		else
			; enable
			(DTEC_MainShelterQuestP as DTEC_MainShelterQuestScript).StartAll()
		endIf
	endIf

EndEvent

;Event OnUnEquipped(Actor akActor)
;EndEvent
