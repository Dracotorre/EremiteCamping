Scriptname DTEC_EquipMonitor extends ReferenceAlias  

; Eremite Camping
; DracoTorre
;
; Since cloaks given ArmorCuirass keyword for warmth in "Survival Mode" then
; need to shadow CampfireData to ensure correct plus keep track of auto-dress cloak
;
; Note: if not wearing body armor then let Campfire treat cloak as cuirass
;
Actor property PlayerRef auto
CampfireData property CampData auto
GlobalVariable property DTEC_IsSE auto
{ mark zero for 32-bit Skyrim }
GlobalVariable property DTEC_InitCampData auto
FormList property Camp_BackpacksList auto
Keyword property ArmorCuirass auto
Keyword property ClothingBody auto
Keyword property WAF_ClothingCloak auto
Keyword property FrostfallIsCloakCloth auto
Keyword property FrostfallIsCloakLeather auto
Keyword property FrostfallIsCloakFur auto 
Spell property DTEC_EncBonusSpell auto

Armor property MyCloak auto hidden
Armor property MyCloakTentStore auto hidden
Armor property MyCuirass auto hidden

Armor property MyRemovedCloak auto hidden
{ only use on init DTEC_InitCampData }
Armor property MyRemovedCuirass auto hidden
{ only use on init DTEC_InitCampData }
Armor property MyRemovedOther auto hidden
{ use on init to catch unknown item }

bool processingUnequip = false       ; lock out equip to give unequip priority
bool reqUpdateEquipCloak = false     ; update flag - only when controls disabled and inside tent   
bool reqUpdateUnequipCloak = false	 ; update flag - only when controls disabled and inside tent  
bool reqUpdateVerifyData = false	 ; update flag - such to delay until exit menus

; remember all scripts attached to this alias will receive OnUpdate event
Event OnUpdate()
	
	if (reqUpdateUnequipCloak)
		; might result in a verify
		UnequipCloak()
	endIf
	if (reqUpdateEquipCloak)
		; will result in a verify
		EquipCloakStore()
	elseIf (reqUpdateVerifyData)
		VerifyCampData()
	endIf
EndEvent

; remember: order of events unknown here and between scripts receiving this
;
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	; give un-equip priority
	int i = 0
	while (processingUnequip && i < 50)
		Utility.WaitMenuMode(0.1)
		i += 1
	endWhile
	
	Utility.WaitMenuMode(0.1)   ; same delay period Campfire uses to avoid race
	
	if (akBaseObject as Armor)
		if (Camp_BackpacksList.HasForm(akBaseObject))
			if (DTEC_EncBonusSpell && PlayerRef.HasSpell(DTEC_EncBonusSpell))
				;Debug.Trace("DTEC removing enc bonus")
				PlayerRef.RemoveSpell(DTEC_EncBonusSpell)
			endIf
	; order matters - check cloaks before body armor
		elseIf (ArmorFormIsCloak(akBaseObject))
			; cloak!
			MyCloak = akBaseObject as Armor
			MyCloakTentStore = None
			
			if (Utility.IsInMenuMode())
				reqUpdateVerifyData = true
				RegisterForSingleUpdate(0.9)   ; time after menu exit to verify
			else
				Utility.WaitMenuMode(0.33)  ; give CampData time
				VerifyCampData()
			endIf
		
		elseIf (akBaseObject.HasKeyword(ArmorCuirass) || akBaseObject.HasKeyword(ClothingBody))
			; body armor!
			MyCuirass = akBaseObject as Armor
			
			if (MyCloakTentStore)
				if (!Game.IsFightingControlsEnabled())
					; likely done using a tent since had a stored cloak - redress cloak
					
					; delay putting on cloak to let character exit tent (assuming)
					; this will force a data verify after equip
					reqUpdateEquipCloak = true
					RegisterForSingleUpdate(1.25)
				else
					; if player puts on armor then cancel auto-redress
					MyCloakTentStore = None
				endIf
			endIf
		endIf
	endIf
endEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	; this has priority
	
	processingUnequip = true  ; mark to delay equip event and verify
	
	Utility.WaitMenuMode(0.06)  ; short delay
	
	if (akBaseObject as Armor)
		; check backpack for encumbrance auto-undress in tent
		if (Camp_BackpacksList.HasForm(akBaseObject))
			if (DTEC_IsSE.GetValueInt() > 0 && DTEC_EncBonusSpell)
				if (PlayerRef.IsOverEncumbered())
					if (!Game.IsFightingControlsEnabled())
						; no fight controls check for tent
						
						ObjectReference aTent = CampUtil.GetCurrentTent()
						if (aTent && !PlayerRef.HasSpell(DTEC_EncBonusSpell))
						
							;Debug.Trace("DTEC adding enc bonus")
			
							PlayerRef.AddSpell(DTEC_EncBonusSpell, false)
						endIf
					endIf
				endIf
			endIf
			
	; order matters - check cloaks before body armor
		elseIf (ArmorFormIsCloak(akBaseObject))
			
			if (DTEC_InitCampData.GetValue() > 0.0)
				MyRemovedCloak = akBaseObject as Armor
			endIf
			MyCloak = None
			
		elseIf (akBaseObject.HasKeyword(ArmorCuirass) || akBaseObject.HasKeyword(ClothingBody))
			if (DTEC_InitCampData.GetValue() > 0.0)
				MyRemovedCuirass = akBaseObject as Armor
			endIf
			
			if (!Game.IsFightingControlsEnabled())
				; no fight controls check for tent
				
				ObjectReference aTent = CampUtil.GetCurrentTent()
				if (aTent)
					if (MyCloak)
						MyCloakTentStore = MyCloak
						
						; Campfire CampData should be (or soon) Body = None so removing again does nothing
						reqUpdateUnequipCloak = true
						RegisterForSingleUpdate(0.7)
					endIf
				endIf
			elseIf (MyCloak )
				; need to let Campfire know has cloak for body
				
				if (Utility.IsInMenuMode())
					reqUpdateVerifyData = true
					RegisterForSingleUpdate(1.0)   ; time after menu exit to verify
				else
					Utility.WaitMenuMode(0.33)  ; give CampData time
					VerifyCampData()
				endIf
			endIf
			
			MyCuirass = None
		elseIf (DTEC_InitCampData.GetValue() > 0.0)
			; init removed something not a known cloak or cuirass
			MyRemovedOther = akBaseObject as Armor
		endIf
	endIf
	processingUnequip = false
endEvent

bool function ArmorFormIsCloak(Form akBaseObject)
	if (akBaseObject.HasKeyword(WAF_ClothingCloak)) 
		return true
	elseIf (akBaseObject.HasKeyword(FrostfallIsCloakCloth) || akBaseObject.HasKeyword(FrostfallIsCloakLeather))
		return true
	elseIf (akBaseObject.HasKeyword(FrostfallIsCloakFur))
		return true
	endIf
	return false
endFunction

Function EquipCloakStore()

	if (MyCloakTentStore)

		if (MyCloakTentStore != MyCloak)
			PlayerRef.EquipItem(MyCloakTentStore, false, true)  ; cleared by monitor
		else
			MyCloakTentStore = None
		endIf
	endIf
	
	reqUpdateEquipCloak = false
endFunction

Function UnequipCloak()
	if (MyCloak)
	
		PlayerRef.UnEquipItem(MyCloak, false, true)
	endIf
	
	reqUpdateUnequipCloak = false
endFunction

function VerifyCampData()
	int i = 0

	if (CampData.CurrentBody)
		if (MyCloak && MyCuirass && CampData.CurrentBody == MyCloak)
			;Debug.Trace("[DTEC em] update CampData Body (cloak) to MyCuirass: " + MyCuirass)
			;Debug.Notification("DTEC update CampData body to cloak ")
			CampData.CurrentBody = MyCuirass
		elseIf (MyCuirass && MyCuirass != CampData.CurrentBody)
			Debug.Trace("[DTEC em] CampData Body mismatch (my/cd) (" + MyCuirass + "/" + CampData.CurrentBody + ")")
		; else if not wearing cuirass then let Campfire believe cloak is body
		endIf
	elseIf (MyCloak && MyCuirass == None)
		; need to drop level to let Campfire assume cloak is body armor
		;Debug.Trace("[DTEC em] update CampData body to MyCloak (naked)")
		CampData.CurrentBody = MyCloak
	endIf
	reqUpdateVerifyData = false
endFunction
