//****************************************************************************
//      class  eyeblaster.events.EBMetadataEvent 
//---------------------------------------------
//The class contains the metada of the video
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBMetadataEvent extends Event
	{
		
		private var _info:Object;

		public static const CUE_POINT:String = "ebCuePoint";
		public static const METADATA_RECEIVED:String = "ebMetadataReceived";
		public static const XMPDATA_RECEIVED:String = "ebXMPDataReceieved";

		public function EBMetadataEvent(type:String, value:Object):void
		{
			super(type);
			_info = value
		}
		
		public function get info():Object
		{
			return _info;
		}
	}
}

