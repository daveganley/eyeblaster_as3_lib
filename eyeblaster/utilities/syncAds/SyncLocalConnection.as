//****************************************************************************
//class eyeblaster.utilities.syncAds.SyncLocalConnection
//-------------------------------------------
//This is a subclass of LocalConnection that is modified to work with the 
//SyncAds class.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.utilities.syncAds
{
	import flash.net.LocalConnection;

	public class SyncLocalConnection extends LocalConnection
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private var _parentRef;  //holds a reference to the localConnection parent -> instance of SyncAds component
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function SyncLocalConnection(objRef)
		{
			//attach _parentRef to the SyncAds instance
			//to allow access to the class from the _lc object
			this._parentRef = objRef;
			super();
		}
		
		//============================
		//	function handleEvent
		//============================
		//call from the _lc instance to the function _handleEvent which exist in the SyncAds class 
		//Parameters:
		//		functionName:String - The functionName we want to call to (which is implemented by the creative)
		//		Params: the parameters the functionName receives
		public function handleEvent(functionName:String,Params:String):void
		{
			this._parentRef.handleEvent(functionName,Params);
		}
		
		//============================
		//	function areUThere
		//============================
		//call from the _lc instance to the function areUThere which exist in the SyncAds class 
		//Parameters:
		//		callerName:String - the instance name of the asset that searches for assets
		public function areUThere(callerName:String):void
		{
			this._parentRef.areUThere(callerName);
		}
		
		//============================
		//	function assetName
		//============================
		//call from the _lc instance to the function assetFound which exist in the SyncAds class 
		//Parameters:
		//	assetName:String - the name of the asset that was called by the other asset
		public function assetFound(assetName:String):void
		{
			this._parentRef.assetFound(assetName);
		}
		
	}
}