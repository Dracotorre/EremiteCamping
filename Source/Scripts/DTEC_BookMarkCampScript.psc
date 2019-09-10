Scriptname DTEC_BookMarkCampScript extends ObjectReference  

; by DracoTorre
; requires Campfire DevKit CampUtil 
;
; best results when player inside tent or sitting on bed-roll checked using CampUtil.GetCurrentTent()

Actor property PlayerREF auto
;Quest property MainShelterQuest auto
Quest property DTEC_MarkCampQuest auto
ReferenceAlias property DTEC_CampRefAlias auto
GlobalVariable property DTEC_SettingEnabled auto
Message property DTEC_CampMarkerClearMsg auto
Message property DTEC_CampNotFoundMsg auto
Message property DTEC_CampNotUsingMsg auto
Message property DTEC_CampRemoveMarkMsg auto

Event OnRead()
	if (DTEC_SettingEnabled != None && DTEC_SettingEnabled.GetValue() >= 1.0 && DTEC_MarkCampQuest != None)
		; toggle off if running or on if camp nearby
		if (DTEC_MarkCampQuest.IsRunning() && DTEC_MarkCampQuest.GetStage() < 100)
			Utility.WaitMenuMode(2.0)
			
			if (DTEC_CampRemoveMarkMsg.Show() >= 1)
				DTEC_MarkCampQuest.SetStage(100)
				DTEC_MarkCampQuest.Stop()
				if (DTEC_CampMarkerClearMsg != None)
					DTEC_CampMarkerClearMsg.Show()
				endIf
			endIf
		else
			DTEC_MarkCampQuest.Start()
			Utility.WaitMenuMode(0.8)
			ObjectReference campfireTent = CampUtil.GetCurrentTent()
			
			if (DTEC_CampRefAlias != None)
				if (campfireTent == None)
					; not using a tent
					DTEC_MarkCampQuest.Stop()
					DTEC_CampNotUsingMsg.Show()
					
				elseIf (campfireTent != None)
					ObjectReference tentRef = DTEC_CampRefAlias.GetReference()
					if (tentRef != campfireTent)
						DTEC_CampRefAlias.ForceRefTo(campfireTent)
					endIf
						
					DTEC_MarkCampQuest.SetStage(10)
				else
					;Debug.Trace("[DTEC_RingMark] no campfireTent found!!")
					DTEC_MarkCampQuest.Stop()
					DisplayNoCampFound()
				endIf
			else
				;Debug.Trace("[DTEC_RingMark] CampRefAlias is None!")
				DTEC_MarkCampQuest.Stop()
				DisplayNoCampFound()
			endIf
		endIf
	endIf

EndEvent

Function DisplayNoCampFound()
	if (DTEC_CampNotFoundMsg != None)
		DTEC_CampNotFoundMsg.Show()
	endIf
endFunction

