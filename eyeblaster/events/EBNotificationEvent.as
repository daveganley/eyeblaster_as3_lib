package eyeblaster.events 
{
	import flash.events.Event;
	
	/**
	 * defines custom events that are dispatched by the component
	 * @author mehari
	 */
	dynamic public class EBNotificationEvent extends Event 
	{
		// Notification event main type
		public static const NOTIFICATION:String 	= "Notification";
		// Notification event subtypes
		/*
		 * close event notification string
		 * For instream, make sure to cleanup listeners and timers
		*/
		public static const CLOSE:String        = "Close";
		/*
		 * Init event notification string
		 */
		public static const INIT:String			= "Init";
		/*
		 * Clickthrough event notification string
		 */
		public static const CLICK:String 		= "Click";
		/*
		 * interaction tracking event notification string
		 */
		public static const TRACK:String        = "Track";
		/*
		 * sound mute event notification string
		 */
		public static const MUTE:String         = "Mute";
		/*
		 * sound unmute event notificaiton string
		 */
		public static const UNMUTE:String       = "Unmute";
		
		/**
		 * Expand Event Notification String subtype
		 */
		public static const EXPAND:String = "Expand";
		
		/**
		 * Collapse Event Notification String subtype
		 */
		public static const COLLAPSE:String = "Collapse";
		
		/**
		 * Log Event Notification String event type
		 */
		public static const LOG:String = "Log";
		
		/* The following event types are instream shell events that can be heard by the creative */
		
		/**
		 * Event type that instructs the ad to start, the format should begin content
		 */
		public static const START_AD:String = "startAd";
		/**
		 * Event type that instructs the Ad to pause.
		 */
		public static const PAUSE_AD:String = "pauseAd";
		/**
		 * Event type that instructs the Ad to resume
		 */
		public static const RESUME_AD:String = "resumeAd";
		/**
		 * Event type that notifies the Ad that it is about to be unloaded
		 */
		public static const STOP_AD:String = "stopAd";
		/**
		 * Event type that instructs the Ad to expand. this event is only valid for NON-LINEAR ads that are 
		 * controlled by the player
		 */
		public static const EXPAND_AD:String = "expandAd";
		/**
		 * Event type that instructs the Ad to collapse. this event is only valid for NON-LINEAR ads that are 
		 * controlled by the player
		 */
		public static const COLLAPSE_AD:String = "collapseAd";
		/**
		 * Event type that instructs the ad to show a "skip Ad" control. This feature is only supported in VPAID 2.0
		 */
		public static const SKIP_AD:String = "skipAd";
		/**
		 * Event type that instructs the ad to set its volume to a specific value (adVolume).  
		 * The ad should set the volume appropriately. It does not need to do it for video volume as this is taken care of in the shell 
		 */
		public static const SET_AD_VOLUME:String = "setAdVolume";
		/**
		 * Event type that instructs the ad to show a "close ad" control. 
		 */
		public static const DISPLAY_AD_CLOSE_BUTTON:String = "displayAdCloseButton";

		/**
		 * Event type that instructs all register objects to exit full screen mode. 
		 */
		public static const EXIT_FULLSCREEN_MODE:String = "exitFullScreenMode";
		
		/* end instream shell events */
		
		
		public var subtype:String;
		
		public function EBNotificationEvent(type:String, subType:String, bubbles:Boolean = true, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
			this.subtype = subType;
		}
		
		override public function clone():flash.events.Event 
		{
			return new EBNotificationEvent(type, subtype, bubbles, cancelable);
		}
	}

}