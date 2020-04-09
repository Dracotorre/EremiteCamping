Scriptname DTEC_RugScript extends ObjectReference  

; ***********************
; Meditation Rug furniture
; Eremite Camping Skyrim mod 
; by DracoTorre
; version 2
; https://www.dracotorre.com/mods/eremitecamping/
; https://github.com/Dracotorre/EremiteCamping
;
; player on use removes boots and main weapon to display as decoration
; after enough time, if character warm it bestows blessing spell
;    and calls DTEC_MainShelterQuestScript to apply bonuses and progress Eremite perk points
; on exit, decorations removed
;
; ----------
; rug is a CampfirePlaceableObjectEx so OnActivate event also being recieved by Campfire to display menu or activate this furniture
; set to align with terrain on Campfire placement
; Campfire handles basic decorations like candle, but we need to handle placement of player's gear since only Campfire tents support that
;   -- CampfirePlaceableObjectEx properties are not accessible, so we cannot cheat by letting it place marker for us without overriding Campfire
;   -- no worry, math is easy - keep in mind rug may be at crazy angle with terrain
; decorations placed with help of DTEC_CommonF functions
; ******************************************

Quest property DTECMainQuest auto
Spell property DTEC_PrayBlessSpell auto
Static property DTEC_Marker auto
int property MyRugType = 0 auto									; may be none for regular rug
{ 0 for regular, 1 for magic }

; ------------- hidden -----------------------
Weapon property MainWeapon auto hidden						; to un-equip, re-equip
ObjectReference property MainWeaponPlacedRef auto hidden	; placed main weapon to remove
ObjectReference property MainWeaponMarkerRef auto hidden	; marker to help orient weapon
Armor property MBoots auto hidden
ObjectReference property MBootsPlacedRef auto hidden
ObjectReference property MBootsMarkerRef auto hidden



int RugUseState = 0
int WasFirstPersonState = 0
int MyWeaponType = 0


Event OnUpdate()
	if (RugUseState >= 1)
		if (self.IsFurnitureInUse())
			CheckMedidation()
		endIf
	elseIf (RugUseState == -5)
		GoEndView()
	endIf
EndEvent

; this _camp_placeableObject activation blocked until player toggles for use (menu)
; - Campfire also catches this event then presents menu (Use, Pick-Up) or toggles for use
; - multiple activations may happen if player exits by activating directly - check RugUseState
;
Event OnActivate(ObjectReference akActionRef)
	
	
	if (self.IsActivationBlocked())
		
		if (RugUseState > 0 || MainWeapon != None)
			; something went wrong?
			DoneFurniture()
		else
			Actor playerRef = Game.GetPlayer()
			
			if (akActionRef == playerRef)
				RugUseState = 0						; init

				; likely viewing menu - check first-person view now
				if (playerRef.GetAnimationVariableBool("IsFirstPerson"))		; may not report correct state
					WasFirstPersonState = 2
				else
					WasFirstPersonState = -1
				endIf
			endIf
		endIf
	elseIf (RugUseState <= 0 && RugUseState >= -2)
		; activated for use
		Actor playerRef = Game.GetPlayer()

		if (akActionRef == playerRef)
			RugUseState = 1
			RegisterForSingleUpdate(6.7)
			GoStartView(playerRef)			; may change RugUseState
		endif
	elseIf (RugUseState >= -2)
		; activated for exit furniture
		UnregisterForUpdate()		; in case before timer expires
		DoneFurniture()					; reset view if needed
	endIf
EndEvent

; this never happens
;Event OnExitFurniture(ObjectReference akActionRef)

;EndEvent


Function CheckMedidation()

	if (DTECMainQuest != None)
		if ((DTECMainQuest as DTEC_MainShelterQuestScript).IsPlayerWarm(true, true) == false)
			; too cold!
			return
		endIf
	endIf
	
	RugUseState = 3						; flag meditation
	
	Actor playerRef = Game.GetPlayer()
	
	if (DTEC_PrayBlessSpell != None)

		DTEC_PrayBlessSpell.Cast(playerRef, playerRef)
	endIf
	if (DTECMainQuest != None)
		
		(DTECMainQuest as DTEC_MainShelterQuestScript).ApplyPlayerPerkPointsMeditateAddSpell(MyWeaponType, MyRugType)
	endIf
endFunction

Function DoneFurniture()
	if (RugUseState != -5)
		if (RugUseState != 3)
			; report exited early
			(DTECMainQuest as DTEC_MainShelterQuestScript).PlayerCanceledMeditation(MyRugType)
		endIf
		RugUseState = -5				; temp finishing view to block another activaton
		RegisterForSingleUpdate(1.4)
		PlacedItemsCleanUp()
	endIf
endFunction

; best to call after end of standing animation
Function GoEndView()
	Actor playerRef = Game.GetPlayer()
	if (MainWeapon != None)
		playerRef.EquipItem(MainWeapon, abSilent = true)
		MainWeapon = None
	endIf
	if (MBoots != None)
		playerRef.EquipItem(MBoots, abSilent = true)
		MBoots = None
	endIf
	
	if (WasFirstPersonState >= 2)
		Utility.Wait(0.42)					; must wait long enough for animation to finish
		Game.ForceFirstPerson()
	endIf
	WasFirstPersonState = 0
	RugUseState = -1
endFunction

; weapon type numbers
; https://www.creationkit.com/index.php?title=GetEquippedItemType_-_Actor
;
Function GoStartView(Actor playerRef)
	bool remArmorSetting = CampUtil.GetCampfireSettingBool("TentRemovePlayerEquipment")
	bool remArmorBoots = CampUtil.GetCampfireSettingBool("TentRemovePlayerBoots")
	int weaponType = playerRef.GetEquippedItemType(1)				; does player have main weapon in right hand?
	
	MyWeaponType = 0				; reset to update on placed
	
	; place footwear
	if (remArmorSetting && remArmorBoots)
		MBoots = CampUtil.GetPlayerEquippedFeet()
		if (MBoots != None)
			playerRef.UnequipItem(MBoots, abSilent = true)
			PlaceBoots()
		endIf
	else
		MBoots = None
	endIf
	
	; remove and place weapons
	if ((weaponType > 0 && weaponType <= 8) || weaponType == 12)
		MainWeapon = playerRef.GetEquippedWeapon()
		playerRef.UnequipItem(MainWeapon, abSilent = true)
		
		; may switch to last one-handed weapon!
		Utility.Wait(0.2)
		int altType = playerRef.GetEquippedItemType(1)
		if (altType > 0 && altType <= 8)
			Weapon altWeapon = playerRef.GetEquippedWeapon()
			if (altWeapon != None)
				playerRef.UnequipItem(altWeapon, abSilent = true)
			endIf
		endIf
		
		if (remArmorSetting)

			PlaceMainWeapon(weaponType)
		endIf
	else
		MainWeapon = None
	endIf
	
	Utility.Wait(0.2)
	Game.ForceThirdPerson()		; always
endFunction

Function PlacedItemsCleanUp()
	if (MainWeaponPlacedRef != None)
		DTEC_CommonF.DisableAndDeleteObjectRef(MainWeaponPlacedRef, true)
	endIf
	if (MBootsPlacedRef != None)
		DTEC_CommonF.DisableAndDeleteObjectRef(MBootsPlacedRef, true)
	endIf
	if (MainWeaponMarkerRef != None)
		DTEC_CommonF.DisableAndDeleteObjectRef(MainWeaponMarkerRef, false)
	endIf
	if (MBootsMarkerRef != None)
		DTEC_CommonF.DisableAndDeleteObjectRef(MBootsMarkerRef, false)
	endIf
	MainWeaponPlacedRef = None
	MBootsPlacedRef = None
	MainWeaponMarkerRef = None
endFunction

Function PlaceBoots()
	if (MBoots != None)
		
		; prefer place marker first then place boots directly at marker to avoid movement of objects in scene
		if (DTEC_Marker != None)
			MBootsMarkerRef = DTEC_CommonF.PlaceFormAtObjectRef(DTEC_Marker, self)
		else
			MBootsPlacedRef = DTEC_CommonF.PlaceFormAtObjectRef(MBoots, self)
		endIf
		
		float distance = 43.0
		float htAdj = 2.00					; rug at 4, so sink down since placing just beyond edge of rug
		float heading = self.GetAngleZ()
		float headingOffset = 150.0
		float xAngle = self.GetAngleX()
		float yAngle = self.GetAngleY()

		float[] offsetArray = DTEC_CommonF.RotateObjectByDistanceAngles(distance, xAngle, yAngle, heading + headingOffset)
		
		if (MBootsMarkerRef != None)
			; position marker
			MBootsMarkerRef.SetAngle(xAngle, yAngle, heading + 5.0)
			MBootsMarkerRef.SetPosition(self.GetPositionX() + offsetArray[0], self.GetPositionY() + offsetArray[1], self.GetPositionZ() + offsetArray[2] + htAdj)
			; place boots at marker
			if (MBootsPlacedRef == None)
				MBootsPlacedRef = DTEC_CommonF.PlaceFormAtObjectRef(MBoots, MBootsMarkerRef)
			else
				; unexpected
				MBootsPlacedRef.MoveTo(MBootsMarkerRef, 0.0, 0.0, 0.0, true)
			endIf
			
		elseIf (MBootsPlacedRef != None)
			MBootsPlacedRef.SetAngle(xAngle, yAngle, heading + 5.0)
			MBootsPlacedRef.SetPosition(self.GetPositionX() + offsetArray[0], self.GetPositionY() + offsetArray[1], self.GetPositionZ() + offsetArray[2] + htAdj)
		endIf
	endIf
endFunction

Function PlaceMainWeapon(int weaponType)
	if (MainWeapon != None)
	
		MyWeaponType = weaponType
		
		float yAngle = self.GetAngleY()			; roll/tilt
		float xAngle = self.GetAngleX()			; pitch
		
		; prefer place marker first then place weapon directly to avoid movement of objects in scene
		if (DTEC_Marker != None)
			MainWeaponMarkerRef = DTEC_CommonF.PlaceFormAtObjectRef(DTEC_Marker, self)
		else
			MainWeaponPlacedRef = DTEC_CommonF.PlaceFormAtObjectRef(MainWeapon, self)
		endIf
		
		float zAngle = self.GetAngleZ()		; yaw
		float distance = 46.6
		float zRot = 89.8
		float htAdj = 6.0								; rug floats 4 and weapons centered
		float wTilt = 0.0								; be nice to tilt swords and crossbows to lean on end
		
		float yaw = self.GetAngleZ()
		float headingOffset = -34.0						; sword
		
		if (weaponType == 5 || weaponType == 1)
			wTilt = 2.2
		endIf
		
		if (weaponType == 7)							; bow
			distance = 42.0
			headingOffset = 0.0
			htAdj = 6.4
		elseIf (weaponType == 3)						; axe
			zRot = -89.0
			distance = 42.5
			headingOffset = -6.0
		elseIf (weaponType >= 5 && weaponType <= 6)		; 2-hand
			htAdj = 6.2
		elseIf (weaponType == 8)						; staff
			distance = 44.5
			headingOffset = 30.0
		elseIf (weaponType == 12)						; crossbow
			zRot = -89.7
			htAdj = 7.5
			distance = 46.5
			wTilt = -2.5
		endIf
		
		; tilting weapon would require matrix math to find combined angles
		
		float[] offsetArray = DTEC_CommonF.RotateObjectByDistanceAngles(distance, xAngle, yAngle, zAngle + headingOffset)

		;Debug.Notification("weapon zOff:" + offsetArray[2])
		
		; rotate and position
		if (MainWeaponMarkerRef != None)
			; position marker
			MainWeaponMarkerRef.SetAngle(xAngle, yAngle, yaw + zRot)
			MainWeaponMarkerRef.SetPosition(self.GetPositionX() + offsetArray[0], self.GetPositionY() + offsetArray[1], self.GetPositionZ() + htAdj + offsetArray[2])
			; move weapon to marker
			if (MainWeaponPlacedRef == None)
				MainWeaponPlacedRef = DTEC_CommonF.PlaceFormAtObjectRef(MainWeapon, MainWeaponMarkerRef)
			elseIf (MainWeaponPlacedRef != None)
				; unexpected
				MainWeaponPlacedRef.MoveTo(MainWeaponMarkerRef, 0.0, 0.0, 0.0, true)
			endIf
		elseIf (MainWeaponPlacedRef != None)
			
			MainWeaponPlacedRef.SetAngle(xAngle, yAngle, yaw + zRot)
			MainWeaponPlacedRef.SetPosition(self.GetPositionX() + offsetArray[0], self.GetPositionY() + offsetArray[1], self.GetPositionZ() + htAdj + offsetArray[2])
		endIf
	endIf
endFunction
