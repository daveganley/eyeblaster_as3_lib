//****************************************************************************
//class eyeblaster.media.general.ebVideoEvent
//------------------------------------
//This class represents eyeblaster video Event object
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.general
{
	import flash.events.Event;
	
	public class VideoEvent extends flash.events.Event
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _value;					//event value
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function VideoEvent(type:String, value):void
		{
			super(type);
			this._value = value;
		}
		//===============
		//	value
		//===============
		public function get value()
		{
			return this._value;
		}
		
	}
}