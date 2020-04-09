Scriptname DTEC_VendorStockScript extends Quest
; based on Chesko's _Camp_VendorStock 

; this script is used for main Eremite and the EremiteLite Campfire patch
; DTEC_VendorStockEnabled should be 2 or greater for the main mod

; merchant
ReferenceAlias property SolitudeBitsAndPiecesChestAlias auto			; used for patch Campfire bug
ObjectReference property MerchantSolitudeBitsAndPiecesChestRef auto		; used for patch

; our main mod merchants
ReferenceAlias property MarkarthHagsCureChestAlias auto
ObjectReference property MerchantMarkarthHagsCureChestRef auto

ReferenceAlias property WCollegeTolfdirChestAlias auto
ObjectReference property MerchantWCollegeTolfdirChestRef auto

GlobalVariable property DTEC_VendorStockEnabled auto			; check this 2+ for our store items and 1+ to keep updating

; fix for Campfire bug: items continually increasing count
Armor property _Camp_Backpack_Black auto
Armor property _Camp_Backpack_White auto
Armor property _Camp_Cloak_BasicFur auto

; my items
MiscObject property DTEC_AlchemyRetortBurnSet auto
Book property DTEC_SpellTomeWaterWalk auto
Book property DTEC_SpellTomeIceShell auto


Event OnInit()
	
	RegisterForSingleUpdate(15.0)
	
endEvent

Event OnUpdate()

	;Stock items
	FillAllAliases()
	Utility.Wait(3.0)
	UpdateVendorItems()
	
	if (DTEC_VendorStockEnabled.GetValueInt() >= 1)
		RegisterForSingleUpdateGameTime(24)
	else
	
		self.Stop()
	endIf
endEvent

Event OnUpdateGameTime()

	UpdateVendorItems()
	
	RegisterForSingleUpdateGameTime(24)
	
endEvent

Function UpdateVendorItems()
    
	;Clear the alias
	ClearAllAliases()
	
	;Remove any items found in any of the chests listed
	RemoveAllModItems()
	
	;Re-fill the alias
	FillAllAliases()
	
endFunction

Function ClearAllAliases()
	SolitudeBitsAndPiecesChestAlias.Clear()
endFunction

Function FillAllAliases()
	; we only fill our main mod items
	if (DTEC_VendorStockEnabled.GetValueInt() >= 2)
		SolitudeBitsAndPiecesChestAlias.ForceRefIfEmpty(MerchantSolitudeBitsAndPiecesChestRef)
		
		; check player skill and not none to add spellbooks - not currently using illusion spells
		float altSkill = Game.GetPlayer().GetActorValue("Alteration")
		if (altSkill >= 50.0 && WCollegeTolfdirChestAlias != None)
			WCollegeTolfdirChestAlias.ForceRefIfEmpty(MerchantWCollegeTolfdirChestRef)
		endIf
	endIf
endFunction

Function RemoveAllModItems()

	; remove bugged backpacks first
	RemoveItemFromVendor(_Camp_Backpack_Black, MerchantSolitudeBitsAndPiecesChestRef, false)
	RemoveItemFromVendor(_Camp_Backpack_White, MerchantSolitudeBitsAndPiecesChestRef, false)
	RemoveItemFromVendor(_Camp_Cloak_BasicFur, MerchantSolitudeBitsAndPiecesChestRef, false)
	
	; check our main mod and make sure not None just in case
	if (DTEC_VendorStockEnabled.GetValueInt() >= 2)
		if (DTEC_AlchemyRetortBurnSet != None)
			RemoveItemFromVendor(DTEC_AlchemyRetortBurnSet, MerchantSolitudeBitsAndPiecesChestRef)
			RemoveItemFromVendor(DTEC_AlchemyRetortBurnSet, MerchantMarkarthHagsCureChestRef)
		endIf
		
		if (DTEC_SpellTomeWaterWalk != None)
			RemoveItemFromVendor(DTEC_SpellTomeWaterWalk, MerchantWCollegeTolfdirChestRef)
		endIf
		if (DTEC_SpellTomeIceShell != None)
			RemoveItemFromVendor(DTEC_SpellTomeIceShell, MerchantWCollegeTolfdirChestRef)
		endIf
	endIf

endFunction

Function RemoveItemFromVendor(Form akItem, ObjectReference akContainer, bool allItems = true)
	int itemCount = akContainer.GetItemCount(akItem)
	if (itemCount > 0)
		if (allItems)
			akContainer.RemoveItem(akItem, itemCount)
		elseIf (itemCount > 1)
			akContainer.RemoveItem(akItem, itemCount - 1)
		endIf
	endif
endFunction