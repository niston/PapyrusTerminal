﻿package
{
	// Papyrus Terminal for Fallout4
	// coding by niston
	// shout outs to Scrivener007
	
	// TODO: Implement Color() command
	
	
	import System.Diagnostics.Debug;
	import System.Diagnostics.Utility;
	import System.Display;
	
	// flash imports
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;	
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
    import flash.geom.Point;	
    import flash.geom.Rectangle;
	import flash.geom.ColorTransform;
	import flash.text.TextField;	
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.engine.Kerning;
	import flash.ui.Mouse;	
	import flash.ui.Keyboard;

	// for StringFormatPapyrus()
	import printf;
	
	// scaleform extensions
	import scaleform.gfx.Extensions;

	// scrivener007 stuff
	import System.Diagnostics.Debug;
	import System.Diagnostics.Utility;
	
	// game related importsf
	import FO4.IExternalCommunication;	
	import FO4.BGSExternalInterface;
	import FO4.Keyboard.Input;
	import flash.display.Bitmap;
	import flash.events.TimerEvent;
	import flash.text.engine.TextElement;
	import flash.filters.ColorMatrixFilter;
	import fl.motion.Color;
	
	public class PapyrusTerminal extends MovieClip implements IExternalCommunication {

		// hardcoded config
		// "real" terminal stage size is 826x700, but vanilla terminal screen estate is just 774x695 with 26 marginleft
		private const cfgTerminalWidth:int = 826;
		private const cfgTerminalHeight:int = 700;
		private const cfgTerminalMarginTop:int = 0;
		private const cfgPipboyWidth:int = 804;
		private const cfgPipboyHeight:int = 660;
		private const cfgPipboyMarginTop:int = 20;
		private const cfgDisplayLeftMargin:int = 26;
		private const cfgConsoleFontName:String = "Share-TechMono";		// Share-TechMono is the vanilla console font available in the game
		
		// Terminal events
		private const PipboyPlayEvent:String = "PapyrusTerminal:PipboyPlayEvent";
		private const TerminalReadyEvent:String = "PapyrusTerminal:ReadyEvent";
		private const TerminalShutdownEvent:String = "PapyrusTerminal:ShutdownEvent";
		private const ReadAsyncCancelledEvent:String  = "PapyrusTerminal:ReadAsyncCancelledEvent";
		private const ReadAsyncResultEvent:String = "PapyrusTerminal:ReadAsyncResultEvent";
		
		// cursor movement types
		private const CURSORMOVEMENTTYPE_UP:String = "UP";
		private const CURSORMOVEMENTTYPE_RIGHT:String = "RIGHT";
		private const CURSORMOVEMENTTYPE_DOWN:String = "DOWN";
		private const CURSORMOVEMENTTYPE_LEFT:String = "LEFT";
		
		// erase constants
		private const ERASE_EOS:int = -1;
		private const ERASE_EOL:int = -2;
		private const ERASE_CURPOS:int = -3;
		private const ERASE_BOS:int = -4;
		private const ERASE_BOL:int = -5;
		private const ERASE_LINE:int = -6;
				
		// color constants
		private const COLOR_BLACK:int = 0x000000;
		private const COLOR_WHITE:int = 0xffffff;
		private const COLOR_RED:int = 0x880000;;
		private const COLOR_CYAN:int = 0xaaffee;
		private const COLOR_PURPLE:int = 0xcc44cc;
		private const COLOR_GREEN:int = 0x00cc55;
		private const COLOR_BLUE:int = 0x0000aa;
		private const COLOR_YELLOW:int = 0xeeee77;
		private const COLOR_ORANGE:int = 0xdd8855;
		private const COLOR_BROWN:int = 0x664400;
		private const COLOR_LIGHTRED:int = 0xff7777;
		private const COLOR_DARKGREY:int = 0x333333;
		private const COLOR_GREY:int = 0x777777;
		private const COLOR_LIGHTGREEN:int = 0xaaff66;
		private const COLOR_LIGHTBLUE:int = 0x0088ff;
		private const COLOR_LIGHTGREY:int = 0xbbbbbb;
		private const COLOR_TRANSPARENT:int = 1;
		//private const COLOR_SYSTEM:int = -2;
				
		// screen mode config members
		private var cfgTerminalResolutionX = cfgTerminalWidth;
		private var cfgTerminalResolutionY = cfgTerminalHeight;
		private var cfgTerminalColumns:int = 0;
		private var cfgTerminalLines:int = 0;
		private var cfgFontSize:int = 0;
		private var cfgCursorOffsetY:int = 0;
		private var cfgDisplayTopMargin:int = 0;
		private var cfgForegroundColor:int = COLOR_WHITE; 		// White
		private var cfgBackgroundColor:int = COLOR_TRANSPARENT; // Transparent		
				
		// screen related members
		private var aScreenMemory:Array; 					// this is the screen "memory" of the terminal
		private var defaultFormat:TextFormat;				// default (non-reverse) text format
		private var reverseFormat:TextFormat;				// reverse text format

		// terminal related members
		private var iCurrentColorBG:int = cfgBackgroundColor;
		private var iCurrentColorFG:int = cfgForegroundColor;
		private var bInsertMode:Boolean = false;			// toggle insert mode on/off
		private var bReverseMode:Boolean = false;			// toggle reverse display mode on/off
		private var bScreenEchoEnable:Boolean = true;		// enable local character echo from keyboard
		private var bMousePointerEnable:Boolean = false		// mouse pointer is disabled
		private var bQuitOnTABEnable:Boolean = true;		// TAB key quits terminal

		// keyboard related members
		private var cKeyboardInput:FO4.Keyboard.Input;		// our FO4 keyboard input class

		// boot logo
		private var bootScreen:Bitmap;
		private var bootLogoTimer:Timer;
		
		// instance members
		public var mcCursor:MovieClip;
		public var tfInitChar:TextField;
		
		
		// Game related
		public var BGSCodeObj:Object;		
		public var IsMiniGame:Boolean = true;				// enables ConfirmQuit hook when true
		//public var UseOwnCursor:Boolean = true;
		
		// F4SE
		public static var F4SE:*;							// F4SE Api Object
		
		// cursor related
		private var iCursorPositionLine:int = 1;
		private var iCursorPositionColumn:int = 1;
		private var bCursorEnabled:Boolean = true;
		
		// async read related
		public const READASYNCMODE_NONE = 0;
		public const READASYNCMODE_LINE = 1;
		public const READASYNCMODE_KEY = 2;		
		private var iReadAsyncMode:int = 0;					// default to none
		private var iReadStartIndex:int = -1;				// index is zero based, -1 = not defined
		private var iReadMaxLength:int = 0;					// 0 = unlimited
		private var sReadAsyncBuffer:String = "";
		
		// special game interaction related
		private var sPapyrusStringEscapeSequence = "";
		

		// life cycle mgmt	
		public function PapyrusTerminal()
		{
			Extensions.enabled = true;
			this.BGSCodeObj = new Object();
		
			if(stage)
        	{
				this.init();
	    	}
	    	else
	    	{
		       	addEventListener(Event.ADDED_TO_STAGE, this.init);
		    }
		    addEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
		}
		
		public function onCodeObjDestruction() : void
      	{
        	this.BGSCodeObj = null;
		}
		
		private function init(param1:Event = null) : void
		{
		 	removeEventListener(Event.ADDED_TO_STAGE, this.init);
		 	if(!Extensions.isScaleform)
		 	{								
				//Mouse.hide();
				this.InitProgram();
		 	}
		}

		private function dispose(param1:Event) : void
		{
			removeEventListener(TimerEvent.TIMER, this.dispose);
			removeEventListener(FO4.Keyboard.InputEvent.KEY_DOWN, this.procKeyDown);
			removeEventListener(FO4.Keyboard.InputEvent.FILTERED_KEY_DOWN, this.procTextInput);
			removeEventListener(FO4.Keyboard.InputEvent.TEXT_INPUT, this.procTextInput);			
			removeEventListener(Event.ADDED_TO_STAGE, this.init);
			removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
			
		}

		public function InitProgram() : void
		{
			// enable movement input while in terminal			
			BGSExternalInterface.call(this.BGSCodeObj, "executeCommand", "fepc 1 1 0 0 0 0 0 0 0 0 0");
			//BGSExternalInterface.call(this.BGSCodeObj, "registerSound", AppConstants.SOUND_TERMINAL_SCROLL_LOOP);
			// keyboard input
			this.cKeyboardInput = new FO4.Keyboard.Input(stage);
			this.cKeyboardInput.addEventListener(FO4.Keyboard.InputEvent.FILTERED_KEY_DOWN, this.procKeyDown, false, 0, false);
			this.cKeyboardInput.addEventListener(FO4.Keyboard.InputEvent.TEXT_INPUT, this.procTextInput);
			
			// debug stuff
			//var instance:String = System.Display.GetInstance(this);
			//trace("My instance: " + instance);

			// prepare and show  boot logo
			//var bootScreenImage:BitmapData = new BootScreenLogo();
			//bootScreen = new Bitmap();
			//bootScreen.bitmapData = bootScreenImage;
			//this.addChild(bootScreen);
			
			// amber crt transform
			//var ct:ColorTransform = new ColorTransform(1,0.65,0,1,0,0,0,0);
			//stage.transform.colorTransform = ct;

/*			var matrix:Array = new Array();
			matrix = matrix.concat([0.3333, 0.3333, 0.3333, 0, 0]); // red
			matrix = matrix.concat([0.21, 0.21, 0.21, 0, 0]); // green
			matrix = matrix.concat([0, 0, 0, 0, 0]); // blue
			matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
			var filter:ColorMatrixFilter = new ColorMatrixFilter(matrix);
			var filters:Array = new Array();
			filters.push(filter);
			stage.filters = filters;*/

			trace("Configure screen...")
			// set up the screen in default mode (72x25)
			if (ConfigureScreen("default"))
			{
				// configuration successful, setup screen
				SetupScreen();

				// send pipboy bootstrap message (notifyScript API is broken for Terminals - we exploit this bug to "bootstrap" the Pipboy)
				SendHolotapeChatter(0, "PAPYRUSTERMINAL:PIPBOY_BOOTSTRAP");

				// TODO: start boot timeout

				trace("HandleBootComplete...")
				// boot screen is disabled, go to bootcomplete directly
				HandleBootComplete();

				// boot process timer (mainly here to keep the bootscreen visible long enough for player to see it)
				//bootLogoTimer = new Timer(1400, 1);
				//bootLogoTimer.addEventListener(TimerEvent.TIMER, this.BootComplete);
				//bootLogoTimer.start();

			}
			else
			{
				trace("Screen mode configuration (default) failed. Can't initialize display.")
				// TODO: show bombs
			}
			
		
		}	
				
		// terminal related functions

		private function ConfigureScreen(screenMode:String) : Boolean
		{
			trace("Configure Screen Mode: " + screenMode)
			
			// apply defaults
			cfgTerminalResolutionX = cfgTerminalWidth;
			cfgTerminalResolutionY = cfgTerminalHeight;
			cfgDisplayTopMargin = cfgTerminalMarginTop;
			
			// switch mode
			switch (screenMode.toLowerCase())
			{
				// vic-20: 22x23
				case "40x17":
					//40x17 chars config
					cfgTerminalColumns = 40;
					cfgTerminalLines = 17;
					cfgFontSize = 36;
					cfgCursorOffsetY = 0;
					trace("Screen mode 40x17 configured.")
					return true;
				case "50x20":
					// 60x22 chars config
					cfgTerminalColumns = 50;
					cfgTerminalLines = 20;		
					cfgFontSize = 31;
					cfgCursorOffsetY = 0;		
					trace("Screen mode 60x22 configured.")
					return true;				
				case "60x22":
					// 60x22 chars config
					cfgTerminalColumns = 60;
					cfgTerminalLines = 22;		
					cfgFontSize = 22;
					cfgCursorOffsetY = 0;		
					trace("Screen mode 60x22 configured.")
					return true;
				case "72x25":
				case "default":
				case "":
					// 72x25 chars config
					cfgTerminalColumns = 72;
					cfgTerminalLines = 25;		
					cfgFontSize = 19;
					cfgCursorOffsetY = 0;
					trace("Screen mode DEFAULT (72x25) configured.")
					return true;
				case "80x28":
					// 80x28 chars config
					cfgTerminalColumns = 80;
					cfgTerminalLines = 28;		
					cfgFontSize = 16;
					cfgCursorOffsetY = 0;			
					trace("Screen mode 80x25 configured.")
					return true;
				case "pipboy":
				    // special mode for pipboy
					cfgTerminalColumns = 72;
					cfgTerminalLines = 22;		
					cfgFontSize = 20;
					cfgCursorOffsetY = 0;		
					cfgDisplayTopMargin = cfgPipboyMarginTop;
					cfgTerminalResolutionX = cfgPipboyWidth;
					cfgTerminalResolutionY = cfgPipboyHeight;
					trace("Screen mode PIPBOY configured.")
					return true;										
				default:
					// unrecognized mode
					trace("Unrecognized screen mode: " + screenMode.toLowerCase() + "; Configuration failed.")
					return false;
			}			
		}

		private function SetupScreen() : void
		{
			trace("Screen setup...")

			// turn off cursor
			CursorEnabled = false;			

			// calculate number of lines and elements / lines
			//var charElementHeight:Number = 700 / cfgTerminalLines;
			//var charElementWidth:Number = 826 / cfgTerminalColumns;
			var charElementHeight:Number = cfgTerminalResolutionY / cfgTerminalLines;
			var charElementWidth:Number = cfgTerminalResolutionX / cfgTerminalColumns;
						
			// prepare embedded font
			// can't get this to work with textfields created at runtime
			//Font.registerFont(UnispaceFont);
			//var embeddedFont:Font = new UnispaceFont();			

			// define default format for char elements			
			defaultFormat = new TextFormat(cfgConsoleFontName, cfgFontSize, iCurrentColorFG);
			defaultFormat.leftMargin = 0; // cfgDisplayLeftMargin;
			defaultFormat.rightMargin = 0;
			defaultFormat.kerning = false; // we use monospace font, plus auto-kerning garbles text in game
			defaultFormat.align = flash.text.TextFormatAlign.LEFT;

			// define reverse format for char elements
			reverseFormat = new TextFormat(cfgConsoleFontName, cfgFontSize, iCurrentColorBG);
			reverseFormat.leftMargin = defaultFormat.leftMargin;
			reverseFormat.rightMargin = defaultFormat.rightMargin;
			reverseFormat.kerning = false;
			reverseFormat.align = flash.text.TextFormatAlign.LEFT;

			// setup init char
			tfInitChar.setTextFormat(defaultFormat);

			// create char elements
			aScreenMemory = new Array();
			var curLine:int;
			var curColumn:int;
			for (curLine = 1; curLine <= cfgTerminalLines; curLine++)
			{
				for (curColumn = 1; curColumn <= cfgTerminalColumns; curColumn++)
				{
					//trace("Line:" + curLine + ", Column:" + curColumn);					
					var newCharElement:TextField = new TextField();							
					//newCharElement.embedFonts = true;  // could not get this to work with textfields created at runtime
					newCharElement.y = ((curLine - 1) * charElementHeight) + cfgDisplayTopMargin;
					newCharElement.x = ((curColumn - 1) * charElementWidth) + cfgDisplayLeftMargin;
					newCharElement.height = tfInitChar.textHeight + 2;
					newCharElement.width = tfInitChar.textWidth + 3;
					newCharElement.type = TextFieldType.DYNAMIC;
					newCharElement.selectable = false;					
					newCharElement.antiAliasType = flash.text.AntiAliasType.ADVANCED;
					newCharElement.defaultTextFormat = defaultFormat;
					newCharElement.setTextFormat(defaultFormat);
					newCharElement.multiline = true;
					newCharElement.text = "";
					//newCharElement.autoSize = flash.text.TextFieldAutoSize.LEFT; 
					newCharElement.name = "CharElement_" + curLine + "_" + curColumn;
					//trace("Element X=" + newCharElement.x + ", Y=" + newCharElement.y)
					// add new element to screen memory array
					aScreenMemory.push(newCharElement);
					// add new element to stage
					this.addChild(newCharElement);
				}
			}			
			//Utility.TraceDisplayList(GetRoot());		
			//trace("this.name:" + this.name);
			//trace("this.root.name:" + this.root.name);

			// refresh cursor
			if (mcCursor)
			{
				this.removeChild(mcCursor);
				this.addChild(mcCursor);			
				trace("Applying color transform to cursor...")
				var cTrans:ColorTransform = new ColorTransform();
				cTrans.color = iCurrentColorFG;
				cTrans.concat(stage.transform.colorTransform);
				mcCursor.transform.colorTransform = cTrans;
			}
			else
			{
				trace("Cursor failure!")
				
			}

			// move cursor to home position
			CursorMove(1, 1);
			//Sleep(500);
			//this.removeChild(bootScreen);		

		}	
		
		private function TeardownScreen()
		{
			trace("Screen teardown...")
			CursorEnabled = false
			
			// remove text elements
			var i:int = 0
			while(aScreenMemory.length > 0)
			{
				//trace("Removing aScreenMemory[" + i + "]...")
				this.removeChild(aScreenMemory.pop())
			}
			aScreenMemory = null;
		}
		
		private function BootComplete(e:TimerEvent) : void
		{			
			HandleBootComplete();
		}
		
		private function HandleBootComplete()
		{
			//this.removeChild(bootScreen);					
			
			// Inform Papyrus that the terminal is ready
			if (F4SE)
			{
				F4SE.SendExternalEvent(TerminalReadyEvent);								
				trace("Papyrus Terminal is ready; Script notified.");				
			}
			else
			{			
				// todo: show bombs
				
				// write failure message to f4se logs
				trace("F4SE API Object unavailable; Unable to send notification to Papyrus.");				

				// print somewhat cryptic error message to terminal screen
				PrintLine("");
				PrintLine("ERROR #3: EXTENDER INIT FAILURE.");
			}			
		}
		
		public function get TerminalLines() : int
		{
			return cfgTerminalLines;
		}
		
		public function get TerminalColumns() : int
		{
			return cfgTerminalColumns;
		}
		
		public function get QuitOnTABEnable() : Boolean
		{
			return bQuitOnTABEnable;
		}
		
		public function set QuitOnTABEnable(val:Boolean)
		{
			bQuitOnTABEnable = val;
		}
		
		public function End() : void
		{
			// force quit
			ConfirmQuit(true);
		}
				
		// papyrus accessible wrappers for functions w/ arguments
		public function ScreenModePapyrus(argument:Object, ...rest) : Boolean
		{
			if (argument != null)
			{
				var newMode:String = argument.toString();
				
				// configure 
				if (ConfigureScreen(newMode))
				{
					// configuration successful, re-initialize screen
					trace("Tearing down screen...")
					TeardownScreen();
					trace("Setting up screen for new mode (" + newMode + ")...")
					SetupScreen();
					trace("Screen mode (" + newMode + ") set.")
					return true;
				}
				else
				{
					trace("Invalid screen mode selected.")
					// invalid screen mode selected, configuration unchanged
					return false;
				}
			}
			
			// mode argument was null
			return false;
		}
		
		public function get ColorFG() : int
		{
			return iCurrentColorFG;
		}
		
		public function set ColorFG(colorValue:int) : void
		{
			// set new foreground color value
			iCurrentColorFG = colorValue;
			
			// update cursor color
			var cTrans:ColorTransform = new ColorTransform();
			cTrans.color = iCurrentColorFG;
			//cTrans.concat(stage.transform.colorTransform);
			mcCursor.transform.colorTransform = cTrans;
			
			// update default and reverse format
			UpdateTextFormats();
		}
		
		public function get ColorBG() : int
		{
			return iCurrentColorBG;
		}
		
		public function set ColorBG(colorValue:int) : void
		{
			// set new background color value;
			iCurrentColorBG = colorValue;
			
			// update default and reverse format
			UpdateTextFormats();
		}
		
		private function UpdateTextFormats()
		{
			// define default format for char elements			
			defaultFormat = new TextFormat(cfgConsoleFontName, cfgFontSize, iCurrentColorFG);
			defaultFormat.leftMargin = 0; 
			defaultFormat.rightMargin = 0;
			defaultFormat.kerning = false; // we use monospace font, plus auto-kerning garbles text in game
			defaultFormat.align = flash.text.TextFormatAlign.LEFT;

			// define reverse format for char elements
			reverseFormat = new TextFormat(cfgConsoleFontName, cfgFontSize, iCurrentColorBG);
			reverseFormat.leftMargin = defaultFormat.leftMargin;
			reverseFormat.rightMargin = defaultFormat.rightMargin;
			reverseFormat.kerning = false;
			reverseFormat.align = flash.text.TextFormatAlign.LEFT;			
		}
				
		public function PrintPapyrus(argument:Object, ...rest) : void
		{
			if (argument != null)
			{
				Print(argument.toString());
				if (rest != null)
				for (var i:uint = 0; i < rest.length; i++)
				{
					Print(rest[i].toString());
				}
			}
		}
		
		public function PrintLinePapyrus(argument:Object, ...rest) : void
		{
			if (argument != null)
			{
				PrintLine(argument.toString());
			
				if (rest != null)
				{
					for (var i:uint = 0; i < rest.length; i++)
					{
						PrintLine(rest[i].toString());
					}
				}							
			}
		}
		
		public function PrintFieldPapyrus(argument:Object, ...rest) : void
		{			
			if (argument != null && rest[0] != null && rest[1] != null && rest[2] != null && rest[3] != null)
			{
				PrintField(argument.toString(), int(rest[0]), int(rest[1]), rest[2].toString(), Boolean(rest[3]));
			}
		}
			
		public function ClearScreenPapyrus(argument1:Object, ...rest) : void
		{
			if (argument1 != null)
			{
				var homeCursor:Boolean = Boolean(argument1);				
				ClearScreen(homeCursor);
			}
		}
		
		public function EraseRangePapyrus(argument1:Object, ...rest) : void
		{			
			if (argument1 != null)
			{
				var startIndex:int = int(argument1);
				var endIndex:int = ERASE_EOS;
				if (rest != null)
				{
					endIndex= int(rest[0]);					
				}
				trace("EraseRangePapyrus(" + startIndex + "->" + endIndex + ")");
				EraseRange(startIndex, endIndex);
			}
		}
		
		public function CursorMovePapyrus(argument1:Object, ...rest) : void
		{
			if (argument1 != null)
			{
				var cursorRow:int = int(argument1);
				
				if (rest != null)
				{
					var cursorColumn:int = int(rest[0])
					
					trace("Cursor moving to:" + cursorRow + ", " + cursorColumn);
					
					CursorMove(cursorRow, cursorColumn);
				}				
			}			
		}
		
		public function ReadLineAsyncBeginPapyrus(argument1:Object, ...rest) : Boolean
		{
			if (argument1 != null)			
			{
				var maxLen = int(argument1);
				trace("ReadLineAsyncBeginPapyrus(" + maxLen + ")");
				return ReadLineAsyncBegin(maxLen);
			}
			else
			{
				trace("ReadLineAsyncBeginPapyrus()");
				return ReadLineAsyncBegin(0);
			}		
		}
		

		// display related functions
		
		public function EraseRange(startIndex:int = ERASE_CURPOS, endIndex:int = ERASE_EOL) : void
		{
			// clear part of the screen
			var validIndexes:int = (aScreenMemory.length - 1);
		
			// resolve special values
			if (startIndex == ERASE_EOS) { return; } // nothing to do
			if (startIndex == ERASE_EOL) { startIndex = GetLastIndexOnLine(CursorCurrentLine); }
			if (startIndex == ERASE_BOS) { startIndex = 0; }
			if (startIndex == ERASE_BOL) { startIndex = GetFirstIndexOnLine(CursorCurrentLine); }			
			if (endIndex == ERASE_BOS) { return; } // nothing to do
			if (endIndex == ERASE_BOL) { startIndex = GetFirstIndexOnLine(CursorCurrentLine); }	
			if (endIndex == ERASE_EOS) { endIndex = validIndexes; }
			if (endIndex == ERASE_EOL) { endIndex = GetLastIndexOnLine(CursorCurrentLine); }			
			if (startIndex == ERASE_CURPOS) { startIndex = CursorCurrentIndex; }
			if (endIndex == ERASE_CURPOS) { endIndex = CursorCurrentIndex; }									
			if ((startIndex == ERASE_LINE) || (endIndex == ERASE_LINE))
			{
				startIndex = GetFirstIndexOnLine(CursorCurrentLine);
				endIndex = GetLastIndexOnLine(CursorCurrentLine);
			}
			
			// sanitize resovled parameters
			if (endIndex > validIndexes) { endIndex = validIndexes; } // impossible
			if (endIndex < startIndex) { endIndex = startIndex; } // impossible						
			if (endIndex < 0) { endIndex = 0; } // negative index doesn't exist
			if (startIndex > endIndex) { startIndex = endIndex; }
			if (startIndex < 0) { startIndex = 0; } // negative index doesn't exist						
			if (startIndex > validIndexes) { startIndex = validIndexes; } // out of bounds
			
			// detect null op
			if (startIndex == endIndex) { return; } // nothing to do
						
			trace("EraseRange(" + startIndex + "->" + endIndex + ")");
						
			// erase the specified range
			for (var i:int = startIndex; i <= endIndex; i++)
			{
				ClearChar(i);
				//aScreenMemory[i].text = "";
				//aScreenMemory[i].background = false;
			}			
		}
				
		public function PrintLine(textToPrint:String)
		{
			// do not append line feed if end of string coincides with last column (will auto line feed)
			if (((iCursorPositionColumn - 1 ) + textToPrint.length) == TerminalColumns)
			{
				Print(textToPrint);
			}
			else
			{
				Print(textToPrint + "\n");
			}				
		}
		
		public function PrintField(textToPrint:String, fieldSize:int, alignmentType:int, paddingChar:String = " ", noElipsis:Boolean = false)
		{
			// zero width fields are empty
			if (fieldSize == 0)
			{
				return "";
			}
			
			// field size may not exceed terminal width
			if ((fieldSize + iCursorPositionColumn) > cfgTerminalColumns)
			{
				fieldSize = cfgTerminalColumns - (iCursorPositionColumn - 1)
			}
			
			// negative fieldsize means "to end of line"
			if (fieldSize < 0)
			{
				fieldSize = cfgTerminalColumns - (iCursorPositionColumn - 1)
			}
			
			// truncate if too long
			if (textToPrint.length > fieldSize)
			{
				if (noElipsis || fieldSize < 3)
				{
					textToPrint = textToPrint.substr(0, fieldSize);	
				}
				else
				{
					// leave room for elipsis
					textToPrint = textToPrint.substr(0, fieldSize - 3);
					// add elipsis
					textToPrint += "..."					
				}
			}
			
			if (textToPrint.length < fieldSize)
			{
				var padLen:int = fieldSize - textToPrint.length;
				switch (alignmentType)
				{
					case 0:						
						// left align, pad to the right
						textToPrint = textToPrint + StringRepeat(paddingChar, padLen);
						break;
					
					case 1: 						
						// center align
						padLen = Math.floor(padLen / 2)
						textToPrint = StringRepeat(paddingChar, padLen) + textToPrint + StringRepeat(paddingChar, padLen);
						if ((padLen *  2) < fieldSize)
						{
							textToPrint += " "
						}
						break;
						
					case 2:						
						// right align
						textToPrint = StringRepeat(paddingChar, padLen) + textToPrint
						break;
				}
			}
			
			Print(textToPrint)
		}
						
		public function Print(textToPrint:String)
		{
			// ditch papyrus string escape sequence
			textToPrint = textToPrint.replace(sPapyrusStringEscapeSequence, "");

			var aText:Array = textToPrint.split("");
			var i:int
			for (i = 0; i < aText.length; i++)
			{
				// insert position char index
				var insertIndex:int = GetCharIndexFromLineAndColumn(iCursorPositionLine, iCursorPositionColumn)				

				// get char element at cursor position
				var tfElementToWrite:TextField = TextField(this.getChildByName("CharElement_" + iCursorPositionLine + "_" + iCursorPositionColumn));
				//trace("ElementToWrite: Column=" + iCursorPositionColumn + ", Line=" + iCursorPositionLine + ", CharIndex=" + CursorCurrentIndex);
				
				// write to element
				if (aText[i] == "\n")
				{			
					// HANDLE LINE BREAK						
					
					if (bInsertMode)
					{
						if (iCursorPositionLine < cfgTerminalLines - 1)
						{
							ShiftDown(iCursorPositionLine + 1, 1)
						}
						
						// shift forward screen contents from insertposition by amount required to clear current line										
						var shiftAmount:int = cfgTerminalColumns - iCursorPositionColumn + 1;
						var shiftEnd:int = GetCharIndexFromLineAndColumn(iCursorPositionLine + 1, cfgTerminalColumns);
						if (shiftEnd > (cfgTerminalLines * cfgTerminalColumns ) - 1)
						{
							shiftEnd = (cfgTerminalLines * cfgTerminalColumns) - 1
						}
						trace("Shifting forward from insertIndex=" + insertIndex + " by " + shiftAmount + ", EndIndex=" + shiftEnd);			
						ShiftForward(insertIndex, shiftAmount, shiftEnd);						
					}
					
					// write linebreak at cursor position
					tfElementToWrite.text = "\n";
					tfElementToWrite.setTextFormat(defaultFormat);
					if (iCurrentColorBG == COLOR_TRANSPARENT)
					{
						tfElementToWrite.background = false;
					}
					else
					{
						tfElementToWrite.background = true;
						tfElementToWrite.backgroundColor = iCurrentColorBG;
					}
					
					tfElementToWrite.background = false;					
					
					//ReprocessLineBreaks(CursorCurrentIndex + shiftAmount + 1);
										
					// move cursor and scroll screen if required
					if (iCursorPositionLine == cfgTerminalLines)
					{
						// cursor is on last line, so shift up screen by one
						ShiftUp(1);
						
						// move cursor to beginning of line
						CursorMove(iCursorPositionLine, 1);
						
						// update async read startIndex if screen was scrolled
						if (iReadStartIndex > -1)
						{
							// shift ReadStartIndex up by one line
							iReadStartIndex -= cfgTerminalColumns;
							
							// index 0 is lowest possible index
							if (iReadStartIndex < 0)
							{								
								iReadStartIndex = 0;
							}
						}
						
					}
					else
					{
						// advance cursor to next line, position 1
						CursorMove(iCursorPositionLine + 1, 1)							
					}										
				}
				else
				{
					// insert mode
					if (bInsertMode)
					{
						// shift forward screen contents from insertposition on by one
						ShiftForward(insertIndex, 1);
					}
					
					// write element					
					tfElementToWrite.text = aText[i];
					
					// reverse mode?
					if (bReverseMode)
					{
						tfElementToWrite.setTextFormat(reverseFormat);						
						tfElementToWrite.backgroundColor = iCurrentColorFG;
						tfElementToWrite.background = true;
					}
					else
					{
						tfElementToWrite.setTextFormat(defaultFormat);
						if (iCurrentColorBG == COLOR_TRANSPARENT)
						{
							tfElementToWrite.background = false;
						}
						else
						{
							tfElementToWrite.backgroundColor = iCurrentColorBG;
							tfElementToWrite.background = true;
						}
					}

					// move cursor
					if (CursorCurrentIndex < CursorMaxIndex)
					{
						// 
						//var curIdx:int = CursorCurrentIndex;
						//var curIdx1: int = CursorCurrentIndex + 1;
						CursorMoveByIndex(CursorCurrentIndex + 1);						
					}
					else
					{
						// scroll screen
						ShiftUp(1);
						
						// move to beginning of last line
						CursorMove(iCursorPositionLine, 1);
					}
				}
			}
		}
		
/*		// broken and no longer used
		private function ReprocessLineBreaks(startIndex:int, shiftAmount:int)
		{
			var i:int;
			for (i = startIndex; i < (cfgTerminalLines * cfgTerminalColumns) - 1; i++)
			{				
				var curChar:String = aScreenMemory[i].text;
				if (curChar == "\n" || curChar == "\r")
				{
					var nextElement:int = GetNextOccupiedCharElement(i + 1);					
					if (nextElement > -1)
					{
						//var nextElementLine = GetLineFromCharIndex(nextElement);
						//var nextElementColumn = GetColumnFromCharIndex(nextElement);

						//var curLine:int = GetLineFromCharIndex(i);
						//var curCol:int = GetColumnFromCharIndex(i);
						
						//var shiftAmount:int;
						//if (nextElementLine == curLine)
						//{
						//	shiftAmount = cfgTerminalColumns - nextElementColumn - 1;
						//}
						//else
						//{
						//	shiftAmount = cfgTerminalColumns + 1;
						//}
						ShiftForward(i , shiftAmount);		
					}
					//ReprocessLineBreaks(i + shiftAmount + 1);
					break;					
				}				
			}
		}*/
		
		// not used
/*		private function GetNextOccupiedCharElement(startIndex:int) : int
		{
			var i:int;
			for (i = startIndex; i < (cfgTerminalLines * cfgTerminalColumns - 1); i++)
			{
				if (aScreenMemory[i].text != "")
				{
					return i;
				}
					
			}
			return -1;
		}*/
		
		
		public function ClearScreen(homeCursor:Boolean)
		{
			var i:int = 0;
			for (i = 0; i < aScreenMemory.length; i++)
			{
				ClearChar(i);
			}
			if (homeCursor)
			{
				CursorMove(1, 1);
			}			
		}
		
		public function ClearChar(memoryIndex:int)
		{
				aScreenMemory[memoryIndex].text = "";
				aScreenMemory[memoryIndex].setTextFormat(defaultFormat);
				if (iCurrentColorBG == COLOR_TRANSPARENT)
				{
					aScreenMemory[memoryIndex].background = false;
				}
				else
				{
					aScreenMemory[memoryIndex].background = true;
					aScreenMemory[memoryIndex].backgroundColor = iCurrentColorBG; 
					
				}
			
		}
				
		public function set ReverseMode(val:Boolean)
		{
			bReverseMode = val;
		}
		
		public function get ReverseMode() : Boolean
		{
			return bReverseMode;
		}
		
		public function set InsertMode(val:Boolean)
		{
			bInsertMode = val;
		}
		
		public function get InsertMode() : Boolean
		{
			return bInsertMode;
		}
		
		public function set ScreenEchoEnable(val:Boolean)
		{
			bScreenEchoEnable = val;
		}
		
		public function get ScreenEchoEnable() : Boolean
		{
			return bScreenEchoEnable;
		}
		
		public function set MousePointerEnable(val:Boolean)
		{
			bMousePointerEnable = val;
			if (val == true)
			{
				//trace("Mouse pointer enabled")
				Mouse.show();						   
			}
			else
			{
				//trace("Mouse pointer disabled")
				//Mouse.hide();
			}
		}
		
		public function get MousePointerEnable() : Boolean
		{
			return bMousePointerEnable;
		}


		public function set PapyrusStringEscapeSequence(val:String)
		{
			sPapyrusStringEscapeSequence = val;
		}
		
		public function get PapyrusStringEscapeSequence() : String
		{
			return sPapyrusStringEscapeSequence;
		}











		// UNUSED
		// cursor related functions/event handlers		
		//private function CursorBlinkCycleComplete(param1:Event) : void
      	//{
		//	if (this.mcCursor)
		//	{
		//		this.mcCursor.stop();
		//	}
      	//}		
		
		public function CursorMove(line:int, column:int)
		{
			// limit line/column to valid cursor position ranges
			if (line < 1) { line = 1; }
			if (line > cfgTerminalLines) {line = cfgTerminalLines; }			
			if (column < 1) { column = 1; }
			if (column > cfgTerminalColumns) { column = cfgTerminalColumns; }
			
			// get char at line/row
			var tfAddressedChar:TextField = TextField(this.getChildByName("CharElement_" + line + "_" + column));
			
			if (bCursorEnabled)
			{
				// move cursor to char
				mcCursor.x = tfAddressedChar.x //+ cfgDisplayLeftMargin;
				mcCursor.y = tfAddressedChar.y + cfgCursorOffsetY;
				mcCursor.width = tfInitChar.textWidth;
				mcCursor.height = tfInitChar.textHeight;				
			}
			
			// update cursor position memory
			iCursorPositionLine = line;
			iCursorPositionColumn = column;
			
			//trace("Cursor is on Line (" + iCursorPositionLine + "), Column (" + iCursorPositionColumn + "); CharIndex=" + GetCharIndexFromLineAndColumn(iCursorPositionLine, iCursorPositionColumn));
		}
		
		public function CursorMoveByIndex(index:int)
		{
			if (index < 0) { index = 0; }
			if (index > (cfgTerminalLines * cfgTerminalColumns) - 1) { index = (cfgTerminalLines * cfgTerminalColumns) - 1; }
						
			var tfAddressedChar = aScreenMemory[index];

			if (bCursorEnabled)
			{
				// move cursor to char
				mcCursor.x = tfAddressedChar.x //+ cfgDisplayLeftMargin;
				mcCursor.y = tfAddressedChar.y + cfgCursorOffsetY;
				mcCursor.width = tfInitChar.textWidth;
				mcCursor.height = tfInitChar.textHeight;				
			}

			var curLine:int = GetLineFromCharIndex(index);
			var curColumn:int = GetColumnFromCharIndex(index);
			
			iCursorPositionLine = curLine;
			iCursorPositionColumn = curColumn;
		}
		
		// cursor properties
		public function set CursorEnabled(val:Boolean)
		{
			bCursorEnabled = val;
			if (val)
			{
				CursorMove(iCursorPositionLine, iCursorPositionColumn);
			}
			mcCursor.visible = val;
		}
		
		public function get CursorEnabled() : Boolean
		{
			return mcCursor.visible;
		}
		
		public function get CursorCurrentIndex() : int
		{
			return GetCharIndexFromLineAndColumn(iCursorPositionLine, iCursorPositionColumn);
		}
		
		public function get CursorCurrentLine() : int
		{
			return iCursorPositionLine;
		}
		
		public function get CursorCurrentColumn() : int
		{
			return iCursorPositionColumn;
		}
		
		public function get CursorMaxIndex() : int
		{
			return (cfgTerminalLines * cfgTerminalColumns) - 1;
		}
		
		// cursor helpers
		private function GetCharIndexFromLineAndColumn(charLine:int, charColumn:int) : int
		{
			return  (((charLine - 1) * cfgTerminalColumns) + charColumn) - 1;
		}

		private function GetLineFromCharIndex(charIndex:int) : int
		{
			return Math.floor(charIndex / cfgTerminalColumns) + 1;
		}				
		
		private function GetColumnFromCharIndex(charIndex:int) : int
		{
			return (charIndex % cfgTerminalColumns) + 1;
		}
		
		private function GetFirstIndexOnLine(lineNumber:int) : int
		{
			if (lineNumber == 1) { return 0; }
			return (((lineNumber - 1) * cfgTerminalColumns) + 1);
		}
		
		private function GetLastIndexOnLine(lineNumber:int)  : int
		{
			if (lineNumber == 1) { return cfgTerminalColumns; }
			return (GetFirstIndexOnLine(lineNumber) + cfgTerminalColumns - 1);
		}

		private function IsCursorMovementRestricted(movementDirection:String, movementDistance:int) : Boolean
		{
			var retVal:Boolean = false;
			switch (movementDirection)
			{
				case CURSORMOVEMENTTYPE_UP:
					if (iReadStartIndex > -1)
					{
						if (CursorCurrentIndex - (movementDistance * cfgTerminalColumns) < iReadStartIndex)
						{
							return true;
						}
						break;						
					}
				
				case CURSORMOVEMENTTYPE_DOWN:
					if (iReadStartIndex > -1)
					{
						if (CursorCurrentIndex + (movementDistance * cfgTerminalColumns) > (iReadStartIndex + iReadMaxLength))
						{
							return true;
						}
					}
					break;
					
				case CURSORMOVEMENTTYPE_LEFT:
					if (iReadStartIndex > -1)
					{
						if ((CursorCurrentIndex - movementDistance) < iReadStartIndex)
						{
							return true;
						}
					}
					break;
				
				case CURSORMOVEMENTTYPE_RIGHT:
					if (iReadStartIndex > -1)
					{
						if (iReadMaxLength > 0)
						{
							if ((CursorCurrentIndex + movementDistance) > (iReadStartIndex + iReadMaxLength))
							{
								return true;
							}
						}
					}
					
					break;
			}
			return retVal;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		

		// keyboard related					
		
		public function ReadLineAsyncBegin(maxLength:int = 0) : Boolean
		{			
			if (iReadAsyncMode == READASYNCMODE_NONE)			
			{
				trace("PapyrusTerminal: DEBUG - ReadLineAsyncBegin() called.")
				sReadAsyncBuffer = "";
				iReadStartIndex = CursorCurrentIndex;
				iReadMaxLength = maxLength;
				iReadAsyncMode = READASYNCMODE_LINE;
				return true;			
			}
			else
			{
				trace("PapyrusTerminal: ReadLineAsyncBegin() failed. Read operation already in progress.")
				return false;
			}
		}
		
		public function ReadKeyAsyncBegin() : Boolean
		{
			if (iReadAsyncMode == READASYNCMODE_NONE)
			{
				trace("PapyrusTerminal: DEBUG - ReadKeyAsyncBegin() called.")
				sReadAsyncBuffer = "";
				iReadStartIndex = -1;
				iReadMaxLength = 0;
				iReadAsyncMode = READASYNCMODE_KEY;			
				return true;
			}
			else
			{
				trace("PapyrusTerminal: ReadKeyAsyncBegin() failed. Read operation already in progress.")
				return false;				
			}
		}
		
		public function ReadAsyncCancel()
		{
			trace("PapyrusTerminal: DEBUG - ReadAsyncCancel() called.")
			if (iReadAsyncMode != READASYNCMODE_NONE)
			{
				sReadAsyncBuffer = ""
				iReadAsyncMode = READASYNCMODE_NONE;
				iReadStartIndex = -1;
				iReadMaxLength = 0;
			
				trace("PapyrusTerminal: Pending Read operation cancelled.")
			
				if (F4SE)
				{
					trace("PapyrusTerminal: DEBUG - Sending OnReadAsyncCancelled event...")
					F4SE.SendExternalEvent(ReadAsyncCancelledEvent);				
				}
				else
				{
					trace("PapyrusTerminal: ERROR - Failed to send ReadLineAsyncCancel notification; F4SE API object is unavailable.");
				}										
			}
		}
		
		
		private function procTextInput(param1:FO4.Keyboard.InputEvent) : void
		{
			if (iReadAsyncMode == READASYNCMODE_LINE)
			{
				// don't accept input if cursor movement is restricted
				if (IsCursorMovementRestricted(CURSORMOVEMENTTYPE_RIGHT, 1))
					{
						if(this.BGSCodeObj)
			        	{
				        	BGSExternalInterface.call(this.BGSCodeObj, "playSound", "UITerminalCharEnter");
						}			

						return;
					}
			}
			
			if (iReadAsyncMode == READASYNCMODE_KEY)
			{
				iReadAsyncMode = READASYNCMODE_NONE;
				if (F4SE)
				{
					sReadAsyncBuffer = String.fromCharCode(param1.charCode);
					
					// prepend papyrus string escape sequence
					sReadAsyncBuffer = sPapyrusStringEscapeSequence + sReadAsyncBuffer;
					
					trace("PapyrusTerminal: DEBUG - [ReadKey] Sending OnReadAsyncResult(" + sReadAsyncBuffer + ")...")
					F4SE.SendExternalEvent(ReadAsyncResultEvent, sReadAsyncBuffer);
				}
				else
				{
					trace("PapyrusTerminal: ERROR - [ReadKey] Failed to send OnReadAsyncResult notification; F4SE API object is unavailable.");
				}				
			}
			else
			{
				// print to screen if screen echo is enabled and we are not in readasync key mode
				if (bScreenEchoEnable)
				{
					// print char at current cursor position
					Print(String.fromCharCode(param1.charCode));				
				}				
			}
			
			// acoustic feedback
			if(this.BGSCodeObj)
        	{
	        	BGSExternalInterface.call(this.BGSCodeObj, "playSound", "UITerminalCharEnter");
			}			
		}
		
		private function procKeyDown(param1:FO4.Keyboard.InputEvent) : void
		{
			var keypressHandled:Boolean = true;
         	switch(param1.keyCode)
         	{
	            case Keyboard.ENTER:					
					if (iReadAsyncMode == READASYNCMODE_LINE)
					{												
						for(var i:int = iReadStartIndex; i < CursorCurrentIndex; i++)
						{
							if (aScreenMemory[i].text == "")
							{
								sReadAsyncBuffer += " ";
							}
							else
							{
								sReadAsyncBuffer += aScreenMemory[i].text;
							}							
						}												
						
						// prepend papyrus string escape sequence
						sReadAsyncBuffer = sPapyrusStringEscapeSequence + sReadAsyncBuffer;
						
						iReadAsyncMode = READASYNCMODE_NONE;
						iReadStartIndex = -1;
						
						if (F4SE)
						{
							trace("PapyrusTerminal: DEBUG - [ReadLine] Sending OnReadAsyncResult(" + sReadAsyncBuffer + ") event...")
							F4SE.SendExternalEvent(ReadAsyncResultEvent, sReadAsyncBuffer);
						}
						else
						{
							trace("PapyrusTerminal: ERROR - [ReadLine] Failed to send OnReadAsyncResult notification; F4SE API object is unavailable.");
						}
						break;
					}					
					
					if (bScreenEchoEnable)
					{
						PrintLine("");
					}					
										
               		break;
					
            	case Keyboard.BACKSPACE:
					if (bScreenEchoEnable)
					{
						if (CursorCurrentIndex > 0)
						{
							if (!IsCursorMovementRestricted(CURSORMOVEMENTTYPE_LEFT, 1))
							{
								ShiftBackward(CursorCurrentIndex - 1, 1);
								CursorMoveByIndex(CursorCurrentIndex - 1);
							}
						}						
					}
					break;
					
            	case Keyboard.DELETE:    
					if(bScreenEchoEnable)
               		{
						ShiftBackward(CursorCurrentIndex, 1);
					}
	                break;
					
				case Keyboard.UP:
					if (bScreenEchoEnable)
					{
						if (iCursorPositionLine > 1)
						{
							if (!IsCursorMovementRestricted(CURSORMOVEMENTTYPE_UP, 1))
							{
								CursorMove(iCursorPositionLine - 1, iCursorPositionColumn);
							}							
						}						
					}
					break;
					
				case Keyboard.DOWN:
					if (bScreenEchoEnable)
					{
						if (iCursorPositionLine < cfgTerminalLines)
						{
							if (!IsCursorMovementRestricted(CURSORMOVEMENTTYPE_DOWN, 1))
							{
								CursorMove(iCursorPositionLine + 1, iCursorPositionColumn);
							}							
						}						
					}
					break;
					
            	case Keyboard.LEFT:
					if (bScreenEchoEnable)
					{
						if (!IsCursorMovementRestricted(CURSORMOVEMENTTYPE_LEFT, 1))
						{
							CursorMoveByIndex(CursorCurrentIndex - 1);
						}						
					}
					break;
					
            	case Keyboard.RIGHT:
					if (bScreenEchoEnable)
					{
						if (!IsCursorMovementRestricted(CURSORMOVEMENTTYPE_RIGHT, 1))
						{
							CursorMoveByIndex(CursorCurrentIndex + 1);
						}						
					}										
					break;
					
            	case Keyboard.HOME:
					if (bScreenEchoEnable)
					{
						if (iReadStartIndex > -1)
						{
							CursorMoveByIndex(iReadStartIndex);
						}
						else
						{
							if(this.cKeyboardInput.ctrlKeyPressed)
							{
								ClearScreen(true);
							}
							CursorMove(1,1);						
						}
					}
               		break;
					
            	case Keyboard.END:
               		if (bScreenEchoEnable)
					{
						CursorMove(cfgTerminalLines, cfgTerminalColumns);
					}
               		break;
					
            	case Keyboard.PAGE_UP:
               		//this._saveCurrentPage();
               		//this._setCurrentPage(this._currentJournalPage - 1);
               		break;
            	case Keyboard.PAGE_DOWN:
               		//this._saveCurrentPage();
               		//this._setCurrentPage(this._currentJournalPage + 1);
               		break;
					
            	case Keyboard.INSERT:
					if (bScreenEchoEnable)
					{
	               		bInsertMode = !bInsertMode;	
					}
               		break;
					
					
				case Keyboard.C:
					if(this.cKeyboardInput.ctrlKeyPressed)
					{
						ConfirmQuit();
					}
					break;
					
            	case Keyboard.NUMPAD_ADD:
               		//trace("Cursor Line=" + iCursorPositionLine + ", Column=" + iCursorPositionColumn + ", Index=" + CursorCurrentIndex);
               		break;
            	case Keyboard.NUMPAD_SUBTRACT:
               		//Log.info("TEST FUNC");
               		break;
            	case Keyboard.NUMPAD_MULTIPLY:
               		//Log.info("TEST FUNC");
               		break;
            	case Keyboard.NUMPAD_DIVIDE:
               		//Log.info("TEST FUNC");
               		break;
					
            	default:
               		keypressHandled = false;
			}
         	if(keypressHandled)
         	{
	        	if (BGSCodeObj)
	            {
	               BGSExternalInterface.call(BGSCodeObj, "playSound", "UITerminalCharEnter");
	            }
	        }			
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		// game interaction related
		public function onF4SEObjCreated(codeObject:*) : void
		{
			if (codeObject)
			{
				F4SE = codeObject;
				trace("PapyrusTerminal: DEBUG - Received F4SE Codeobject.");				
			}
			else
			{
				trace("PapyrusTerminal: ERROR - Failed to obtain F4SE Codeobject. Terminal won't work properly.");
			}
		}
		
      	public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      	{			
			if(this.cKeyboardInput)
         	{
				// pipe UserEvents into KeyboardInput object
				return this.cKeyboardInput.ProcessUserEvent(param1,param2);
         	}
         	return false;
      	}		

      	public function Pause(param1:Boolean) : void
      	{
        	var _loc2_:String = !!param1 ? "Paused" : "Resumed";
         	trace("PapyrusTerminal: DEBUG - Game has been " + _loc2_ + "!");
      	}
		
        public function ConfirmQuit(forceQuit:Boolean = false) : void		
        {
			if (bQuitOnTABEnable || forceQuit)
			{
				// Inform Papyrus that the terminal is shutting down
				if (F4SE)
				{
					F4SE.SendExternalEvent(TerminalShutdownEvent);
					trace("PapyrusTerminal: DEBUG - Papyrus notified about terminal shutdown.");
					Sleep(1000);
				}
				else
				{
					trace("PapyrusTerminal: ERROR - F4SE object unavailable; Unable to send shutdown notification to Papyrus.");
				}
				
				// clear temporary input layers enable
				BGSExternalInterface.call(this.BGSCodeObj, "executeCommand", "rfepc");
				
				// close the holotape
				BGSExternalInterface.call(this.BGSCodeObj, "closeHolotape");    
				
				// shutdown keyboard object
				this.cKeyboardInput.ConfirmQuit();				
			}
	    }		
				
		private function SendHolotapeChatter(numParam:int, stringParam:String)
		{
			// does not seem to work at all
			if (BGSCodeObj)
			{
				//BGSCodeObj.notifyScripts(stringParam, numParam); // does not work
				BGSCodeObj.notifyScripts(stringParam);
				trace("PapyrusTerminal: DEBUG - Sent holotape chatter.")
			}
			else
			{
				trace("PapyrusTerminal: ERROR - Failed to send holotape chatter: BGSCodeObj unavailable.")
			}			
		}		
		
		
		
		// helper functions
		
		private function ShiftForward(startIndex:int, shiftAmount:int, endIndex:int = -1)
		{
			// shifts contents of screen memory forward by <shiftAmount> chars, beginning at char index <startIndex>
			var i:int;			
			var c:int;
			var src:TextField;
			var dst:TextField;						
			var lastCharIndex:int = (cfgTerminalLines * cfgTerminalColumns) - 1;
			if (endIndex > lastCharIndex) { endIndex = lastCharIndex; }
			if (endIndex > -1) { lastCharIndex = endIndex; }
			for (i = lastCharIndex; i >= (startIndex + shiftAmount); i--)
			{
				//trace("Shifting element " + (i - 1) + " to element " + i);
				src = aScreenMemory[i - shiftAmount];
				dst = aScreenMemory[i];
				dst.text = src.text;
				
				if (src.background != dst.background)
				{
					dst.backgroundColor = src.backgroundColor;
					dst.background = src.background;
				}
				
				dst.setTextFormat(src.getTextFormat());
				src.background = false;
				src.text = "";
			}			
		}
		
		private function ShiftBackward(startIndex:int, shiftAmount:int, endIndex:int = -1)
		{
			// shifts contents of screen memory backward by <shiftAmount> chars, beginning at char index <startIndex>
			var i:int;
			var c:int;
			var src:TextField;
			var dst:TextField;
			var lastCharIndex:int = (cfgTerminalLines * cfgTerminalColumns) - 1;
			if (endIndex > lastCharIndex) { endIndex = lastCharIndex; }
			if (endIndex > -1) { lastCharIndex = endIndex; }			
			for (i = startIndex; i <= lastCharIndex - shiftAmount - 1; i++)
			{
				src = aScreenMemory[i + shiftAmount];
				dst = aScreenMemory[i];
				dst.text = src.text;
				dst.setTextFormat(src.getTextFormat());
				dst.background = src.background;						
				if (src.backgroundColor != dst.backgroundColor)
				{
					dst.backgroundColor = src.backgroundColor;						
				}					
				src.background = false;
				src.text = "";
			}
		}
		
		private function ShiftUp(shiftAmount:int)
		{
			// shifts contents of screen memory up by <shiftAmount> lines
			// LOW PRIO TODO: optimize and get rid of outer loop
			var elementsToShift = (cfgTerminalLines * cfgTerminalColumns) - cfgTerminalColumns - 1;
			var i:int;
			var c:int;
			var src:TextField;
			var dst:TextField;
			for (c = 0; c < shiftAmount; c++)
			{								
				for (i = 0; i <=  elementsToShift; i++)
				{
					src = aScreenMemory[i + cfgTerminalColumns]; // element is one line down
					dst = aScreenMemory[i];
					dst.text = src.text;					
					dst.setTextFormat(src.getTextFormat());
					dst.backgroundColor = src.backgroundColor;
					dst.background = src.background;					
					//src.backgroundColor = 0x000000;
					src.background = false;
					src.text = "";
				}
			}
		}
		
		private function ShiftDown(startLine:int, shiftAmount:int)
		{
			//trace("Startline=" + startLine);
			// shifts contents of screen memory down by <shiftAmount> lines
			var firstElement:int = GetCharIndexFromLineAndColumn(startLine, 1);
			var lastElement:int = cfgTerminalLines * cfgTerminalColumns - 1;
			var i:int;
			var c:int;
			var src:TextField;
			var dst:TextField;
			//for (c = 0; c < shiftAmount; c++)
			//{
				//trace("Cursor currently at [L=" + iCursorPositionLine + ", C=" + iCursorPositionColumn + "]");
				//trace("First element is [L=" + GetLineFromCharIndex(firstElement) + ", C=" + GetColumnFromCharIndex(firstElement) + "]");
				for (i = lastElement; i >= firstElement + (shiftAmount * cfgTerminalColumns); i--)
				{
					//trace("Shifting [L=" + GetLineFromCharIndex(i - (shiftAmount * cfgTerminalColumns)) + ", C=" + GetColumnFromCharIndex(i - (shiftAmount * cfgTerminalColumns)) + "] to [L=" + GetLineFromCharIndex(i) + ", C=" + GetColumnFromCharIndex(i) + "]...");
					src = aScreenMemory[i - (shiftAmount * cfgTerminalColumns)]; // source element is one line up
					dst = aScreenMemory[i];
					dst.text = src.text;					
					dst.setTextFormat(src.getTextFormat());
					dst.background = src.background;
					if (dst.backgroundColor != src.backgroundColor)
					{
						dst.backgroundColor = src.backgroundColor;
					}
					src.background = false;
					src.text = "";
				}
			//}
		}
		
		private function ReadScreenMemory(startIndex:int, endIndex:int) : String
		{
			var contents:String = "";
			var i:int = 0;
			for (i = startIndex; i <= endIndex; i++)
			{
				contents += aScreenMemory[i].text;
			}
			return contents;
		}
		
		private function WriteScreenMemory(startIndex:int, charsToWrite:String) : void
		{
			var contents:Array = charsToWrite.split("");
			var i:int = 0;
			for (i = startIndex; i < contents.length; i++)
			{
				aScreenMemory[i].text = contents[i];
			}
		}
		
		private function WriteChars(charToWrite:String, startPos:int, repetitions:int)
		{
			var i:int;
			for (i = 0; i < repetitions; i++)
			{
				aScreenMemory[startPos + i].text = charToWrite;
			}
		}
		
		private function Sleep(ms:int):void
		{
    		var init:int = flash.utils.getTimer();
    		while(true)
			{
        		if (flash.utils.getTimer() - init >= ms)
				{
            		break;
        		}
    		}
		}

		private function GetRoot():MovieClip
		{
    		return stage.getChildAt(0) as MovieClip;
		}		
		

		// convenience functions
		public function StringRepeat(sequenceToRepeat:String, numberOfRepetitions:int)
		{	
			var retVal:String = ""
			var i:int
			for (i = 0; i < numberOfRepetitions; i++)
			{
				retVal += sequenceToRepeat;
			}
			return retVal
		}
		
	
		// string utility functions / wrappers and other papyrus extensions, directly callable by papyrus				

		public function ExecuteConsoleCommandPapyrus(param1:Object, ...rest) : void
		{
			if (param1 != null)
			{
				var command:String = String(param1);
				if (command != "")
				{
					BGSExternalInterface.call(this.BGSCodeObj, "executeCommand", command);
				}
			}			
		}

		public function StringSplitPapyrus(param1:Object, ...rest) : Array
		{
			var line:String = "";
			var separator:String = " ";
			
			if (param1 != null)
			{
				line = String(param1);
				
				// ditch papyrus string escape sequence
				line = line.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					separator = String(rest[0]);
					separator = separator.replace(sPapyrusStringEscapeSequence, "");
				}

				var res:Array = line.split(separator);


				// prepend escape seq to array elements
				var i:int = 0;
				for (i = 0; i < res.length; i++)
				{
					res[i] = sPapyrusStringEscapeSequence + res[i];
				}
				
				return res;
			}
			
			return new Array();
		}
		
		public function StringCharAtPapyrus(param1:Object, ...rest) : String
		{
			var inString:String = "";
			var charIndex:int = 0;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					charIndex = int(rest[0]);
				}
				
				// prepend papyrus string escape sequence
				return sPapyrusStringEscapeSequence + inString.charAt(charIndex);
			}
			
			return "";
		}
		
		public function StringCharCodeAtPapyrus(param1:Object, ...rest) : int
		{
			var inString:String = "";
			var charIndex:int = 0;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					charIndex = int(rest[0]);
				}
				
				return int(inString.charCodeAt(charIndex));			
			}
			
			return -1;
			
		}
		
		public function StringIndexOfPapyrus(param1:Object, ...rest) : int
		{
			var inString:String = "";
			var subString:String = "";
			var startIndex:int = 0;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					subString = String(rest[0]);
					subString = subString.replace(sPapyrusStringEscapeSequence, "");
				}
				
				if (rest[1] != null)
				{
					startIndex = int(rest[1]);
				}
				
				return int(inString.indexOf(subString, startIndex));
			}
			
			return -1;
			
		}

		public function StringLastIndexOfPapyrus(param1:Object, ...rest) : int
		{
			trace("StringLastIndexOfPapyrus");
			var inString:String = "";
			var subString:String = "";
			var startIndex:int = 0x7FFFFFFF;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				//trace("StringLastIndexOfPapyrus-inString=" + inString);
				
				if (rest[0] != null)
				{
					subString = String(rest[0]);
					subString = subString.replace(sPapyrusStringEscapeSequence, "");					
					//trace("StringLastIndexOfPapyrus-subString=" + subString); 
				}
				
				if (rest[1] != null)
				{
					startIndex = int(rest[1]);
					if (startIndex == -1)
					{
						startIndex = inString.length - 1;
					}
					//trace("StringLastIndexOfPapyrus-startIndex=" + startIndex);
				}
				
				var retVal:int = inString.lastIndexOf(subString, startIndex);				
				//trace("StringLastIndexOfPapyurs-retVal=" + retVal);
				return retVal;
			}
			
			return -1;			
		}
		
		public function StringReplacePapyrus(param1:Object, ...rest) : String
		{
			var inString:String = "";
			var pattern:String = null;
			var replacement:String = null;
			
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					pattern = String(rest[0]);
					pattern = pattern.replace(sPapyrusStringEscapeSequence, "");
					
				}
				if (rest[1] != null)
				{
					replacement = String(rest[1]);
				}
				
				return sPapyrusStringEscapeSequence + inString.replace(pattern, replacement);				
			}
			
			return "";
		}
		
		public function StringSlicePapyrus(param1:Object, ...rest) : String
		{
			var inString:String = "";
			var startIndex:int = 0;
			var endIndex:int = 0x7fffffff;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					startIndex = int(rest[0]);
				}
				if (rest[1] != null)
				{
					endIndex = int(rest[1]);
				}
								
				return sPapyrusStringEscapeSequence + inString.slice(startIndex, endIndex);
			}
			
			return "";
		}
		
		public function StringSubstringPapyrus(param1:Object, ...rest) : String
		{
			var inString:String = "";
			var startIndex:int = 0;
			var endIndex:int = 0x7fffffff;
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (rest[0] != null)
				{
					startIndex = int(rest[0]);
				}
				if (rest[1] != null)
				{
					endIndex = int(rest[1]);
				}
								
				return sPapyrusStringEscapeSequence + inString.substring(startIndex, endIndex);
			}
			
			return "";			
		}
		
		public function StringIsNumericPapyrus(param1:Object, ...rest) : Boolean
		{
			var inString:String = "";
			if (param1 != null)
			{				
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				if (inString == "")
				{
					return false;
				}
				
				return (!isNaN(Number(inString)));
			}
			
			return false;
		}
		
		public function StringLengthPapyrus(param1:Object, ...rest) : int
		{
			var inString:String = "";
			if (param1 != null)
			{
				inString = String(param1);
				inString = inString.replace(sPapyrusStringEscapeSequence, "");
				
				return inString.length;
			}
			
			return 0;
		}
		
		public function StringFormatPapyrus(param1:Object, ...rest) : String
		{
			var inString:String = "";
			if (param1 != null)
			{
				inString = String(param1);
				return printf(inString, rest)
			}
			
			return "";
		}
		
		public function StringRepeatPapyrus(param1:Object, ...rest) : String
		{
			var sequenceToRepeat:String = "";
			var repetitions:int = 1;
			var retVal:String = "";
			
			if (param1 != null)
			{
				sequenceToRepeat = String(param1);
				sequenceToRepeat = sequenceToRepeat.replace(sPapyrusStringEscapeSequence, "");
				
				if (sequenceToRepeat != "")
				{
					if (rest[0] != null)
					{
						repetitions = int(rest[0]);
					}
					
					for (var i:int = 0; i < repetitions; i++)
					{
						retVal += sequenceToRepeat
					}
					
					return sPapyrusStringEscapeSequence + retVal;					
				}
			}
			
			return ""
		}		
	}	
}
