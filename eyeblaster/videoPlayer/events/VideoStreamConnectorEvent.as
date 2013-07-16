package eyeblaster.videoPlayer.events
{
	import flash.events.Event;
	import eyeblaster.videoPlayer.core.EBNetConnection;
	
	/** @private */
	public class VideoStreamConnectorEvent extends Event
	{
		public static var STREAM_CONNECTED:String = "streamConnected";
		public static var STREAM_FAILED:String = "streamFailed";
		public var stream:EBNetConnection;
		
		public function VideoStreamConnectorEvent(name:String, stream:EBNetConnection)
		{
			super(name);
			this.stream = stream;
		}
	}
}