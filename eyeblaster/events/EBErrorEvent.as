//****************************************************************************
//class eyeblaster.events.EBErrorEvent
//------------------------------------
//This class represents eyeblaster Error Event object
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBErrorEvent extends Event
	{
		
		private var _msg:String;					

		public static const ERROR:String = "Error";

		public function EBErrorEvent(type:String, msg:String):void
		{
			super(type);
			_msg = msg;
		}

		public function get message():String
		{
			return _msg;
		}

		public override function toString():String
		{
			return formatToString("Event", "type", "message");
		}
	}
}