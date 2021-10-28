package
{
	import PapyrusTerminal;
	import System.Diagnostics.Debug;
	import System.Diagnostics.Utility;
	import System.Display;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	// https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findfirstfilea
	// https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findnextfilea
	// https://docs.microsoft.com/en-us/cpp/standard-library/directory-iterator-class
	// https://docs.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-win32_find_dataa
	// http://www.cs.rpi.edu/courses/fall01/os/WIN32_FIND_DATA.html <---

	public class CodeClient extends MovieClip
	{
		// private const DirectoryRoot:String = "..\\Fallout 4";
		// private const ScrivenerFO4:String = "E:\\Games\\Steam\\steamapps\\common\\Fallout 4";


		// Initialize
		//---------------------------------------------

		public function CodeClient()
		{
			Debug.Prefix = "PapyrusTerminal";
			Debug.WriteLine("[CodeClient]", "(CTOR)");
			addEventListener(Event.ADDED_TO_STAGE, this.OnAddedToStage);
		}


		protected function OnAddedToStage(e:Event):void
		{
			Debug.WriteLine("[CodeClient]", "(OnAddedToStage)", "swf:"+this.loaderInfo.url);
			try
			{
				Utility.TraceObject(PapyrusTerminal.F4SE);
			}
			catch (error:Error)
			{
				Debug.WriteLine("[CodeClient]", "(OnAddedToStage)", "Exception", String(error));
			}
		}


		// Displays the name of or changes the current directory.
		public function CD(directory:String):String
		{
			directory = "."; //  <---------- temp testing without Papyrus.
			Debug.WriteLine("[CodeClient]", "(CD)", "directory:"+directory);

			try
			{
				var result:Array = PapyrusTerminal.F4SE.GetDirectoryListing(directory, "*.txt", false);
				Debug.WriteLine("[CodeClient]", "(CD)", "result.length:", result.length);
				Debug.WriteLine("\n");

				if(result.length > 0)
				{
					for each (var entry in result)
					{
						Debug.WriteLine("(CD)", "'"+directory+"'", "+ name:         ", entry.name);
						Debug.WriteLine("(CD)", "'"+directory+"'", "+ -- nativePath: ", entry.nativePath);
						Debug.WriteLine("(CD)", "'"+directory+"'", "+ -- isDirectory:", entry.isDirectory);
						Debug.WriteLine("(CD)", "'"+directory+"'", "+ -- isHidden:   ", entry.isHidden);
						Debug.WriteLine("");

						// if(entry.isDirectory && !entry.isHidden)
						// {
						// 	return entry.nativePath;
						// }
					}

					Debug.WriteLine("\n");
					return result[0].nativePath;
				}
				return "";
			}
			catch (error:Error)
			{
				Debug.WriteLine("[CodeClient]", "(CD)", "Exception", String(error));
			}
			return "";
		}


		// Displays a list of files and subdirectories in a directory.
		public function DIR(directory:String):*
		{
			// directory = "."; //  <---------- temp testing without Papyrus.

			try
			{
				var result:Array = PapyrusTerminal.F4SE.GetDirectoryListing(directory, "*", false);
				Debug.WriteLine("[CodeClient]", "(DIR)", "directory:"+directory, "result.length:", result.length);

				var values:Array = new Array(result.length);
				if(result.length > 0)
				{
					var idx:int = 0;
					while(idx < result.length)
					{
						var isDir:String = "  ";
						if(result[idx].isDirectory)
						{
							isDir = "<DIR>";
						}

						values[idx] = result[idx].lastModified + "  "+isDir + "  "+result[idx].name;
						idx += 1;
					}
				}
				return values;
			}
			catch (error:Error)
			{
				Debug.WriteLine("[CodeClient]", "(DIR)", "Exception", String(error));
			}

			return null;
		}


		// Prints a text file.
		public function TYPE(filepath:String):Array
		{
			Debug.WriteLine("[CodeClient]", "(TYPE)", "filepath:"+filepath);
			//filepath = "..\\..\\Data\\Scripts\\Source\\PapyrusTerminal\\PapyrusTerminal\\KERNAL.psc";

			var fileLoader:URLLoader = new URLLoader();
			fileLoader.addEventListener(Event.COMPLETE, TYPE_OnLoaded);
			fileLoader.load(new URLRequest(filepath));

			return new Array("Eins", "Zwei", "Drei"); // temp
		}

		// TODO: synchronously return this value, or embrace async
		private function TYPE_OnLoaded(e:Event):void
		{
			// TODO: send it to the this.parent.parent.parent instance directly.
			var lines:Array = e.target.data.split(/\n/);
			Debug.WriteLine("[CodeClient]", "(TYPE)", "lines:"+lines.length);
		}


	}
}
