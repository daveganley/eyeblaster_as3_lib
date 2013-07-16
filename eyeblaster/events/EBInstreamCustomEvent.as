package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBInstreamCustomEvent extends Event
	{
		private var _data:Object;
		private var _isFromPlayer:Boolean
		
		/**
		 * Property that denotes whether the custom event was dispatched from the player or from the ad.
		 */
		public var isFromPlayer:Boolean;
		
		public function EBInstreamCustomEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			_data = data;
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Custom data associated with custom event
		 */
		public function get data():Object
		{
			return _data;
		}
	}
}