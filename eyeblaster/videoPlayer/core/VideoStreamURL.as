package eyeblaster.videoPlayer.core
{
	
	public class VideoStreamURL
	{
		private var _vsFMS:String;
		private var _vsFileName:String;
		
		public function get vsFMS():String
		{
			return _vsFMS;
		}
		
		public function get vsFileName():String
		{
			return _vsFileName;
		}
				
		public function VideoStreamURL(fms:String, filename:String)
		{
			if (filename.toLowerCase().indexOf("rtmp://") == 0)
				splitURL(filename);
			else
			{
				_vsFMS = fms;
				_vsFileName = fixFileName(filename);
			}
		}
		
		private function splitURL(filename:String):void
		{
			var tmpArr:Array;

			if ( filename.indexOf("mp4:") != -1 )
			{
				tmpArr = filename.split("mp4:");

				_vsFMS = tmpArr[0];
				_vsFileName = fixFileName("mp4:"+tmpArr[1]);
			}
			else
			{
				_vsFMS = filename.slice(0, filename.lastIndexOf("/"));
				_vsFileName = fixFileName( filename.slice(filename.lastIndexOf("/")+1, filename.length) );
			}
			
		}
		
		private function fixFileName(fname:String):String
		{
			var extention:String = fname.slice(fname.lastIndexOf("."), fname.length);

			switch (extention.toLowerCase())
			{

			case ".flv":
				return fname.substr(0, fname.length-4);
			
			case ".mp4":
			case ".f4v":
				if (fname.indexOf("mp4:") != 0)
					return "mp4:"+fname;
				else
					return fname;
			
			default:
				return fname;
			
			} 
		}
	}
}
