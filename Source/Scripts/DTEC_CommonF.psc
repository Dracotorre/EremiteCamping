ScriptName DTEC_CommonF hidden
 
; helper functions for Eremite Camping for Skryim by DracoTorre
; https://www.dracotorre.com/mods/eremitecamping/
; https://github.com/Dracotorre/EremiteCamping
;
; may copy-paste these functions or entire file to use in your Skyrim mod

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
	if (enabledVar != None)
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

;
; no need to call directly form your script -- call PlaceFormAtObjectRef instead 
; -- waits to ensure 3D loaded --
; normally for decorations we want to block activation and disable Havok to prevent bouncing around which means
;   objects will clip like other Campfire tent decorations
;   if prefer to have object settle 
; havok motionType:
; https://www.creationkit.com/index.php?title=SetMotionType_-_ObjectReference
;
ObjectReference Function Ensure3DIsLoadedForNewObjRef(ObjectReference newObj, bool blockActivate = true, bool disableHavok = true) global
	if (newObj != None)
		; make sure 3D loaded
		int tryCnt = 0
		while (tryCnt < 50)
			if (newObj.Is3DLoaded())
				if (disableHavok)
					newObj.SetMotionType(4)
				endIf
				if (blockActivate)
					newObj.BlockActivation(true)
				endIf
				tryCnt = 100
				return newObj
			else
				Utility.Wait(0.03)
			endIf
			tryCnt += 1
		endWhile
	endIf
	return None
EndFunction

; -----
; spawns new object usually used as decoration
; place form at a marker reference; returns last created -- please use DisableAndDeleteObjectRef to remove this created object
;   activation and Havok disabled by default to be like other Campfire decorations 
;   if instead want object to settle on ground (allow Havok), objRef should be destination marker -- avoid moving or using SetPosition again
; 
; for spawned item best to remove using DisableAndDeleteObjectRef to prevent bloat
; see https://www.creationkit.com/index.php?title=PlaceAtMe_-_ObjectReference
;
; based on Chesko's Campfire object placement shared on GitHub under license
;
ObjectReference Function PlaceFormAtObjectRef(Form formToPlace, ObjectReference objRef, bool persist = false, bool disableHavok = true) global
	
	if (objRef != None && formToPlace != None)
		ObjectReference newObj = objRef.PlaceAtMe(formToPlace, 1, persist)
		
		newObj = Ensure3DIsLoadedForNewObjRef(newObj, true, disableHavok)
		
		newObj.SetPosition(objRef.GetPositionX(), objRef.GetPositionY(), objRef.GetPositionZ() + 0.1)

		return newObj
	endIf
	
	return None
EndFunction

; ---------------------
; rotations
;
; order of operations: Z-Yaw, Y-Tilt, Z-Pitch
;
float[] Function RotateObjectByAngles(ObjectReference objectRef, float angleXPitch, float angleYTilt, float angleZYaw) global
	float ptX = objectRef.GetPositionX()
	float ptY = objectRef.GetPositionY()
	float ptZ = objectRef.GetPositionZ()
	; rotate yaw first
	float resultX = ptX * Math.Cos(angleZYaw) + ptY * Math.Sin(angleZYaw)
	float resultY = ptY * Math.Cos(angleZYaw) - ptX * Math.Sin(angleZYaw)
	
	return RotateObjectByTiltPitch(ptX, ptY, ptZ, angleXPitch, angleYTilt, angleZYaw)
EndFunction

;
; use this to find offset at distance from center/origin
; for level object placement leave angleXPitch and angleYTilt zero
; order of operations: Z-Yaw, Y-Tilt, Z-Pitch
;
float[] Function RotateObjectByDistanceAngles(float distance, float angleXPitch, float angleYTilt, float angleZYaw) global
	; rotate yaw first
	; notice same as function above with ptY = distance and ptX = 0
	float ptX = distance * Math.Sin(angleZYaw)
	float ptY = distance * Math.Cos(angleZYaw)
	
	return RotateObjectByTiltPitch(ptX, ptY, 0.0, angleXPitch, angleYTilt, angleZYaw)
EndFunction

;
; called by other Rotate* functions - call this if already found yaw/heading result
; assumed rotated by Z-angle / yaw first
; order of operations: Y-Tilt, Z-Pitch
;
float[] Function RotateObjectByTiltPitch(float ptX, float ptY, float ptZ, float angleXPitch, float angleYTilt, float angleZYaw) global

	float[] result = new float[3]
	result[0] = ptX
	result[1] = ptY
	result[2] = ptZ
	
	if (angleXPitch == 0.0 && angleYTilt == 0.0)
		; nothing to do - return now
		
		return result
	endIf
	
	; rotate tilt
	float rTiltZ = ptZ * Math.Cos(angleYTilt) + ptX * Math.Sin(angleYTilt)	
	
	; rotate pitch
	result[2] = rTiltZ * Math.Cos(angleXPitch) - ptY * Math.Sin(angleXPitch)


	return result
endFunction
