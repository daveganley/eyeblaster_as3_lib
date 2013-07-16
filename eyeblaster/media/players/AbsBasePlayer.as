//****************************************************************************
//class eyeblaster.media.players.AbsBasePlayer
//-----------------------------------------
//This is an "abstract" class that contains common attributes and methods of
//the FLV player classes, to be extended by The FLV player classes.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.players
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.players.IPlayer;
	import eyeblaster.media.players.STATE;
	import eyeblaster.media.general.VideoEvent;
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.ObjectEncoding;
	import flash.media.SoundTransform;
	import flash.events.*;
	import flash.utils.setInterval;
	import flash.utils.clearInterval;
	import flash.media.Video;
		
	public class AbsBasePlayer implements IPlayer
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private/Protected Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++

		//-----General---- 		
		private var _fMovieEnded:Boolean;		//indicates whether the movie was ended.
		private var _path;					//the path to the component
		protected var _fAutoPlay:Boolean;		//Indicates whether we need to play the video automatically when the buffer is ready (default true)
		protected var _fBufferReady:Boolean;	//Indicates whether the buffer is ready or not (default false).
		protected var _nBufferingStatus:Number;	//Indicates the buffering status (1 for progressive, 2 for streaming).
		private var _initSizeInterval:Number;		//Video size was initialization interval
		private var _fClearVideo:Boolean; 	 //Indicates wether we nedd to clear the video in _stop function
		private var _fMetadataRecieved:Boolean; //Indicates whether metadata was recieved for the current video
		
		//-----Load/Play---- 
		private var _bufferSize:Number;	//buffer (defualt 2)/risk(default 0.1) size
		protected var _nc:NetConnection;//PlayerNetConnection;	//NetConnection object
		protected var _ns:NetStream;//PlayerNetStream;	//NetStream object
		protected var _strAppURL:String;	//The FCS URL (Null is case of progressive) - (defualt Null)
		protected var _strStreamName:String;	//The resource URL/Path (default "")
		private var _fCloseNSUponReset:Boolean; //Indicates that the NetStream object should be closed upon reset (set to false in case of NetStream error).

		//-----Sound---- 
		private var _nVolume:Number;	//The speaker volume (default 100)
		private var _fIsMuted:Boolean;	//Indicates if the sound is on or off (defualt true)
		private var _sound:SoundTransform;	//The audio
		private var _fAudioInitialized:Boolean;	//Indicates whether the sound object was initialized (defualt false)
		
		//-----Video and  video data----
		private var _videoHolder:Video;	//The video container
		private var _nPosition:Number;	//Last video position (defualt -1)
		protected var _nStatus:Number;	//Indicate the video status: Idle: 0 (default), Loading:1, Buffering:2
											//, Ready:3, Playing:4, Paused:5, Stopped:6, Full Screen Playback:7
		
		protected var _nState:Number;	//Indicate the video status: load: 0 (default), Play:1, Stop:2
		private var _nLength:Number;	//Holds the video length (defualt -1)
		private var _startPosition:Number;	//Position to start the video from (defualt 0)
		
		//-----Progress---- 
		private var _nProgressIntervalID:Number;	//The interval id for the progress method (defualt -1)
		private var _fFirstPlay:Boolean; 		//Indicates first play (after load).
		private var _fIsIdle:Boolean;	//Indicates whether the video is Idle or not
		private var _fVideoIsStopped:Boolean;	//Indicates whether the video is stopped (or ended)
		
		//-----Events-----
		private var _listeners:Array;		//an array of listeners to the player event

		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
			
		//=======================
		//	Constructor
		//=======================
		public function AbsBasePlayer(){}
		
		//-----Setter/Getter-----
		
		//=======================
		//	videoLength
		//=======================
		//This function return the video length
		public function get videoLength():Number{return this._nLength;}
		
		//=======================
		//	position
		//=======================
		//This function return the video current position
		public function get position():Number{return this._nPosition;}
		
		//=======================
		//	state
		//=======================
		//This function return the video current state
		public function get state():Number{return this._nState;}
		
		//=======================
		//	bufferSize
		//=======================
		//This function get/set the bufferSize
		public function get bufferSize():Number{return this._bufferSize;}
		public function set bufferSize(bufferSize:Number):void{this._bufferSize = bufferSize;}
		
		//=======================
		//	startPosition
		//=======================
		//This function get/set the bufferSize
		public function get startPosition():Number{return this._startPosition;}
		public function set startPosition(pos:Number):void{this._startPosition = pos;}
		
		//=======================
		//	status
		//=======================
		public function set status(nStatus:Number):void{this._changeStatus(nStatus);}
		
		//-----Methods-----
		
		//===========
		//	getMute
		//============
		public function getMute():Boolean{return this._fIsMuted;}
		
		//=======================
		//	function getVolume
		//=======================
		//This function return the speaker volume
		public function getVolume():Number{return this._nVolume;}
		
		
		//============================
		//	function setBuffer
		//============================
		//This function set the buffer/risk size
		//Parameters:
		//	nBuffer:Number - The buffer/risk size
		public function setBuffer(nBuffer:Number):void{this._bufferSize = nBuffer;}
		
		//============================
		//	function setLength
		//============================
		//This function is used by the player to set the video length as 
		//recieved from the javascript (for WMV) or PlayerNetStream (for FLV)
		//Parameters:
		//	nLength:Number - the video length as recieved from the javascript
		public function setLength(nLength:Number):void{this._nLength = nLength;}
		
		//============================
		//	function isLocalFile
		//============================
		//This function used by the FLV players
		//It checks whether the playing media is a local file.
		public function isLocalFile():Boolean{return false;}
		
		//============================
		//	function setClearVideoFlag
		//============================
		//This function set the _fClearVideo to true or false according the parameter
		//Parameter:
		//	clearVideo:Boolean - indicates whether the video should be cleared
		public function setClearVideoFlag(clearVideo:Boolean):void{this._fClearVideo = clearVideo;}
		
		//============================
		//	function setMute
		//============================
		//This function set or unset speaker mute according to 
		//nMuteVal value.
		//Parameters:
		//	fShouldMute:Boolean - the speaker mute state
		public function setMute(fShouldMute:Boolean):void
		{
			this._fIsMuted = fShouldMute;
			if(this._fAudioInitialized)
				this._setSound();
		}
			
		//============================
		//	function setVolume
		//============================
		//This function set the speaker volume for the video
		//Parameter:
		//	nVolLevel:Number - volume level (0-100)
		public function setVolume(nVolLevel:Number):void
		{
			this._nVolume = nVolLevel;
			if(this._fAudioInitialized)
				this._setSound();
		}
		
		//=======================
		//	netStreamVideo
		//=======================
		//This function return the video length
		public function get netStreamVideo():NetStream{return this._ns;}


		//-----Control----- 
		
		//============================
		//	function load
		//============================
		//This function downloads an FLV media, and play it in case 
		//fAutoPlay is true.
		//Parameters:
		//	strURL:String - the video URL
		//	fAutoPlay:Boolean - indicates whether the video should be played
		public function load(strURL:String,fAutoPlay:Boolean):void
		{
			Tracer.debugTrace("AbsBasePlayer: load("+strURL + "," + fAutoPlay + ")",6);
			//Sets _fAutoPlay flag
			this._fAutoPlay = fAutoPlay;
			//hide video to avoid jump when resizing it
			this._videoHolder.visible = false;
			//indicates first play (after load).
			this._fFirstPlay = true;
			//update flag
			_fIsIdle = false;
			//reset flag
			this._fVideoIsStopped = false;
			//load and play
			this._initMedia(strURL);
		}
			
		//============================
		//	function play
		//============================
		//This function starts the video playback
		public function play():void
		{
			Tracer.debugTrace("AbsBasePlayer: play("+this._strStreamName +")", 6);
			this._nState = STATE.PLAY;
			
			//Update status
			//for progressive - always update the status (for updating the buffer ready flag)
			//for streaming - update the status only in case of
			//				  play after stop
			if( !_fFirstPlay || (this._nBufferingStatus == 1)) 
			{
				this._checkIfReadyPlay(); //Play					
			}
				
			//play video
			this._play();
		}
			
		//============================
		//	function pause
		//============================
		//This function pause the video playback
		public function pause():void
		{
			Tracer.debugTrace("AbsBasePlayer: pause("+this._strStreamName +")",6);
			this._nState = STATE.PAUSE;
			this._pause();
			this._changeStatus(5); //pause
		}
		
		//============================
		//	function stop
		//============================
		//This function stop the video playback
		public function stop():void
		{
			Tracer.debugTrace("AbsBasePlayer: stop("+this._strStreamName +")",6);
			this._nState = STATE.STOP;
			this._stop();
			this._changeStatus(6); //Stop
		}
		
		//============================
		//	function seek
		//============================
		//This function seek the video to nSec position
		//Parameters:
		//	nSec:Number - The time value, in seconds, to move to in 
		//				  the video
		public function seek(nSec:Number):void
		{
			Tracer.debugTrace("AbsBasePlayer: seek("+ nSec +")",6);
			this._seek(nSec);
		}
		
		//============================
		//	function close
		//============================
		//This function close the player
		public function close():void
		{
			Tracer.debugTrace("AbsBasePlayer: close()",6);
			//clear and close the NetStream object
			//in case the video to play was not found or
			//seek was failed, closing the NetStream cause a crash
			if(_ns != null)
			{
				if(this._fCloseNSUponReset)
					_ns.close();
				else
					this._fCloseNSUponReset = true;
				
				_ns = null;
			}
			//clear and close the NetConnection object
			if (_nc != null)
			{
				_nc.close();
				_nc = null;
			}
			this._videoHolder.clear();
		}
				
		//-----Events----- 
		
		//============================
		//	function addListener
		//============================
		//This function adds a listener to the listeners array
		//[Used to dispatch the player events to the VideoLoader]
		//Parameters:
		//	handler:Object - a listener object
		public function addListener(handler:Object):void
		{
			Tracer.debugTrace("AbsBasePlayer: addListener: handler: "+handler, 6);
			this._listeners.push(handler);
		}
		
		//-----General----- 
		
		//===================================
		//	function isPlayingComplete
		//===================================
		//This function checks whether the play head is close enough to the 
		//end of the movie, so we can consider the video as "completed"
		// Note: There are cases when the play head doesn't reach the end, 
		//thus a factor is used.
		public function isPlayingComplete():Boolean
		{
			if (this._fMovieEnded) 
				return true;
			//is playing
			var fIsPlaying = (this._ns != null);
			//the NetStream object was closed
			if(!fIsPlaying)
				return false;
			//if length is not available and there is no buffering
			//the video is ended
			var timeTillEnd = (this._nLength - this._ns.time);
			if(this._nLength == -1)
				timeTillEnd = 1;
			//close enough to the end
			var fIsCloseEnough:Boolean = (timeTillEnd < 0.5);
			return (fIsPlaying && fIsCloseEnough);
		}
			
		//=========================
		//	function reset
		//=========================
		//This function reset the player after the movie ends
		public function reset():void
		{
			this.stop();
			this._changeStatus(0);
		}
			
		//================================
		//	function handleVideoInfoEvent
		//================================
		//This function dispatch the player events metaData and CuePoint.
		//used for those that send object and not string (metaData and cuePoint)
		//Parameters: 
		//		strEventName - the event name
		//		eventParam - the information about the event
		public function handleVideoInfoEvent(strEventName:String,eventParam:Object):void
		{
			Tracer.debugTrace("AbsBasePlayer: handleVideoInfoEvent",3);
			try
			{
				//dispatch event
				_broadcast2(strEventName,eventParam);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in AbsBasePlayer: handleVideoInfoEvent: "+ error, 1);
			}
		}
		
		//=======================
		//	function getStatus
		//=======================
		//This function return the video status
		public function getStatus():Number
		{
			Tracer.debugTrace("AbsBasePlayer: getStatus()",3);
			return this._nStatus;
		}
			
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//-----Sound----- 
		
		//=======================
		//	function _initSound
		//=======================
		//This function init sound
		private function _initSound():void
		{
			if(this._fAudioInitialized)
				return;
			this._setSound();
			this._fAudioInitialized = true;
		}
		
		//=======================
		//	function _setSound
		//=======================
		//This function set sound
		private function _setSound():void
		{
			if(this._fIsMuted)
				this._sound.volume = 0;
			else
				this._sound.volume = this._nVolume / 100;	//the volume attribute is between 0 and 1
			this._ns.soundTransform = this._sound;
		}
		
		//=======================
		//	function _showVideo
		//=======================
		//This function show the video
		private function _showVideo():void
		{
			try
			{
				for(var i = 0;i < this._listeners.length; i++)
					this._listeners[i].showVideo();
			}catch(e){}
		}
		
		//=======================
		//	function _init
		//=======================
		//This function init class attributes
		//(Called from the Constructor)
		//Parameters:
		//	videoHolder:Video - the video container
		//	fSetMute:Boolean - Mute start value
		//	nVol:Number - the speaker volume
		//	nBufferSize:Number - buffer size
		protected function _init(videoHolder:Video, fSetMute:Boolean, nVol:Number, nBufferSize:Number):void
		{
			Tracer.debugTrace("AbsBasePlayer: _init("+arguments+")",1);
			//-----Sound-----
			this._nVolume = nVol;			//The speaker volume
			this._fIsMuted = fSetMute;
			
			//-----Video and  video data----
			this._videoHolder = videoHolder;
			this._nStatus = 0;				//video status
			this._nLength = -1;				//video lenght
			this._fMetadataRecieved = false;
			
			//buffer size
			if(nBufferSize != -1)
				this.bufferSize = nBufferSize;
			
			Tracer.debugTrace("AbsBasePlayer: _init: buffer size = "+this.bufferSize,1);
			
			//-----Load/Play---- 
			this._strAppURL = null;	//The FCS URL
			this._strStreamName = "";	//The resource URL/Path
			this._fCloseNSUponReset = true;	//Indicates that the NetStream object should be closed
											//Set to false in case of NetStream error
			
			//-----Sound---- 
			this._fAudioInitialized = false;	//Indicates whether the sound object was initialized
			
			//-----Events---- 
			this._listeners = new Array();
			
			//-----Clear Video Flag------
			this._fClearVideo = true;
		
			//set path
			this._path = this._videoHolder.parent;
			
			//progress
			this._fVideoIsStopped = false; 	//Indicates whether the video is stopped (or ended)
			
			this._reset();
		}
		
		//-----Load/Play----- 
	
		//==========================
		//	function _setNS
		//==========================
		//This function creates the NetStream object and initializes it
		private function _setNS()
		{
			//this._ns = new PlayerNetStream(_nc, this);
			this._ns = new NetStream(this._nc);
			var customClient:Object = new Object();
			customClient.onMetaData = onMetaData;
			customClient.onCuePoint = onCuePoint;
			customClient.onPlayStatus = _nsStatusChange;
			customClient.onXMPData = function();
			_ns.client = customClient;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, _netStatusHandler);
            _ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, _errorHandler);
			_ns.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
			this._videoHolder.attachNetStream(_ns);
			this._sound = new SoundTransform(0);
			//Init sound volume
			if(!this._fAudioInitialized)
			{
				this._initSound();
				this._fAudioInitialized = true;
			}
			//start load
			this._startLoad();
		}

   		//============================
		//	function onMetaData
		//============================
		//This function is an Event handler, receives descriptive information embedded in the FLV file being played. 
		//Parameters:
		//	info:Object - An object containing the metadata. 
		public function onMetaData(info:Object):void
		{
			Tracer.debugTrace("PlayerNetStream: onMetaData: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate, 3);
			this.setLength(Number(info.duration));
			_fMetadataRecieved = true;
			this.handleVideoInfoEvent("metaData", info);
		}
		
		//============================
		//	function onCuePoint
		//============================
		//This function is an Event handler, invoked when the Flash Player reached to the cuepoint
		//Parameters:
		//	info:Object - An object containing an error or status message. 
		public function onCuePoint(info:Object):void
		{
			Tracer.debugTrace("PlayerNetStream: onCuePoint",3);
			this.handleVideoInfoEvent("cuePoint", info);
		}
		
		//-----Events----- 
	
		//=======================
		//	function _broadcast
		//=======================
		//This function dispatch the player events  
		protected function _broadcast(strEventName:String,eventParam:String):void
		{
			Tracer.debugTrace("AbsBasePlayer: _broadcast("+arguments+")",3);
			try
			{
				//dispatch event
				for(var i = 0;i < this._listeners.length; i++)
					//this._listeners[i].dispatchEvent(ev);
					this._listeners[i].playerEventsHandler(strEventName,eventParam);
					
			}catch(e){}
		}
		
		//=============================
		//	function _broadcast2
		//==============================
		//This function dispatch the player events  
		//ToDO: the 2 functions this one and the one above (_broadcast) should be transferred to one function
		private function _broadcast2(strEventName,eventParam)
		{
			Tracer.debugTrace("AbsBasePlayer: _broadcast2",3);
			//dispatch the events
			for(var i = 0;i < this._listeners.length; i++)
					this._listeners[i].playerEventsHandler2(strEventName,eventParam);
		}
		//-----Control----- 
		
		//============================
		//	function _play
		//============================
		//This function is called from play function, to play the video.
		//Addition functionality was added to this function, to play from 
		//a specific location.
		private function _play():void
		{
			Tracer.debugTrace("AbsBasePlayer: _play("+this._strStreamName +")",3);
	
			//update flag
			_fIsIdle = false;
			//The NetStream object is not defined yet
			//set the _fAutoPlay to true so the video will be played when ready.
			if(!this._nsReady())
			{
				this._fAutoPlay = true;
				return;
			}
			//streaming - play (after load or stop/movie end)
			//Note:  seek is done upon "onMetaData" NetStream event
			if((_fFirstPlay || _fVideoIsStopped)
							&& (this._nBufferingStatus != 1))
			{
				_fFirstPlay = false;
				_fVideoIsStopped = false;
				this._ns.play(this._strStreamName);
				_changeStatus(2);
			}
			else	//play after stop/movie end or pause
			{
				this._ns.resume();
			}
			_showVideo();
		}
		
		//=================
		//	function _stop
		//=================
		//This function is stopping the video (called by stop)
		private function _stop():void
		{
			Tracer.debugTrace("AbsBasePlayer: _stop",3);
			//verify ns object is noit null before reseting it
			if(_ns != null)
			{
				//progressive
				if(this._nBufferingStatus == 1)
				{
					_ns.pause();
					_ns.seek(0);
				}
				else	//streaming
					try{_ns.close();}catch(e){Tracer.debugTrace("AbsBasePlayer: _stop: Error, "+e, 6);}
			}
			//we clear the video as long as we didn't arrive from replay, so in replay the video will play smoothly
			Tracer.debugTrace("AbsBasePlayer: _stop - _fClearVideo = " + this._fClearVideo ,6);
			if (this._fClearVideo)
				_videoHolder.clear();
			else
				this._fClearVideo = true;
			this._reset();
			this._fVideoIsStopped = true;	 //video is stopped
		}
		
		//=================
		//	function _pause
		//=================
		//This function is pausing the video (called by pause)
		protected function _pause():void
		{
			Tracer.debugTrace("AbsBasePlayer: _pause",3);
			_ns.pause();
		}
		
		//=================
		//	function _seek
		//=================
		//This function is seeking the video (called by seek)
		protected function _seek(nSec:Number):void
		{
			Tracer.debugTrace("AbsBasePlayer: _seek(" + nSec+ ")",3);
			_ns.seek(nSec);
		}
		
		//============================
		//	function _initMedia
		//============================
		//Init the Media attributes for loading and playing it
		//Parameters:
		//	strURL:String - the video URL
		protected function _initMedia(strURL:String):void{}
		
		//=========================
		//	function _loadMedia
		//=========================
		//This function connect to the FCS
		//object
		protected function _loadMedia():void{}
		
		//=========================
		//	function _startLoad
		//=========================
		//This function set the buffer size for the NetConnection object and start loading
		protected function _startLoad():void{}
		
		//=========================
		//	function _progress
		//=========================
		//This function monitor load and play progress of the video.
		protected function _progress():void{}
		
		//=============================
		//	function _nsReady
		//=============================
		//This function checks if the NetStream object is ready to be played
		protected function _nsReady(){}
		
		//-----General----- 
		
		//=========================
		//	function _initVideoSize
		//=========================
		//This function set the video size
		//Parameters:
		//	width:Number - the video new width
		//	height:Number - the video new height
		private function _initVideoSize():void
		{
			Tracer.debugTrace("AbsBasePlayer: _initVideoSize",3);
			
			//check if the video is ready (its dimensions were initialized)
			if(this._videoHolder.videoWidth != 0)
			{
				//clear interval
				if(this._initSizeInterval != -1)
				{
					clearInterval(this._initSizeInterval);
					this._initSizeInterval = -1;
				}
				this._broadcast("initVideoSize","");
			}
			else
			{
				//set a timeout, the video is not ready
				if(this._initSizeInterval == -1)
					this._initSizeInterval = setInterval(this._initVideoSize,10);
			}
		}
		
		//=========================
		//	function _movieEnd
		//=========================
		//This function trigger the movie end event
		//It Calls the event handler and reset all flags
		private function _movieEnd():void
		{
			Tracer.debugTrace("AbsBasePlayer: _movieEnd",3);
			this._fMovieEnded = true;
			this._broadcast("movieEnd","");
		}
		
		//=========================
		//	function _reset
		//=========================
		//This function resets the class attributes for replay
		private function _reset():void
		{
			Tracer.debugTrace("AbsBasePlayer: _reset",3);
			this._broadcast("playProgress",""+0);
			this._broadcast("loadProgress",""+0);
			this._broadcast("bufferProgress",""+0);
			
			//-----Video and  video data----
			this._nPosition = -1;			//video position	
			//this._ns.time = 0;
			this._changeStatus(0);			//video status
			this.startPosition = 0;		//video start point
			this._initSizeInterval	= -1;		//set video size interval
			
			//-----General---- 		
			this._fAutoPlay = false;		//Indicates whether we need to play the video automatically when the buffer is ready (default true)
			this._fBufferReady = false;	//Indicates whether the buffer is ready or not (default false).
			this._fMovieEnded = false;	//indicates whether the movie was ended.
			this._fFirstPlay = false;	//indicates first play (after load).
			this._fIsIdle = true;	//indicates whether the video is Idle or not
			
			//-----Progress----
			this._nProgressIntervalID = -1;	//The interval id for the progress method
		}
		
		//-----Progress and events-----
		
		//============================
		//	function _getLoadProgress
		//============================
		//This function calculate the load progress and return it  
		private function _getLoadProgress():Number
		{
			Tracer.debugTrace("AbsBasePlayer: _getLoadProgress: this._ns.bytesLoaded", 6);
			var loadPorgress:Number = 0;
			//check if valid
			if((this._ns.bytesTotal != 0) && 
				(typeof(this._ns.bytesTotal) != "undefined") &&
					(typeof(this._ns.bytesLoaded) != "undefined"))
			{
				loadPorgress = this._ns.bytesLoaded/this._ns.bytesTotal;
			}
			
			//set valid
			if(loadPorgress > 1)
				loadPorgress = 1;
					
			//round to 2 numbers after the decimal point
			loadPorgress = Math.round(loadPorgress * 10000)/100;
			return (loadPorgress);
		}
		
		//===============================
		//	function _fireProgressEvents
		//===============================
		//This function fires the load and play progress events 
		protected function _fireProgressEvents():void
		{
			Tracer.debugTrace("AbsBasePlayer: _fireProgressEvents: _nPosition: "+this._nPosition, 6);
			
			//claculate play progress
			var playProgress:Number = this._ns.time/this._nLength;
			//set valid
			if(playProgress < 0)
				playProgress = 0;
			if(playProgress > 1)
				playProgress = 1;
				
			//round to 2 numbers after the decimal point
			playProgress = Math.round(playProgress * 10000)/100;
			
			//fire event - verify that the status is updated to be 
			//playing
			if(this._nState == STATE.PLAY)
			{
				//fire event - playProgress 
				this._broadcast("playProgress",""+playProgress);
			}
		
			///fix _nState/_nStatus/_ns.time/_nPosition mixup
			//_nState - load: 0 (default), Play:1, Stop:2
			//_nStatus - Idle: 0 (default), Loading:1, Buffering:2, Ready:3, Playing:4, Paused:5, Stopped:6, Full Screen Playback:7
			//_ns.time - netStream position
			//_nPosition - VideoLoader position
			if( (typeof(this._ns.time) != "undefined") && (this._ns.time >= 0 && this._ns.time < this._nPosition) ) //this._ns.time < this._nPosition is not valid - can happen after seeking backward
				if( this._nState == STATE.PLAY && (_nStatus == 1 || _nStatus == 2) ) //_nStatus == 1 == Loading || _nStatus == 2 == Buffering
					this._nPosition = -1; //force enter the following if

			Tracer.debugTrace("AbsBasePlayer: _fireProgressEvents: _nPosition="+this._nPosition+" | _ns.time="+this._ns.time + " | _nState="+this._nState + " | _nStatus=" + this._nStatus, 4);
			//loading or playing
			if (((this._nPosition < this._ns.time) && (this._nState == STATE.PLAY)) || (this._nState == STATE.LOAD))
			{
				if(this._nState == STATE.PLAY)
				{
					this._checkIfReadyPlay();
				}
				//check if valid
				if( (typeof(this._ns.time) != "undefined") && (this._ns.time >= 0) )
				{
					this._nPosition = this._ns.time;
				}
				//Calculate the load progress
				var loadProgress:Number = this._getLoadProgress();
				
				//fire events
				this._broadcast("loadProgress",""+""+loadProgress);
				return;
				
			}
			//no play progress
			//movie end
			if(this.isPlayingComplete())
			{
				this._movieEnd();
				return;
			}
			//buffering
			if (this._nState == STATE.PLAY)
			{
				Tracer.debugTrace("AbsBasePlayer: _fireProgressEvents: _changeStatus("+this._nBufferingStatus +")" , 4);
				this._changeStatus(this._nBufferingStatus);
			}
		}
		
		//==============================
		//	function _netStatusHandler
		//==============================
		//This function is NetStatusEvent Event handler, invoked by the NetStream/NetConnection object
		//every time a status change or error is posted for the NetStream/NetConnection 
		//object.
		//Parameters:
		//	event:NetStatusEvent - NetStatusEvent event object.
		function _netStatusHandler(event:NetStatusEvent):void
		{
			var objSrc:String = event.info.code.substr(0,9);
			//NetStream
			if(objSrc == "NetStream")
			{
				this._nsStatusChange(event.info);
			}
			//NetConnection
			else
			{
				this._ncStatusChange(event);
			}
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
		protected function _ncStatusChange(event:NetStatusEvent):void
		{
			var info = event.info;
			Tracer.debugTrace("AbsBasePlayer: _ncStatusChange: Enter with status = "+ info.code + ", level: " + info.level +")", 6);
			//connected successfully
			if (info.code == "NetConnection.Connect.Success")
			{
				//set the NetStream object
				this._setNS();
			}
			//error status
			if(info.level == "error")
			{
				Tracer.debugTrace("AbsBasePlayer: _ncStatusChange: Error: "+info.code,6);
				//trigger the error event
				this._broadcast("onError",info.code);
				this._changeStatus(-1);
			}
		}
		
		//============================
		//	function _errorHandler
		//============================
		//This function handles any error event thrown from the NetConnection/NetStream objects
		protected function _errorHandler(errEvent:Event)
		{
			//trigger the error event
			this._broadcast("onError", errEvent.type + ": "+errEvent);
		}
		
		//============================
		//	function _nsStatusChange
		//============================
		//This function handles NetStatusEvent and onPlayStatus events from the 
		//NetStream object.
		//The function calls _changeStatus function to update the status and
		//invoke the proper events
		//Parameters: 
		//	info:Object: An information object that has a code 
		//	property containing a string that describes the result of the 
		//	onPlayStatus/NET_STATUS event, and a level property containing a string 
		//	that is either "Status" or "Error". 
		protected function _nsStatusChange(info:Object):void
		{
			Tracer.debugTrace("AbsBasePlayer: _nsStatusChange("+info.code + ", level: " + info.level + ")", 3);			
			//event code
			switch (info.code)
			{
				case "NetStream.Play.Start":
					//buffering only before the video is playing
					//+ to handle FLV streaming bug in which upon replay, 
					//the status changed to buffering in a loop right after 
					//movie end (because the status is 0), to identify 
					//the situation we use the _fIsIdle flag, which
					//is set to true upon load and/or play.
					if((this._nStatus == 0) && !_fIsIdle)
					{
						this._changeStatus(this._nBufferingStatus); //buffering
						this._nState = STATE.LOAD;
					}
					break;
				case "NetStream.Buffer.Full":
					if(this._nState == STATE.PLAY)
					{
						this._checkIfReadyPlay(); //playing
					}
					break;
				case "NetStream.Seek.Notify":
					if (this._nState == STATE.PLAY)
					{
						Tracer.debugTrace("AbsBasePlayer: NetStream.Seek.Notify, this._nStatus="+this._nStatus, 4);
						this._checkIfReadyPlay(); //playing
						this._nPosition = -1;
					}
					break;
				case "NetStream.Seek.InvalidTime":
					_dealWithInvalidTime(info);					
					break;
				case "NetStream.Play.StreamNotFound":
				case "NetStream.Play.Failed":
					this._fCloseNSUponReset = false;
				default:
					//error status
					if((info.level == "error"))
					{
						Tracer.debugTrace("AbsBasePlayer: _nsStatusChange: Error: "+info.code, 0);
						//trigger the error event
						this._broadcast("onError",info.code);
						this._stop();
						this._changeStatus(-1);
					}
					break;
			}
		}
		
		private function _dealWithInvalidTime(info:Object):void
		{
			///handling problematic issue of seek to the ivalid time (over max lenth of a video or )
			Tracer.debugTrace("AbsBasePlayer: _dealWithInvalidTime: _nStatus = " + this._nStatus + " | position = " + this.position + " | _ns.time = " + this._ns.time, 4);

			switch (this._nStatus)
			{
				case 4: //playing
					this._checkIfReadyPlay(); //playing
					if( this.position == -1 )
						this._stop();
					else
						this.seek(info.details);
					break;
				case 5: //paused (NetStream.Seek.InvalidTime during dragging playback slider)
					if( this.position != -1 )
						this.seek(info.details);
					break;
				default:
					Tracer.debugTrace("AbsBasePlayer: NetStream.Seek.InvalidTime | _nStatus = " + this._nStatus, 1);
				
			}
		}
		
		//============================
		//	function ncRegisterEvents
		//============================
		//This function register to events of the NetConnection object
		protected function ncRegisterEvents(nc:NetConnection):NetConnection 
		{ 
			try
			{
				nc.objectEncoding = ObjectEncoding.AMF0;
				var customClient:Object = new Object();
				customClient.onBWDone = function();
				nc.client = customClient;
				nc.addEventListener(NetStatusEvent.NET_STATUS, _netStatusHandler);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
				nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, _errorHandler);
				nc.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _errorHandler);
			}catch(error:Error)
			{
				Tracer.debugTrace("Error | Exception in FLVStreamingPlayer:ncRegisterEvents: "+ error, 0);
				return null;
			}
			return nc;
		}
		
		//=========================
		//	function _changeStatus
		//=========================
		//This function is called from _ncStatusChange and the different control methods, 
		//in order to update the video status.
		//Parameters:
		//	nStatus:Number - the video status, optional statuses:
		//			Idle: 0 (default), Loading:1, Buffering:2, Ready:3, Playing:4, 
		//			Paused:5, Stopped:6
		public function _changeStatus(nStatus:Number):void
		{
			Tracer.debugTrace("AbsBasePlayer: _changeStatus(" + nStatus + ")",3);
			Tracer.debugTrace("AbsBasePlayer: _changeStatus(old status: " + this._nStatus + ")",3);
			
			//don't report the same status twice
			if(this._nStatus == nStatus)
				return;
				
			//if the status is 4 (playing) or loading, an interval should be set 
			//to report on progress
			var fBufferPrePlay:Boolean = ((nStatus == 1) && (this._nStatus < nStatus));
			if (fBufferPrePlay || (nStatus == 4) || (nStatus == 3)) 
			{
				//the intrval wasn't set already
				if(this._nProgressIntervalID == -1)
					this._nProgressIntervalID = setInterval(this._progress, 250);
			}
			//not playing
			else if(((nStatus < 1) || (nStatus > 4) )&& this._nProgressIntervalID != -1)
			{
				clearInterval(this._nProgressIntervalID);
				this._nProgressIntervalID = -1;
			}
			
			//Update the status
			this._nStatus = nStatus;
			
			//trigger the event
			this._broadcast("statusChanged",""+nStatus);
		}
		
		//=========================
		//	function _checkIfReadyPlay
		//=========================
		private function _checkIfReadyPlay():void
		{
			if ((this._nBufferingStatus == 1) || (_fMetadataRecieved))
			{
				this._changeStatus(4);
			}
		}

		//=========================
		//	function _bufferIsReady
		//=========================
		//This function called when the buffer is ready to init the video
		protected function _bufferIsReady():void
		{
			Tracer.debugTrace("AbsBasePlayer: _bufferIsReady",3);
			//set size
			this._initVideoSize();
			this._changeStatus(3);	//ready
			//fire event
			this._broadcast("bufferLoaded", "");
		}
	}
}