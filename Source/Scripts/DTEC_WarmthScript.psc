Scriptname DTEC_WarmthScript extends activemagiceffect  

GlobalVariable property DTEC_IsFrostfallActive auto

Event OnEffectStart(actor akTarget, actor akCaster)
	if (DTEC_IsFrostfallActive.GetValueInt() >= 1)
		if (DTEC_CommonF.GetFrostfallRunningValue() == 2)
			; bump warmth
			FrostUtil.ModPlayerExposure(-30.0)
		endIf
	endIf
EndEvent