ScriptName DTEC_CommonF hidden

bool Function DisableAndDeleteObjectRef(ObjectReference objRef, bool fadeOut) global
	int cnt  = 3
	while cnt > 0
		if (objRef && objRef.IsEnabled())
			objRef.Disable(fadeOut)
			objRef.Delete()
			Utility.Wait(0.1)
		else
			return true
		endIf
		cnt -= 1
	endWhile
	if (objRef && objRef.IsEnabled())
		return false
	endIf
	return true
EndFunction

Form Function IsPluginActive(int formID, string pluginName) global
	; from CreationKit.com: "Note the top most byte in the given ID is unused so 0000ABCD works as well as 0400ABCD"	
	Form formFound = Game.GetFormFromFile(formID, pluginName)
	if (formFound)
		Debug.Trace("[DTEC_commonF] found plugin: " + pluginName)
		return formFound 
	endIf
	return None
EndFunction

bool Function IsSurvivalModeEnabled() global
	GlobalVariable enabledVar = Game.GetFormFromFile(0x05000826, "ccqdrsse001-survivalmode.esl") as GlobalVariable
	if (enabledVar)
		if (enabledVar.GetValue() > 0.0)
			return true
		endIf
	endIf
	return false
endFunction

float Function GetGameTimeHoursDifference(float time1, float time2) global
	float result = 0.0
	if (time2 == time1)
		return 0.0
	elseIf (time2 > time1)
		result = time2 - time1
	else
		result = time1 - time2
	endIf
	result *= 24.0
	return result
endFunction

float Function GetHourFromGameTime(float gameTime) global
	gameTime -= Math.Floor(gameTime)
	gameTime *= 24.0
	return gameTime 
endFunction

; set to 2 on startup
int Function GetFrostfallRunningValue() global
	GlobalVariable frGV = Game.GetFormFromFile(0x0306DCFB, "Frostfall.esp") as GlobalVariable
	if (frGV)
		return frGV.GetValueInt()
	endIf
	return -1
endFunction

;bool function GetFrostfallPlayerNearFire() global
;    GlobalVariable ffpnfGV = Game.GetFormFromFile(0x03064AFD, "Frostfall.esp") as GlobalVariable
;	if (ffpnfGV)
;		if (ffpnfGV.GetValueInt() == 2)
;			return true
;		endIf
;	endIf
;
;	return false
;endFunction

;bool function GetFrostfallWarmRemoveGear() global
;    GlobalVariable ffpnfGV = Game.GetFormFromFile(0x030665F9, "Frostfall.esp") as GlobalVariable
;	if (ffpnfGV)
;		if (ffpnfGV.GetValue() > 0.0)
;			return true
;		endIf
;	endIf
;	return false
;endFunction

Perk Function GetOrdinatorAltMasteryPerk() global
	return Game.GetFormFromFile(0x030148FF, "Ordinator - Perks of Skyrim.esp") as Perk
endFunction

Perk Function GetOrdinatorVancianPerk() global
	return Game.GetFormFromFile(0x0302CB20, "Ordinator - Perks of Skyrim.esp") as Perk
endFunction

FormList Function GetSurvivalWarmList() global
	return Game.GetFormFromFile(0x050008AA, "ccqdrsse001-survivalmode.esl") as FormList
endFunction

Spell Function GetSurvivalDrainedSpell() global
	return Game.GetFormFromFile(0x05000879, "ccqdrsse001-survivalmode.esl") as Spell
endFunction

Spell Function GetSurvivalTiredSpell() global
	return Game.GetFormFromFile(0x0500087A, "ccqdrsse001-survivalmode.esl") as Spell
endFunction

Spell Function GetSurvivalWearySpell() global
	return Game.GetFormFromFile(0x0500087B, "ccqdrsse001-survivalmode.esl") as Spell
endFunction

Spell Function GetSurvivalRefreshedSpell() global
	return Game.GetFormFromFile(0x05000878, "ccqdrsse001-survivalmode.esl") as Spell
endFunction

; -----
; spawns new object 
; place form at a marker reference; returns last created;
; for spawned item best to remove using DisableAndDeleteObjectRef to prevent bloat
; see https://www.creationkit.com/fallout4/index.php?title=PlaceAtMe_-_ObjectReference
; havok motion type: https://www.creationkit.com/fallout4/index.php?title=SetMotionType_-_ObjectReference
;
; based on Chesko's Campfire object placement
ObjectReference Function PlaceFormAtObjectRef(Form formToPlace, ObjectReference objRef, bool persist = false) global
	
	if (objRef)
		ObjectReference newObj = objRef.PlaceAtMe(formToPlace, 1, persist, false)
		
		; make sure 3D loaded
		int tryCnt = 0
		while tryCnt < 100
			if (newObj.Is3DLoaded())
				;newObj.SetMotionType(4)
				newObj.BlockActivation(true)
				return newObj
			else
				Utility.Wait(0.05)
			endIf
			tryCnt += 1
		endWhile
	endIf
	
	return None
EndFunction

