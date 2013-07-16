package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBVideoStateEvent extends Event
	{
		public static const VIDEOSTATE_CHANGE:String = "ebVideoStateChange";
		
		public var isPaused:Boolean;
		public var isPlaying:Boolean;
		public var isStopped:Boolean;
		public var isFullScreen:Boolean;
		
		public function EBVideoStateEvent(type:String, isPlaying:Boolean, isPaused:Boolean, isStopped: Boolean, isFullScreen:Boolean, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.isPaused = isPaused;
			this.isPlaying = isPlaying;
			this.isStopped = isStopped;
			this.isFullScreen = isFullScreen;
		}
	}
}