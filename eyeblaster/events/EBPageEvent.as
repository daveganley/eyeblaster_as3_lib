//****************************************************************************
//class eyeblaster.video.general.EBPageEvent
//-------------------------------------------
//This class contains events from the page
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBPageEvent extends Event
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _info:Object;					//event value
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public static const PAGE_LOAD:String = "ebPageLoad";
		public static const MOUSE_MOVE:String = "ebMouseMove";
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function EBPageEvent(type:String, args:String):void
		{
			super(type);
			var arrParams:Array = args.split(",");
			this._info = { };
			this._info.xPos = Number(arrParams[0]);
			this._info.yPos = Number(arrParams[1]);
			this._info.relXPos = Number(arrParams[2]);
			this._info.relYPos = Number(arrParams[3]);
		}
		
		//====================
		//	Getter functions
		//====================
		public function get xPos():Number
		{
			return _info.xPos;
		}
		
		public function get yPos():Number
		{
			return _info.yPos;
		}
		
		public function get relXPos():Number
		{
			return _info.relXPos;
		}
		
		public function get relYPos():Number
		{
			return _info.relYPos;
		}
	}
}