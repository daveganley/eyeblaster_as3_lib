package eyeblaster.events {
	import flash.events.Event;
	
	/**
	 * @author jhaygood
	 */
	public class EBLiveStreamEvent extends Event
	{
		public var info:Object;
		
		public static const FC_SUBSCRIBE:String = "fcSubscribe";
		public static const FC_UNSUBSCRIBE:String = "fcUnsubscribe";
		
		public function EBLiveStreamEvent(type:String, info:Object)
		{
			super(type);
			this.info = info;
		}
	}
}
