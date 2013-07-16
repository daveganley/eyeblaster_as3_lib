//****************************************************************************
//class eyeblaster.utilities.syncAds.SyncSearchedAsset
//-------------------------------------------
//class SyncSearchedAsset handles the object in the array that looks for the assets.
// Each object contains 3 values- the name of the asset that 
// needs to be found, a flag that indicates if the asset is looked for
// at the present and maximum number of calls in order to find the asset.
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************

package eyeblaster.utilities.syncAds
{
	class SyncSearchedAsset 
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private var _assetName:String;		//the asset name
		private var _numOfInterval:Number;	//the maximum number of calls in order to find the asset.
		private var _fIsLookedFor:Boolean;	//a flag that indicates if the asset is looked for
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//================================
		//	constructor SyncSearchedAsset
		//================================
		// A constructor for an object in the array that looks for the assets.
		// Each object contains 3 values- the name of the asset that 
		// needs to be found, a flag that indicates if the asset is looked for
		// at the present and maximum number of calls in order to find the asset.
		//	Parameters:
		//		assetName:String-     the asset name
		//		numOfInterval:Number- the maximum number of calls in order to find the asset.
		public function SyncSearchedAsset(assetName:String,numOfInterval:Number)
		{
			this._assetName = assetName;
			this._numOfInterval = numOfInterval;
			// Since a new object is created when wanting to find a new asset
			// isLookedFor is set to true
			this._fIsLookedFor = true;
		}
	
		//------- set/get functions --------  
		
		//==========================
		//	function set isLookedFor
		//==========================
		// The function set the _fIsLookedFor data member of the instance
		//	Parameters:
		//		isLookedForVal:Boolean - a parameter that indicates the value that 
		//		should be set to isLookedFor data member.
		public function set isLookedFor(isLookedForVal:Boolean):void
		{
			this._fIsLookedFor = isLookedForVal;
		}
		
		//==========================
		//	function get isLookedFor
		//==========================
		// The function returns the _fIsLookedFor data member of the instance	
		public function get isLookedFor()
		{
			return this._fIsLookedFor;
		}
		
		//==========================
		//	function numOfInterval
		//==========================
		// The function set the _numOfInterval data member of the instance
		//	Parameters:
		//		NumOfIntervalVal:Number - a parameter that indicates the value that 
		//		should be set to numOfInterval data member.
		public function set numOfInterval(NumOfIntervalVal:Number):void
		{
			this._numOfInterval = NumOfIntervalVal;
		}
	
		//==============================
		//	function get numOfInterval
		//==============================
		// The function returns the _numOfInterval data member of the instance	
		public function get numOfInterval()
		{
			return this._numOfInterval;
		}
		
		//==========================
		//	function get assetName
		//==========================
		// The function returns the assetName data member of the instance	
		public function get assetName()
		{
			return this._assetName;
		}
		
	}
}