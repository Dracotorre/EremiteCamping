Scriptname DTEC_MagicFocusQuestScript extends Quest  

; ***********************
; MagicFocusQuest - player meditates to learn new spells or abilities
; Eremite Camping Skyrim mod 
; by DracoTorre
; version 2
; https://www.dracotorre.com/mods/eremitecamping/
; https://github.com/Dracotorre/EremiteCamping
;
;  choose a school to meditate on and learn single-use spells or gain limited-time abilities.
;  pick again to learn new spells or relearn lost spells.
;
;  quest always runs
; ***************************

Actor property PlayerRef auto
Message property DTEC_MagicFocusPickMessage auto			; school picker
Message property DTEC_FocusConsumableMissingMsg auto		; reminder missing required consumable
GlobalVariable property DTEC_IsFrostfallActive auto
GlobalVariable property DTEC_CampfireUpdated auto
GlobalVariable property DTEC_MFQNeedAlteration auto
GlobalVariable property DTEC_MFQNeedConjuration auto
GlobalVariable property DTEC_MFQNeedDestruction auto
GlobalVariable property DTEC_MFQNeedIllusion auto
GlobalVariable property DTEC_MFQNeedRestoration auto

Spell property DTEC_AnimalAllyBlessSpell auto 				; illusion ability to cast
MagicEffect property DTEC_AnimalAllyEffect auto
Spell property DTEC_BarkFleshSpell auto						; alteration spell to add
Spell property DTEC_ConjureGFamilar auto					; conjuration
Spell property DTEC_ConjureRFamilar	auto					; conjuration
Spell property DTEC_PoisonCloakSpell auto					; destruction
Spell property DTEC_RestoreHealthSpell auto					; restoration
Spell property DTEC_StoneFleshSpell auto
Spell property DTEC_StormCloakSpell auto					; destruction
Spell property DTEC_WarmthSpell auto						; restoration for Frostfall or Survival
Spell property DTEC_WaterWalkSpell auto						; alteration

Potion property ConsumablePotionCost auto
{ item to be taken at cost for study }

int property MySchoolFocusChoice = 0 auto hidden

;int UpdateType = 0

Event OnInit()
	; nothing to do
endEvent

Event OnUpdate()

EndEvent


; 
; returns 0 for player chose combat study, -2 not started, or else a school:
; 1-alteration, 2-conjuration, 3-destruction, 4-illusion, 5-restoration
; 
; then call PublicAddSpellsToPlayer when ready to distribute spells/abilities
;
int Function PublicStartFocus()

	MySchoolFocusChoice = -2
	int prepMagicStudyVal = 2
	
	if (PlayerRef.GetItemCount(ConsumablePotionCost) == 0)
		; ask if player wishes to cancel (0) or meditate on combat (1)
		prepMagicStudyVal = DTEC_FocusConsumableMissingMsg.Show()
		
		if (prepMagicStudyVal == 1)
			; combat
			MySchoolFocusChoice = 0
		endIf
	endIf
	
	if (prepMagicStudyVal == 2)
		PrepMenu()

		MySchoolFocusChoice = DTEC_MagicFocusPickMessage.Show()
		
		if (MySchoolFocusChoice >= 1)
			PlayerRef.RemoveItem(ConsumablePotionCost)
			Utility.Wait(1.0)
		endIf
	endIf
	
	return MySchoolFocusChoice
endFunction

bool Function PublicStopAll()
	MySchoolFocusChoice = -1
	
	return true
endFunction

int Function PublicAddSpellsToPlayer()

	if (MySchoolFocusChoice > 0 && MySchoolFocusChoice < 7)
		if (MySchoolFocusChoice == 1)
			; alteration
			if (PlayerRef.GetActorValue("Alteration") >= 75.0)
				PlayerRef.AddSpell(DTEC_StoneFleshSpell)
				
				if (!PlayerRef.HasSpell(DTEC_WaterWalkSpell))
					PlayerRef.AddSpell(DTEC_WaterWalkSpell)
				endIf
			endIf
			if (!PlayerRef.HasSpell(DTEC_BarkFleshSpell))
				PlayerRef.AddSpell(DTEC_BarkFleshSpell)
			endIf
			
		elseIf (MySchoolFocusChoice == 2)
			;conjuration - 1 spell or 2 spells over 75
			bool hasGreen = PlayerRef.HasSpell(DTEC_ConjureGFamilar)
			bool hasRed = PlayerRef.HasSpell(DTEC_ConjureRFamilar)
			if (!hasGreen && !hasRed)
				if (Utility.RandomInt(0, 6) > 2)
					hasRed = true
					PlayerRef.AddSpell(DTEC_ConjureRFamilar)
				else
					hasGreen = true
					PlayerRef.AddSpell(DTEC_ConjureGFamilar)
				endIf
			elseIf (!hasGreen)
				PlayerRef.AddSpell(DTEC_ConjureGFamilar)
				hasGreen = true
			else
				PlayerRef.AddSpell(DTEC_ConjureRFamilar)
				hasRed = true
			endIf
			if (!hasGreen || !hasRed)
				if (PlayerRef.GetActorValue("Conjuration") >= 75.0)
					; 2nd spell
					if (!hasGreen)
						PlayerRef.AddSpell(DTEC_ConjureGFamilar)
					endIf
					
					if (!hasRed)
						PlayerRef.AddSpell(DTEC_ConjureRFamilar)
					endIf
				endIf
			endIf
		elseIf (MySchoolFocusChoice == 3)
			; destruction
			if (PlayerRef.GetActorValue("Destruction") >= 75.0)
				if (!PlayerRef.HasSpell(DTEC_PoisonCloakSpell))
					PlayerRef.AddSpell(DTEC_PoisonCloakSpell)
				endIf
			endIf
			if (!PlayerRef.HasSpell(DTEC_StormCloakSpell))
				PlayerRef.AddSpell(DTEC_StormCloakSpell)
			endIf
		elseIf (MySchoolFocusChoice == 4)
			; illusion
			DTEC_AnimalAllyBlessSpell.Cast(PlayerRef, PlayerRef)

		elseIf (MySchoolFocusChoice == 5)
			; restoration
			if (!PlayerRef.HasSpell(DTEC_RestoreHealthSpell))
				PlayerRef.AddSpell(DTEC_RestoreHealthSpell)
			endIf
			if (DTEC_IsFrostfallActive.GetValueInt() >= 1 || DTEC_CampfireUpdated.GetValueInt() >= 1)
				if (!PlayerRef.HasSpell(DTEC_WarmthSpell))
					PlayerRef.AddSpell(DTEC_WarmthSpell)
				endIf
			endIf
		endIf
		
		return 1
	endIf
		
	return 0
endFunction

Function PrepMenu()
	; tricky to do all these conditions in MessageBox, so simplify using these globals
	DTEC_MFQNeedAlteration.SetValueInt(0)
	DTEC_MFQNeedConjuration.SetValueInt(0)
	DTEC_MFQNeedIllusion.SetValueInt(0)
	DTEC_MFQNeedDestruction.SetValueInt(0)
	DTEC_MFQNeedRestoration.SetValueInt(0)
	
	float skillLevel = PlayerRef.GetActorValue("Alteration")
	if (skillLevel >= 50.0)
		if (!PlayerRef.HasSpell(DTEC_BarkFleshSpell))
			DTEC_MFQNeedAlteration.SetValueInt(1)
			
		elseIf (skillLevel >= 75.0)
			if (!PlayerRef.HasSpell(DTEC_StoneFleshSpell))
				DTEC_MFQNeedAlteration.SetValueInt(1)
			elseIf (!PlayerRef.HasSpell(DTEC_WaterWalkSpell))
				DTEC_MFQNeedAlteration.SetValueInt(1)
			endIf
		endIf
	endIf
	
	skillLevel = PlayerRef.GetActorValue("Conjuration")
	if (skillLevel >= 50.0)
		if (!PlayerRef.HasSpell(DTEC_ConjureGFamilar))
			DTEC_MFQNeedConjuration.SetValueInt(1)
		elseIf (!PlayerRef.HasSpell(DTEC_ConjureRFamilar))
			DTEC_MFQNeedConjuration.SetValueInt(1)
		endIf
	endIf
	
	skillLevel = PlayerRef.GetActorValue("Destruction")
	if (skillLevel >= 50.0)
		if (!PlayerRef.HasSpell(DTEC_StormCloakSpell))
			DTEC_MFQNeedDestruction.SetValueInt(1)
		elseIf (skillLevel >= 75)
			if (!PlayerRef.HasSpell(DTEC_PoisonCloakSpell))
				DTEC_MFQNeedDestruction.SetValueInt(1)
			endIf
		endIf
	endIf
	
	skillLevel = PlayerRef.GetActorValue("Illusion")
	if (skillLevel >= 50.0)
		DTEC_MFQNeedIllusion.SetValueInt(1)
	endIf
	
	skillLevel = PlayerRef.GetActorValue("Restoration")
	if (skillLevel >= 50.0)
		if (!PlayerRef.HasSpell(DTEC_RestoreHealthSpell))
			DTEC_MFQNeedRestoration.SetValueInt(1)
			
		elseIf (DTEC_IsFrostfallActive.GetValueInt() >= 1 || DTEC_CampfireUpdated.GetValueInt() >= 1)
			if (!PlayerRef.HasSpell(DTEC_WarmthSpell))
				DTEC_MFQNeedRestoration.SetValueInt(1)
			endIf
		endIf
	endIf
	
endFunction

; -------------------------------------------------- deprecated
MiscObject property ItemToRefund auto						
{ no longer used}
Ingredient property Taproot auto							
{ no longer used }
