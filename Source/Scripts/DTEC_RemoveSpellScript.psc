Scriptname DTEC_RemoveSpellScript extends ActiveMagicEffect  

; removes spell on casting

Spell property SpellToRemoveProperty auto


Event OnEffectStart(actor akTarget, actor akCaster)

	if (SpellToRemoveProperty != None)

		akCaster.RemoveSpell(SpellToRemoveProperty)
	endIf
EndEvent
