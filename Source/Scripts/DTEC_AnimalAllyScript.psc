Scriptname DTEC_AnimalAllyScript extends ActiveMagicEffect 

Faction property DTEC_BeastAllyFaction auto
Faction property BearFaction auto
Faction property WolfFaction auto
Faction property SabreCatFaction auto
Message property DTEC_AnimalAllyEndMessage auto
Message property DTEC_AnimalAllyStartMessage auto
GlobalVariable property DTEC_NotificationsEnabled auto

Event OnEffectStart(actor akTarget, actor akCaster)
	DTEC_BeastAllyFaction.SetAlly(WolfFaction)
	DTEC_BeastAllyFaction.SetAlly(BearFaction)
	DTEC_BeastAllyFaction.SetAlly(SabreCatFaction)
	akCaster.AddToFaction(DTEC_BeastAllyFaction)
	
	if (DTEC_AnimalAllyStartMessage != None && DTEC_NotificationsEnabled != None)
		if (DTEC_NotificationsEnabled.GetValueInt() >= 1)
			DTEC_AnimalAllyStartMessage.Show()
		endIf
	endIf
EndEvent

Event OnEffectFinish(actor akTarget, actor akCaster)
	akCaster.RemoveFromFaction(DTEC_BeastAllyFaction)
	
	if (DTEC_AnimalAllyEndMessage != None && DTEC_NotificationsEnabled != None)
		if (DTEC_NotificationsEnabled.GetValueInt() >= 1)
			DTEC_AnimalAllyEndMessage.Show()
		endIf
	endIf
EndEvent
