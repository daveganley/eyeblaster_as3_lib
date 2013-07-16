//****************************************************************************
//class eyeblaster.events.EBSingleExpandableEvent
//------------------------------------
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBSingleExpandableEvent extends Event
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public static const EXPAND_PANEL:String = "ExpandPanel";
		public static const BEFORE_COLLAPSE_PANEL:String = "BeforeCollapsePanel";
		public static const AFTER_COLLAPSE_PANEL:String = "AfterCollapsePanel";
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function EBSingleExpandableEvent(type:String):void
		{
			super(type);
		}

		//===============
		//	toString
		//===============
		public override function toString():String
		{
			return formatToString("Event", "type");
		}
		
	}
}