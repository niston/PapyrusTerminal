package  {
	
	import flash.display.MovieClip;
	
	
	public class Cursor extends MovieClip {
		
		
		public function Cursor() {
			// constructor code
/*						// apply color filter to cursor
			var matrix:Array = new Array();
			matrix=matrix.concat([0,0,0,0,0]);// red
			matrix=matrix.concat([0,1,0,0,0]);// green
			matrix=matrix.concat([0,0,0,0,0]);// blue
			matrix=matrix.concat([0,0,0,1,0]);// alpha
			var colorFilter:ColorMatrixFilter = new ColorMatrixFilter(matrix);			
			this.filters = [colorFilter]
*/
		}
		
		public function instance():MovieClip
		{
			return this;
		}
	}
	
}
