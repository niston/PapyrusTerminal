Scriptname PapyrusTerminal:BIOS extends PapyrusTerminal:KERNAL Hidden

; Papyrus Terminal Color BIOS - Base Class
; This is the code layer that allows your Papyrus Scripts to interact with the Papyrus Terminal Scaleform application
; Derive from this base class to implement your Papyrus Terminal programs. See Example Holotapes for example usage :)

; custom scripting by niston & Scrivener07


; internal constants, do not mess with
string TerminalReadyEvent = "PapyrusTerminal:ReadyEvent" const
string TerminalShutdownEvent = "PapyrusTerminal:ShutdownEvent" const
string ReadAsyncCancelledEvent = "PapyrusTerminal:ReadAsyncCancelledEvent" const
string ReadAsyncResultEvent = "PapyrusTerminal:ReadAsyncResultEvent" const
int READMODE_NONE = 0 const
int READMODE_LINE_SYNC = 1 const
int READMODE_LINE_ASYN = 2 const
int READMODE_KEY_SYNC = 3 const
int READMODE_KEY_ASYN = 4 const
float SYNCREAD_WAIT_INTERVAL = 0.2 const
string TerminalHolotapeMenu = "TerminalHolotapeMenu" const
string PipboyHolotapeMenu = "PipboyHolotapeMenu" const


; declarative properties
int property ALIGNMENT_LEFT = 0 auto const hidden
int property ALIGNMENT_CENTER = 1 auto const hidden
int property ALIGNMENT_RIGHT = 2 auto const hidden
int property FIELDSIZE_TOEOL = -1 auto const hidden
int property ERASE_EOS = -1 auto const hidden
int property ERASE_EOL = -2 auto const hidden
int property ERASE_CURPOS = -3 auto const hidden
int property ERASE_BOS = -4 auto const hidden
int property ERASE_BOL = -5 auto const hidden
int property ERASE_LINE = -6 auto const  hidden

; Color BIOS palette
int property COLOR_BLACK = 0x000000 auto const hidden
int property COLOR_WHITE = 0xffffff auto const hidden
int property COLOR_RED = 0x880000 auto const hidden
int property COLOR_CYAN = 0xaaffee auto const hidden
int property COLOR_PURPLE = 0xcc44cc auto const hidden
int property COLOR_GREEN = 0x00cc55 auto const hidden
int property COLOR_BLUE = 0x0000aa auto const hidden
int property COLOR_YELLOW = 0xeeee77 auto const hidden
int property COLOR_ORANGE = 0xdd8855 auto const hidden
int property COLOR_BROWN = 0x664400 auto const hidden
int property COLOR_LIGHTRED = 0xff7777 auto const hidden
int property COLOR_DARKGREY = 0x333333 auto const hidden
int property COLOR_GREY = 0x777777 auto const hidden
int property COLOR_LIGHTGREEN = 0xaaff66 auto const hidden
int property COLOR_LIGHTBLUE = 0x0088ff auto const hidden
int property COLOR_LIGHTGREY = 0xbbbbbb auto const hidden
int property COLOR_TRANSPARENT = 1 auto const hidden
int property COLOR_SYSTEM = 2 auto const hidden

; valid text screen modes
string property SCREENMODE_40x17 = "40x17" auto const hidden
string property SCREENMODE_50x20 = "50x20" auto const hidden
string property SCREENMODE_60x22 = "60x22" auto const hidden
string property SCREENMODE_72x25 = "72x25" auto const hidden
string property SCREENMODE_80x28 = "80x28" auto const hidden
string property SCREENMODE_DEFAULT = "DEFAULT" auto const hidden
string property SCREENMODE_PIPBOY = "PIPBOY" auto const hidden

; NISTRON HD Color System CRT definitions
int property CRT_TYPE_UNDEFINED = 0 auto const hidden
int property CRT_TYPE_VANILLA = 1 auto const hidden
int property CRT_TYPE_HD_MONO_GREEN = 2 auto const hidden
int property CRT_TYPE_HD_MONO_AMBER = 3 auto const hidden
int property CRT_TYPE_HD_COLOR = 4 auto const hidden

; hardware type definitions
int property HW_TYPE_UNKNOWN = 0 auto const hidden
int property HW_TYPE_TERMLINK = 1 auto const hidden
int property HW_TYPE_PIPBOY = 2 auto const hidden
int property HW_TYPE_HAL_PC = 3 auto const hidden

; color CRT support & hardware detection
String Property ColorHDSystemPluginName = "NISTRONHDColorSystem.esl" Auto Const
int detectedCRTType = 0
int detectedHWType = 0

Int Property SystemDisplayType Hidden
	Int Function Get()
		Return detectedCRTType
	EndFunction
EndProperty

Int Property SystemHardwareType Hidden
	Int Function Get()
		Return detectedHWType
	EndFunction
EndProperty

; target flash menu name
string FLASH_MENUNAME = "TerminalHolotapeMenu" 

; ReadLine related vars
int readMode = 0
Bool readSyncCompleteFlag = false
string readAsyncBuffer = ""

; gets set to true upon receiving OnTerminalShutdown event.
Bool isShuttingDown = false

Bool Property IsTerminalShutdown Hidden
	Bool Function Get()
		Return isShuttingDown
	EndFunction
EndProperty

Bool Property AsyncReadInProgress
	Bool Function Get()
		Return (readMode != READMODE_NONE)
	EndFunction
EndProperty

; Lifecycle management

Event OnInit()	
	Debug.Trace(Self + ": DEBUG - Papyrus Terminal holotape initialized.")
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akWorkshop)
	If (!isShuttingDown)
		Debug.Trace(Self + ": INFO - Holotape destroyed.")
		OnTerminalShutdown()
	EndIf
EndEvent

Event OnHolotapeChatter(string astrChatter, float afNumericData)
	; Pipboy does not generate OnHolotapePlay events, so we won't know when our holotape is playing.	
	; OTOH, Holotape Chatter (notifyScripts API) is broken on regular Terminals and will ONLY be received from the Pipboy.
	; Papyrus Terminal SWF sends Holotape Chatter to bootstrap the BIOS when run on a Pipboy.

	If (astrChatter == "PAPYRUSTERMINAL:PIPBOY_BOOTSTRAP")
		Debug.Trace(Self + ": INFO - Pipboy hardware detected; Writing CBM80 signature to $8004 for 64K System Bootstrap from $C000...")		
		; setup holotape script with Terminal ref <none>
		OnHolotapePlay(none)
		; generate "fake" TerminalReady event
		OnTerminalReady()
	EndIf
EndEvent

Event OnHolotapePlay(ObjectReference refTerminal)
	Debug.Trace(Self + ": DEBUG - OnHolotapePlay(" + refTerminal + ") event recevied.")	
	
	; register for holotape menu events
	;RegisterForMenuOpenCloseEvent(TerminalHolotapeMenu)
	;RegisterForMenuOpenCloseEvent(PipboyHolotapeMenu)


	; setup flash menu communication target
	If (refTerminal == none)
		; no terminal reference; runs in pipboy
		FLASH_MENUNAME = PipboyHolotapeMenu
	Else
		; runs in referenced terminal
		FLASH_MENUNAME = TerminalHolotapeMenu
	EndIf		

	; initialize internal vars
	readMode = READMODE_NONE
	readSyncCompleteFlag = false;
	readAsyncBuffer = "";
	isShuttingDown = false

	; register for terminal ready and shutdown events
	If (refTerminal != none)
		; do not register this when running on pipboy. it has fired already, before the BOOSTRAP even commenced.
		RegisterForExternalEvent(TerminalReadyEvent, "OnTerminalReady")
	EndIf
	RegisterForExternalEvent(TerminalShutdownEvent, "OnTerminalShutdown")

	; hardware detection
	detectedHWType = DetectHWType()

	; color CRT support
	detectedCRTType = DetectCRTType(refTerminal)
	Debug.Trace(Self + ": DEBUG - CRT type detected: " + detectedCRTType)

	; ready for text replacement tokens to be set, notify derived class
	OnPapyrusTerminalInitialize(refTerminal)
EndEvent

Function OnTerminalReady()	
	If (!isShuttingDown)
		Debug.Trace(Self + ": DEBUG - OnTerminalReady event received.")

		; unregister OnTerminalReady events
		UnRegisterForExternalEvent(TerminalReadyEvent)

	    ; use special PIPBOY screen mode when run on pipboy
	    If (SystemHardwareType == HW_TYPE_PIPBOY)
        	If (!ScreenMode("PIPBOY"))
	            Debug.Trace(Self + ": ERROR - Failed to configure for screenmode 'PIPBOY'.")
        	EndIf        
    	EndIf

		; initialize to system colors
		ColorTxt = COLOR_SYSTEM
		ColorBgr = COLOR_SYSTEM
	
		; notify derived class that terminal is ready for interaction
		OnPapyrusTerminalReady()
	EndIf
EndFunction

Function OnTerminalShutdown()	
	If (!isShuttingDown)
		Debug.Trace(Self + ": DEBUG - OnTerminalShutdown event received.")	

		; set shutdown flag
		isShuttingDown = true

		; unregister for all events
		UnRegisterForExternalEvent(TerminalShutdownEvent)
		UnRegisterForExternalEvent(TerminalReadyEvent)
		UnregisterForAllEvents()
	
		; cancel pending keyboard read operations
		If (readMode == READMODE_LINE_SYNC || readMode == READMODE_KEY_SYNC)
			; sync read did NOT complete (isShuttingDown = true)
			readSyncCompleteFlag = false
	
		ElseIf (readMode == READMODE_LINE_ASYN || readMode == READMODE_KEY_ASYN)
			; send async read cancel to derived class
			OnPapyrusTerminalReadAsyncCancelled()
		EndIf
	EndIf
	
	; clear readmode
	readMode = READMODE_NONE
	
	; notify derived class that terminal has shut down
	OnPapyrusTerminalShutdown()
EndFunction



; terminal related functions
; Number of text rows in the current Terminal display mode
Int Property TerminalRows
	Int Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.TerminalLines") as Int
		Else
			return 0
		EndIf
	EndFunction
EndProperty

; Number of text columns in the current Terminal display mode
Int Property TerminalColumns
	Int Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.TerminalColumns") as Int
		Else
			return 0
		EndIf
	EndFunction
EndProperty

; Enable/disable leaving Terminal by pressing TAB key (useful for making menus with submenus, or when you want to react to TAB)
Bool Property QuitOnTABEnabled Hidden
	Function Set(Bool value) 
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.QuitOnTABEnable", value)
		EndIf
	EndFunction
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.QuitOnTABEnable") as Bool
		Else
			return false
		EndIf
	EndFunction
EndProperty

; End the terminal session (exit holotape)
Function End()
	If (!isShuttingDown)
		Var[] args = new Var[1]
		args[0] = true
		UI.Invoke(FLASH_MENUNAME, "root1.End", args)
	EndIf
EndFunction



; screen functions

; Switch Screen Mode
Bool Function ScreenMode(String newScreenModeName)
	If (!isShuttingDown)
		If (newScreenModeName == "")
			; empty mode name is invalid
			Return False
		Else
			Var[] args = new Var[1]
			args[0]	= newScreenModeName
			Return UI.Invoke(FLASH_MENUNAME, "root1.ScreenModePapyrus", args) as Bool
		EndIf
	EndIf
EndFunction

; Print aligned fixed-width field (no LF appended)
Function PrintField(String fieldText, Int fieldSize, Int alignmentType, String paddingChar = " ", Bool noElipsis = false)
	If (!isShuttingDown)
		If ((fieldSize + CursorPositionColumn) > TerminalColumns)
			; field size may not exceed terminal width
			fieldSize = TerminalColumns - (CursorPositionColumn - 1)
		EndIf
		Var[] args = new Var[5]
		args[0] = fieldText
		args[1] = fieldSize
		args[2] = alignmentType
		args[3] = paddingChar
		args[4] = noElipsis
		UI.Invoke(FLASH_MENUNAME, "root1.PrintFieldPapyrus", args)
	EndIf
EndFunction

; Print line to screen (appends LF at the end)
Function PrintLine(String lineToPrint = "")
	If (!isShuttingDown)
		Var[] args = new Var[1]
		args[0] = lineToPrint
		UI.Invoke(FLASH_MENUNAME, "root1.PrintLinePapyrus", args)
	EndIf
EndFunction

; Print characters to screen
Function Print(String charsToPrint)
	If (!isShuttingDown)
		Var[] args = new Var[1]
		args[0] = charsToPrint
		UI.Invoke(FLASH_MENUNAME, "root1.PrintPapyrus", args)
	EndIf
EndFunction

; Convenience wrapper for EraseRange()
; - Erase n chars of screen memory, from current cursor position onward
; - Erase from current cursor position to End Of Line (ERASE_EOL)
; - Erase from current cursor position to End Of Screen (ERASE_EOS)
; - Erase the current line (ERASE_LINE)
Function Erase(Int numberOfChars = -1)
	If (!isShuttingDown)
		If (numberOfChars == ERASE_EOL)
			EraseRange(ERASE_CURPOS, ERASE_EOL)
		ElseIf (numberOfChars == ERASE_EOS)
			EraseRange(ERASE_CURPOS, ERASE_EOS)
		ElseIf (numberOfChars == ERASE_LINE)
			EraseRange(ERASE_BOL, ERASE_EOL)
		Else
			EraseRange(ERASE_CURPOS, CursorPositionIndex + numberOfChars)
		EndIf
	EndIf
EndFunction

; Erase range of screen memory (by screen memory index)
Function EraseRange(Int startIndex, Int endIndex = -1)
	If (!isShuttingDown)
		Var[] args = new Var[2]
		args[0] = startIndex
		args[1] = endIndex
		UI.Invoke(FLASH_MENUNAME, "root1.EraseRangePapyrus", args)
	EndIf
EndFunction

; Clear entire screen
Function Clear()
	If (!isShuttingDown)
		Var[] args = new Var[1]
		args[0] = false
		UI.Invoke(FLASH_MENUNAME, "root1.ClearScreenPapyrus", args)
	EndIf
EndFunction

; Clear entire screen and move cursor to home position (1, 1)
Function ClearHome()
	If (!isShuttingDown)
		Var[] args = new Var[1]
		args[0] = true
		UI.Invoke(FLASH_MENUNAME, "root1.ClearScreenPapyrus", args)
	EndIf
EndFunction



; Enable/disable reverse (inverse) text mode
Bool Property ReverseMode Hidden
	Function Set(Bool value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.ReverseMode", value)
		EndIf
	EndFunction
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.ReverseMode") as Bool
		Else
			return false
		EndIf
	EndFunction	
EndProperty

; Enable/disable insert mode (insert key toggle)
Bool Property InsertMode Hidden
	Function Set(Bool value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.InsertMode", value)
		EndIf
	EndFunction
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.InsertMode") as Bool
		Else
			return false
		EndIf
	EndFunction
EndProperty

; Enable/disable Terminal local echo (print typed keys to screen)
Bool Property LocalEcho Hidden
	Function Set(Bool value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.ScreenEchoEnable", value)
		EndIf
	EndFunction
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.ScreenEchoEnable") as Bool
		Else
			return false
		EndIf
	EndFunction
EndProperty

String Property PapyrusStringEscapeSequence Hidden
	Function Set(String value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.PapyrusStringEscapeSequence", value)
		EndIf
	EndFunction
	String Function Get()
		If (!isShuttingDown)
			Return UI.Get(FLASH_MENUNAME, "root1.PapyrusStringEscapeSequence") as String
		Else
			Return ""
		EndIf
	EndFunction
EndProperty


; cursor functions

; Move the cursor by row and column number (top left is 1,1)
Function CursorMove(Int row, Int column)
	If (isShuttingDown)
		return
	EndIf

	Var[] args = new Var[2]
	args[0] = row
	args[1] = column
	UI.Invoke(FLASH_MENUNAME, "root1.CursorMovePapyrus", args)
EndFunction

; Move the cursor by character index (zero based "screen memory" address, top left is 0)
Function CursorMoveByIndex(Int index)
	If (isShuttingDown)		
		Var[] args = new Var[1]
		args[0] = index
		UI.Invoke(FLASH_MENUNAME, "root1.CursorMoveByIndex", args)
	EndIf
EndFunction

; Number of screen row the cursor is currently positioned at (first row is 1)
Int Property CursorPositionRow
	Int Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.CursorCurrentLine") as Int
		Else
			return 0
		EndIf
	EndFunction
EndProperty

; Number of screen column the cursor is currently positioned at (first column is 1)
Int Property CursorPositionColumn
	Int Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.CursorCurrentColumn") as Int
		Else
			return 0
		EndIf
	EndFunction
EndProperty

; Character index of current cursor position (zero based "screen memory" address, top left is 0)
Int Property CursorPositionIndex
	Int Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.CursorCurrentIndex") as Int
		Else
			return 0
		EndIf
	EndFunction
EndProperty

; Enable/disable visible cursor rectangle on Terminal screen
Bool Property CursorEnabled Hidden
	Function Set(Bool value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.CursorEnabled", value)
		EndIf
	EndFunction	
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.CursorEnabled") as Bool
		EndIf
	EndFunction
EndProperty

; set/get foreground color
Int Property ColorTxt Hidden
	Function Set(Int value)
		If (!isShuttingDown)
			;If (detectedCRTType != CRT_TYPE_HD_COLOR)
			;	; always set COLOR_WHITE on monochrome systems
			;	UI.Set(FLASH_MENUNAME, "root1.ColorFG", 0xffffff)
			;	Return
			;EndIf
			If (value == COLOR_SYSTEM)
				If (detectedCRTType == CRT_TYPE_HD_COLOR)
					; default color on color systems
					value = COLOR_GREEN
				Else
					; default color on monochrome systems			
					value = COLOR_WHITE
				EndIf
			EndIf
			UI.Set(FLASH_MENUNAME, "root1.ColorFG", value)
		EndIf
	EndFunction
	Int Function Get()
		If (!isShuttingDown)
			;If (detectedCRTType != CRT_TYPE_HD_COLOR)
			;	; Always return COLOR_SYSTEM on monochrome systems
			;	Return COLOR_SYSTEM
			;EndIf
			;return UI.Get(FLASH_MENUNAME, "root1.ColorFG") as Int
		EndIf
	EndFunction
EndProperty

; set/get background color
Int Property ColorBgr Hidden
	Function Set(Int value)
		If (!isShuttingDown)
			;If (detectedCRTType != CRT_TYPE_HD_COLOR)
			;	; always set COLOR_BLACK on mono systems
			;	UI.Set(FLASH_MENUNAME, "root1.ColorBG", 0x0)
			;	Return
			;EndIf
			If (value == COLOR_SYSTEM)
				value = COLOR_TRANSPARENT
			EndIf
			UI.Set(FLASH_MENUNAME, "root1.ColorBG", value)
		EndIf
	EndFunction
	Int Function Get()
		If (!isShuttingDown)
			;If (detectedCRTType != CRT_TYPE_HD_COLOR)
			;	; always return COLOR_SYSTEM on mono systems
			;	Return COLOR_SYSTEM
			;EndIf
			return UI.Get(FLASH_MENUNAME, "root1.ColorBG") as Int
		EndIf
	EndFunction
EndProperty



; keyboard functions

; Begin asynchronous ReadLine operation. Completes on ENTER keypress by user. Cancellable by calling ReadAsyncCancel().
; Operation will generate OnPapyrusTerminalReadAsyncCompleted event callback on completion.
Bool Function ReadLineAsyncBegin(Int maxLength = 0)
	If (isShuttingDown)
		return false
	EndIf
	If (readMode == READMODE_NONE)

		; set async readline mode
		readMode = READMODE_LINE_ASYN
		
		; clear async read buffer
		readAsyncBuffer = ""

		; register for terminal async read result and cancel events
		RegisterForExternalEvent(ReadAsyncResultEvent, "OnReadAsyncResult")		

		; invoke async ReadLine on Terminal
		Var[] args = new Var[1]
		args[0] = maxLength
		return UI.Invoke(FLASH_MENUNAME, "root1.ReadLineAsyncBeginPapyrus", args) as Bool
	
	Else
		; read operation in progress
		Debug.Trace(Self + ": ERROR - ReadLineAsyncBegin() called, but a Read operation is already in progress.")
		return false;

	EndIf
EndFunction

; Begin asynchronous ReadKey operation. Completes as user depresses a key. Cancellable by calling ReadAsyncCancel().
Bool Function ReadKeyAsyncBegin()
	If (isShuttingDown)
		return false
	EndIf

	If (readMode == READMODE_NONE)

		; set readmode KEY ASYNC
		readMode = READMODE_KEY_ASYN

		; clear async read buffer
		readAsyncBuffer = ""

		; register for readasyncresult event
		RegisterForExternalEvent(ReadAsyncResultEvent, "OnReadAsyncResult")

		; invoke on Terminal
		Var[] args = new Var[1]
		args[0] = ""
		return UI.Invoke(FLASH_MENUNAME, "root1.ReadKeyAsyncBegin", args) as Bool
	
	Else
		; read operation in progress
		Debug.Trace(Self + ": ERROR - ReadKeyAsyncBegin() called, but a Read operation is already in progres.")
		return false;

	EndIf
EndFunction

; Cancel a pending asynchronous Read operation
Function ReadAsyncCancel()
	If (isShuttingDown)
		return
	EndIf

	If (readMode == READMODE_LINE_ASYN || readMode == READMODE_KEY_ASYN)		
		; unregister for terminal async read result event
		UnRegisterForExternalEvent(ReadAsyncResultEvent)
		
		; register for terminal async read cancelled event
		RegisterForExternalEvent(ReadAsyncCancelledEvent, "OnReadAsyncCancelled")

		; invoke ReadLineAsyncCancel on Terminal
		Var[] args = new Var[1]
		args[0] = ""
		UI.Invoke(FLASH_MENUNAME, "root1.ReadAsyncCancel", args)
		
		; allow UI Invoke processing
		Sleep(0.1)
	Else
		Debug.Trace(Self + ": WARNING - ReadAsyncCancel() called, but no async Read operation was in progress.")

	EndIf
EndFunction

; Synchronously read a line (ends in ENTER keypress) from the Terminal
String Function ReadLine(Int maxLength = 0)
	If (isShuttingDown)
		return "";
	EndIf

	If (readMode == READMODE_NONE)
		; store current state: localecho, cursorenabled
		Bool csLocalEcho = LocalEcho
		Bool csCursorEnabled = CursorEnabled
	
		; always enable cursor and localecho for synchronous read operation
		LocalEcho = true
		CursorEnabled = true

		; set read mode synchronous line
		readMode = READMODE_LINE_SYNC

		; clear readAsync input buffer and sync read complete flag
		readSyncCompleteFlag = false
		readAsyncBuffer = ""
		
		; register for async result event
		RegisterForExternalEvent(ReadAsyncResultEvent, "OnReadAsyncResult");

		; invoke ReadLineAsync on Terminal
		Var[] args = new Var[1]
		args[0] = maxLength
		
		; never attempt invoke if shutting down
		If (!isShuttingDown)			
			; invoke on SWF
			UI.Invoke(FLASH_MENUNAME, "root1.ReadLineAsyncBeginPapyrus", args)	
			
			; wait for async result
			While (IsBoundGameObjectAvailable() &&  readMode == READMODE_LINE_SYNC && !readSyncCompleteFlag && !isShuttingDown)
				;Debug.Trace(Self + ": DEBUG - [ReadLine] Waiting for OnReadAsyncResult")	
			
				; WARNING: DO NOT use Utility.Wait() in your Papyrus Terminal scripts!
				; Doing so will suspend execution of your script, because the Terminal Menu is open.
				; Use Utility.WaitMenuMode() instead.
			
				Utility.WaitMenuMode(SYNCREAD_WAIT_INTERVAL)
			EndWhile
		EndIf

		; restore LocalEcho, CursorEnabled to original state
		LocalEcho = csLocalEcho
		CursorEnabled = csCursorEnabled

		If (!isShuttingDown)			
			; return async input buffer contents
			If (readSyncCompleteFlag)
				return readAsyncBuffer
			Else
				; synchronous read did not complete
				return ""
			EndIf
		Else
			Debug.Trace(Self + ": INFO - ReadLine() aborted due to Terminal shutdown.")
			return ""
		EndIf
	Else
		Debug.Trace(Self + ": ERROR - ReadLine() called, but a Read operation is already in progress.")		
		return ""
	EndIf
EndFunction

String Function ReadKey()
	If (isShuttingDown)
		Return "";
	EndIf
	If (readMode == READMODE_NONE)
		; set read mode synchronous key
		readMode = READMODE_KEY_SYNC

		; clear readAsync input buffer and sync read complete flag
		readSyncCompleteFlag = false
		readAsyncBuffer = ""
		
		; register for async result event
		RegisterForExternalEvent(ReadAsyncResultEvent, "OnReadAsyncResult");

		; invoke ReadLineAsync on Terminal
		Var[] args = new Var[1]
		args[0] = ""
		Bool readAsyncBeginResult = UI.Invoke(FLASH_MENUNAME, "root1.ReadKeyAsyncBegin", args) as Bool
		If (readAsyncBeginResult)
			; wait for read async result
			While (IsBoundGameObjectAvailable() &&  readMode == READMODE_KEY_SYNC && !readSyncCompleteFlag && !isShuttingDown)
				;Debug.Trace(Self + ": DEBUG - [ReadKey] Waiting for OnReadAsyncResult")	
			
				; ##### WARNING: DO NOT use Utility.Wait() in your Papyrus Terminal scripts! #####
				; Doing so will suspend execution of your script, because the Terminal Menu is open.
				; Use Utility.WaitMenuMode() instead.
				
				Utility.WaitMenuMode(SYNCREAD_WAIT_INTERVAL)
			EndWhile

			If (!isShuttingDown)
				If (readSyncCompleteFlag)
					; completed, return async input buffer contents
					Return readAsyncBuffer
				Else
					; aborted, return empty string
					return ""
				EndIf
			Else
				Debug.Trace(Self + ": INFO - ReadKey() aborted due to Terminal shutdown.")
			EndIf
		Else
			Debug.Trace(Self + ": ERROR - ReadKeyAsyncBegin call failed.")
			return ""
		EndIf	
	Else
		Debug.Trace(Self + ": ERROR - ReadKey() called, but a Read operation is already in progress.")		
		return ""		
	EndIf
EndFunction

; Result event handler for Terminal ReadLine operations
; The Flash Terminal itself can only do async Reads, but the API provides synchronous wrappers ReadKey() and ReadLine()
Function OnReadAsyncResult(string readBuffer)
	Debug.Trace(Self + ": DEBUG - OnReadAsyncResult event received.") ;" readLineBuffer=" + readLineBuffer)
	
	; unregister for async result event
	UnRegisterForExternalEvent(ReadAsyncResultEvent)	

	If (readMode == READMODE_LINE_SYNC || readMode == READMODE_KEY_SYNC)		
		; synchronous Read operation has completed, fill async read buffer from event parameter
		readAsyncBuffer = readBuffer
 		; set sync read complete flag
		readSyncCompleteFlag = true
		; clear readmode		
		readMode = READMODE_NONE

	ElseIf (readMode == READMODE_LINE_ASYN || readMode == READMODE_KEY_ASYN) 		
		; asynchronous Read operation has completed, signal derived class
		OnPapyrusTerminalReadAsyncCompleted(readBuffer)
		; reset readmode
		readMode = READMODE_NONE

	Else
		Debug.Trace(Self + ": WARNING - OnReadAsyncResult event received, but no Read operation was in progress.");
	EndIf	
EndFunction

; Result event handler for async Read cancellation
Function OnReadAsyncCancelled()
	If (readMode == READMODE_LINE_ASYN || readMode == READMODE_KEY_ASYN)		
		; unregister for async result and cancelled events
		UnRegisterForExternalEvent(ReadAsyncResultEvent)
		UnRegisterForExternalEvent(ReadAsyncCancelledEvent)
		
		; clear async read mode
		readMode = READMODE_NONE
		
		; notify derived class 
		OnPapyrusTerminalReadAsyncCancelled()
	EndIf
EndFunction

; Mouse Functions and Properties

Bool Property MousePointerEnabled Hidden
	Function Set(Bool value)
		If (!isShuttingDown)
			UI.Set(FLASH_MENUNAME, "root1.MousePointerEnable", value)
		EndIf
	EndFunction	
	Bool Function Get()
		If (!isShuttingDown)
			return UI.Get(FLASH_MENUNAME, "root1.MousePointerEnable") as Bool
		EndIf
	EndFunction
EndProperty


; Convenience Functions

Function Sleep(Float secondsToSleep)
	; must NEVER use Utiltiy.Wait() in terminal programs, so we provide a simple Sleep() method wrapper for Utility.WaitMenuMode
	Utility.WaitMenuMode(secondsToSleep)
EndFunction

; call function asynchronously with up to 6 parameters
Function Dispatch(String functionName, Var arg1 = none, Var arg2 = none, Var arg3 = none, Var arg4 = none, Var arg5 = none, Var arg6 = none)	
	; TODO: Find a way to prevent idiotic log spam about the none default value when using this
	If (functionName == "")
		Debug.Trace(Self + ": ERROR - Dispatch() called with no function name.")
		Return
	EndIf
	Var[] callArgs = new var[0]
	AddArg(callArgs, arg1)
	AddArg(callArgs, arg2)
	AddArg(callArgs, arg3)
	AddArg(callArgs, arg4)
	AddArg(callArgs, arg5)
	AddArg(callArgs, arg6)
	; do not dispatch if terminal has shut down
	If (!isShuttingDown)
		Debug.Trace(Self + ": DEBUG - Dispatch(" + functionName + ", <" + callArgs.Length + " parameters>).")			
		CallFunctionNoWait(functionName, callArgs)
	EndIf
EndFunction

; used internally
Function AddArg(Var[] argsArray, var varArg)
	If ((varArg + "") == "None")
		Return
	EndIf

	; TESTING THIS
	argsArray.Add(varArg)
	Return

	;/ 	If (varArg is String)
		argsArray.Add(varArg as String)
		Debug.Trace(Self + ": DEBUG - Argument (" + varArg + ") added as String")
	ElseIf (varArg is Int)
		argsArray.Add(varArg as Int)
		Debug.Trace(Self + ": DEBUG - Argument (" + varArg + ") added as Int")
	ElseIf (varArg is Float)
		argsArray.Add(varArg as Float)
		Debug.Trace(Self + ": DEBUG - Argument (" + varArg + ") added as Float")
	ElseIf (varArg is Form)
		argsArray.Add(varArg as Form)
		Debug.Trace(Self + ": DEBUG - Argument (" + varArg + ") added as Form")
	ElseIf (varArg is ObjectReference)
		Debug.Trace(Self + ": DEBUG - Argument (" + varArg + ") added as ObjectReference")
		argsArray.Add(varArg as ObjectReference)
	EndIf /;	
EndFunction

; Executes an ObScript console command
Function ExecuteConsoleCommand(String commandLine)	
	If (isShuttingDown)
		Return
	EndIf

	Var[] args = new Var[1]
	args[0] = commandLine
	UI.Invoke(FLASH_MENUNAME, "root1.ExecuteConsoleCommandPapyrus", args)
EndFunction

; hardware detection
Int Function DetectHWType()
	If (UI.IsMenuOpen(TerminalHolotapeMenu))
		detectedHWType = HW_TYPE_TERMLINK
	ElseIf (UI.IsMenuOpen(PipboyHolotapeMenu))
		detectedHWType = HW_TYPE_PIPBOY
	Else
		detectedHWType = 0
	EndIf
EndFunction

; color crt support
Int Function DetectCRTType(ObjectReference refTerminal)
	; try to read NISTRON HD Color System CRT keywords from reference and return type ID
	If (Game.IsPluginInstalled(ColorHDSystemPluginName))

		Bool loadFail = false
		Debug.Trace(Self + ": DEBUG - " + ColorHDSystemPluginName + " installed; Support enabled.")

		; handle Pipboy CRT Types
		If (SystemHardwareType == HW_TYPE_PIPBOY)
			GlobalVariable glbPipboyScreenType = Game.GetFormFromFile(0x10, ColorHDSystemPluginName) as GlobalVariable
			If (glbPipboyScreenType == none)
				Debug.Trace(Self + ": ERROR - Failed to load glbPipboyScreenType.")
			EndIf
			Int pbScreenType = glbPipboyScreenType.GetValue() as Int
			If(pbScreenType == CRT_TYPE_HD_MONO_GREEN)
				Debug.Trace(Self + ": DEBUG - Monochrome Pipboy CRT (Green) detected.")
			ElseIf(pbScreenType == CRT_TYPE_HD_MONO_AMBER)
				Debug.Trace(Self + ": DEBUG - Monochrome Pipboy CRT (Amber) detected.")
			ElseIf(pbScreenType == CRT_TYPE_HD_COLOR)
				Debug.Trace(Self + ": DEBUG - Color Pipboy CRT detected.")
			Else
				Debug.Trace(Self + ": DEBUG - Vanilla Pipboy CRT detected.")
			EndIf
			Return pbScreenType
		EndIf

		Keyword kwdCRTGreen = Game.GetFormFromFile(0x1, ColorHDSystemPluginName) as Keyword
		Keyword kwdCRTAmber = Game.GetFormFromFile(0x2, ColorHDSystemPluginName) as Keyword
		Keyword kwdCRTColor = Game.GetFormFromFile(0x3, ColorHDSystemPluginName) as Keyword
		GlobalVariable glbPipboyScreenType = Game.GetFormFromFile(0x10, ColorHDSystemPluginName) as GlobalVariable

		If (kwdCRTGreen == none)
			Debug.Trace(Self + ": ERROR - Failed to load kwdCRTGreen.")
			loadFail = true
		EndIf
		If (kwdCRTAmber == none)
			Debug.Trace(Self + ": ERROR - Failed to load kwdCRTAmber.")
			loadFail = true		
		EndIf
		If (kwdCRTColor == none)
			Debug.Trace(Self + ": ERROR - Failed to load kwdCRTColor.")
			loadFail = true		
		EndIf
		If (glbPipboyScreenType == none)
			Debug.Trace(Self + ": ERROR - Failed to load glbPipboyScreenType.")
		EndIf
		
		If (!loadFail)		
			; TODO: move this detection stuff into HD COLOR System
			If (refTerminal != none)
				; read CRT keyword
				If (refTerminal.HasKeyword(kwdCRTGreen))
					; HD Mono (Green)
					Debug.Trace(Self + ": INFO - Monochrome CRT (Green) detected.")
					Return CRT_TYPE_HD_MONO_GREEN			
				ElseIf (refTerminal.HasKeyword(kwdCRTAmber))
					; HD Mono (Amber)
					Debug.Trace(Self +  ": INFO - Monochrome CRT (Amber) detected.")
					Return CRT_TYPE_HD_MONO_AMBER
				ElseIf (refTerminal.HasKeyword(kwdCRTColor))
					; color perfectron
					Debug.Trace(Self + ": INFO - Color CRT detected.")
					Return CRT_TYPE_HD_COLOR
				EndIf
			Else
				; pipboy/powerarmor		
			EndIf
		Else
			Debug.Trace(Self + ": ERROR - Failed to load CRT keywords. NISTRON HD Color System is unavailable.")
		EndIf
	Else
		Debug.Trace(Self + ": DEBUG - NISTRON Color HD System (" + ColorHDSystemPluginName + ") not present.")
	EndIf			

	; Vanilla keyword, no Color HD keywords or Color HD system not installed.
	; assume vanilla crt
	Debug.Trace(Self + ": DEBUG - Vanilla CRT detected.")
	Return CRT_TYPE_VANILLA

EndFunction





; String Utility Functions
String[] Function StringSplit(string line, string separator = " ")
	If (isShuttingDown) 
		string[] retVal = new string[0] 
		return retVal
	EndIf

	Var[] args = new Var[2]
	args[0] = line
	args[1] = separator
	Return Utility.VarToVarArray(UI.Invoke(FLASH_MENUNAME, "root1.StringSplitPapyrus", args)) as string[]
EndFunction

String Function StringCharAt(String line, Int charIndex)
	If (isShuttingDown)
		Return ""
	EndIf

	Var[] args = new Var[2]
	args[0] = line
	args[1] = charIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringCharAtPapyrus", args) as String
EndFunction

Int Function StringCharCodeAt(String line, Int charIndex)
	If (isShuttingDown)
		Return -1
	EndIf

	Var[] args = new Var[2]
	args[0] = line
	args[1] = charIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringCharCodeAtPapyrus", args) as Int	
EndFunction

Int Function StringIndexOf(String line, String part, Int startIndex)
	If (isShuttingDown)
		Return -1
	EndIf

	Var[] args = new Var[3]
	args[0] = line
	args[1] = part
	args[2] = startIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringIndexOfPapyrus", args) as Int		
EndFunction

Int Function StringLastIndexOf(String line, String part, Int priorToIndex = -1)
	If (isShuttingDown)
		Return -1
	EndIf

	Var[] args = new Var[3]
	args[0] = line
	args[1] = part
	args[2] = priorToIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringLastIndexOfPapyrus", args) as Int		
EndFunction

Int Function StringLength(String line)
	If (isShuttingDown)
		return 0
	EndIf

	Var[] args = new var[1]
	args[0] = line
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringLengthPapyrus", args) as Int
EndFunction

String Function StringReplace(String line, String pattern, String replacement)
	If (isShuttingDown)
		Return ""
	EndIf

	Var[] args = new Var[3]
	args[0] = line
	args[1] = pattern
	args[2] = replacement
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringReplacePapyrus", args) as String
EndFunction

String Function StringSlice(String line, Int startIndex, Int endIndex = 0x7fffffff)
	If (isShuttingDown)
		Return ""
	EndIf

	Var[] args = new Var[3]
	args[0] = line
	args[1] = startIndex
	args[2] = endIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringSlicePapyrus", args) as String
EndFunction

String Function StringSubstring(String line, Int startIndex, Int endIndex = 0x7fffffff)
	If (isShuttingDown)
		Return ""
	EndIf

	Var[] args = new Var[3]
	args[0] = line
	args[1] = startIndex
	args[2] = endIndex
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringSubstringPapyrus", args) as String
EndFunction

Bool Function StringIsNumeric(String line)
	If (isShuttingDown)
		Return false
	EndIf

	If (line == "")
		Return false
	EndIf

	Var[] args = new Var[1]
	args[0] = line
	Return UI.Invoke(FLASH_MENUNAME, "root1.StringIsNumericPapyrus", args) as Bool
EndFunction

String Function StringFormat(string line, var arg1 = none, var arg2 = none, var arg3 = none, var arg4 = none, var arg5 = none, var arg6 = none, var arg7 = none, var arg8 = none, var arg9 = none)
	If (isShuttingDown)
		Return ""
	EndIf
	var[] lineAndArguments = new var[1]
	lineAndArguments[0] = line
	AddArg(lineAndArguments, arg1)
	AddArg(lineAndArguments, arg2)
	AddArg(lineAndArguments, arg3)
	AddArg(lineAndArguments, arg4)
	AddArg(lineAndArguments, arg5)
	AddArg(lineAndArguments, arg6)
	AddArg(lineAndArguments, arg7)
	AddArg(lineAndArguments, arg8)
	AddArg(lineAndArguments, arg9)
	If (isShuttingDown)
		Return ""
	Else
		Return UI.Invoke(FLASH_MENUNAME, "root1.StringFormatPapyrus", lineAndArguments) as String
	EndIf	
EndFunction

String Function StringRepeat(String sequenceToRepeat, Int numberOfRepetitions)
	If (isShuttingDown)
		Return ""
	EndIf

	Var[] args = new Var[2]
	args[0] = sequenceToRepeat
	args[1] = numberOfRepetitions

	If (isShuttingDown)
		Return ""
	Else
		Return UI.Invoke(FLASH_MENUNAME, "root1.StringRepeatPapyrus", args) as String
	EndIf	
EndFunction
