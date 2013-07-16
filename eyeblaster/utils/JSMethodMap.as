package eyeblaster.utils 
{
	/**
	 * This class contains all the JS Method interfaces that the unicast component uses
	 * These JS methods will eithr have to be implemented in mdmd delivery or equivalent functionality in EB needs to be found
	 * @author ml
	 */
	public class JSMethodMap 
	{
		
		public static const JS_TRACK_INTERACTION:String = 				 "VwTrackInteraction";
		public static const JS_LIMIT_INTERACTION:String =				 "VwLimit";
		public static const JS_SET_VIDEO_TIME_PLAYED:String =			 "VwSetTimePlayed";
		public static const JS_AD_READY_TO_PLAY:String = 				 "VwReadyToPlay";
		public static const JS_CLOSE_AD:String = 						 "VwCloseAd";
		public static const JS_EXECUTE_COMMAND:String =					 "VwCmd";
		public static const JS_PING:String = 							 "VwPing";
		public static const JS_HIDE_PANEL:String = 						 "VwHidePanel";
		public static const JS_TRACE:String = 							 "VwTrace";
		public static const JS_SHOW_PANEL:String = 						 "VwShowPanel";
		public static const JS_MODFIY_PANEL:String =					 "VwModifyPanel";
		public static const JS_MODIFY_PANEL_REL_TO_ORIG:String = 		 "VwModifyPanelRelToOrig";
		public static const JS_ANIMATE_PANEL:String =					 "VwAnimatePanel";
		public static const JS_START_TIMEOUT:String = 					 "VwStartTimeout";
		public static const JS_PING_NAVIGATE:String = 					 "VwPingNavigate";
		public static const JS_CANCEL_ALL_TIMEOUTS:String = 			 "VwCancelAllTimeouts";
		
		
	}

}