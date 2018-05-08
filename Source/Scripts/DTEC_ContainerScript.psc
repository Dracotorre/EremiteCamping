Scriptname DTEC_ContainerScript extends ObjectReference

; by DracoTorre
; for use with Eremite Camping
; 
; limits container capacity and rejects other containers

Actor property PlayerREF auto
FormList property DTEC_InvalidContainerItemsList auto

int property ContentsItemCount auto hidden
 
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	if (akSourceContainer == PlayerREF)
		ContentsItemCount += aiItemCount
		;Debug.Trace("[DTEC_ContainerScript] Added to total: " + ContentsItemCount)
		if (ContentsItemCount >= 100 || DTEC_InvalidContainerItemsList.HasForm(akBaseItem))
			RemoveItem(akBaseItem, aiItemCount, true, akSourceContainer)
		endIf
	endIf
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
  if (akDestContainer == PlayerREF)
	ContentsItemCount -= aiItemCount
	;Debug.Trace("[DTEC_ContainerScript] Removed to total: " + ContentsItemCount)
  endIf
endEvent