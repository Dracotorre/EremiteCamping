Scriptname DTECP_PlayerAliasScript extends ReferenceAlias

Quest property DTECP_PatchQuestP auto
GlobalVariable property DTECP_CampfireUpdated auto

bool reqOnUpdate = false

Event OnPlayerLoadGame()
	reqOnUpdate = true
	
	RegisterForSingleUpdate(4.0)
	
EndEvent

Event OnUpdate()
	if (reqOnUpdate)
		reqOnUpdate = false
		(DTECP_PatchQuestP as DTECP_PatchQuestScript).CheckEremiteCamping()
	
		if (DTECP_CampfireUpdated.GetValue() <= 0.0)
			;Debug.Trace("[DTECP playerAlias update Campfire")
			(DTECP_PatchQuestP as DTECP_PatchQuestSCript).UpdateCampfireData()
		endIf
		
		(DTECP_PatchQuestP as DTECP_PatchQuestScript).MaintainMod()
	endIf
EndEvent