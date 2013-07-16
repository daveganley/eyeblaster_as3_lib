//****************************************************************************
//class eyeblaster.media.players.ProgressivePlayer
//------------------------------------
//This class replaces the old FLVProgressiveLoader component functionality
//It will be used as a "player" class for the FLV progressive media.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.players
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.players.AbsBasePlayer;
	import flash.net.NetConnection;
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	import flash.media.Video;
	import flash.events.*;
	
	public class ProgressivePlayer extends AbsBasePlayer
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _nStartLoadingTime:Number;			//Mark the time when the load of the movie began.
														//(used for the progressive download algorithm)
		private var _nInitBytesLoaded:Number;			//The video bytes in the cache.
		
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
		public function ProgressivePlayer(videoHolder:Video,fSetMute:Boolean,nVol:Number,nBufferSize:Number)
		{
			Tracer.debugTrace("ProgressivePlayer: Constructor",6);
			this.bufferSize = 0;	//default buffer size
			this._init(videoHolder,fSetMute,nVol,nBufferSize);
			this._nStartLoadingTime = -1; 
			this._nInitBytesLoaded = 0;
			this._nBufferingStatus = 1; //loading
		}
		
		//============================
		//	function isLocalFile
		//============================
		//This function checks whether the playing media is a local file.
		public override function isLocalFile():Boolean
		{
			return (this._strStreamName.indexOf("http://") == -1);
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//-----Load/Play----
		
		//============================
		//	function _initMedia
		//============================
		//Init the Media attributes for loading and playing it
		//Parameters:
		//	strURL:String - the video URL
		protected override function _initMedia(strURL:String):void
		{
			Tracer.debugTrace("ProgressivePlayer: _initMedia(" + strURL + ")",6);
			
			//set _strStreamName
			this._strStreamName = strURL;
			Tracer.debugTrace("ProgressivePlayer: _initMedia: _strAppURL(AKAMAI) = " + this._strAppURL,6);
			Tracer.debugTrace("ProgressivePlayer: _initMedia: _strStreamName(AKAMAI) = " + this._strStreamName,6);
			//connect to the FCS for loading and playing
			this._loadMedia();
		}
		
		//=========================
		//	function _loadMedia
		//=========================
		//This function connect to the FCS
		//object
		protected override function _loadMedia():void
		{
			Tracer.debugTrace("ProgressivePlayer: _loadMedia",6);
			if(this._nc is NetConnection)
				return;		
			//connect to the FCS - wait for the status event before setting the NetStream object
			this._nc = new NetConnection();
			this._nc = ncRegisterEvents(this._nc);
			this._nc.connect(this._strAppURL);
		}
		
		//=========================
		//	function _startLoad
		//=========================
		//This function set the buffer size for the NetConnection object and start loading
		protected override function _startLoad():void
		{
			this._setBufferSize();
			//load
			this._ns.play(this._strStreamName);
			this._pause();
		}
		
		//=========================
		//	function _setBufferSize
		//=========================
		//This function set the buffer size to the NetConnection object
		private function _setBufferSize():void
		{
			// Determine the buffer size relative to the total time of the FLV.
			// Buffer size = length / 4, with a minimum size of .1 and a maximum size of 5
			var bufferSize:Number = this.videoLength / 4;
			if (bufferSize < 0.1) 
				bufferSize = 0.1;
			else if (bufferSize > 5) 
				bufferSize = 5;
			this._ns.bufferTime = bufferSize;
		}
		
		
		//-----Progress----
		
		//=========================
		//	function _progress
		//=========================
		//This function monitor load and play progress of the video.
		protected override function _progress():void
		{
			Tracer.debugTrace("ProgressivePlayer: _progress",6);
			//check if ready
			if(!this._fBufferReady)
				this._downloadProgress();
			//fire events
			this._fireProgressEvents();
		}
		
		//=============================
		//	function _downloadProgress
		//=============================
		//This function monitor the load progress of the video
		//and implements the progressive download algorithm
		private function _downloadProgress():void
		{
			Tracer.debugTrace("ProgressivePlayer: _downloadProgress",6);
			if(this._nStartLoadingTime == -1)
			{
				this._nStartLoadingTime = getTimer();	//start loading time
				this._nInitBytesLoaded = this._ns.bytesLoaded;	//bytes in the cache
				//set defualt value
				if((this._nInitBytesLoaded < 0) 
						|| (typeof(this._nInitBytesLoaded) == "undefined"))
					this._nInitBytesLoaded = 0;
			}
			//Calculate the buffer progress 
			var bufferProgress:Number = this._getBufferProgress();
			//fire event
			this._broadcast("bufferProgress",""+bufferProgress);
			
			//buffer is ready
			if(bufferProgress == 100)	
			{
				this._fBufferReady = true;
				this._bufferIsReady();
				//play
				if(this._fAutoPlay)
					this.play();
			}
		}
			
		
		//=============================
		//	function _getBufferProgress
		//=============================
		//This function return the buffer progress
		private function _getBufferProgress():Number
		{
			//we should check if the remaining time for download is less then the
			//movie duration. if the movie duration is not defined (not greater then 0) we should
			//do nothing
			var nTimeLeft:Number;	//time left to complete the download
			var nBW:Number;			//bandwidth
			var nTime:Number;		//time since the start
			
			//the video length is available 
			if (this.videoLength > 0)
			{
				//bytes loaded (not including the bytes in the cache)
				var nBytesLoaded:Number = this._ns.bytesLoaded - this._nInitBytesLoaded;
				
				//calc time since the start in sec
				nTime = 0.001 * (getTimer() - this._nStartLoadingTime);
				
				Tracer.debugTrace("ProgressivePlayer: _getBufferProgress: this._ns.bytesLoaded = "+this._ns.bytesLoaded +", this._ns.bytesTotal = "+this._ns.bytesTotal+", this._nInitBytesLoaded = "+this._nInitBytesLoaded + ", nTime" +nTime,4);
				
				//No time passed since we start loading
				if(nTime == 0)
					return(0);
				
				//calc the BW in kbps
				nBW = nBytesLoaded * 8/1024/nTime;
				
				//ignore - loaded from the cache
				if(nBW > 8000)
				{
					Tracer.debugTrace("ProgressivePlayer: _getBufferProgress: nBW = "+nBW +": ignore - loaded from the cache",4);
					this._nStartLoadingTime = getTimer();
					this._nInitBytesLoaded = this._ns.bytesLoaded;
					return(0);
				}
				   
				//the video was fully loaded 
				if(this._ns.bytesLoaded == this._ns.bytesTotal)
					nTimeLeft = 0;
				else  //calculate the time left to complete the download
					nTimeLeft = (8/1024 * (this._ns.bytesTotal - this._ns.bytesLoaded)) / nBW;
	
				Tracer.debugTrace("ProgressivePlayer: _getBufferProgress: timeLeft="+nTimeLeft+",risk="+this.bufferSize+",totalTime="+this.videoLength+",BW="+nBW,4);
				
				//add risk
				nTimeLeft *= (1+this.bufferSize);
				
				//ready
				if (nTimeLeft < this.videoLength)
				{
					//buffer size
					return(100);
				}
				else
				{
					//calc buffer progress
					var bufferProgress:Number = nTime / (nTime + (nTimeLeft - this.videoLength));
								
					//set valid
					if(bufferProgress < 0)
						bufferProgress = 0;
					if(bufferProgress > 1)
						bufferProgress = 1;
						
					//round to 2 numbers after the decimal point
					bufferProgress = Math.round(bufferProgress * 10000)/100;
					return(bufferProgress);
				}
			}
			
			//in cases the video length is unknown and the entire movie is 
			//loaded, we would like to start playing.
			if (this._ns.bytesTotal == this._ns.bytesLoaded)
			{
				Tracer.debugTrace("ProgressivePlayer: _getBufferProgress: check progressive - movie fully loaded and total time is unknown",6);
				//buffer size
				return(100)
			}
			
			//buffer size - no buffering
			return (0);
		}
		
		//=============================
		//	function _nsReady
		//=============================
		//This function checks if the NetStream object is ready to be played
		protected override function _nsReady()
		{
			return ((typeof(this._ns) == "object") && this._fBufferReady);
		}
	}
}