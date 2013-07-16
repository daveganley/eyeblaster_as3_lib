//****************************************************************************
//class eyeblaster.media.players.StreamingPlayer
//------------------------------------
//This class replaces the old StreamingPlayer component functionality
//It will be used as a "player" class for the FLV streaming media
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.players
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.players.AbsBasePlayer;
	import eyeblaster.media.players.STATE;
	import flash.net.NetConnection;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.media.Video;
	import flash.utils.*;
	
	public class StreamingPlayer extends AbsBasePlayer
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private var _connectionArr:Array;		//connections array
		private var _timeoutInterval:Number;	//master timeout
		private var _connectionAttempt:Number;		//attempt index
		private var _connectionInterval:Number;		//attempt timeout
		private var _ncArr:Array = new Array();		//NetConnection array
		private var _startConnectTime:Number;		//strat connection time
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		//Parameters:
		//	videoHolder:MovieClip - the movieclip the video operates on
		//	fSetMute:Boolean - Mute start value
		//	nVol:Number - the speaker volume
		//	nBufferSize:Number - buffer size
		//	strExtFCSURL:String - FCS URL.
		public function StreamingPlayer(videoHolder:Video,fSetMute:Boolean,nVol:Number,nBufferSize:Number,strExtFCSURL:String)
		{
			Tracer.debugTrace("StreamingPlayer: Constructor",6);
			this.bufferSize = 2;	//default buffer size
			this._init(videoHolder, fSetMute, nVol, nBufferSize);
			this._nBufferingStatus = 2; //buffering
			this._strAppURL = strExtFCSURL;	//external FCS URL
		}
		
		//============================
		//	function setLength
		//============================
		//This function is used by the player to set the video length as 
		//recieved from the PlayerNetStream.
		//This function also seek the video to its start position.
		//Parameters:
		//	nLength:Number - the video length as recieved from the PlayerNetStream
		public override function setLength(nLength:Number):void
		{
			super.setLength(nLength);
			//seek video
			if(this.startPosition > 0)
			{
				Tracer.debugTrace("StreamingPlayer: seek video to start position ("+this.startPosition+")", 6); 
				this._seek(this.startPosition);
				//reset
				this.startPosition = 0;
			}
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//-----Load/Play----
		
		//============================
		//	function _initMedia
		//============================
		//Init the Media attributes for loading and playing it.
		//Parameters:
		//	strURL:String - the video URL
		protected override function _initMedia(strURL:String):void
		{
			//Build the final video URL:
			//for external URL, _strAppURL is set upon init 
			var fExternalURL:Boolean = (this._strAppURL != "");
			var urlParams = EBBase.urlParams;
					
			//strips off .flv for 6.0 players and add the virtual path
			//Note: _root.ebStreamVirtualPath is defined when _root.ebStreamingAppURL is - so there is no need to check
			//extetnal URL
			if(fExternalURL)
			{
				//in case of external URL we recieve the path to the file
				//including the file name
				this._strStreamName = strURL;
				//strip off .flv for 6.0 players
				if(_strStreamName.indexOf(".flv") != -1)
					_strStreamName = _strStreamName.substring(0,_strStreamName.length - 4);
				//connect to the FCS
				this._loadMedia();
			}
			else if(typeof(urlParams.ebStreamingAppURL) != "undefined") //AKAMAI
			{
				//set the application URL (URL to the FCS)
				this._strAppURL = urlParams.ebStreamingAppURL; 
				
				//extract the file name from the URL given
				var strFileName:String = strURL.substr(strURL.lastIndexOf("/")+1);
				//strips off .flv for 6.0 players and add the virtual path
				//Note: _root.ebStreamVirtualPath is defined when _root.ebStreamingAppURL is - so there is no need to check
				this._strStreamName = urlParams.ebStreamVirtualPath + strFileName.substring(0,strFileName.length-4);
				//connect to the FCS
				this._loadMedia();
			}
		}
			
		//=========================
		//	function _loadMedia
		//=========================
		//This function connect to the FCS
		//for the NetConnection object
		protected override function _loadMedia():void
		{
			Tracer.debugTrace("StreamingPlayer: _loadMedia",3);
			if(this._nc is NetConnection)
				return;		
			//clear timeout interval		
			clearInterval(_timeoutInterval);
			this._startConnectTime = getTimer();
			//connect to the FCS
			this._buildConnectionSequence();
			
		}
	
		//====================================
		//	function _buildConnectionSequence
		//====================================
		//This function builds an array of connection strings and starts connecting
		private function _buildConnectionSequence():void
		{
			var portProtocolArr:Array = _buildPortProtocolSequence();
			this._connectionArr = new Array();
			//build connection array
			for (var i:Number = 0; i < portProtocolArr.length; i++) 
			{
				var connectionObj:Object = new Object();
				var startIndex = this._strAppURL.indexOf("://") + 3;
				var endIndex = this._strAppURL.indexOf("/", startIndex);
				var strDomain = this._strAppURL.substring(startIndex, endIndex);
				var address = portProtocolArr[i].protocol + "://" + strDomain + ":" + portProtocolArr[i].port + this._strAppURL.substring(endIndex);
				connectionObj.address = address;
				this._connectionArr.push(connectionObj);
			}
			//set intervals (per attempt and a global one) and make the 1st attempt
			this._timeoutInterval = setInterval(this._masterTimeout, 10000);
			this._connectionAttempt = 0;
			this._tryToConnect();
			this._connectionInterval = setInterval(this._tryToConnect, 200);
		}
		
		//====================================
		//	function _tryToConnect
		//====================================
		// This function attempts to connect to FMS using a particular connection string
		private function _tryToConnect() 
		{ 
			try
			{
				//clear interval if no more attemps
				if (_connectionAttempt >= this._connectionArr.length) 
				{
					Tracer.debugTrace("StreamingPlayer: All Connection attempts failed", 0);
					clearInterval(this._connectionInterval);
				} 
				else 
				{
					//build the new NetConnection
					this._ncArr[this._connectionAttempt] = new Object();
					this._ncArr[this._connectionAttempt].nc = new NetConnection;
					
					
					Tracer.debugTrace("StreamingPlayer._tryToConnect: trying to connect to: "+this._connectionArr[this._connectionAttempt].address, 3);
					//register to events
					var nc = this._ncArr[this._connectionAttempt].nc;
					nc = ncRegisterEvents(nc);
					this._ncArr[this._connectionAttempt].expectBWDone = false;
					//connect to the FCS
					nc.connect(this._connectionArr[this._connectionAttempt].address);
					this._connectionAttempt++;
					//last attempt, clear the interval 
					if (this._connectionAttempt >= this._connectionArr.length) 
						clearInterval(this._connectionInterval);
				}
			}catch(error:Error)
			{
				Tracer.debugTrace("Error | Exception in StreamingPlayer:_tryToConnect: "+ error, 0);
			}
		}
		
		//====================================
		//	function _masterTimeout
		//====================================
		// This function catches the master timeout when no connections have succeeded
		// within CONNECTION_TIMEOUT.
		private function _masterTimeout() 
		{
			//clear all connection attempts
			_clearAttempts();
			//trigger the error event
			this._broadcast("onError", "timout occured("+this._timeoutInterval+" milliseconds) while trying to connect to the FCS");
		}
	
		//====================================
		//	function _buildPortProtocolSequence
		//====================================
		// This function assembles the array of ports and protocols to be attempted
		private function _buildPortProtocolSequence():Array 
		{
			var arr:Array = new Array();
			arr.push({port:"1935", protocol:"rtmp"});
			arr.push({port:"80", protocol:"rtmp"});
			arr.push({port:"443", protocol:"rtmp"});
			arr.push({port:"80", protocol:"rtmpt"});
			arr.push({port:"1935", protocol:"rtmpt"});
			arr.push({port:"443", protocol:"rtmpt"});
			arr.push({port:"1935", protocol:"rtmpe"});
			arr.push({port:"80", protocol:"rtmpe"});
			arr.push({port:"443", protocol:"rtmpe"});
			arr.push({port:"80", protocol:"rtmpte"});
			arr.push({port:"1935", protocol:"rtmpte"});
			arr.push({port:"443", protocol:"rtmpte"});
			return arr;
		}
	
		//============================
		//	function _ncStatusChange
		//============================
		//This function handles NetStatusEvent event from the NetConnection object
		//The function calls _changeStatus function to update the status and
		//invoke the proper events
		//Parameters: 
		//	event:NetStatusEvent - NetStatusEvent event object.
		//	this object contains An information object that has a code 
		//	property containing a string that describes the result of the 
		//	NET_STATUS event, and a level property containing a string 
		//	that is either "Status" or "Error". 
		protected override function _ncStatusChange(event:NetStatusEvent):void
		{
			try
			{	
				
				var info = event.info;
				//established connection,  clear intervals and clear all other connection attempts
				if (info.code == "NetConnection.Connect.Success") 
				{ 
					this._nc = event.target as NetConnection;
					Tracer.debugTrace("StreamingPlayer: connected to "+this._nc.uri+" (Total Time (sec):"+(getTimer()-_startConnectTime)/1000+")", 0);
					//clear all connection attempts
					_clearAttempts();
					_changeStatus(3);
				}
				//error messages can be ignores during the connection attempts
				if((info.level == "error") && !this._nc)
					return;
				//connect to stream
				super._ncStatusChange(event);
			}catch(error:Error)
			{
				Tracer.debugTrace("Error | Exception in StreamingPlayer:_ncStatusChange: "+ error, 0);
			}
		}
		
		//============================
		//	function _clearAttempts
		//============================
		//This function clears intervals and clear all other connection attempts
		private function _clearAttempts()
		{
			try
			{
				clearInterval(this._connectionInterval);
				clearInterval(this._timeoutInterval);
				//clear all connection attempts except the successfull attempt if there is any
				for (var i = 0; i < this._ncArr.length; i++) 
				{
					var nc = this._ncArr[i].nc;
					if (nc.uri != this._nc.uri)
					{
						nc.close();
						nc.removeEventListener(NetStatusEvent.NET_STATUS, _netStatusHandler);
						nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
						nc.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, _errorHandler);
						nc.removeEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
						nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
						nc = null;
						delete this._ncArr[i];
					}
				}
			}catch(error:Error)
			{
				Tracer.debugTrace("Error | Exception in StreamingPlayer:_clearAttempts: "+ error, 0);
			}
		}
	
		//=========================
		//	function _startLoad
		//=========================
		//This function set the buffer size for the NetConnection object and start loading
		protected override function _startLoad():void
		{
			this._setBufferSize();
			this._nState = STATE.LOAD;
		}
		
		//=========================
		//	function _setBufferSize
		//=========================
		//This function set the buffer size to the NetConnection object
		private function _setBufferSize():void
		{
			this._ns.bufferTime = this.bufferSize;
		}
		
		//-----Progress----
		
		//=========================
		//	function _progress
		//=========================
		//This function monitor load and play progress of the video.
		protected override function _progress():void
		{
			Tracer.debugTrace("StreamingPlayer: _progress",6);
			//check if ready
			if(!this._fBufferReady)
			{
				if (this._nStatus == 3)
				{
					this._bufferIsReady();
					this._fBufferReady = true;
	
					//play
					if(this._fAutoPlay)
					{
						this.play();
					}
				}
			}
			
			//fire events
			this._fireProgressEvents();
			
			//Calculate the buffer progress 
			var bufferProgress:Number = this._getBufferProgress();
			
			this._broadcast("bufferProgress",""+bufferProgress);
		}
		
		//=============================
		//	function _getBufferProgress
		//=============================
		//This function return the buffer progress
		private function _getBufferProgress():Number
		{
			var bufferProgress:Number = 0;
			Tracer.debugTrace("StreamingPlayer: _getBufferProgress: bufferTime = " + this._ns.bufferTime+" bufferLength = "+this._ns.bufferLength,6);
			
			//check if valid
			if((this._ns.bufferTime != 0) && 
				(typeof(this._ns.bufferTime) != "undefined") &&
					(typeof(this._ns.bufferLength) != "undefined"))
			{
				bufferProgress = this._ns.bufferLength/this._ns.bufferTime;
			}
			if(bufferProgress > 1)
				bufferProgress = 1;
			//round to 2 numbers after the decimal point
			bufferProgress = Math.round(bufferProgress * 10000)/100;
			return (bufferProgress);
		}
		
		//=============================
		//	function _nsReady
		//=============================
		//This function checks if the NetStream object is ready to be played
		protected override function _nsReady()
		{
			return ((typeof(this._ns) == "object"));
		}
	}
}
		
		