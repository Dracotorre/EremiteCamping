Scriptname DTEC_MainShelterQuestScript extends Quest  

; by DracoTorre
; version 2
; web page: http://www.dracotorre.com/mods/eremitecamping/
; https://github.com/Dracotorre/EremiteCamping
;
; EremiteCamping.esp - MainShelterQuest - Do not stop this quest!
;
; ----------------- notes
;  spellmaking??
;
; ------------
; Detects Campfire tents and base-game tents for warm sleep bonus
; if in Survival Mode then tent extends warmth from heat source
; Monitor no-armor combat for perk bonus.
; ------------
;
; using CampUtil and FrostUtil -
; Requires Campfire Dev Kit 1.7.1 and SKSE64 sources to compile
;  - use CampUtil instead of using CampfireSystem quest directly which may block Campfire functionality
;  - Remember to remove Dev Kit for play-testing.
;  - repackage the dev kit with sources in correct folder for Special Edition
;
;
; Overview:
; To determine if player inside tent, simply
; ask CampUtil GetCurrentTent in use by player.
; stop everything using StopAll() and restart using StartAll()
; 
; Not using SKSE events to support normal Skyrim so we'll poll which we need to do anyway
; to find if player is near a base-game tent. This detection will only
; run if Frostfall or Survival Mode are found.
;
; Refresh bonus gained by sleeping in warm tent if 7-12 sleep hours
; and apply no more than about once a day. Unarmored points gain limited
; to about 2 game-hours, more often if hit in combat.

Actor property PlayerRef auto
Keyword property ActorTypeCreature auto
Keyword property ArmorLightKY auto
Keyword property ArmorHeavyKY auto
Keyword property MagicArmorSpellKY auto
Spell Property WerewolfChange auto
MagicEffect property doomLordDamageEffect auto

;Quest property DTCampUpdateQuest auto
ReferenceAlias property DTECPlayerAlias auto
Quest property DTEC_MagicFocusQuest auto

GlobalVariable property DTEC_InitCampData auto
GlobalVariable property DTEC_CampfireUpdated auto
GlobalVariable property DTEC_ShelterPollSecs auto
GlobalVariable property DTEC_MonitorExistingTentsEnable auto
GlobalVariable property DTEC_MonitorTentsEnable auto
GlobalVariable property DTEC_NotificationEnabled auto
GlobalVariable property DTEC_FatigueRefreshEnabled auto
GlobalVariable property DTEC_IsOrdinatorActive auto
GlobalVariable property DTEC_IsFrostfallActive auto
GlobalVariable property DTEC_PerkRank_SleepBasic auto
GlobalVariable property DTEC_PerkRank_SleepPro auto
GlobalVariable property DTEC_PerkPointProgress auto
GlobalVariable property DTEC_PerkPointsEarned auto
GlobalVariable property DTEC_PerkPointsTotal auto
GlobalVariable property DTEC_PerkPoints auto
GlobalVariable property DTEC_PerkRank_TentWarm auto
GlobalVariable property DTEC_WarmRestTotal auto
GlobalVariable property DTEC_UnarmoredCombatTotal auto
{ unarmed or no-armor combat total}
GlobalVariable property DTEC_WarmTentPerkTotal auto
GlobalVariable property DTEC_LastTentWarmPerkTime auto
GlobalVariable property DTEC_LastCombatPerkTime auto
GlobalVariable property DTEC_PerkRank_Unarmored auto
GlobalVariable property DTEC_PerkRank_Pugalist auto
GlobalVariable property DTEC_PerkRank_Craft auto
GlobalVariable property DTEC_ErrorQuestStopShown auto
GlobalVariable property DTEC_FocusTotal auto			; v2

; settings
GlobalVariable property DTEC_SettingExistingTentsWarm auto
GlobalVariable property DTEC_SettingEnabled auto
{ 1 = on, 0 = 0ff, -1 = need to start, -2 = quest stopped/no-start }

Spell property DTEC_DamageResistAbility auto
Spell property DTEC_UnarmedDamageAbility auto
Spell property DTEC_RefreshedRegen auto
Spell property DTEC_FocusSpellAb auto			; v2 no-armor bonus
Spell property DTEC_FocusSpellAbBrawl auto		; v2 unarmed damage bonus
Spell property DTEC_FocusSpellAbArchery auto	; v2
Spell property DTEC_FocusSpellAbMagicka auto	; v2
Spell property DTEC_FocusSpellAbOneHand auto	; v2
Spell property DTEC_FocusSpellAbTwoHand auto	; v2
Spell property DTEC_FocusSpellExpired auto 		; v2 removes focus spells

Message property DTEC_MonitorEnabledMsg auto
Message property DTEC_MonitorDisabledMsg auto
Message property DTEC_WarmTentMsg auto
Message property DTEC_WarmBedrollMsg auto
Message property DTEC_RefreshMsg auto
Message property DTEC_PerkAdvanceMsg auto
Message property DTEC_PerkAdvanceBonusMsg auto
Message property DTEC_PerkEarnedMsg auto
Message property DTEC_AllDisabledMsg auto
Message property DTEC_AllEnabledMsg auto
Message property DTEC_ErrorQuestStopMsg auto
Message property DTEC_PerkAdvanceErrorMsg auto
Message property DTEC_ArmorNoProgMsg auto
Message property DTEC_ArmorBadMsg auto
Message property DTEC_HasMeditatedMessage auto		;v2
Message property DTEC_WarnMagicArmorInHandMsg auto 	;v2 reminder
Message property DTEC_WarnMagicArmorMessage auto 	;v2 reminder
Message property DTEC_ColdMessage auto 				;v2
Message property DTEC_MeditateEndMessage auto 		;v2

;FormList property DTEC_CampHeatSource_EmbersFL auto
FormList property DTEC_CampHeatSource_MediumFL auto
FormList property DTEC_HeatSources_SmallFL auto
FormList property DTEC_CampHeatSource_AllFL auto
FormList property Camp_HeatSources_LargeFL auto
FormList property Camp_WarmBaseTentsFL auto   ; only need if no Frostfall
Keyword property IsCampfireTentWarmKW auto
Keyword property IsCampfireTentNoShelterKW auto
Keyword property IsCampfireTentWaterProofKW auto
FormList property DTEC_ModTentShelterList auto
FormList property DTEC_ArmoredBadSpellList auto		; v2 known spells equipped to cause magic armor keyword
FormList property DTEC_SpellsRemOnExpiredList auto	; v2 spells we want to remove end of meditate period

; ------------- hidden 

ObjectReference property CurrentWarmTent auto hidden
FormList property SurvivalWarmList auto hidden
; let's give free perks for starting at higher levels
int property FreePerkPoints auto hidden 
bool property CampDataInitialized auto hidden
int property PerkAdvanceErrorCount auto hidden
float property LastFocusTime auto hidden

; goal maximizing points per day: 0.1156 or perk point every 9 game-days
; if player chooses to fight in armor then perk gain every 14 game-days
; average unarmored combats per day should work out same as sleep --- or more? - try 4-8 combats per day (4 for both no-armor, no-weapon)
float property PointsPerSleep = 0.0714 autoReadOnly hidden
; not used-- divide evenly with perSleep if used
float property PointsPerTentWarm = 0.0001 autoReadOnly hidden 
float property PointsPerUnarmCombat = 0.01087 autoReadOnly hidden ; -- old value: 0.0054
float property PointsPerMeditate = 0.030 autoReadOnly hidden
string property myScriptName = "[DTEC_MainShelterQuest]" autoReadOnly hidden

; ************* private vars **********

bool isEnabled = false
bool isInTent = false
bool isRefreshed = false
bool IsFatigueRecovered = false
int updateTentSearchCount = 0
int checkInit = 0
int unarmoredCombatRoundsCount
int unarmCombatRounds
int playerTookHitCount
int updateGameTimeType = 0
float sleepStartTime
float sleepLastStopTime
float updateWaitSeconds
float updateWaitSecsDefault

; ******************* Events ***************

Event OnInit()
	CampDataInitialized = false
	Utility.Wait(24.0)					;v2.24 - increased time
	StartAll()
endEvent

Event OnUpdate()

	if (DTEC_SettingEnabled.GetValueInt() > 0)
		if (!self.IsRunning())
			Debug.Trace(myScriptName + " quest not running!!")
			if (DTEC_ErrorQuestStopShown.GetValueInt() < 1)
				DTEC_ErrorQuestStopMsg.Show()
				DTEC_ErrorQuestStopShown.SetValueInt(1)
			endIf
			Utility.Wait(1.1)
			StopAll()
			DTEC_SettingEnabled.SetValue(-2.0)
		endIf
		; check default poll frequency
		GetDefaultUpdateWaitSecs()
		
		if (sleepLastStopTime <= 0.0)
			sleepLastStopTime = Utility.GetCurrentGameTime() - 1.0
		endIf
		
		if (DTEC_SettingEnabled.GetValueInt() > 0)
			HandleOnUpdate()
		endIf
	elseIf (DTEC_SettingEnabled.GetValueInt() == -1)
		StartAll()
	endIf
endEvent

Event OnUpdateGameTime()	
	if (updateGameTimeType == 2)
		if (DTEC_NotificationEnabled.GetValueInt() > 0)
			DTEC_MeditateEndMessage.Show()
		endIf
		updateGameTimeType = 0
		PlayerRef.RemoveSpell(DTEC_FocusSpellAb)
		RemSpellOnExpired()
		
		DTEC_FocusSpellExpired.Cast(PlayerRef, PlayerRef)			; clear focus spells
	else
		Debug.Notification("Eremite focus not removed!!")
	endIf
endEvent

; ------------

Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	sleepStartTime = afSleepStartTime
EndEvent

Event OnSleepStop(bool abInterrupted)
	if (abInterrupted)
		return
	endIf
	
	if (isInTent)
		float currentTime = Utility.GetCurrentGameTime()
		float hoursSinceLastSleep = DTEC_CommonF.GetGameTimeHoursDifference(currentTime, sleepLastStopTime)
		sleepLastStopTime = currentTime
		
		;Debug.Trace(myScriptName + " Warm Tent SleepStop - hours since last sleep: " + hoursSinceLastSleep)
		
		if (hoursSinceLastSleep > 17.0)
			; limit refresh to once a day
			float sleepHours = DTEC_CommonF.GetGameTimeHoursDifference(currentTime, sleepStartTime)
			ApplyPlayerPerkPointsSleep(sleepHours)

			if (IsPlayerAllowedRestBonus(sleepHours))
				isRefreshed = true
				Utility.Wait(0.2)
				
			; v2.1 let's allow a level of fatigue recovery for Survival without the perk
			elseIf (sleepHours > 6.5 && DTEC_CampfireUpdated.GetValueInt() >= 1 && !PlayerRef.HasKeyword(ActorTypeCreature))
				IsFatigueRecovered = true
				Utility.Wait(0.2)
			endIf
		endIf
		if (DTEC_PerkRank_Unarmored.GetValueInt() >= 1)
			; to avoid ability condition stuck bug (4096 cell loads) reset ability
			if (PlayerRef.HasSpell(DTEC_DamageResistAbility))
				PlayerRef.RemoveSpell(DTEC_DamageResistAbility)
			endIf
			;Debug.Trace(myScriptName + " add damage resist spell")
			PlayerRef.AddSpell(DTEC_DamageResistAbility)
		endIf
		if (DTEC_PerkRank_Pugalist.GetValueInt() >= 1)
			; to avoid ability condition stuck bug (4096 cell loads) reset ability
			if (PlayerRef.HasSpell(DTEC_UnarmedDamageAbility))
				PlayerRef.RemoveSpell(DTEC_UnarmedDamageAbility)
			endIf
			;Debug.Trace(myScriptName + " add pugilist spell")
			PlayerRef.AddSpell(DTEC_UnarmedDamageAbility)
		endIf
	endIf
EndEvent

; ****************** Functions ****************

Function AddRefreshToPlayer()
	isRefreshed = false
	IsFatigueRecovered = false
	if (DTEC_SettingEnabled.GetValue() >= 1.0)
	
		if (DTEC_CampfireUpdated.GetValueInt() >= 1)
				SurvivalRecoverFatigue(2)			; full recovery
			endIf
		;Debug.Trace(myScriptName + " player refreshed sleeping in sheltered tent")
		if (!PlayerRef.HasSpell(DTEC_RefreshedRegen))
			PlayerRef.AddSpell(DTEC_RefreshedRegen, false)
			
			DTEC_RefreshMsg.Show()
		endIf
	endIf
endFunction

; same conditions found in Ordinator     --- v2.23 - remove this is incorrect usage
Function AddOrdinatorVancianToPlayer()
	if (DTEC_SettingEnabled.GetValue() >= 1.0)
		Perk vancianPerk = DTEC_CommonF.GetOrdinatorVancianPerk()
		if (vancianPerk != None && !PlayerRef.HasPerk(vancianPerk) && PlayerRef.GetBaseActorValue("Alteration") >= 30)
			Perk altMaster = DTEC_CommonF.GetOrdinatorAltMasteryPerk()
			if (altMaster != None && PlayerRef.HasPerk(altMaster))
				; should check if have vancianPerk then restore spells from Ordinator 
			endIf
		endIf
	endIf
endFunction

Function AddTentToWarmList()
	if (CurrentWarmTent)
		if (DTEC_CampfireUpdated.GetValueInt() >= 1)
			SurvivalWarmList = DTEC_CommonF.GetSurvivalWarmList()
			if (SurvivalWarmList)
				SurvivalWarmList.AddForm(CurrentWarmTent.GetBaseObject())
				;Debug.Trace(myScriptName + " added " + CurrentWarmTent + " to warmList size: " + SurvivalWarmList.GetSize())
			endIf
		endIf
		if (DTEC_IsFrostfallActive.GetValueInt() >= 1)
			if (DTEC_CommonF.GetFrostfallRunningValue() == 2)
				; bump warmth
				FrostUtil.ModPlayerExposure(-10.0)
			endIf
		endIf
	endIf
endFunction

; only for upgrade from older version to grant back points (v1.20)
;
Function ApplyPlayerPerkPointsUpgrade()
	if (checkInit == 1 && FreePerkPoints < 2 && DTEC_PerkPointsEarned.GetValueInt() < 10)
		checkInit = 3
		float combatCount = DTEC_UnarmoredCombatTotal.GetValue()
		if (combatCount > 201.0)
			FreePerkPoints += 1
			int points = 1 + DTEC_PerkPoints.GetValueInt()
			DTEC_PerkPoints.SetValueInt(points)
			DTEC_PerkAdvanceMsg.Show()
		endIf
	endIf
endFunction

bool Function ApplyPlayerPerkPoints(float perkPoints, bool skipChecks = false, bool showAltMsg = false)
	int currentPointsEarned = DTEC_PerkPointsEarned.GetValueInt()
	int totalPoints = DTEC_PerkPointsTotal.GetValueInt()
		
	if (currentPointsEarned < totalPoints)
	
		float perkProgress = DTEC_PerkPointProgress.GetValue()
		perkProgress += perkPoints
		int pointsToSpend = DTEC_PerkPoints.GetValueInt()
		
		; error / cheating check
		if (pointsToSpend > currentPointsEarned)
			Debug.Trace(myScriptName + "ApplyPerks: points > pointsEarned!")
			pointsToSpend = currentPointsEarned
			DTEC_PerkPoints.SetValueInt(pointsToSpend)
		endIf
		
		if (!skipChecks && currentPointsEarned > 0)
			; error / cheating check 2
			float pointsFromSleep = DTEC_WarmRestTotal.GetValue() * PointsPerSleep
			float pointsFromCombat = DTEC_UnarmoredCombatTotal.GetValue() * PointsPerUnarmCombat
			float pointsFromMeditate = DTEC_FocusTotal.GetValue() * PointsPerMeditate
			float totalPointsCheck = pointsFromCombat + pointsFromSleep + pointsFromMeditate
			if (FreePerkPoints > 0 && FreePerkPoints < 3)
				totalPointsCheck += FreePerkPoints
			endIf
		
			if ((totalPointsCheck + 0.33) < currentPointsEarned as float)
				PerkAdvanceErrorCount += 1
				
				Debug.Trace(myScriptName + "ApplyPerks: totalPoints < points earned! " + totalPointsCheck + ", " + currentPointsEarned)
				DTEC_PerkAdvanceErrorMsg.Show()
				
				if (pointsToSpend > 0)
					int pointDiff = currentPointsEarned - Math.Floor(totalPointsCheck)
					pointsToSpend = pointsToSpend - pointDiff
					if (pointsToSpend < 0)
						pointsToSpend = 0
					endIf
					DTEC_PerkPoints.SetValueInt(pointsToSpend)
				else
					perkProgress -= perkPoints
				endIf
			else
				PerkAdvanceErrorCount = 0
			endIf
		elseIf (skipChecks)
			PerkAdvanceErrorCount = 0
		endIf
		
		if (perkProgress + 0.01 >= 1.0)
			currentPointsEarned += 1
			pointsToSpend += 1
			DTEC_PerkPoints.SetValueInt(pointsToSpend)
			if (currentPointsEarned >= totalPoints)
				perkProgress = 1.0
			else
				perkProgress = 0.00
			endIf
			DTEC_PerkPointsEarned.SetValueInt(currentPointsEarned)
			
			DTEC_PerkEarnedMsg.Show()
			;Debug.Trace(myScriptName + " ApplyPerks - perk earned msg")
		elseIf (perkProgress > DTEC_PerkPointProgress.GetValue())
			;Debug.Trace(myScriptName + " ApplyPerks - progress advanced msg")
			if (showAltMsg)
				DTEC_PerkAdvanceBonusMsg.Show()
			else
				DTEC_PerkAdvanceMsg.Show()
			endIf
		endIf
		
		DTEC_PerkPointProgress.SetValue(perkProgress)
		
		return true
	endIf
	
	return false
endFunction

;
; v2: meditation for combat or magic
; rugType 0 for combat, 1 for magic
;
Function ApplyPlayerPerkPointsMeditateAddSpell(int weaponType, int rugType = 0)
	
	if (DTEC_SettingEnabled.GetValue() >= 1.0)
		int noArmorVal = IsPlayerInArmor(true)				; remove known bad spells
		float currentTime = Utility.GetCurrentGameTime()
		int currentDayNum = Math.Floor(currentTime)
		int lastFocusDayNum = Math.Floor(LastFocusTime)
		
		if (PlayerRef.HasSpell(DTEC_FocusSpellAb))
			if (currentDayNum > lastFocusDayNum)
				; new day, clear
				PlayerRef.RemoveSpell(DTEC_FocusSpellAb)
			endIf
		endIf
			
		if (noArmorVal > 1)

			DTEC_ArmorNoProgMsg.Show()
			if (noArmorVal >= 4)
				Utility.Wait(1.0)
				DTEC_WarnMagicArmorInHandMsg.Show()
			endIf
			
		elseIf (PlayerRef.HasSpell(DTEC_FocusSpellAb))
			
			; has spell, remind player
			if (rugType == 1)
				(DTEC_MagicFocusQuest as DTEC_MagicFocusQuestScript).PublicStopAll()
			endIf
			DTEC_HasMeditatedMessage.Show()
		else
			; no spell
			int chooseToContinue = 100			; player may choose combat or magic
			; likely longer than 8 hours, but in case spell removed sooner
			float hoursSinceLastFocus = DTEC_CommonF.GetGameTimeHoursDifference(LastFocusTime, currentTime)
					
			if (hoursSinceLastFocus > 8.0)
				; limited by hours
				
				if (rugType == 1)
					; magic rug
					if (!DTEC_MagicFocusQuest.IsRunning())
						DTEC_MagicFocusQuest.Start()
					endIf
					Utility.Wait(1.2)
					
					; may be negative if player fails to meet requirements
					chooseToContinue = (DTEC_MagicFocusQuest as DTEC_MagicFocusQuestScript).PublicStartFocus()
				endIf
				
				if (chooseToContinue >= 0)
					; player meets requirements
					; add no-armor bonus spell
					PlayerRef.AddSpell(DTEC_FocusSpellAb)
					
					updateGameTimeType = 2
					RegisterForSingleUpdateGameTime(8.0)
				endIf
				
				if (rugType == 1 && chooseToContinue > 0 && chooseToContinue < 100)
					; magic
					LastFocusTime = currentTime				; update
					Utility.Wait(1.5)
					(DTEC_MagicFocusQuest as DTEC_MagicFocusQuestScript).PublicAddSpellsToPlayer()
					
				elseIf (chooseToContinue == 100 || chooseToContinue == 0)
				
					; combat skills 
					LastFocusTime = currentTime				; update
					
					if (weaponType >= 1 && weaponType <= 4)
						; one-hand
						PlayerRef.AddSpell(DTEC_FocusSpellAbOneHand)
					elseIf (weaponType >= 5 && weaponType <= 6)
						; two-hand
						PlayerRef.AddSpell(DTEC_FocusSpellAbTwoHand)
						
					elseIf (weaponType == 7 || weaponType == 12)
						PlayerRef.AddSpell(DTEC_FocusSpellAbArchery)
						
					elseIf (weaponType == 8)
						; staff
						PlayerRef.AddSpell(DTEC_FocusSpellAbMagicka)
					else
						PlayerRef.AddSpell(DTEC_FocusSpellAbBrawl)
					endIf
				
				endIf
			else
				; has meditated by time limit
				chooseToContinue = -2
				
				DTEC_HasMeditatedMessage.Show()
			endIf
			
			; check perk progress
			if (chooseToContinue >= 0 && chooseToContinue <= 100 && currentDayNum > lastFocusDayNum)
				; advanced limited to once per day
				int totalMed = DTEC_FocusTotal.GetValueInt()
				totalMed += 1
					
				float perkPoints = PointsPerMeditate
				if (perkPoints > 0.050)
					perkPoints = 0.050
				endIf
				if (noArmorVal == 1)
					DTEC_ArmorBadMsg.Show()				; reminder detected armor keywords but no armor rating
					Utility.Wait(0.5)
				endIf
				if (DTEC_PerkPointsEarned.GetValueInt() == 0)
					; double to reach first perk quicker
					perkPoints += PointsPerMeditate
					totalMed += 1		; double the count for error check
				endIf
					
				if (totalMed < 9000)
					DTEC_FocusTotal.SetValueInt(totalMed)
				endIf
					
				ApplyPlayerPerkPoints(perkPoints, (PerkAdvanceErrorCount > 2), false)
			endIf
			
			if (rugType == 1)
				(DTEC_MagicFocusQuest as DTEC_MagicFocusQuestScript).PublicStopAll()
			endIf
		endIf
	endIf

endFunction

Function ApplyPlayerPerkPointsSleep(float sleepHours)
	if (DTEC_SettingEnabled.GetValue() >= 1.0)
		if (CurrentWarmTent && sleepHours >= 7.0)
			int noArmorVal = IsPlayerInArmor()
			if (noArmorVal > 1)

				DTEC_ArmorNoProgMsg.Show()
			else
				
				int totalRests = DTEC_WarmRestTotal.GetValueInt()
				totalRests += 1
				float perkPoints = PointsPerSleep
				if (perkPoints > 0.080)
					perkPoints = 0.080
				endIf
				if (noArmorVal == 1)
					DTEC_ArmorBadMsg.Show()
					Utility.Wait(0.5)
				endIf
				if (DTEC_PerkPointsEarned.GetValueInt() == 0)
					; double to reach first perk quicker
					perkPoints += PointsPerSleep
					totalRests += 1		; double the count for error check
				endIf
				DTEC_WarmRestTotal.SetValueInt(totalRests)
				
				ApplyPlayerPerkPoints(perkPoints, (PerkAdvanceErrorCount > 2), false)
			endIf
		endIf
	endIf
endFunction

; combat perks for unarmed or no-armor
Function ApplyPlayerPerkPointsUnarmedCombat(bool hitInCombat, bool getBonus = false)
	; let's limit point-gain per hours
	float lastCombatTime = DTEC_LastCombatPerkTime.GetValue()
	float currentTime = Utility.GetCurrentGameTime()
	float hoursSinceLastCombat = DTEC_CommonF.GetGameTimeHoursDifference(currentTime, lastCombatTime)
	float minHourLim = 1.333 
	if (hitInCombat || getBonus)
		minHourLim = 0.580
	endIf
	float timeLim = Utility.RandomFloat(minHourLim, (minHourLim + 0.67))
	
	; eligible to gain
	if (hoursSinceLastCombat > timeLim)
		float perkPoints = PointsPerUnarmCombat
		if (perkPoints > 0.020)
			perkPoints = 0.020
		endIf
		int totalPerkCombats = DTEC_UnarmoredCombatTotal.GetValueInt()
		int combatCount = 1
		totalPerkCombats += combatCount
		if (getBonus)
			perkPoints += perkPoints
			totalPerkCombats += 1
		endIf
		if (DTEC_PerkPointsEarned.GetValueInt() == 0 && PointsPerUnarmCombat < 0.020)
			; extra to reach first perk quicker
			perkPoints += PointsPerUnarmCombat
			totalPerkCombats += 1
		endIf
		if (ApplyPlayerPerkPoints(perkPoints, false, getBonus))
			; only keep counting if still earning
			DTEC_UnarmoredCombatTotal.SetValueInt(totalPerkCombats)
		endIf
		DTEC_LastCombatPerkTime.SetValue(currentTime)
		;Debug.Trace(myScriptName + " ApplyPerks - unarmed, no-armor combat")
	endIf
endFunction

; run once 
Function CheckArmor()
	(DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCuirass = None
	(DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCloak = None
	(DTECPlayerAlias as DTEC_EquipMonitor).MyCloakTentStore = None
	
	if (!CampDataInitialized)
		DTEC_InitCampData.SetValueInt(1)
		Utility.Wait(0.05)
		PlayerRef.UnequipItemSlot(32)
		Utility.Wait(0.5)
		PlayerRef.UnequipItemSlot(46)
		Utility.Wait(1.0)
		Armor bodyArm = (DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCuirass
		if (bodyArm)
			PlayerRef.EquipItem(bodyArm, false, true)
			Utility.Wait(0.5)
		endIf
		Armor cloak = (DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCloak
		if (cloak)
			PlayerRef.EquipItem(cloak, false, true)
		endIf
		
		Armor other = (DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedOther
		if (other)
			PlayerRef.EquipItem(other, false, true)
		endIf
		
		DTEC_InitCampData.SetValueInt(0)
		(DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCuirass = None
		(DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedCloak = None
		(DTECPlayerAlias as DTEC_EquipMonitor).MyRemovedOther = None
		
		CampDataInitialized = true
	endIf
endFunction

Function CheckForTentShelter()
	if (isEnabled && !PlayerRef.IsOnMount() && !PlayerRef.HasKeyword(ActorTypeCreature))
	
		updateTentSearchCount -= 1
		ObjectReference campfireTent = CampUtil.GetCurrentTent()
		
		if (campfireTent != None)
			;Debug.Trace(myScriptName + " player using campfire tent, let's check it out")
			if (IsTentWarm(campfireTent))
				;Debug.Trace(myScriptName + " warm tent!")
				if (isInTent)
					if (CurrentWarmTent != campfireTent)
						;Debug.Trace(myScriptName + " we switched tents!")
						PlayerExitedTent()
						Utility.Wait(0.1)
						PlayerEnteredTent(campfireTent)
					endIf
				else
					PlayerEnteredTent(campfireTent)
					updateWaitSeconds = 4.0
				endIf
				
			elseIf (isInTent)
				PlayerExitedTent()
				updateWaitSeconds = updateWaitSecsDefault
			endIf
		elseIf (IsSearchForTentsEnabled() && updateTentSearchCount < 2)
			; time to search for base-game tent
			;Debug.Trace(myScriptName + " searching for base-game tents")
			;WorldSpace loc = PlayerRef.GetWorldSpace()
			
			if (CampUtil.LegalToCampHere(true))
				; search wide first to see if getting close
				float radius = 96360.0
				if (updateTentSearchCount < 1)
					; set size for inside tent
					radius = 224.0
				endIf
				
				ObjectReference nearTent = GetBaseTentNear(PlayerRef, radius)
				
				if (nearTent)
					if (radius <= 250.0 || PlayerRef.GetDistance(nearTent) < 232.0)
						if (IsTentWarm(nearTent))
							;Debug.Trace(myScriptName + " found base warm tent " + nearTent)
							if (isInTent)
								if (CurrentWarmTent != nearTent)
									;Debug.Trace(myScriptName + " we switched base-game tents!")
									PlayerExitedTent()
									Utility.Wait(0.3)
									PlayerEnteredTent(nearTent)
								endIf
							else
								PlayerEnteredTent(nearTent)
								updateWaitSeconds = 4.0
							endIf
						endIf
					else
						; a tent is close -- keep lookout for it
						;Debug.Trace(myScriptName + "found base tent, " + nearTent + ", in radius " + radius)
						updateWaitSeconds = 8.0
						updateTentSearchCount = 1
					endIf
				else
					If (isInTent)
						PlayerExitedTent()
						updateWaitSeconds = 8.0
						updateTentSearchCount = 1
					elseIf (radius > 1000.0)
						updateTentSearchCount = 4
					else
						updateTentSearchCount = 2
					endIf
				endIf
			else
				updateTentSearchCount = 5
				;Debug.Trace(myScriptName + " no search for tents in restricted camp location, ")
			endIf
		elseIf (isInTent)
			PlayerExitedTent()
			updateTentSearchCount = 1
			updateWaitSeconds = updateWaitSecsDefault
		endIf
	endIf
endFunction

Function CheckToGrantFreePerkPoints()
	if (PlayerRef.GetLevel() >= 19 && DTEC_PerkPointsEarned.GetValueInt() == 0 && DTEC_PerkPointProgress.GetValue() == 0.0)
		FreePerkPoints = 1
		DTEC_PerkRank_Craft.SetValueInt(1)
		if (PlayerRef.GetLevel() > 40)
			FreePerkPoints = 2
			DTEC_PerkPoints.SetValueInt(1)
		endIf
		DTEC_PerkPointsEarned.SetValueInt(FreePerkPoints)
	else
		FreePerkPoints = 0
	endIf
endFunction

; Only use if no Frostfall running since Frostfall does this and updates Campfire tent in use
ObjectReference Function GetBaseTentNear(ObjectReference nearRef, float radius)
	return Game.FindClosestReferenceOfAnyTypeInList(Camp_WarmBaseTentsFL, nearRef.X, nearRef.Y, nearRef.Z, radius)
	
endFunction

Function GetDefaultUpdateWaitSecs()
	float checkWaitSec = DTEC_ShelterPollSecs.GetValue()
	if (checkWaitSec != updateWaitSecsDefault && checkWaitSec >= 4.0 && checkWaitSec <= 64.0)
		;Debug.Trace(myScriptName + " updated default frequency")
		updateWaitSecsDefault = checkWaitSec
	endIf
endFunction

; send outer radius for large fire
; if medium fire then returns true if within radius - 812
; note: large fires have radius 2048, medium: 1024, small: 512
;
; If Frostfall is running, use FrostUtil instead as it also runs Game.FindClosestRef...
;
ObjectReference Function GetFireNear(ObjectReference nearRef, float radius)
	;Debug.Trace(myScriptName + " looking for fire in radius " + radius)
	
	; find only the closest of any fire then determine what size
	; this could mean ignoring larger fire if closer not enabled, but better to reduce function calling
	ObjectReference aFire = Game.FindClosestReferenceOfAnyTypeInList(DTEC_CampHeatSource_AllFL, nearRef.X, nearRef.Y, nearRef.Z, radius)
	if (aFire && aFire.IsEnabled())
		Form fireBase = aFire.GetBaseObject() as Form
		if (Camp_HeatSources_LargeFL.HasForm(fireBase))
			;Debug.Trace(myScriptName + " found large heat source nearby " + aFire.GetBaseObject())
			return aFire
		elseIf (DTEC_CampHeatSource_MediumFL.HasForm(fireBase))
			if (radius > 1324.0)
				radius = radius - 812
			else
				radius = 1024.0
			endIf
			if (nearRef.GetDistance(aFire) <= radius)
				;Debug.Trace(myScriptName + " found medium fire nearby " + aFire.GetBaseObject())
				return aFire
			endIf
		elseIf (DTEC_HeatSources_SmallFL.HasForm(fireBase) && nearRef.GetDistance(aFire) <= 384.0)
			;Debug.Trace(myScriptName + " found small fire nearby " + aFire.GetBaseObject())
			return aFire
		endIf
	endIf
	
	return None
endFunction

Function HandleOnUpdate()
	bool isSurvivalModeUpdated = false
	bool isFrostfallRunning = false
	bool isFrostfallActive = false
	
	if (DTEC_CampfireUpdated.GetValueInt() >= 1)
		isSurvivalModeUpdated = true
	endIf
	
	if (DTEC_IsFrostfallActive.GetValueInt() >= 1)
		isFrostfallActive = true
		if (DTEC_CommonF.GetFrostfallRunningValue() >= 2)
			isFrostfallRunning = true
		endIf
	endIf
	
	if (isRefreshed)
		AddRefreshToPlayer()
		; v2.23 fix -- do nothing here
		;if (DTEC_IsOrdinatorActive.GetValueInt() as bool)
		;	AddOrdinatorVancianToPlayer()
		;endIf
	elseIf (IsFatigueRecovered)
		SurvivalRecoverFatigue(1)
	endIf
	
	IsFatigueRecovered = false
	
	; have we been disabled or still in intro?
	if (DTEC_MonitorTentsEnable.GetValue() <= 0.0)
		if (isEnabled)
			StopMonitoring()
		endIf
		updateWaitSeconds = 120.0
	
	elseIf (isSurvivalModeUpdated && !DTEC_CommonF.IsSurvivalModeEnabled() && isFrostFallActive && !isFrostfallRunning)
		; now stop if no Survival and no Frostfall running v2.25
		if (isEnabled)
			StopMonitoring()
		endIf
		updateWaitSeconds = 64.0
		
	elseIf (!isSurvivalModeUpdated && isFrostfallActive && !isFrostfallRunning)			
		; no survival installed, Frostfall stopped
		if (isEnabled)
			StopMonitoring()
		endIf
		updateWaitSeconds = 64.0
	
	elseIf (!isEnabled)
		isEnabled = true
		;Debug.Trace(myScriptName + " enabled")
		updateWaitSeconds = updateWaitSecsDefault
		if (DTEC_NotificationEnabled.GetValue() >= 1.0)
			DTEC_MonitorEnabledMsg.Show()
		endIf
	endIf
	
	if (isFrostfallRunning)
		DTEC_SettingExistingTentsWarm.SetValueInt(1)
	endIf
	
	if (PlayerRef.IsInCombat())
		; skip shelter check and watch for combat bonus
		if (IsPlayerInArmor() > 1)
			unarmoredCombatRoundsCount = 0
			playerTookHitCount = 0
		else
			;Debug.Trace(myScriptName + " player in unarmored combat round: " + unarmoredCombatRoundsCount)
			updateWaitSeconds = 9.25
			unarmoredCombatRoundsCount += 1
		endIf
		if (IsPlayerUnarmed())
			unarmCombatRounds += 1
		else
			unarmCombatRounds = 0
		endIf
	else
		; player should survive a minute (18-minute fight) or get hit
		bool unarmAward = false
 
		if (unarmoredCombatRoundsCount > 0)
			if (IsPlayerInArmor() > 1)
				; final check fail - player put on armor near end of combat
				unarmoredCombatRoundsCount = 0
			endIf
		endIf
		
		if (unarmCombatRounds >= 4)
			unarmAward = true
		endIf
		
		if (unarmoredCombatRoundsCount > 0)
			if (IsPlayerInArmor() > 1)
				; warn player -- appears like armor
				DTEC_ArmorBadMsg.Show()
				Utility.Wait(0.5)
			endIf
		endIf
		
		if (unarmoredCombatRoundsCount >= 15)
			; grant bonus for long combat
			ApplyPlayerPerkPointsUnarmedCombat(false, true)
		elseIf (unarmoredCombatRoundsCount >= 5)
			ApplyPlayerPerkPointsUnarmedCombat(false, unarmAward)
		elseIf (unarmoredCombatRoundsCount > 0 && playerTookHitCount > 0)
			;Debug.Trace(myScriptName + " applying unarmored points for getting hit; count: " + playerTookHitCount)
			ApplyPlayerPerkPointsUnarmedCombat(true, unarmAward)
		elseIf (unarmAward)
			ApplyPlayerPerkPointsUnarmedCombat(true, false)
		endIf
		unarmoredCombatRoundsCount = 0
		playerTookHitCount = 0
		unarmCombatRounds = 0
		CheckForTentShelter()
	endIf
	
	RegisterForSingleUpdate(updateWaitSeconds)
endFunction

;bool Function IsInInterior(ObjectReference objRef)
;	if objRef.IsInInterior()
;		return true
;	elseIf (Camp_WorldspacesInteriorsFL && Camp_WorldspacesInteriorsFL.HasForm(objRef.GetWorldSpace()))
;		return true
;	endIf
;	return false
;endFunction

; player can't be over encumbered, not a creature
bool Function IsPlayerAllowedRestBonus(float hoursSleep)
	if (DTEC_FatigueRefreshEnabled.GetValue() < 1.0)
		return false
	endIf
	if (PlayerRef.HasSpell(WerewolfChange))
		return false
	endIf
	if (PlayerRef.HasKeyword(ActorTypeCreature))
		return false
	endIf
	if (PlayerRef.IsOverEncumbered() || PlayerRef.IsInCombat())
		return false
	endIf
	if (DTEC_PerkRank_SleepBasic.GetValueInt() < 1)
		return false
	endIf
	float sleepHoursLim = 6.67
	
	if (hoursSleep < sleepHoursLim || hoursSleep >= 12.0)
		return false
	endIf
	
	if (DTEC_PerkRank_SleepPro.GetValueInt() >= 1)
		return true
	elseIf (IsPlayerInArmor() > 0)
		return false
	elseIf (DTEC_PerkRank_SleepBasic.GetValueInt() >= 1)
		if (IsTentOwned(CurrentWarmTent))
			if (DTEC_IsFrostfallActive.GetValueInt() < 1 && DTEC_CampfireUpdated.GetValueInt() < 1)
				return true
			elseIf (IsTentWarm(CurrentWarmTent))
				return true
			endIf
		endIf
	endIf
	
	return false
endFunction

; returns 0 for no, 2=yes, 3=magic, 4=magicEquipped
int Function IsPlayerInArmor(bool removeBadSpells = false)
	
	if (PlayerRef.WornHasKeyword(ArmorLightKY) || PlayerRef.WornHasKeyword(ArmorHeavyKY))
		if (PlayerArmorRatingZero())
			return 1
		endIf
		return 2
	endIf
	
	if (removeBadSpells)
		PlayerCheckRemoveBadSpells()
	endIf
	
	if (PlayerRef.HasMagicEffectWithKeyword(MagicArmorSpellKY))
		; !! having an armor spell equipped may cause this
		;Debug.Trace(myScriptName + " IsPlayerInArmor - has magic armor KY")
		if (PlayerArmorRatingZero())
			return 4
		endIf
		return 3
	endIf
	
	return 0
endFunction

bool Function IsPlayerWarm(bool coldOkay = false, bool displayColdMessage = true)
	bool result = true
	
	if (DTEC_IsFrostfallActive.GetValueInt() >= 1 && DTEC_CommonF.GetFrostfallRunningValue() >= 2)
		; http://skyrimsurvival.com/home/frostfall/mod-developers/frostutil-api/#FrostUtil_GetPlayerExposure
		; 1 is comfortable, 0 is warm
		int limit = 2			; cold 
		if (coldOkay)
			limit = 3			; very cold
		endIf
		if (DTEC_PerkRank_SleepPro.GetValueInt() >= 1)
			limit += 1
		endIf
		int exposureLevel = FrostUtil.GetPlayerExposureLevel()
		if (exposureLevel >= limit)
			result = false
		endIf
	; TODO: Survival - could check for cold stage effects
		
	endIf
	
	if (!result && displayColdMessage)
		; display a message!!
		DTEC_ColdMessage.Show()
	endIf
	
	return result
endFunction

bool Function IsPlayerUnarmed()
	if (PlayerRef.GetEquippedItemType(0) == 0 && PlayerRef.GetEquippedItemType(1) == 0)
		return true
	endIf
	return false
endFunction

bool Function IsTentOwned(ObjectReference tentRef)
	if (tentRef)
		Form tentForm = tentRef.GetBaseObject()
		if tentForm.HasKeyword(IsCampfireTentNoShelterKW)
			return true
		elseIf tentForm.HasKeyword(IsCampfireTentWarmKW)
			return true
		elseIf tentForm.HasKeyword(IsCampfireTentWaterProofKW)
			return true
		endIf
	endIf
	return false
endFunction

bool Function IsSearchForTentsEnabled()
	if (DTEC_IsFrostfallActive.GetValueInt() < 1 || DTEC_CommonF.GetFrostfallRunningValue() != 2)
		if (DTEC_SettingExistingTentsWarm.GetValueInt() >= 1 && DTEC_MonitorExistingTentsEnable.GetValue() >= 1.0)
			if (!CampUtil.IsRefInInterior(PlayerRef))
				return true
			endIf
		endIf
	endIf
	return false
endFunction

; Campfire tents have a keyword and Campfire lists other warm tents
;
bool Function IsTentWarm(ObjectReference tentRef)
	ObjectReference heatSource = None
	
	if (tentRef)
		float distOffset = 0.0
		bool frostfallNearFire = false
		; if Frostfall is running let's use FrostUtil to check for fire
		
		int tentRank = DTEC_PerkRank_TentWarm.GetValueInt()
		if (tentRank > 0)
			distOffset += 150.0 * tentRank
		endIf
		
		if (DTEC_IsFrostfallActive.GetValueInt() >= 1 && DTEC_CommonF.GetFrostfallRunningValue() >= 2)
			if (FrostUtil.IsPlayerNearFire() && FrostUtil.GetPlayerHeatSourceLevel() >= 2)
				;Debug.Trace("DTEC Frostfall near fire")
				frostfallNearFire = true
			endIf
		endIf
		
		Form tentForm = tentRef.GetBaseObject()
		;Debug.Trace("DTEC base tent: " + tentForm)
		
		if (DTEC_ModTentShelterList.HasForm(tentForm))
			;Debug.Trace("DTEC tent on ModTent List")
			if (frostfallNearFire)
				return true
			endIf
			heatSource = GetFireNear(tentRef, 1600.0 + distOffset)
		elseIf tentForm.HasKeyword(IsCampfireTentNoShelterKW)
			if (DTEC_PerkRank_SleepPro.GetValueInt() > 0)
				; allow outdoors with perk 
				if (frostfallNearFire)
					float dist = FrostUtil.GetPlayerHeatSourceDistance()
					if (dist < 400)
						return true
					endIf
				else
					heatSource = GetFireNear(tentRef, 396.0 + distOffset)
				endIf
			elseIf (CampUtil.IsRefInInterior(tentRef))
				; allow Campfire bed-rolls in caves
				if (frostfallNearFire)
					return true
				endIf
				heatSource = GetFireNear(tentRef, 556.0 + distOffset)
			endIf
		elseIf (frostfallNearFire)
			return true
		elseIf tentForm.HasKeyword(IsCampfireTentWarmKW)
			heatSource = GetFireNear(tentRef, 1600.0 + distOffset)	
		elseIf tentForm.HasKeyword(IsCampfireTentWaterProofKW)
			heatSource = GetFireNear(tentRef, 1024.0 + distOffset)
		elseIf Camp_WarmBaseTentsFL.HasForm(tentForm)
			heatSource = GetFireNear(tentRef, 1812.0 + distOffset)
		elseIf CampUtil.IsCurrentTentConjured()
			; only happens if conjured shelter not marked warm
			heatSource = GetFireNear(tentRef, 656.0 + distOffset)
		endIf
	endIf
	
	return heatSource as bool
endFunction

bool Function PlayerArmorRatingZero()

	float totalAC = PlayerRef.GetActorValue("DamageResist")
	if (totalAC == 0.0)
		return true
	endIf
	if (totalAC == 50.0 && PlayerRef.HasMagicEffect(doomLordDamageEffect))
		return true
	endIf

	return false
endFunction

Function PlayerCheckRemoveBadSpells()
	; these spells equipped in hand known to add MagicArmorSpellKY
	int weaponType = PlayerRef.GetEquippedItemType(1)
	if (weaponType == 9)
		Spell mainSpellEquipped = playerRef.GetEquippedSpell(1)
		if (DTEC_ArmoredBadSpellList.HasForm(mainSpellEquipped as Form))
			PlayerRef.UnequipSpell(mainSpellEquipped, 1)
		endIf
	endIf
	weaponType = PlayerRef.GetEquippedItemType(0)
	if (weaponType == 9)
		Spell secondSpellEquipped = playerRef.GetEquippedSpell(0)
		if (DTEC_ArmoredBadSpellList.HasForm(secondSpellEquipped as Form))
			PlayerRef.UnequipSpell(secondSpellEquipped, 0)
		endIf
	endIf
endFunction

Function PlayerEnteredTent(ObjectReference tentRef)
	;Debug.Trace(myScriptName + " player entered warm tent " + tentRef)
	CurrentWarmTent = tentRef
	AddTentToWarmList()
	updateWaitSeconds = 6.0
	isInTent = true
	RegisterForSleep()
	if (tentRef.HasKeyword(IsCampfireTentNoShelterKW))
		DTEC_WarmBedrollMsg.Show()
	else
		DTEC_WarmTentMsg.Show()
	endIf
	; v2 - check for magic armor reminders
	int armVal = IsPlayerInArmor(true)			; remove known bad spells
	if (armVal > 0)
		Utility.Wait(1.0)
		if (armVal >= 3)
			if (armVal >= 4)
				DTEC_WarnMagicArmorInHandMsg.Show()
			else
				DTEC_WarnMagicArmorMessage.Show()
			endIf
		endIf
	endIf
	
endFunction

Function PlayerExitedTent()
	;Debug.Trace(myScriptName + " player exited warm tent")
	RemoveTentFromWarmList()
	isInTent = false
	UnregisterForSleep()
endFunction

; these may come rapidly if attack is enchanted or magic - one for each magic effect + original
Function PlayerHitBy(ObjectReference akAggressor, Form akSource, Projectile akProjectile)
	if (akAggressor && unarmoredCombatRoundsCount > 0)
		; to save on checking for unarmored too often - round count must have started
		; let's assume player didn't swap gear between rounds
		if (akSource || akProjectile)
			playerTookHitCount += 1
		endIf
	endIf
endFunction

;
;  player stopped before meditation begins
;
Function PlayerCanceledMeditation(int rugType)
	if (rugType == 1)

		(DTEC_MagicFocusQuest as DTEC_MagicFocusQuestScript).PublicStopAll()
	endIf
endFunction

Function RemoveTentFromWarmList()
	if (CurrentWarmTent)
		if (SurvivalWarmList && SurvivalWarmList.HasForm(CurrentWarmTent.GetBaseObject()))
			SurvivalWarmList.RemoveAddedForm(CurrentWarmTent.GetBaseObject())
			;Debug.Trace(myScriptName + " removed tent from warmList size: " + SurvivalWarmList.GetSize())
			CurrentWarmTent = None
			SurvivalWarmList = None
		else
			Debug.Trace(myScriptName + " no tent to remove! " + CurrentWarmTent)
		endIf
	endIf
endFunction

Function RemSpellOnExpired()
	int i = 0
	int len = DTEC_SpellsRemOnExpiredList.GetSize()
	while (i < len)
		Spell aRemSpell = DTEC_SpellsRemOnExpiredList.GetAt(i) as Spell
		if (aRemSpell != None && PlayerRef.HasSpell(aRemSpell))
			PlayerRef.RemoveSpell(aRemSpell)
		endIf
		
		i += 1
	endWhile
endFunction

Function StartAll()
	if !self.IsRunning()
		Debug.Trace("[DTEC] StartAll quest was stopped!!!")
		if (DTEC_SettingEnabled.GetValueInt()== -2 && DTEC_ErrorQuestStopShown.GetValueInt() >= 1)
			return
		endIf
	endIf
	
	;DTECPlayerAlias.ForceRefTo(PlayerRef)
	
	if (Game.IsFightingControlsEnabled())
		DTEC_SettingEnabled.SetValueInt(1)
		updateWaitSeconds = 24.0
		;Debug.Trace(myScriptName + "StartAll")
		(DTECPlayerAlias as DTEC_PlayerAliasScript).UpdateCampfireData()
		(DTECPlayerAlias as DTEC_PlayerAliasScript).MaintainMod()
		if (checkInit < 1)
			CheckToGrantFreePerkPoints()
			CheckArmor()
			checkInit = 2
		endIf
		DTEC_AllEnabledMsg.Show()
	else
		DTEC_SettingEnabled.SetValueInt(-1)
		updateWaitSeconds = 64.0
	endIf
	
	RegisterForSingleUpdate(updateWaitSeconds)
endFunction

Function StopAll()
	StopMonitoring()
	DTEC_SettingEnabled.SetValueInt(0)
	
	; Do not stop this quest
	
	if (PlayerRef.HasSpell(DTEC_UnarmedDamageAbility))
		PlayerRef.RemoveSpell(DTEC_UnarmedDamageAbility)
	endIf
	if (PlayerRef.HasSpell(DTEC_DamageResistAbility))
		PlayerRef.RemoveSpell(DTEC_DamageResistAbility)
	endIf
	if (PlayerRef.HasSpell(DTEC_FocusSpellAb))
		PlayerRef.RemoveSpell(DTEC_FocusSpellAb)
	endIf

	Utility.Wait(1.0)
	DTEC_AllDisabledMsg.Show()
endFunction

Function StopMonitoring()
	CurrentWarmTent = None
	SurvivalWarmList = None
	isInTent = false
	isEnabled = false
	if (DTEC_NotificationEnabled.GetValue() >= 1.0)
		DTEC_MonitorDisabledMsg.Show()
	endIf
	updateWaitSeconds = 182.0
	;Debug.Trace(myScriptName + " disabled")
endFunction

Function SurvivalRecoverFatigue(int level)
	Spell drainSpell = DTEC_CommonF.GetSurvivalDrainedSpell()
	Spell tiredSpell = DTEC_CommonF.GetSurvivalTiredSpell()
	Spell refreshSpell = DTEC_CommonF.GetSurvivalRefreshedSpell()
	if (drainSpell != None && PlayerRef.HasSpell(drainSpell))
		;Debug.Notification(" remove Drain spell")
		PlayerRef.RemoveSpell(drainSpell)
		if (level >= 2 && refreshSpell != None)
			PlayerRef.AddSpell(refreshSpell, false)
		endIf
	elseIf (tiredSpell != None && PlayerRef.HasSpell(tiredSpell))
		;Debug.Notification("remove Tired spell")
		PlayerRef.RemoveSpell(tiredSpell)
		if (level >= 2 && refreshSpell != None)
			PlayerRef.AddSpell(refreshSpell, false)
		endIf
	endIf
endFunction

; not currently used
Quest property MQ101 auto