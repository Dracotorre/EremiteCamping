Scriptname DTECP_PatchQuestScript extends Quest

Actor property PlayerRef auto
ReferenceAlias property DTECP_PlayerAliasP auto

GlobalVariable property DTEC_IsSE auto
{ mark zero for 32-bit Skyrim }

GlobalVariable property DTECP_InitCampData auto
GlobalVariable property DTECP_CampfireUpdated auto
GlobalVariable property DTEC_IsFrostfallActive auto
GlobalVariable property DTEC_VendorStockEnabled auto
Message property DTECP_CampfireUpdateSuccessMessage auto
Message property DTECP_UpdateFailMessage auto
Message property DTECP_EremiteFoundMessage auto

Light property Camp_Campfire_Light_3 auto   ; medium fire "Flickering"
Light property Camp_Campfire_Light_4 auto 
Light property Camp_Campfire_Light_5 auto
Activator property Camp_ObjectRubbleFire auto  ; burning tent

bool property CampDataInitialized auto hidden

Event OnLoad()
	self.OnInit()
endEvent

Event OnInit()
	CampDataInitialized = false
	Utility.Wait(1.0)
	if (CheckEremiteCamping())
		return
	endIf
	
	RegisterForSingleUpdate(8.0)
endEvent

Event OnUpdate()
	
	UpdateCampfireData()
	MaintainMod()
endEvent

Form Function IsPluginActive(int formID, string pluginName)
	; from CreationKit.com: "Note the top most byte in the given ID is unused so 0000ABCD works as well as 0400ABCD"
	Form formFound = Game.GetFormFromFile(formID, pluginName)
	if (formFound)
		Debug.Trace("[DTECP] found plugin: " + pluginName)
		return formFound 
	endIf
	return None
EndFunction

Function StopAll()
	DTEC_VendorStockEnabled.SetValueInt(-1)
	self.Stop()
endFunction

Function CheckArmor()
	
	(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCuirass = None
	(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCloak = None
	(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyCloakTentStore = None
	(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedOther = None
	
	if (!CampDataInitialized)
		DTECP_InitCampData.SetValueInt(1)
		Utility.Wait(0.05)
		PlayerRef.UnequipItemSlot(32)
		Utility.Wait(0.5)
		PlayerRef.UnequipItemSlot(46)
		Utility.Wait(1.0)
		Armor bodyArm = (DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCuirass
		if (bodyArm)
			PlayerRef.EquipItem(bodyArm, false, true)
			Utility.Wait(0.5)
		endIf
		Armor cloak = (DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCloak
		if (cloak)
			PlayerRef.EquipItem(cloak, false, true)
		endIf
		Armor other = (DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedOther
		if (other)
			PlayerRef.EquipItem(other, false, true)
		endIf
		CampDataInitialized = true
		
		DTECP_InitCampData.SetValueInt(0)
		
		(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCuirass = None
		(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedCloak = None
		(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyCloakTentStore = None
		(DTECP_PlayerAliasP as DTEC_EquipMonitor).MyRemovedOther = None
	endIf
endFunction

bool Function CheckEremiteCamping()
	GlobalVariable eremiteGV = IsPluginActive(0x09000D64, "EremiteCamping.esp") as GlobalVariable
	if (eremiteGV)
		Debug.Trace("[DTECP] found EremiteCamping, stop patch quest")
		StopAll()
		return true
	endIf
	return false
endFunction

Function MaintainMod()
	if (DTEC_IsFrostfallActive.GetValueInt() < 1)
		if (IsPluginActive(0x03067B8F, "Frostfall.esp"))
			DTEC_IsFrostfallActive.SetValueInt(1)
		endIf
	endIf
endFunction


Function UpdateCampfireData()
	if (DTEC_IsSE.GetValueInt() < 1)
		return
	endIf
	; may need to change this depending on next Campfire update
	;if (Campfire_Version.GetValueInt() > 11100)
	;	DTECP_CampfireUpdated.SetValue(1.0)
	;	return
	;endIf

	bool doUpgrade = true
	
	GlobalVariable eremiteGV = IsPluginActive(0x09000D64, "EremiteCamping.esp") as GlobalVariable
	if (eremiteGV)
		if (eremiteGV.GetValueInt() > 0)
			DTECP_CampfireUpdated.SetValue(1.0)
			doUpgrade = false
		endIf
		DTECP_EremiteFoundMessage.Show()
		StopAll()
	endIf
	if (doUpgrade)
	
		if (Game.IsFightingControlsEnabled())
			CheckArmor()
		endIf
		Debug.Trace("[DTECP] updating Campfire for Survival Mode...")
		
		FormList warmUpFormList = IsPluginActive(0x050008AA, "ccqdrsse001-survivalmode.esl") as FormList
		if (warmUpFormList)
			if (!warmUpFormList.HasForm(Camp_Campfire_Light_3))
				; let's not add the smallest fire - just 3,4,5
				;warmUpFormList.AddForm(Camp_Campfire_Light_2)
				warmUpFormList.AddForm(Camp_Campfire_Light_3)
				warmUpFormList.AddForm(Camp_Campfire_Light_4)
				warmUpFormList.AddForm(Camp_Campfire_Light_5)
				warmUpFormList.AddForm(Camp_ObjectRubbleFire)
			endIf
			
			DTECP_CampfireUpdated.SetValue(1.0)
			DTECP_CampfireUpdateSuccessMessage.Show()
		else
			DTECP_CampfireUpdated.SetValue(-1.0)
			;DTECP_UpdateFailMessage.Show()
		endIf
	endIf
endFunction  