Scriptname PapyrusTerminal:Example04 extends PapyrusTerminal:BIOS

; Provisioner Diagnostics v0.1
; Fully working example application for the Papyrus Terminal
; custom scripting by niston

; External Dependencies (other than F4SE):
; - RenameAnything

RefCollectionAlias Property CaravanActors Auto Const
RefCollectionAlias Property Workshops Auto Const
AIPackageDescriptor[] Property AIPackageDescriptors Auto Const

Keyword kwdWorkshopLinkCaravan
Keyword kwdWorkshopLinkCaravanStart
Keyword kwdWorkshopLinkCaravanEnd
ActorValue avWorkshopRatingProvisioner
ActorValue avWorkshopActorWounded
WorkshopParentScript scrWorkshopParent

Bool bAsyncKeyRead = false
Int iAsyncResultMode = 0

Event OnPapyrusTerminalReady()

    ; initialize async related vars to defaults
    bAsyncKeyRead = false
    iAsyncResultMode = 0
   
    InsertMode = false
    LocalEcho = false

    ; load dynamic forms
    PrintLine("Loading...")        
    kwdWorkshopLinkCaravanStart = Game.GetForm(0x66eae) as Keyword
    kwdWorkshopLinkCaravanEnd = Game.GetForm(0x66eaf) as Keyword
    avWorkshopRatingProvisioner = Game.GetForm(0x249e4a) as ActorValue        
    avWorkshopActorWounded = Game.GetForm(0x33b) as ActorValue    
    kwdWorkshopLinkCaravan = Game.GetForm(0x61c0c) as Keyword
    kwdWorkshopLinkCaravanStart = Game.GetForm(0x66eae) as Keyword
    kwdWorkshopLinkCaravanEnd = Game.GetForm(0x66eaf) as Keyword
    avWorkshopRatingProvisioner = Game.GetForm(0x249e5a) as ActorValue        
    avWorkshopActorWounded = Game.GetForm(0x33b) as ActorValue
    scrWorkshopParent = Game.GetForm(0x2058E) as WorkshopParentScript
    
    ; show provisioner list
    NaviProvisionerListFirst()
EndEvent

Event OnPapyrusTerminalShutdown()
    ; if you get this event, the terminal has shut down (user left holotape with tab, ctrl-c or by some other means)
    ; your script should unregister for all events and perform any necessary clean-up duty upon receiving this event,
    ; so that it may terminate properly.
    ; NOTE: The Terminal is already gone when this event occurs.
    ; DO NOT interact with the terminal in this event handler, or suffer a CTD!

    kwdWorkshopLinkCaravan = none
    kwdWorkshopLinkCaravanStart = none
    kwdWorkshopLinkCaravanEnd = none
    avWorkshopRatingProvisioner = none
    avWorkshopActorWounded = none
    kwdWorkshopLinkCaravanStart = none
    kwdWorkshopLinkCaravanEnd = none
    avWorkshopRatingProvisioner = none
    avWorkshopActorWounded = none
    scrWorkshopParent = none    
EndEvent



; ##########################
; #### PROVISIONER LIST ####
; ##########################

Function MenuProvisionerList(Int startIndex)
    ; prepare screen
    ClearHome()
    PrintProgramHeader()
    PrintProvisionerListHeader()    
    
    ; generate list view
    Int lastIndex = PrintProvisionerListEntries(startIndex)        
    Int listHeight = TerminalRows - 6

    ; prompt user
    PrintLine("")
    PrintField("# Provisioner number, [n]ext/[p]rev or Ctrl-C to quit.", FIELDSIZE_TOEOL, ALIGNMENT_LEFT)
    Print("> ")
    
    ; read from keyboard
    String pgOption = ReadLine(3)

    ; process user input
    If (StringIsNumeric(pgOption))
        ; entered a number, assume provisioner index and sanitize
        Int provisionerIndex = pgOption as Int
        If (provisionerIndex < 0)
            provisionerIndex = 0
        EndIf
        If (provisionerIndex > CaravanActors.GetCount() - 1)
            provisionerIndex = CaravanActors.GetCount() - 1
        EndIf
        ; show details menu for selcted provisioner
        NaviProvisionerDetails(CaravanActors.GetAt(provisionerIndex) as ObjectReference)
    Else
        If (pgOption == "F")                
            NaviProvisionerListFirst()
        ElseIf (pgOption == "L")
            NaviProvisionerListLast(listHeight)
        ElseIf (pgOption == "P")
            NaviProvisionerListPrevious(startIndex, listHeight)
        ElseIf (pgOption == "N")
            NaviProvisionerListNext(startIndex, listHeight)
        ElseIf (pgOption == "C")
            NaviProvisionerListContinue(lastIndex)
        Else
            ; refresh current page
            NaviProvisionerList(startIndex)
        EndIf
    EndIf
EndFunction

; print provisioner list entries
Int Function PrintProvisionerListEntries(Int startIndex)
    Int i = startIndex
    String listEntry = ""
    String entryWarnings = ""
    ObjectReference refProvisioner = none
    ; DEV NOTE: Async Read works with unpaused holotape terminal menu only
    iAsyncResultMode = 1
    bAsyncKeyRead = false
    ReadKeyAsyncBegin()
    While (i < CaravanActors.GetCount() && !IsTerminalShutdown && !bAsyncKeyRead && !PageFull(3))                
        refProvisioner = CaravanActors.GetAt(i) as ObjectReference   
        entryWarnings = GetProvisionerWarningFlags(refProvisioner)
        If (entryWarnings != "--------")
            ColorTxt = COLOR_WHITE
            ColorBgr = COLOR_RED
        EndIf
        PrintField(i, 3, ALIGNMENT_RIGHT)
        Print("  ")
        PrintField(GetProvisionerRoute(refProvisioner), TerminalColumns - 15, ALIGNMENT_LEFT)
        Print("  ")
        Print(entryWarnings)
        ColorTxt = COLOR_SYSTEM
        ColorBgr = COLOR_SYSTEM
        i += 1
    EndWhile
    ; handle async read
    If (bAsyncKeyRead)
        ; key pressed, listing interrupted
        PrintLine("# Listing interrupted.")
    Else
        ; cancel pending async read if no key was pressed
        ReadAsyncCancel()
        ; sleep required to clear readasync state when holotape menu is NOT unpaused
        ;Sleep(0.1)
    EndIf
    iAsyncResultMode = 0
    bAsyncKeyRead = false
    ; correct printed entries count
    If (i > startIndex)
        i -= 1
    EndIf
    Return i
EndFunction    

Event OnPapyrusTerminalReadAsyncCompleted(String readBuffer)
    If (iAsyncResultMode == 1)
        bAsyncKeyRead = true
    EndIf
EndEvent

Function NaviProvisionerList(int startIndex)
    Dispatch("MenuProvisionerList", startIndex)
EndFunction

Function NaviProvisionerListFirst()
    Dispatch("MenuProvisionerList", 0)
EndFunction

Function NaviProvisionerListLast(int listHeight)
    Int lastPageStartIndex = CaravanActors.GetCount() - listHeight
    Dispatch("MenuProvisionerList", lastPageStartIndex)
EndFunction

Function NaviProvisionerListContinue(int currentLastIndex)
    Int nextStartIndex = currentLastIndex + 1
    If (nextStartIndex > CaravanActors.GetCount() - 1)
        nextStartIndex = CaravanActors.GetCount() - 1
    EndIf
    Dispatch("MenuProvisionerList", nextStartIndex)
EndFunction

Function NaviProvisionerListNext(int currentFirstIndex, int listHeight)    
    Int nextStartIndex = currentFirstIndex + listHeight
    If (nextStartIndex > CaravanActors.GetCount() - 1)
        nextStartIndex = CaravanActors.GetCount() - 1
    EndIf
    Dispatch("MenuProvisionerList", nextStartIndex)
EndFunction

Function NaviProvisionerListPrevious(int currentFirstIndex, int listHeight)
    Int nextStartIndex = currentFirstIndex - listHeight
    If (nextStartIndex < 0)
        nextStartIndex = 0
    EndIf
    Dispatch("MenuProvisionerList", nextStartIndex)
EndFunction

Function PrintProvisionerListHeader()    
    PrintField("No.  Route", TerminalColumns - 8, ALIGNMENT_LEFT)
    PrintLine("Warnings")
    PrintSeparator()
    ;Print("------------------------------------------------------------------------")
EndFunction 

; #############################
; #### PROVISIONER DETAILS ####
; #############################

Function MenuProvisionerDetails(ObjectReference refProvisioner)
    ; prepare screen
    ClearHome()
    PrintProgramHeader()

    ; local vars
    Actor actProvisioner = refProvisioner as Actor
    Location lctRouteOrigin = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanStart).GetCurrentLocation()
    Location lctRouteDest = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanEnd).GetCurrentLocation()    
    Form frmXMarker = Game.GetForm(0x3b)
    ObjectReference refPosMarker = none

    String strWarningFlags = GetProvisionerWarningFlags(refProvisioner)

    PrintLine("Details for Provisioner #" + CaravanActors.Find(refProvisioner))
    PrintSeparator()
    PrintField("Name: " + refProvisioner.GetDisplayName(), TerminalColumns - 20, ALIGNMENT_LEFT)
    Print("  ")
    If (strWarningFlags != "--------")
        ColorBgr = COLOR_RED
        ColorTxt = COLOR_WHITE
    EndIf
    PrintField("Warnings: " + strWarningFlags, TerminalColumns - 54, ALIGNMENT_RIGHT)    
    ColorTxt = COLOR_SYSTEM
    ColorBgr = COLOR_SYSTEM
    Print("From: ")
    PrintField(GetLocationName(lctRouteOrigin), TerminalColumns - 6, ALIGNMENT_LEFT)
    Print("  To: ")
    PrintField(GetLocationName(lctRouteDest), TerminalColumns - 6, ALIGNMENT_LEFT)    
    PrintLine()
    PrintLine("       IDs: " + GetFormIDStr(refProvisioner as Form) + " (Reference), " + GetFormIDStr(actProvisioner.GetBaseObject()) + " (Base)")
    PrintLine("      Race: " + actProvisioner.GetRace().GetName() + " (" + GetFormIDStr(actProvisioner.GetRace()) + ")")
    PrintLine("  Workshop: " + GetWorkshopInfo(refProvisioner))        
    PrintLine("     Flags: " + GetActorFlags(actProvisioner))
    ;PrintLine("       AVs: " + GetActorValues(actProvisioner))
    PrintLine("      Line: " + GetSupplyLineStatus(lctRouteOrigin, lctRouteDest))        
    PrintLine("AI Package: " + GetCurrentAIPackageName(actProvisioner))
    PrintLine("  Location: " + GetLocationDescription(refProvisioner)) 
    PrintLine("Pos. X/Y/Z: " + refProvisioner.GetPositionX() + " / " +  refProvisioner.GetPositionY() + " / " + refProvisioner.GetPositionZ())    
    PrintLine()
    Int optionRow = CursorPositionRow
    PrintLine("Options: ")
    PrintLine("  [R] : Reset AI             [C] : Cycle Alias         [S] : Summon")                
    PrintLine("  [M] : Show OMods           [I] : Inventory           [K] : Kill")
    PrintLine("  [U] : Update Display       [T] : Trade               [N] : Rename")
    PrintLine("  [X] : Back to Provisioner List")
    String selectedOption = ReadKey()    
    CursorMove(optionRow,1)
    Erase(ERASE_EOS)
    int i = 0
    If (selectedOption == "x")
        NaviProvisionerList(CaravanActors.Find(refProvisioner))
    ElseIf (selectedOption == "i")
        ; INVENTORY
        CursorMove(2,0)
        Erase(ERASE_EOS)
        PrintLine("Inventory for Provisioner #" + CaravanActors.Find(refProvisioner))
        PrintSeparator()
        Form[] inventoryItems = refProvisioner.GetInventoryItems()
        i = 0
        While (i < inventoryItems.Length && !IsTerminalShutdown)
            PrintField(i, 2, ALIGNMENT_RIGHT)
            Print("  ")
            PrintLine(refProvisioner.GetItemCount(inventoryItems[i]) + "x " + inventoryItems[i].GetName() + " (ID" + GetFormIDStr(inventoryItems[i]) + ")")
            i += 1
        EndWhile
        PrintLine()
        PrintLine("# SPACE to return to details view, Ctrl-C to quit.")
        ReadKey()
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "u")
        ; UPDATE DISPLAY
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "r")
        ; RESET AI
        Print("# Resetting Actor AI... ")  
        ; remember where they are
        refPosMarker = refProvisioner.PlaceAtMe(frmXMarker, 1, true, false, false)
        ; move them to us so they are fully loaded
        refProvisioner.MoveTo(Game.GetPlayer())
        ; reset AI
        actProvisioner.EvaluatePackage(true)
        Sleep(1.0)
        ; send them back to where they were
        refProvisioner.MoveTo(refPosMarker)
        Sleep(0.1)
        ; clean up
        refPosMarker.Delete()
        Print("OK.")
        Sleep(1.0)
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "s")
        Print("# Summoning Provisioner to Player position... ")
        refProvisioner.MoveTo(Game.GetPlayer())
        Print("OK.")
        Sleep(1.0)
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "k")
        Print("? Kill Provisioner - Sure (Y/N)")
        If (ReadKey() == "y")
            PrintLine("Y")
            Print("# Killing provisioner...")
            ; unassign them for good measure and remove them from their workshop, if any (thanks SKK50)
            If  (refProvisioner Is WorkshopNPCScript) && ((refProvisioner As WorkshopNPCScript).GetWorkshopID() > -1)
                scrWorkshopParent.UnassignActor((refProvisioner as WorkshopNPCScript), bRemoveFromWorkshop = true, bSendUnassignEvent = true)
            EndIf
            ; unlink their supply line, if it still persists
            ; kill them dead, even if essential/protected
            actProvisioner.KillEssential()
            Sleep(1.0)
            ; get rid of their dead body
            actProvisioner.Disable()
            actProvisioner.Delete()            
            Print("OK.")
            Sleep(1.0)
            NaviProvisionerListFirst()
        Else
            NaviProvisionerDetails(refProvisioner)
        EndIf
    ElseIf (selectedOption == "c")
        Print("# Cycling CaravanActor Alias Membership... ")            
        ; remember where they were
        refPosMarker = refProvisioner.PlaceAtMe(frmXMarker, 1, true, false, false)
        ; move them to us so they are fully loaded
        refProvisioner.MoveTo(Game.GetPlayer())
        ; remove from CaravanActors alias
        CaravanActors.RemoveRef(refProvisioner)
        ; reset AI
        actProvisioner.EvaluatePackage(true)
        Sleep(2.0)
        ; add them to CaravanActors alias
        CaravanActors.AddRef(refProvisioner)
        ; reset AI again
        actProvisioner.EvaluatePackage(true)
        Sleep(2.0)
        ; send them back to where they came from
        refProvisioner.MoveTo(refPosMarker)
        Sleep(0.1)
        ; clean up
        refPosMarker.Delete()
        PrintLine("OK.")
        Sleep(1.0)
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "m")
        CursorMove(2,0)
        Erase(ERASE_EOS)
        PrintLine("OMods List for Provisioner #" + CaravanActors.Find(refProvisioner))
        PrintSeparator()
        ;Print("------------------------------------------------------------------------")
        ObjectMod[] aryMods = refProvisioner.GetAllMods()
        While (i < aryMods.Length && !IsTerminalShutdown)
            PrintField(i, 2, ALIGNMENT_RIGHT)
            Print(" ")
            PrintLine(aryMods[i].GetName() + " (" + GetFormIDStr(aryMods[i]) + ") ")
            i += 1
        EndWhile
        PrintLine()
        PrintLine("# SPACE to return to details view, Ctrl-C to quit.")
        ReadKey()
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "t")
        Print("# Opening actor container...")
        ; prevent quit on TAB press (so the inventory window may be closed without quitting the application at the same time)
        QuitOnTABEnabled = false
        ; enable mouse pointer (currently broken for some reason)
        MousePointerEnabled = true
        ExecuteConsoleCommand(GetFormIDStr(refProvisioner as Form) + ".OpenActorContainer 1")
        Sleep(0.1)
        PrintLine("OK.")        
        Print("# SPACE to return to details view, Ctrl-C to quit.")
        ReadKey()
        ; disable mouse pointer
        MousePointerEnabled = true
        ; re-enable quit on TAB press
        QuitOnTABEnabled = true
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "n")
        ; RENAME PROVISIONER
        PrintLine("# Rename Provisioner")
        PrintLine("? Enter new name; Empty name to cancel renaming.")
        Print ("> ")        
        ; read name from keyboard (up to 64 chars length)
        String newName = ReadLine(64)        
        PrintLine()
        If (newName != "")
            Print("# Attempting rename...")
            RenameAnything.SetRefName(refProvisioner, newName)
            If (RenameAnything.GetRefName(refProvisioner) == newName)
                PrintLine("OK.")
            Else
                PrintLine("Failed.")
            EndIf
            Sleep(1.0)
        EndIf        
        NaviProvisionerDetails(refProvisioner)
    ElseIf (selectedOption == "v")
        ; Toggle WorkshopRatingProvisioner AV
        PrintLine("# Toggle WorkshopRatingProvisioner ActorValue")
        Print("? Permanent Change - Are you sure (Y/N) ")
        string toggleSure = ReadKey()
        If (toggleSure == "y")
            PrintLine("Y")
            PrintLine("# Toggling value...")
            Float oldVal = actProvisioner.GetValue(avWorkshopRatingProvisioner)
            If (oldVal == 0.0)
                actProvisioner.SetValue(avWorkshopRatingProvisioner, 1.0)
            Else
                actProvisioner.SetValue(avWorkshopRatingProvisioner, 0.0)
            EndIf    
            PrintLine("OK.")
        Else
            PrintLine("N")            
        EndIf
        NaviProvisionerDetails(refProvisioner)
    ; Incomplete and left as an exercise to the so inclined reader
    ;/ ElseIf (selectedOption == "b")
        Print("# Rebuilding Actor...")
        ; remember where they were
        refPosMarker = refProvisioner.PlaceAtMe(frmXMarker, 1, true, false, false)
        ActorBase actbProvisioner = actProvisioner.GetActorBase()
        Race origRace = actProvisioner.GetRace()
        Keyword[] origKeywords = refProvisioner.GetKeywords()     
        ObjectMod[] origOMods = refProvisioner.GetAllMods()       
        ObjectReference refClone = Game.GetPlayer().PlaceAtMe(actbProvisioner, 1, false, false, false)
        Actor actClone = refClone as Actor
        i = 0
        While (i < origOMods.Length)
            refClone.AttachMod(origOMods[i])
            i += 1
        EndWhile
        ;actClone.SetProtected(true)    

        Int workshopId = (refProvisioner as WorkshopNPCScript).GetWorkshopID()
        ObjectReference refHomeWorkshop = scrWorkshopParent.GetWorkshop(workshopID)
        scrWorkshopParent.AddActorToWorkshopPUBLIC(refClone as Actor, refHomeWorkshop as WorkshopScript)

        ; clean up
        refPosMarker.Delete()
        Print("OK.")
        ReadKey()
        ChangeState("ProvisionerDetailsPage_Refresh")            
/;
    Else
        If (!IsTerminalShutdown)
            NaviProvisionerDetails(refProvisioner)
        EndIf
    EndIf        
EndFunction

Function NaviProvisionerDetails(ObjectReference refProvisioner)
    If (!IsTerminalShutdown)
        var[] parms = new var[1]
        parms[0] = refProvisioner
        CallFunctionNoWait("MenuProvisionerDetails", parms)
    EndIf
EndFunction


; ##########################
; #### SHARED FUNCTIONS ####
; ##########################

Function PrintProgramHeader()
    ;ReverseMode = true    
    ColorTxt = COLOR_YELLOW
    ColorBgr = COLOR_BLUE
    String genInfo = scrWorkshopParent.Workshops.Length + " Workshops / " + CaravanActors.GetCount() + " Provisioners"
    Print("Provisioner Diagnostics v0.1  ")
    PrintField(genInfo, TerminalColumns - (CursorPositionColumn - 1), ALIGNMENT_RIGHT)
    ColorTxt = COLOR_SYSTEM
    ColorBgr = COLOR_SYSTEM
EndFunction

Function PrintSeparator()
    PrintLine(StringRepeat("-", TerminalColumns))
EndFunction

Bool Function PageFull(Int linesToPrint)
    If (CursorPositionRow + linesToPrint > TerminalRows)
        Return true
    EndIf
    Return false
EndFunction

String Function GetActorValues(Actor actActor)
    String avString = ""
    If (actActor.GetValue(avWorkshopRatingProvisioner) > 0)
        avString = "WorkshopRatingProvisioner"
    EndIf
    If (avString == "")
        avString = "<None>"
    EndIf
    Return avString
EndFunction

String Function GetActorFlags(Actor actActor)
    String flagsString = ""
    If (actActor.IsEssential())
        flagsString = AppendWith(flagsString, "IsEssential")
    EndIf
    If (actActor.GetActorBase().IsProtected())
        flagsString = AppendWith(flagsString, "IsProtected (Base)")
    EndIf
    If ((actActor as CompanionActorScript) != none)
        flagsString = AppendWith(flagsString, "HasCompanionActorScript")
    EndIf
    If (actActor.IsInCombat())
        flagsString = AppendWith(flagsString, "IsInCombat")
    EndIf
    If (flagsString == "")
        flagsString = "<None>"
    EndIf
    Return flagsString
EndFunction

String Function AppendWith(string sourceString, string appendString, string appendWithPrefix = ", ")
    If (sourceString == "")
        Return appendString
    Else
        Return sourceString + appendWithPrefix + appendString
    EndIf
EndFunction

String Function GetLocationText(ObjectReference refProvisioner)
    String provLocation = refProvisioner.GetCurrentLocation()
    String provWorldspace = refProvisioner.GetWorldSpace().GetName()

    If (provLocation != provWorldspace)        
        Return provLocation + " (" + provWorldspace + ")"
    Else
        Return provWorldspace
    EndIf
EndFunction

String Function GetSupplyLineStatus(Location lctOrigin, Location lctDestination)
    Bool locationsLinked = lctOrigin.IsLinkedLocation(lctDestination, kwdWorkshopLinkCaravan)
    If (locationsLinked)
        Return "Route Locations Linked"
    Else
        
        Return "Route Locations Not Linked"
    EndIf
EndFunction

String Function GetWorkshopInfo(ObjectReference refProvisioner)
    If (refProvisioner != none)
        If (refProvisioner as WorkshopNPCScript)        
            Int workshopId = (refProvisioner as WorkshopNPCScript).GetWorkshopID()
            ObjectReference refWorkshop = scrWorkshopParent.GetWorkshop(workshopID)
            If (refWorkshop != none)
                Location lctWorkshopLocation = refWorkshop.GetCurrentLocation()
                If (lctWorkshopLocation != none)
                    String strWorkshopLocName = lctWorkshopLocation.GetName()
                    If (strWorkshopLocName != "")
                        Return strWorkshopLocName + " (" + GetFormIDStr(refWorkshop)  + ")"
                    Else
                        Return "<Unnamed Location> (" + GetFormIDStr(refWorkshop) + ")"
                    EndIf
                Else
                    Return "<Location is None> + (" + GetFormIDStr(refWorkshop) + ")"
                EndIf
                Return scrWorkshopParent.GetWorkshop(workshopID)
            Else
                Return "<WorkshopId (" + workshopId + ") does not exist in workshop array>"
            EndIf
        Else
            Return "<Actor has no WorkshopNPCScript>"
        EndIf
    Else
        Return "<Provisioner is None>"
    EndIf
EndFunction

String Function YesNoBool(Bool value)
    If (value)
        Return "Yes"
    Else
        Return "No"
    EndIf
EndFunction

String Function GetLocationDescription(ObjectReference refProvisioner)
    String locName = GetLocationName(refProvisioner.GetCurrentLocation())
    String wsName = refProvisioner.GetWorldSpace().GetName()
    If (locName == wsName)
        Return wsName
    Else
        Return locName + " (" + wsName + ")"
    EndIf
EndFunction

String Function GetWorldspaceName(ObjectReference refObject)
    If (refObject.GetWorldSpace() == none)
        Return "<No Worldspace>"
    Else
        Return "(" + refObject.GetWorldSpace().GetName() + ")"
    EndIf
EndFunction

String Function GetLocationName(Location lctCaravan)
    If (lctCaravan == none)
        Return "<Location is none>"
    Else
        String locName = lctCaravan.GetName()
        If (locName == "")
            Return "<Unnamed Location>"
        Else
            Return locName
        EndIf
    EndIf
EndFunction

String Function FormatRefInfo(String referenceInfo)
    referenceInfo = StringReplace(referenceInfo, "[", "")
    referenceInfo = StringReplace(referenceInfo, " <", " ")
    referenceInfo = StringReplace(referenceInfo, ">]", "")
    Return referenceInfo
EndFunction

String Function GetProvisionerRoute(ObjectReference refProvisioner)
    Location lctRouteOrigin = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanStart).GetCurrentLocation()
    Location lctRouteDest = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanEnd).GetCurrentLocation()
    Return lctRouteOrigin.GetName() + " > " + lctRouteDest.GetName()
EndFunction

String Function GetProvisionerWarningFlags(ObjectReference refProvisioner)
    Bool wAIPackage = false
    Bool wOrigin = false
    Bool wDestination = false
    Bool wWounded = false
    Bool wBleedout = false
    Bool wDead = false
    Bool wUnconscious = false
    Bool wSupplyLine = false
    Bool wProvisionerActorValue = false

    Actor actProvisioner = refProvisioner as Actor
    ObjectReference refOriginMarker = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanStart)
    ObjectReference refDestMarker = refProvisioner.GetLinkedRef(kwdWorkshopLinkCaravanEnd)
    Location lctCaravanOrigin = refOriginMarker.GetCurrentLocation()    
    Location lctCaravanDestination = refDestMarker.GetCurrentLocation()

    String strOriginLocName = lctCaravanOrigin.GetName()
    String strOriginWsName
    If (refOriginMarker.GetWorldSpace() != none)
        strOriginWsName = refOriginMarker.GetWorldSpace().GetName()
    EndIf
    String strDestLocName = lctCaravanDestination.GetName()    
    String strDestWsName 
    If (refDestMarker.GetWorldSpace() != none)
        strDestWsName = refDestMarker.GetWorldSpace().GetName()
    EndIf
    
    wAIPackage = ((!CheckPackage(actProvisioner.GetCurrentPackage())) || (!actProvisioner.IsAIEnabled()))
    wOrigin = ((refOriginMarker == none) || (lctCaravanOrigin == none) && (strOriginLocName == strOriginWsName))
    wDestination = ((refDestMarker == none) || (lctCaravanDestination == none) || (strDestLocName == strDestWsName))
    wWounded = (actProvisioner.GetValue(avWorkshopActorWounded) > 0)      
    wBleedout = actProvisioner.IsBleedingOut()
    wDead = actProvisioner.IsDead()
    wUnconscious = actProvisioner.IsUnconscious()
    wSupplyLine = !(lctCaravanOrigin.IsLinkedLocation(lctCaravanDestination, kwdWorkshopLinkCaravan))
    ;wProvisionerActorValue = (actProvisioner.GetValue(avWorkshopRatingProvisioner) == 0.0)

    String retVal = ""
    If (wAIPackage)
        retVal += "A"
    Else
        retVal += "-"
    EndIf
    If (wOrigin)
        retVal += "O"
    Else
        retVal += "-"
    EndIf
    If (wDestination)
        retVal += "D"
    Else
        retVal += "-"
    EndIf
    If (wWounded)
        retVal += "W"
    Else
        retVal += "-"
    EndIf
    If (wBleedout)
        retVal += "B"
    Else
        retVal += "-"         
    EndIf
    If (wUnconscious)      
        retVal += "U"
    Else
        retVal += "-"         
    EndIf
    If (wDead)
        retVal += "X"
    Else
        retVal += "-"
    EndIf
    ;If (wProvisionerActorValue)
    ;    retVal += "V"
    ;Else
    ;    retVal += "-"
    ;EndIf
    If (wSupplyLine)
        retVal += "L"
    Else
        retVal += "-"
    EndIf
    return retVal
EndFunction

String Function GetCurrentAIPackageName(Actor actProvisioner)
    If (actProvisioner.IsAIEnabled())
        Return ResolveAIPackageName(actProvisioner.GetCurrentPackage())
    Else
        Return "<AI is currently disabled>"
    EndIf
EndFunction

String Function ResolveAIPackageName(Package aiPackage)
    Int i = 0
    AIPackageDescriptor curDescr = none
    While ((i < AIPackageDescriptors.Length) && !IsTerminalShutdown)
        curDescr = AIPackageDescriptors[i]
        If (curDescr.AIPackage == aiPackage)
            Return curDescr.PackageName
        EndIf        
        i += 1
    EndWhile
    Return aiPackage
EndFunction

String Function GetFormIDStr(Form frmObject)
    String refInfo = frmObject
    Int startBracketPos = StringLastIndexOf(refInfo, "(")
    If (startBracketPos > -1)
        String idPart = StringSubstring(refInfo, startBracketPos + 1)
        idPart = StringReplace(idPart, ")>]", "")
        Return idPart
    Else
        Return refInfo
    EndIf
EndFunction

Bool Function CheckPackage(Package aiPackage)
    Int i = 0
    AIPackageDescriptor curDescr = none
    While (i < AIPackageDescriptors.Length && !IsTerminalShutdown)
        curDescr = AIPackageDescriptors[i]
        If (curDescr.AIPackage == aiPackage)
            Return curDescr.PackageOK
        EndIf        
        i += 1
    EndWhile
    Return False
EndFunction

Struct AIPackageDescriptor
    Package AIPackage
    String PackageName
    Bool PackageOK
EndStruct