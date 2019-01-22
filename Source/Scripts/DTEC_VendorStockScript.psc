Scriptname DTEC_VendorStockScript extends Quest
; based on Chesko's _Camp_VendorStock  

; merchant
ReferenceAlias property SolitudeBitsAndPiecesChestAlias auto
ObjectReference property MerchantSolitudeBitsAndPiecesChestRef auto

GlobalVariable property DTEC_VendorStockEnabled auto

; fix for Campfire bug: items continually increasing count
Armor property _Camp_Backpack_Black auto
Armor property _Camp_Backpack_White auto
Armor property _Camp_Cloak_BasicFur auto

; my items
MiscObject property DTEC_AlchemyRetortBurnSet auto


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
	if (DTEC_VendorStockEnabled.GetValueInt() >= 2)
		SolitudeBitsAndPiecesChestAlias.ForceRefIfEmpty(MerchantSolitudeBitsAndPiecesChestRef)
	endIf
endFunction

Function RemoveAllModItems()

	RemoveItemFromVendor(_Camp_Backpack_Black, MerchantSolitudeBitsAndPiecesChestRef, false)
	RemoveItemFromVendor(_Camp_Backpack_White, MerchantSolitudeBitsAndPiecesChestRef, false)
	RemoveItemFromVendor(_Camp_Cloak_BasicFur, MerchantSolitudeBitsAndPiecesChestRef, false)
	if (DTEC_VendorStockEnabled.GetValueInt() >= 2 && DTEC_AlchemyRetortBurnSet != None)
		RemoveItemFromVendor(DTEC_AlchemyRetortBurnSet, MerchantSolitudeBitsAndPiecesChestRef)
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