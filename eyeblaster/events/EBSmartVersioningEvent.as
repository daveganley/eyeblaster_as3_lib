//****************************************************************************
//class eyeblaster.events.EBSmartVersioningEvent
//------------------------------------
//This class represents eyeblaster Complete Event object used by Smart Versioning
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBSmartVersioningEvent extends Event
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _item;					//event item property
		
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public static const COMPLETE:String = "Complete";
		public static const XML_LOADED:String = "XMLloaded";
		public static const DOWNLOAD_COMPLETE:String = "DownloadComplete";
		public static const SWFS_DOWNLOAD_COMPLETE:String = "SWFsDownloadComplete";
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function EBSmartVersioningEvent(type:String, item):void
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