package eyeblaster.events
{
	import flash.events.Event;
	
	/**
	 * EBInstreamEvent
	 *
	 * Events that are dispatched to class EBInstream from loader/player
	 *
	 * @see EBInstream
	 */	
	public class EBInstreamEvent extends Event
	{
		public static const COLLAPSE_EVENT	:String = "collapseAd";
		public static const EXPAND_EVENT	:String = "expandAd";
		public static const STOP_EVENT		:String = "stopAd";
		public static const PAUSE_EVENT		:String = "pauseAd";
		public static const RESUME_EVENT	:String = "resumeAd";
		public static const SKIP_EVENT		:String = "skipAd";
		public static const START_EVENT		:String = "startAd";
		
		private var info:Object;
		
		public function EBInstreamEvent(type:String, info:Object = null)
		{
			super(type, info);
			this.info = info;
		}
	}
}