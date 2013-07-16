//****************************************************************************
//class  eyeblaster.utils.syncAds.SyncAds
//-------------------------------------------
// The SyncAds component enables few ads on the page to communicate
// with one another.
// The component will use a class called SyncLocalConnection
// in order to transfer messages between the resources.

//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************

package eyeblaster.utils.syncAds
{
	import eyeblaster.utils.syncAds.SyncSearchedAsset;
	import eyeblaster.utils.syncAds.SyncLocalConnection;
	import eyeblaster.core.Tracer;
	import flash.display.MovieClip;
	import flash.net.LocalConnection;
	import flash.utils.*;
	import flash.events.*;
	import flash.system.Security;
	import flash.system.*;
	
	public class SyncAds extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		// A string that holds the synchronization level group.
		private var _strLevel:String;
		
		// A flag that indicates whether the asset already has
		// a local connection opened for receiving messages from
		// other resources.
		private var _fRegistered:Boolean;
		
		// A string that holds the  name of the asset
		private var _strResName:String; 
		
		// A string that holds the name of the connection of 
		// the asset. The name of the connection is based on 
		// combination between the asset name and the sync level
		private var _strConnName:String;
		
		// An interval that is set in order to find an asset in a loop
		// until it is found or TimeOut period is over.
		private var _findIntervalID:Number;
	
		// A Number that holds the time in milliseconds between calls to areUThere method.
		// The time between the calls of the interval is set to 200 ms.
		private var _findIntervalTime:Number
		
		// A flag that indicates whether to create the interval or not.
		private var _CanCreateInterval:Boolean;
		
		// An array that holds objects of type Asset. Each object holds three properties:
		// the asset name, the number of calls that will be caused by the interval
		// (or -1 if TimeOut period is not sent by the creative), and a flag that indicates whether 
		// the asset is looked for at the present.
		private var _arrFindAsset:Array;
		
		// A LocalConnection object used to receive events (messages)from other resources. 
		private var _localLC:SyncLocalConnection;
		
		// A LocalConnection object used for findConnection function.
		// In this way the caller for the findConnection function
		// will have a connection that it listens to, opened.
		private var _findLC:SyncLocalConnection;
		
		// A string for the connection name of _findLC local connection. 
		private var _findLcConnName:String;
		
		// A LocalConnection object used to send events (messages).
		private var _sendingLC:LocalConnection;
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		// A pointer to a function. Will be called when the 
		// connection that was being looked for was found
		public var onConnectionFound:Function;
		
		// A pointer to a function. Will be called only if the creative inserts
		// a parameter in findConnection function that indicated 
		// the number of seconds until the findConnection  function
		// will be considered as failed if the searched asset wasn’t found
		public var onConnectionNotFound:Function;
		
	
		//----General------
		include "../../core/compVersion.as"
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	constructor SyncAds
		//======================
		// A constructor for the SyncAds component.
		//call to init function which inits the component and the parameters
		public function SyncAds()
		{
			Tracer.debugTrace("SyncAds: Constructor",6);
			Tracer.debugTrace("SyncAds version: "+compVersion,0);
			Tracer.debugTrace("Eyeblaster Workshop | SyncAds | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			this._init();
		}
		
		//-------- API functions -----------
		
		//===================================
		//	function setLevel
		//===================================
		//	This function sets the level 
		//	this resource is using. 
		//	Parameters:
		//		level:String
		//		Possible values:
		//			"ad" 
		//			"campaign"(default)
		//	Note: This function is optional, but if used should be the first 
		//	function Called.
		public function setLevel(level:String):void
		{
			Tracer.debugTrace("SyncAds: setLevel(" + level + ")",2);
			//the initialization is done, the synchronization level cannot 
			//be changed
			if(this._fRegistered)
			{
				Tracer.debugTrace("SyncAds: setLevel - Error: initialization is done, the synchronization level can not be changed!",1);
				return;
			}
		
			//set synchronization level
			if(level.toLowerCase() == "ad")
			{
				this._strLevel = ebGlobal.urlParams.ebAdIdentifier;
			}
			else if(level.toLowerCase() == "campaign")
			{
				this._strLevel = ebGlobal.urlParams.ebCampaignID;
			}
			else 
			{
				//level parameter didn't get suitable value
				this._strLevel = "";
			}
		}
		
		//===================================
		//	function openConnection
		//===================================
		// This function initiates the connection of receiving 
		// messages by opening the local connection this asset 
		// listens to.
		// This function must be called before the asset can 
		// send and receive events (messages). 
		// Parameters:
		//       assetName:String- The asset name as set by the creative designer       
		// Return value:
		// 		If the comp was already registered with the same 
		// 		connection name the function will return true.
		// 		If the comp was already registered with a different
		// 		connection name the function will return false as failure indication
		// 		Otherwise will return the value that is returned from the connect function 
		public function openConnection(assetName:String):Boolean
		{
			try
			{
				Tracer.debugTrace("SyncAds: openConnection",2);
		
		        //report to the js (cmd,param1|param2|..)
		        fscommand("ebSyncAdsInteraction", "'openConnection'," + assetName);
				
				// Check if the component was already registered
				if(this._fRegistered)
				{
					// If the component was already registered with the same connection name
					if (assetName == this._strResName)
					{
						Tracer.debugTrace("SyncAds: openConnection - Connection for " + assetName + " was already opened",1);
						return true;
					}
					else
					{
						Tracer.debugTrace("SyncAds: openConnection - A connection is already opened and therefore connection for "+assetName+" can not be opened",1);
						return false;
					}
				}
				
				// Settings in _strResName the asset name (will be used in 
				// areUThere function.	
				this._strResName = assetName;
				// Set connectionName to be (assetName+"_"+_strLevel)
				this._strConnName = _strResName + "_" + _strLevel;
			
				// The resource try to open the connection it listens to.
				// The result whether the opening connection succeeded is put
				// in _fRegistered
				this._localLC.connect(this._strConnName);
				Tracer.debugTrace("SyncAds: openConnection - _localLC.connect(" +this. _strConnName + ")",1);
				
				this._fRegistered = true;
				
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in openConnection: "+error,1);
				this._fRegistered = false;
			}
			return this._fRegistered;
		}
		
		//===========================
		//	function findConnection
		//===========================
		//	The function is looking for an asset associated with the given assetName.
		//  If the appropriate asset was found the onConnectionFound
		//  event will be triggered on the caller to inform the
		//  caller that the connection was found. 
		//  If the connection was not found- in case parameter secTimeout
		//  was transfered, after the TimeOut period that the creative inserted
		//  the event onConnectionNotFound will be triggered.
		//  In case the parameter was not transfered the resource will be looked for 
		//  in an endless loop.
		//	Parameters:
		//		 assetName:String - the logical name of the asset that the
		//		 message is sent to
		//       secTimeout:Number-  the timeout in seconds.
		//       After that if the asset still not found onConnectionNotFound event will be triggered
		public function findConnection(assetName:String,secTimeout:Number = -1):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: findConnection (" + arguments + ")",2);

		        //report to the js (cmd,param1|param2|..)
		        fscommand("ebSyncAdsInteraction", "'findConnection'," + assetName + "|" + secTimeout);

				// Call to function _initFindLcConnection only on the first time
				// findConnection is called.
				if (this._arrFindAsset.length == 0)
					this._initFindLcConnection();
					
				// Check if the asset is already exist in _arrFindAsset
				// and store its location in _indexAssetInArr
				var indexAssetInArr = this._findAsset(assetName);
				if (indexAssetInArr == -1)
				{
					// The asset is not found in the array and should be added as 
					// a new element to _arrFindAsset
					this._addNewAsset(assetName,secTimeout);
				}
				// The asset is already in the array but not searched right now-> 
				// the asset was found or the TimeOut period was over
				else if (!(this._arrFindAsset[indexAssetInArr].isLookedFor))
				{
					// Indication that the asset is searched again
					this._arrFindAsset[indexAssetInArr].isLookedFor = true;
					
					// Update the asset with numOfInterval property 
					if (secTimeout != -1)
						this._arrFindAsset[indexAssetInArr].numOfInterval = (int((1000/this._findIntervalTime)*secTimeout));
					else
						this._arrFindAsset[indexAssetInArr].numOfInterval = -1;
				}
				// Check whether an interval was already created. 
				// We want to garentee that only one interval will be set.
				if (this._CanCreateInterval)
				{
					
					// The interval calls to _lookForAssets function with the parameters: areUThere and _findLcConnName
					// and from _lookForAssets function the areUThere function is called.
					this._findIntervalID = setInterval(_lookForAssets,this._findIntervalTime,"areUThere",this._findLcConnName,this);
					Tracer.debugTrace("SyncAds: findConnection - Create an interval " + this._findIntervalID + " for _lookForAssets function",2);
					this._CanCreateInterval = false;
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in findConnection: "+error,1);
			}
		 }
		 
		//=============================
		//	function callConnection
		//=============================
		//	This function is used to send the event (functionName) to a specific resource. 
		//	It calls the handleEvent function with the functionName and
		//  Params as parameters and the handleEvent calls the function
		//  that was given in functionName.
		//	Parameters:
		//		 destAssetName:String - the logical name of the asset that the
		//								message is sent to
		//		functionName:String –   the function name we wand to be Called.	
		//		Params:String –         the list of parameters will be passed to the event handlers.
		public function callConnection(destAssetName:String, functionName:String, Params:String = ""):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: - callConnection (" + arguments + ")",2);

		        //report to the js (cmd,param1|param2|..)
		        fscommand("ebSyncAdsInteraction", "'callConnection'," + destAssetName + "|" + functionName + "|" + Params);

				//callConnection parameters
				var sendParams = arguments;
				
				//transfer destAssetName to the connection name by adding _strLevel 
				sendParams[0] += "_" + this._strLevel;
				
				// Add handleEvent to the sendParams at index 1 so by send the 
				// handleEvent function will be called.
				sendParams.splice(1,0,"handleEvent");
				//send message throught the connection of destAssetName to handleEvent, and handleEvent will
				// get as the parameters functionName that we want to call to and Params.	
				this._sendingLC.send(destAssetName + "_" + this._strLevel,"handleEvent",functionName,Params);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in callConnection: "+error,1);
			}
			
		}
		
		//=============================
		//	function closeConnection
		//=============================
		//	This function closes the connection the component is associated to.
		public function closeConnection():void
		{
			try
			{
				Tracer.debugTrace("SyncAds: closeConnection",2);

		        //report to the js (cmd,param1|param2|..)
		        fscommand("ebSyncAdsInteraction", "closeConnection");

				//check if there is a connection opened
				if (this._fRegistered)
				{
					//closes the connection
					this._localLC.close();
					//indication that there is no connection opened anymore
					this._fRegistered = false;
					//initialize variables that included the connection details
					this._strConnName = "";
					this._strResName = "";
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception is closeConnection "+error,1);
			}
		}
		
		//---------- Functions that are called from the localConnection instance ------
		
		//========================
		//	function handleEvent
		//========================
		// This function calls to any function that is received as 
		// parameter in the callConnection function.
		// callConnection will receive a path of the function name as parameter,
		// will call to handleEvent and will pass her the parameter. 
		// handleEvent will check if the path starts with "root." or not 
		// in order to call the function from the suitable place.
		//	Parameters:
		//		PathOfFunction:String - the path of the function  the creative want to call to.
		//                              If the function is implemented by the creative in other place 
		//                              than the root a full path to the function will be given.
		//      Params:String(optional) - the string that includes the parameters wanted to 
		//                                be transfered seperated by ",".
		public function handleEvent(PathOfFunction:String,Params:String):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: handleEvent (" + arguments + ")",2);
				
				//remove PathOfFunction from the sendParams
				var sendParams = arguments.slice(1);
				
				//drop from PathOfFunction the word "root" if exist
				if (PathOfFunction.substr(0,5) == "root.")
					PathOfFunction = PathOfFunction.slice(5);
				
				//the following is actually a replacement for the eval that doesn't exist
				//in AS3. since the following structure works: root.movieClip[function]
				//we build that structure dynamically
				
				//split the elements by '.'
				var arr:Array = PathOfFunction.split('.');
				var functionPath = root;
				
				for (var i=0;i<arr.length-1;i++)
					functionPath = functionPath[arr[i]];
				//call to the function
				if (sendParams == "")
					functionPath[arr[i]]();
				else
					functionPath[arr[i]](sendParams);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in handleEvent: "+error,1);
			}
		}
		
		//========================
		//	function areUThere
		//========================
		// This function will be called by the findConnection 
		// API function. It is called on the asset we are looking
		// for, via the local connection associated to this asset.
		// It calls to assetFound on the caller asset (the caller
		// connection name is received as parameter) to confirm that the asset was found. 
		//	Parameters:
		//		callerName:String - the name of the asset that called
		//                          to findConnection function
		public function areUThere(callerName:String):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: areUThere (" + callerName + ")",2);
				this._sendingLC.send(callerName,"assetFound",this._strResName);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in areUThere: "+error,1);
			}
		}
		
		//========================
		//	function assetFound
		//========================
		// This function will be the CallBack called from the
		// asset we are looking for, to approve it exists.
		//	Parameters:
		//		assetName:String - the name of the asset that was 
		//                         called by the other asset
		public function assetFound(assetName:String):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: assetFound (" + assetName + ")",2);
				// location of the asset in _arrFindAsset array.
				 var index = this._findAsset(assetName);
				
				// Check if the asset is still searched.
				// onConnectionFound Event will be triggered only if 
				// the asset is still searched.
				// There might be a situation in which onConnectionFound was triggered and then there is
				// another call by the interval. to prevent this case we check that the 
				// property isLookedFor is true when calling to  onConnectionFound.
				if (this._arrFindAsset[index].isLookedFor)
				{
					// Indication that the asset won't be searched anymore.
					this._arrFindAsset[index].isLookedFor = false;
					
					//trigger event
					if(this.onConnectionFound != null)
					{
				        //report to the js (cmd,param1|param2|..)
		                fscommand("ebSyncAdsInteraction" , "'onConnectionFound'," + assetName);
						Tracer.debugTrace("SyncAds: onConnectionFound event is triggered for asset "+assetName,2);
						this.onConnectionFound(assetName);
					}
				}
				else
				{
					Tracer.debugTrace("SyncAds: " + assetName + " is not searched at the moment and therefore onConnectionFound event is not triggered",2);
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in assetFound: "+error,1);
			}
			
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	function _init
		//=======================
		// function that calls to _initComp and _initAttr
		// in order to init the component and all the attributes
		private function _init():void
		{
			this._initComp();
			this._initAttr();
		}
		
		//==============================
		//	function _initAttr
		//==============================
		// the function initialize the component attributes
		private function _initAttr():void
		{
			try
			{
				// in case _root.ebCampaignID is not undefined, _strLevel will get
				// the _root.ebCampaignID, otherwise it will be empty string
				this._strLevel = "";
				if(typeof(ebGlobal.urlParams.ebCampaignID) != "undefined")
				{
					Tracer.debugTrace("SyncAds: _initAttr - Set _strLevel to be the campaign level as default",2);
					this._strLevel = ebGlobal.urlParams.ebCampaignID;
				}
				
				// At first the flag is set to false-the asset doesn't have yet a
				// local connection opened for receiving messages .
				 this._fRegistered = false;
			
				 // Set _findIntervalID to -1 as long as the interval is not created
				this._findIntervalID = -1;
				this._findIntervalTime = 200;
				
				this._arrFindAsset = new Array();
				
				// The flag that indicates whether to create the interval should be set to true since
				// an interval was not created yet.
				this._CanCreateInterval = true;
			
				// The default of the event is null. 
				// The event will be called only if onConnectionFound is not null
				this.onConnectionFound = null;
			
				// The default of the event is null. 
				// The event will be called only if onConnectionNotFound is not null
				this.onConnectionNotFound = null;
			
				// A LocalConnection object used to receive events (messages).
				this._localLC = new SyncLocalConnection(this);
				
				// A LocalConnection object used for find assets
				this._findLC = new SyncLocalConnection(this);
				
				// A LocalConnection object used to send events (messages).
				this._sendingLC = new LocalConnection();
				this._sendingLC.addEventListener(StatusEvent.STATUS, onStatus);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in _initAttr: "+error,1);
			}
		}
		
		//==============================
		//	function _initComp
		//==============================
		// the function handles all the general things related to the component:
		//   set the component name
		//	 Remove big icon at runtime
		//   check if the needed data was passed to the resource by the JS
		private function _initComp():void
		{
			//set the component name - for the use of the Admin 
			//to identify the component
			ebGlobal.ebSetComponentName("SyncAds");
			//hiding component at runtime
			this.alpha = 0;
			//Use superdomain when accessing locally persistent data (shared objects). 
			try
			{
				Security.exactSettings = false;
			}
			catch(error:Error)
			{
				Tracer.debugTrace("Exception in SyncAds: _initComp: " + error, 1);
			}
				
			//check if the needed data was passed to the resource by the javascript
			//if it wasn't - disable the component
			if(typeof(ebGlobal.urlParams.ebCampaignID) == "undefined" || typeof(ebGlobal.urlParams.ebAdIdentifier) == "undefined")
			{
				Tracer.debugTrace("SyncAds: _initComp - Error: _root.ebAdIdentifier or root.ebCampaignID are undefined!",1);
			}
		}
		
		//================================
		//	function _initFindLcConnection
		//================================
		// This function inits the LocalConnection of _findLC.
		// A special connection for finding asset is created
		// so the caller to findConnection will have  a connection 
		// that it listens to, opened (not all assets has the _localLC,
		// asset can be a sender only). 
		private function _initFindLcConnection():void
		{
			// Creating name for the connection
			 this._findLcConnName = "connection" + int(Math.random()*10000) + "_" +this. _strLevel;
			try
			{
				 this._findLC.connect(this._findLcConnName);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in _initFindLcConnection in connect method: "+error,1);
			}
		}
		
		//========================
		//	function _lookForAssets
		//========================
		// This function scans the elements in _arrFindAsset array. 
		// For each one checking whether the asset should be 
		// looked for.
		// The asset should be looked for in the following cases:
		// TimeOut period was not over and the asset was not found. 
		// In these cases _lookForAssets calls to areUThere function (by localConnection.send)
		// through the connection of the asset that is looked for. 
		// In case the component at the other side will get the message it
		// means that the asset was found. 
		
		// If TimeOut was inserted by the creative as a parameter to 
		// findConnection and the TimeOut period is over onConnectionNotFound event
		// will be triggered from _lookForAssets.
		
		//	Parameters:
		//		functionName:String - the function name we want to go from
		//      					  _lookForAssets (in our case "areUThere")
		//      Params:String -       the parameters that will be transferred to the functionName
		//       				      that was inserted.
		//      objRef:MovieClip-	  reference to the instance
		private function _lookForAssets(functionName:String,Params:String,objRef:MovieClip):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: _lookForAssets (" + arguments + ")",2);
				
				// Indication whether there is at least one asset in _arrFindAsset
				// that is still searched. 
				// If there isn't the interval will be stopped.
				var leastOneAssetSearched:Boolean = false;
				
				var assetLookedForVal:Boolean;
				
				// For each element in the array check if the
				// asset should be searched.
				// If yes, check if the TimeOut period is over. 
				// In this case call onConnectionNotFound event.
				// Otherwise, try to call areUThere method. 
				for (var index = 0;index < objRef._arrFindAsset.length;index++)
				{
					// Call _shouldLookedFor status who checks the status of the asset
					// and according it handles it.
					// The return value, whether the asset is looked for or not, is put
					// inside assetLookedForVal. If there is at least one asset that is looked for
					// leastOneAssetSearched flag will be true so the interval won't be stopped.
					assetLookedForVal = objRef._shouldLookedFor(objRef._arrFindAsset[index],functionName, Params);
					if (assetLookedForVal)
					{
						Tracer.debugTrace("SyncAds: _lookForAssets - There are connections that are still searched",2);
						leastOneAssetSearched = true;
					}
				}
				// Check according the indication flag, whether there was at least one
				// asset that was still searched.
				if (!leastOneAssetSearched)
				{
					if(objRef._findIntervalID != -1)
					{
						// All the assets are not searched anymore and therefore
						// the interval should be stopped.
						Tracer.debugTrace("SyncAds: _lookForAssets - clearInterval " + this._findIntervalID,2);
						clearInterval(objRef._findIntervalID);
						objRef._findIntervalID = -1;
						objRef._CanCreateInterval = true;
					}
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in _lookForAssets: "+error,1);
			}
		}
		
		//================================
		//	function _addNewAsset
		//================================
		// This function adds a new element to _arrFindAsset.
		// In case the asset searched by findConnection is not in _arrFindAsset array,
		// it should be added to the array.
		//	Parameters:
		//		assetName:String- the name of the asset that is looked for in _arrFindAsset
		//		secTimeout:Number- the maximum number of seconds the asset should be looked for.
		private function _addNewAsset(assetName:String,secTimeout:Number):void
		{
			try
			{
				Tracer.debugTrace("SyncAds: _addNewAsset (" + arguments + ")",2);
				// a variable that will hold the number of times the interval has to be called in oredr to look for the asset
				var numOfInterval:Number;
				
				var indexAssetInArr = this._arrFindAsset.length;
				
				// If secTimeout was inserted, insert the number of calls the interval should call _lookForAssets
				if (secTimeout != -1)
				{
					numOfInterval = int((1000/_findIntervalTime)*secTimeout);
				}
				else
				{
					// If secTimeout was not inserted _numOfInterval will be -1 as indication
					// that the asset should be searched as long as it won't be found.
					numOfInterval = -1;
				}
				// Create and initialize the new object and put it in the array _arrFindAsset as the last element.
				this._arrFindAsset[indexAssetInArr] = new SyncSearchedAsset(assetName,numOfInterval);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in _addNewAsset: "+error,1);
			}
		}
		
		//========================
		//	function _findAsset
		//========================
		//  This function looks for the asset given as a parameter in _arrFindAsset array.
		//	Parameters:
		//		assetName:String- the name of the asset that is looked for in _arrFindAsset
		//  Return value- 
		//		location of the asset in _arrFindAsset
		//  	If the asset is not found in the array return -1.
		private function _findAsset(assetName:String):Number
		{
			// Search the asset name in _arrFindAsset
			for (var index = 0;index <this._arrFindAsset.length;index++)
			{
				// If the asset is found return its location in the array
				if (this._arrFindAsset[index].assetName == assetName)
				{
					Tracer.debugTrace("SyncAds: _findAsset - Asset " + assetName + " is found in _arrFindAsset array",2);
					return index;
				}
			}
			// If the asset is not found return -1 as indication that it is not exist.
			Tracer.debugTrace("SyncAds: _findAsset - Asset " + assetName + " is not found in _arrFindAsset array",2);
			return -1;
		}
		
		//========================
		//	function _shouldLookedFor
		//========================
		//  This function checks whether the asset should be looked for and according it decides 
		//  how to handle it. 
		//  The asset should be looked for in the following cases:
		//  TimeOut period was not over and the asset was not found. 
		//  In these cases _lookForAssets calls to areUThere function (by localConnection.send)
		//  through the connection of the asset that is looked for. 
		//  In case the component at the other side will get the message it
		//  means that the asset was found. 
		
		//  If TimeOut was inserted by the creative as a parameter to 
		//  findConnection and the TimeOut period is over onConnectionNotFound event
		//  will be triggered from _lookForAssets.
		//  Parameters:
		//		functionName:String - the function name we want to go from
		//      					  _lookForAssets (in our case "areUThere")
		//      Params:String -       the parameters that will be transferred to the functionName
		//       				      that was inserted 
		//  Return value:
		//		Boolean value whether the asset is looked for or not.
		//		Return true- When the asset is looked for.
		//		Return false- When the asset is not looked for.
		private function _shouldLookedFor(asset:SyncSearchedAsset,functionName:String, Params:String):Boolean
		{
			try
			{
				var _fAssetIsLookedFor:Boolean;
				Tracer.debugTrace("SyncAds: _shouldLookedFor (" + arguments + ")",2);
				// Check if the asset should be searched.
				// If not the function returns false.
				// If yes the function return true and according value of 
				// numOfInterval calls to areUThere or to onConnectionNotFound
				if (asset.isLookedFor)
				{
					if(asset.numOfInterval != -1)
					{
						//Decrease by one the number of calls that the interval should call areUThere method.
						asset.numOfInterval--;
						
						// In case numOfInterval is equal or below 0 the onConnectionNotFound
						// event should be triggered.
						if(asset.numOfInterval == 0)
						{
							// The asset won't be searched anymore and the
							// onConnectionNotFound event will be triggered.
							asset.isLookedFor = false;
							if (this.onConnectionNotFound != null)
							{
		                        //report to the js (cmd,param1|param2|..)
		                        fscommand("ebSyncAdsInteraction", "'onConnectionNotFound'," + asset.assetName);
								Tracer.debugTrace("SyncAds: onConnectionNotFound event is triggered for asset "+asset.assetName,2);
								this.onConnectionNotFound(asset.assetName);
							}
						}
						// The number of calls didn't reach its limit and therefore,
						// we should try to call the areUThere function. 
						else 
						{
							this._sendingLC.send(asset.assetName + "_" + this._strLevel,functionName,Params);
						}
					}
					// Number of calls is not limited and therefore,
					// the areUThere method should be called.
					else
					{
						this._sendingLC.send(asset.assetName + "_" + _strLevel,functionName,Params);
					}
					// Indication that there is an asset that is still looked for
					_fAssetIsLookedFor = true;
				}
				else
				{
					// Indication that the asset is not looked for.
					_fAssetIsLookedFor = false;
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SyncAds: Exception in _shouldLookedFor: "+error,1);
			}
			return _fAssetIsLookedFor;
		}
		
		//========================
		//	function onStatus
		//========================
		// function that is called by StatusEvent that is triggered when sending message.
		//	The function notifies whether the message succeeded or failed to be transffered.
		private function onStatus(event:StatusEvent):void
		{
            switch (event.level)
			{
                case "status":
                    Tracer.debugTrace("SyncAds: onStatus - sending message succeeded",1);
                    break;
                case "error":
                    Tracer.debugTrace("SyncAds: onStatus - sending message failed",1);
                    break;
            }
		}
	}
}