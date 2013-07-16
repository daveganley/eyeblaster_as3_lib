package eyeblaster.events
{
	import flash.events.Event;
	import eyeblaster.videoPlayer.IVideoScreen;
	
	public class EBVideoManagerEvent extends Event
	{
		public static const VIDEO_REGISTERED:String = "ebVideoRegistered";
		public static const VIDEO_CHANGED:String = "ebVideoChanged";
		
		public var video:*;
		public var screen:IVideoScreen;
		
		public function EBVideoManagerEvent(type:String, video:*, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.video = video;
			
			if(video is IVideoScreen){
				this.screen = video as IVideoScreen;
			}
		}
	}
}