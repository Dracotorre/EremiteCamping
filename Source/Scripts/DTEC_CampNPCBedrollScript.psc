Scriptname DTEC_CampNPCBedrollScript extends ObjectReference  

; Eremite Camping
; DracoTorre
;
; overrides Campfire forms that use _Camp_CampTentNPCBedrollScript which uses RegisterForSingleUpdate
; no need to register for updates, only catch event 

Actor property PlayerRef auto
Keyword property ActorTypeCreature auto
; these Campfire settings are available in CampUtil.GetCampfireSettingBool
; using directly since Campfire is a master
GlobalVariable property Camp_Setting_FollowersRemoveGearInTents auto
GlobalVariable property Camp_Setting_CampingArmorTakeOff auto
GlobalVariable property Camp_Setting_TakeOff_Cuirass auto
GlobalVariable property DTEC_IsFrostfallActive auto
GlobalVariable property DTEC_FollowerUndressEnabled auto
Armor property DTEC_DummyRing auto

Actor property MyActor auto hidden

; private vars

int updateStep = -1

Event OnActivate(ObjectReference akActionRef)
	
	if ((akActionRef as Actor) != PlayerRef)
		if (Camp_Setting_CampingArmorTakeOff.GetValueInt() == 2 && DTEC_FollowerUndressEnabled.GetValue() > 0.0)
			bool okUndress = true
			updateStep = 0
			Actor thisActorRef = akActionRef as Actor
			if (thisActorRef && CampUtil.IsTrackedFollower(thisActorRef))
				if (thisActorRef.IsChild())
					okUndress = false
				elseIf (thisActorRef.HasKeyword(ActorTypeCreature))
					; not sure how a creature uses a bed, but never know with mods
					okUndress = false
				elseIf (Camp_Setting_FollowersRemoveGearInTents.GetValueInt() < 2)
					okUndress = false
				elseIf (Camp_Setting_TakeOff_Cuirass.GetValueInt() < 2)
					okUndress = false
				elseIf (DTEC_IsFrostfallActive.GetValueInt() > 0)
					If (DTEC_CommonF.GetFrostfallRunningValue() == 2)
						; is warm enough?
						
						okUndress = FrostUtil.IsWarmEnoughToRemoveGearInTent()

						;if (!okUndress)
						;	Debug.Trace("[DTEC]: too frosty for NPC to undress")
						;endIf
					endIf
				endIf
				if (okUndress)
					updateStep = 1
					MyActor = akActionRef as Actor
					; no need for RegisterForSingleUpdate(1.2) override Campfire bed
				endIf
			endIf
		endIf
	endIf
endEvent

; Campfire _Camp_CampTentNPCBedrollScript uses OnUpdate to display/un-display weapons
; same form, so we don't need to register - just listen
Event OnUpdate()
	
	if self.IsFurnitureInUse()
		; safe to unequip - weapon captured on activation
		if (updateStep == 1)
			Utility.Wait(0.05)
			MyActor.UnEquipAll()
			updateStep = 2

		endIf
	elseIf (updateStep >= 2)

		; redress
		RedressActor(MyActor)
		updateStep = -1

		MyActor = none
	endIf
endEvent

Function RedressActor(Actor actRef)
	if (actRef)
		actRef.AddItem(DTEC_DummyRing, 1, true)
		actRef.EquipItem(DTEC_DummyRing, true)
		actRef.UnEquipItem(DTEC_DummyRing, true)
		actRef.RemoveItem(DTEC_DummyRing, 1, true)
	endIf
endFunction