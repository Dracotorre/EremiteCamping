Scriptname DTEC_PlayerAliasScript extends ReferenceAlias

; by DracoTorre
; Eremite Camping player alias
; handles mod compatibility, upgrades, and player events
; web page: http://www.dracotorre.com/mods/eremitecamping/
;
; EremiteCamping.esp
; Requires Campfire Dev Kit 1.7.1 to compile. Remember to remove Dev Kit for play-testing.

Actor property PlayerRef auto

FormList property woodChoppingAxesFL auto

Quest property DTEC_MainShelterQuestP auto
GlobalVariable property DTEC_IsSE auto
{ mark zero for 32-bit Skyrim }
GlobalVariable property DTEC_CampfireUpdated auto
GlobalVariable property DTEC_PrevVersion auto
GlobalVariable property DTEC_Version auto
GlobalVariable property DTEC_MonitorTentsEnable auto
GlobalVariable property DTEC_IsOrdinatorActive auto
GlobalVariable property DTEC_IsFrostfallActive auto
GlobalVariable property DTEC_IsTentapaloozaActive auto
Message property DTEC_CampfireUpdateSuccessMessage auto
Weapon property DTEC_Axe auto
;Light property Camp_Campfire_Light_2 auto   ; the tiny starter fire
Light property Camp_Campfire_Light_3 auto   ; medium fire "Flickering"
Light property Camp_Campfire_Light_4 auto 
Light property Camp_Campfire_Light_5 auto
Activator property Camp_ObjectRubbleFire auto  ; burning tent
GlobalVariable property Campfire_Version auto
FormList property DTEC_ModTentShelterList auto


bool reqOnUpdate = false   ; flag to process OnUpdate event

Event OnPlayerLoadGame()
	
	;Debug.Trace("[DTEC_PlayerAliasScript] OnLoad")
	reqOnUpdate = true
	RegisterForSingleUpdate(3.2)

EndEvent

; another script, EquipMonitor also catching OnUpdate - use flag
Event OnUpdate()
	if (reqOnUpdate)
		reqOnUpdate = false
		
		if (DTEC_IsSE.GetValueInt() > 0 && DTEC_CampfireUpdated.GetValue() <= 0.0)
			UpdateCampfireData()
		endIf
		
		MaintainMod()
	endIf
EndEvent


; multiple hits will register if weapon enchanted or spell has multiple effects
; https://www.creationkit.com/index.php?title=OnHit_-_ObjectReference
;
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
  bool abBashAttack, bool abHitBlocked)
  
  (DTEC_MainShelterQuestP as DTEC_MainShelterQuestScript).PlayerHitBy(akAggressor, akSource, akProjectile)
EndEvent


Function MaintainMod()
	float currentV = DTEC_Version.GetValue()
	float oldV = DTEC_PrevVersion.GetValue()
	
	if (oldV < currentV)
		Debug.Trace(self + " update to version " + currentV)
		
		if (oldV < 1.0)
			if (!woodChoppingAxesFL.HasForm(DTEC_Axe))
				woodChoppingAxesFL.AddForm(DTEC_Axe)
			endIf
		elseIf (oldV == 1.0 && (DTEC_MainShelterQuestP as DTEC_MainShelterQuestScript).CampDataInitialized == false)
			(DTEC_MainShelterQuestP as DTEC_MainShelterQuestScript).CheckArmor()
		endIf
		
		DTEC_PrevVersion.SetValue(currentV)
	endIf
	
	Debug.Trace("[DTEC] ============================================================")
	Debug.Trace("[DTEC]                  Eremite Camping")
	Debug.Trace("[DTEC]  compatibility check - expect error reports here as normal ")
	Debug.Trace("[DTEC] ============================================================")
	
	if (DTEC_IsFrostfallActive.GetValueInt() < 1)
		if (DTEC_CommonF.IsPluginActive(0x03067B8F, "Frostfall.esp"))
			DTEC_IsFrostfallActive.SetValueInt(1)
		endIf
	endIf
	
	if (DTEC_IsOrdinatorActive.GetValueInt() < 1)
		if (DTEC_CommonF.IsPluginActive(0x0302CB20, "Ordinator - Perks of Skyrim.esp"))
			DTEC_IsOrdinatorActive.SetValueInt(1)
		endIf
	endIf
	
	if (DTEC_IsTentapaloozaActive.GetValueInt() < 1)
		Form tentForm = DTEC_CommonF.IsPluginActive(0x09450149, "Tentapalooza.esp")
		if (tentForm)
			DTEC_IsTentapaloozaActive.SetValueInt(1)
			if (!DTEC_ModTentShelterList.HasForm(tentForm))
				DTEC_ModTentShelterList.AddForm(tentForm)
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x0946965C, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x416038F6, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x41469666, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x4146966D, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x41469672, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x41469687, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x4155C7D2, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x41594285, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x415BCA99, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x415D0EA6, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x415D0EAF, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x415DB0BA, "Tentapalooza.esp"))
				DTEC_ModTentShelterList.AddForm(Game.GetFormFromFile(0x415D0EAF, "Tentapalooza.esp"))
			endIf
		endIf
	endIf
	
	
	Debug.Trace("[DTEC] ============================================================")
	Debug.Trace("[DTEC]   Eremite Camping check done")
	Debug.Trace("[DTEC] ============================================================")
endFunction

Function UpdateCampfireData()
	if (DTEC_CampfireUpdated.GetValueInt() >= 1)
		return
	endIf
	; may need to change this
	;if (Campfire_Version.GetValueInt() > 11100)
	;	DTEC_CampfireUpdated.SetValue(1.0)
	;	return
	;endIf
	GlobalVariable dtCampPatchGV = DTEC_CommonF.IsPluginActive(0x09000D62, "EremiteCampfireLite.esp") as GlobalVariable
	if (dtCampPatchGV)
		if (dtCampPatchGV.GetValueInt() > 0)
			DTEC_CampfireUpdated.SetValue(1.0)
			return
		endIf
	endIf
	Debug.Trace("[DTEC] updating Campfire for Survival...")
	
	FormList warmUpFormList = DTEC_CommonF.IsPluginActive(0x050008AA, "ccqdrsse001-survivalmode.esl") as FormList
	if (warmUpFormList)
		if (!warmUpFormList.HasForm(Camp_Campfire_Light_3))
			; let's not add the smallest fire - just 3,4,5
			;warmUpFormList.AddForm(Camp_Campfire_Light_2)
			warmUpFormList.AddForm(Camp_Campfire_Light_3)
			warmUpFormList.AddForm(Camp_Campfire_Light_4)
			warmUpFormList.AddForm(Camp_Campfire_Light_5)
			warmUpFormList.AddForm(Camp_ObjectRubbleFire)
		endIf
		
		DTEC_CampfireUpdated.SetValue(1.0)
		if (Game.IsFightingControlsEnabled())
			; only display if player ready
			DTEC_CampfireUpdateSuccessMessage.Show()
		endIf
	else
		DTEC_CampfireUpdated.SetValue(-1.0)
		;DTEC_UpdateFailMessage.Show()
	endIf
endFunction  
