//****************************************************************************
//class eyeblaster.events.SmartVersioningEvent
//------------------------------------
//This class represents eyeblaster Complete Event object used by Smart Versioning
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class SmartVersioningEvent extends Event
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _item;					//event item property
		
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public static const COMPLETE:String = "Complete";
		public static const XMLLOADED:String = "XMLloaded";
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function SmartVersioningEvent(type:String, item):void
		{
			super(type);
			this._item = item;
		}
		
		//===============
		//	item value
		//===============
		public function get item()
		{
			return this._item;
		}
		
		//===============
		//	toString
		//===============
		public override function toString():String
		{
			return formatToString("Event", "type", "item");
		}
		
	}
}