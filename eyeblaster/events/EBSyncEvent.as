//****************************************************************************
//      class eyeblaster.events.EBSyncEvent
//----------------------------------------------
//This class contains the events of Sync ads
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{ 
	import flash.events.Event;
    public class EBSyncEvent extends flash.events.Event
	{
        
		public static const CONNECTION_FOUND:String = "onConnectionFound";
		public static const CONNECTION_NOT_FOUND:String = "onConnectionNotFound";
		private var _assetName;			
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function EBSyncEvent(type:String, value):void
		{
			super(type);
			this._assetName = value;
		}
		//===============
		//	value
		//===============
		public function get assetName()
		{
			return this._assetName;
		}
		
	}
}

