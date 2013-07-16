//****************************************************************************
//class eyeblaster.video.SWFVideoLoader
//------------------------------------
//This class replaces the old SWFVideoLoader component functionality
//It will be used as a "player" class for the SWF media
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************

package eyeblaster.video
{
	import eyeblaster.core.Tracer;
	import flash.events.*;
	import flash.net.*
	import flash.media.SoundTransform;
	import flash.utils.*;
	import flash.system.fscommand;
	import flash.display.*;
	import eyeblaster.video.general.VideoEvent;

	[IconFile("Icons/SWFVideoLoader.png")]

	[Event("ebReadyForVideoStrip", type="mx.eyeblaster.General.VideoEvent")]
	
	public class SWFVideoLoader extends MovieClip
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _fMovieInit:Boolean;			//indicates the first time the _movie parameter is not null
		private var _intervalID:Number;					//interval for calling the _progress function which is called as long as the video is playing
		private var _nMovieNum:Number;					//the movie number chosen by the user
		private var _fLoadAndPlay:Boolean ; 			//indicate if we should start playing the movie when buffer is ready.
		private var _fIsLoaded:Boolean; 				//indicate if the movie is already loaded
		private var _nFrameRate:int; 					//loaded  video movie frame rate
		private var _fIsPaused:Boolean;					//indicator whether paused function was called before _movie is not null
		
		private var _ProgressEvent:Function; 			//holds a reference to the event handler of buffer progress.
		private var _fIdle:Boolean;						 //indicate if the movie clip is loaded with a video or idle
		private var _nVolume:Number;
		private var _fIsSoundOn:Boolean;   				//flag, indicates if the sound is on or off
		private var _nVideoLoopInSec:Number;
		private var _nReportedPlayProgress:Number; 		//indicates playing progress
										 				//(-1: Not started/0: Started/1: 25% Played/2: 50% Played/3: 75% Played/4: Fully played)
		private var _fShouldReport:Boolean;				// Indicates if interactions should be reported.
														// Set by the dynamic mask component to prevent reporting when retracted.
		private var _fDurationTimerStatus:Boolean;				//Indicates the timer status (on/off)
		private var _loader:Loader;						//the loader object to load the swf file
		private var _mcContainer:MovieClip;				//movie clip that contains the loader/movie
		private var _movie:MovieClip; 					//the swf movie
		private var _sound:SoundTransform;				//sound object
		
		//----VideoStrip----
		private var _fReadyForVideoStrip:Boolean = false;	//indicates that the component is ready for the VideoStrip comp
		
		//----General------
		include "../core/compVersion.as"
		public var compName:String = "SWFVideoLoader";	//The component name to be used for components detection.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function SWFVideoLoader()
		{
			
			Tracer.debugTrace("SWFVideoLoader: Constructor", 6);
			Tracer.debugTrace("SWFVideoLoader version: " + compVersion, 0);	
			Tracer.debugTrace("Eyeblaster Workshop | SWFVideoLoader | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			this._init();
			
		}
		
		//+++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//		 functions	related to VideoStrip Component				
		//+++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//flag for videoStrip - used to notify the VideoStrip component that it can call to functions related to the video		
		public function get fReadyForVideoStrip():Boolean{return this._fReadyForVideoStrip;}
		public function set fReadyForVideoStrip(flag:Boolean):void{this._fReadyForVideoStrip = flag;}	
		
		//============================
		//	function resetReportStatus
		//============================
		// Reset the play progress interactions reporting status.
		// This function is called from the VideoStrip component upon expand.
		public function resetReportStatus():void
		{
			Tracer.debugTrace("SWFVideoLoader: resetReportStatus", 4);
			try
			{
				// Set the reported play progress to -1 (not reported) so it will start all over again
				_nReportedPlayProgress = -1;
				
				// Enable reporting (including play duration timer manipulations)
				_fShouldReport = true;
				
				// If the video is playing, start the video duration timer.
				// Otherwise it will be started when the status changes to "playing".
				if (isVideoPlaying())
					_StartVideoPlayDuration();
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in resetReportStatus: " + error, 1);
			}
		}
		
		//============================
		//	function disableReport
		//============================
		// Disable the play progress interactions reporting.
		// this function is called from the VideoStrip component upon retract.
		public function disableReport():void
		{
			Tracer.debugTrace("SWFVideoLoader: disableReport", 4);
			try
			{
				//stop the video duration timer
				_EndVideoPlayDuration();
			
				// Disable reporting (including play duration timer manipulations)
				_fShouldReport = false;
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in disableReport: " + error, 1);
			}
		}
		
		//============================
		//	function setVideoLoop
		//============================
		// This function is used by other components (e.g VideoStrip)
		//Parameters:
		//	Secs:Number - seconds of the movie (0: loop the whole movie)
		public function setVideoLoop(Secs):void
		{
			Tracer.debugTrace("SWFVideoLoader: setVideoLoop", 4);
			_nVideoLoopInSec = Secs;
			Tracer.debugTrace("swfLoader.setVideoLoop(" + Secs + ")", 1);
		}
		
		//============================
		//	function isVideoPlaying
		//============================
		// This function is used by other components (e.g VideoStrip)
		public function isVideoPlaying():Boolean
		{
			Tracer.debugTrace("SWFVideoLoader: isVideoPlaying", 4);
			return(!_fIdle);
		}
		
		//============================
		//	function videoSetMute
		//============================
		//This function set or unset speaker mute according to 
		//fShouldMute value.
		//Parameters:
		//	fShouldMute:Boolean - the speaker mute state
		public function videoSetMute(mute:Boolean):void
		{
			Tracer.debugTrace("SWFVideoLoader: videoSetMute("+mute + ") _fIsSoundOn=" + _fIsSoundOn, 2);
		
			//if the wanted result of this function is not the current situation
			//call videoMute to toggele the sound.
			if((mute && _fIsSoundOn)||(!mute && !_fIsSoundOn))
				videoMute();
		}
		
		
		//+++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						 API functions					
		//+++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//============================
		//	function videoMute
		//============================
		//This function set or unset speaker mute 
		public function videoMute():void
		{
			Tracer.debugTrace("SWFVideoLoader: videoMute", 3);
			try
			{
				// Mute/Unmute the sound
				_fIsSoundOn = !_fIsSoundOn;
				
				//The sound was initialized	- set the volume that was saved
				if (_movie != null)
					setVolume();
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in videoMute: " + error, 1);
			}
		}
		
		//============================
		//	function videoSetVolume
		//============================
		//This function set the speaker volume for the video
		//Parameter:
		//	nVolume:Number - volume level (0-100)
		public function videoSetVolume(nVolume:Number):void
		{
			Tracer.debugTrace("SWFVideoLoader: videoSetVolume: " + nVolume, 3);
			try
			{
				//in AS3 the volume is between 0 to 1 whereas in AS2 is between 0 to 100.
				//Therefore we devided the input to 100
				nVolume = nVolume / 100;
				if (nVolume > 1)
					nVolume = 1;
				if (nVolume < 0)
					nVolume = 0;
				//Save new volume level
				_nVolume = nVolume;
				if (_movie != null)
					setVolume();
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in videoSetVolume: " + error, 1);
			}
		}
		
		//============================
		//	function videoLoad
		//============================
		//This function downloads an SWF media
		//Parameters:
		//	szMovieURL:String - the video URL
		//	nFrameRate:Number - frame rate
		//	nProgressiveDownloadRisk:Boolean - This parameter should not be sent for AS3 since 
		//										we can't control the progressive download
		public function videoLoad(szMovieURL:String, nFrameRate:int, nProgressiveDownloadRisk:Number = -1):void
		{
			Tracer.debugTrace("SWFVideoLoader: videoLoad ", 3);
			try
			{
				//check if the nProgressiveDownloadRisk parameter was sent and if yes write an adequate message for the user
				if (nProgressiveDownloadRisk != -1)
					Tracer.debugTrace("Eyeblaster SWFVideoLoader component | When working in AS3, the nProgressiveDownloadRisk parameter cannot be used for the videoLoad / videoLoadAndPlay functions since the progressive buffering is handled by Adobe Flash", 0);
				if (nFrameRate > 0)
					this._nFrameRate = nFrameRate;
				else
				{
					Tracer.debugTrace("Eyeblaster SWFVideoLoader component | FrameRate must be greater than 0", 0);
					return;
				}
				//retrieve the video ordinal number
				_nMovieNum = getMovieNum(szMovieURL);
				_SetIdle(false);
				_fLoadAndPlay = false;
				_fIsLoaded = false;
				//load the movie
				_loadMovie(szMovieURL);
				//hide the movie
				_mcContainer.alpha = 0;
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in videoLoad: " + error, 1);
			}
		}
		
		//============================
		//	function videoLoadAndPlay
		//============================
		//This function downloads an SWF media and play it
		//Parameters:
		//	szMovieURL:String - the video URL
		//	nFrameRate:Number - frame rate
		//	nProgressiveDownloadRisk:Boolean - This parameter should not be sent for AS3 since 
		//										we can't control the progressive download
		public function videoLoadAndPlay(szMovieURL:String, nFrameRate:int, nProgressiveDownloadRisk:Number = -1):void
		{	
			Tracer.debugTrace("SWFVideoLoader: videoLoadAndPlay ", 3);
			try
			{
				//check if the nProgressiveDownloadRisk parameter was sent and if yes write an adequate message for the user
				if (nProgressiveDownloadRisk != -1)
					Tracer.debugTrace("Eyeblaster SWFVideoLoader component | When working in AS3, the nProgressiveDownloadRisk parameter cannot be used for the videoLoad / videoLoadAndPlay functions since the progressive buffering is handled by Adobe Flash", 0);
				if (nFrameRate > 0)
					this._nFrameRate = nFrameRate;
				else
				{
					Tracer.debugTrace("Eyeblaster SWFVideoLoader component | FrameRate must be greater than 0", 0);
					return;
				}
				//retrieve the video ordinal number
				_nMovieNum = getMovieNum(szMovieURL);
				_SetIdle(false);
				_fLoadAndPlay = true;
				_fIsLoaded = false;
				//load the movie
				_loadMovie(szMovieURL);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in videoLoadAndPlay: " + error, 1);
			}
		}
		
		///============================
		//	function videoPlay
		//============================
		//This function playing the video.
		//The funcrion is API function and also can be called from the VideoStrip component
		public function videoPlay()
		{
			Tracer.debugTrace("SWFVideoLoader: videoPlay ", 3);
			try
			{
				//show the movie 
				_mcContainer.alpha = 1;
				
				//reset the _fIdle flag (the play head was reset in the _mc.play();).
				//when the playhead reaches the end the flag is set to true and thus
				//_calcProgressive is not called, as a result the indicators are not being
				//updated (on replay)
				if (_fIdle)
					_SetIdle(false);
				
				//There might be a case that the user called to play while the _movie is still null
				if (_movie != null)
				{
					_Play();
					setVolume();
				}
				else
					_fLoadAndPlay = true; 
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in videoPlay: " + error, 1);
			}
		}
		
		//========================================
		//	function videoSetProgressEventHandler
		//========================================
		//Used to set the callback function that receives progress 
		//information as the video downloads or plays.
		public function videoSetProgressEventHandler(eventHandler:Function):Boolean
		{
			Tracer.debugTrace("SWFVideoLoader: videoSetProgressEventHandler: " + eventHandler, 3);

			if ("function" != typeof(eventHandler))
				return false;
				
			_ProgressEvent = eventHandler;
			
			return true;							 
		}
		
		//============================
		//	function videoStop
		//============================
		//This function stop the video 
		public function videoStop()
		{
			Tracer.debugTrace("SWFVideoLoader: videoStop" , 3);
			
			if (_movie != null)
				_Stop();
			else	
			{		
				//indicates that _fLoadAndPlay is false so when the _movie will not be null it will be stopped
				_fLoadAndPlay = false;   
				_mcContainer.alpha = 0;					
			}
			if (!_fIdle)
				_SetIdle(true);
		}
		
		//============================
		//	function videoPause
		//============================
		//This function pause the video 
		public function videoPause()
		{
			Tracer.debugTrace("SWFVideoLoader: videoPause" , 3);
			if (_movie != null)
			{
				//on pause the movie should stop and we should indicate that the video is in idle state (not playing) 
				_movie.stop();
				if (!_fIdle)
					_SetIdle(true);
			}
			else
				_fIsPaused = true; //indicator that we called pause while the _movie is still null
		}
				
		//============================
		//	function isPlayingComplete
		//============================
		// Check if the play head is close enough to the movie end, so we can consider the video "completed"
		// There are cases when the play head doesn't reach the total time, so we use a factor.
		public function isPlayingComplete():Boolean
		{
			Tracer.debugTrace("SWFVideoLoader: isPlayingComplete" , 3);
			if (_movie != null)
				return (_movie.currentFrame >= _movie.totalFrames);
			return false;
		}

		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//========================
		//	function _init
		//========================
		//The function inits the component and the attributes
		private function _init():void
		{
			Tracer.debugTrace("SWFVideoLoader: _init", 4);
			
			this._initComp();
			this._initAttr();
			//fire event to the videoStrip, so in case videoStrip component exist the swfLoader will notify the 
			//the videoStrip when to call to _setVideoComponent function
			var evStrip:VideoEvent = new VideoEvent("ebReadyForVideoStrip", "");
			// Dispatch the event
			dispatchEvent(evStrip);
			this._fReadyForVideoStrip = true;
		}
		
		//========================
		//	function _initComp
		//========================
		//The function inits all the things related to the component
		private function _initComp()
		{
			Tracer.debugTrace("SWFVideoLoader: _initComp", 4);
			ebGlobal.ebSetComponentName("SWFVideoLoader");
			//hiding the icon at runtime
			this.getChildAt(0).alpha = 0;
		}
		
		//========================
		//	function _initAttr
		//========================
		//The function inits all the attributes of the VideoStrip class
		private function _initAttr():void
		{
			Tracer.debugTrace("SWFVideoLoader: _initAttr", 4);
			_nMovieNum = 0;
			_fMovieInit = false;
			_fIsPaused = false;
			_fLoadAndPlay = true; 
			_fIsLoaded = false; 
			_nFrameRate = 30; 
			_intervalID = -1;
			_ProgressEvent = null; 			//holds a reference to the event handler of buffer progress.
			_fIdle = true; 
			_nVolume = 1;
			_fIsSoundOn = false;  
			_nVideoLoopInSec = -1;
			_nReportedPlayProgress = -1;		 //indicates that playing progress not strated
			_fShouldReport = true;
			_loader = new Loader();
			_mcContainer = new MovieClip();
			//handle sound - set the sound to 0
			_sound = new SoundTransform();			
			_sound.volume = 0;
			this._fDurationTimerStatus = false;		//Indicates the timer status (on/off)
		}
		
		//========================
		//	function _loadMovie
		//========================
		//This function load the movie given in the url
		private function _loadMovie(url):void
		{
			Tracer.debugTrace("SWFVideoLoader: _loadMovie: url: " + url , 4);
			try
			{
				var urlReq:URLRequest = new URLRequest(url);
				//load the movie
				_loader.load(urlReq);
				//add the _loader as a child of the container. Done since in VideoLoad without the container the movie is seen for a second 
				//and than hided. To prevent it we used a container
				_mcContainer.addChild(_loader);
				addChild(_mcContainer);
				_mcContainer.alpha = 0;
				
				//add event listeners to indicate the progress of the movie and when the movie is completely downloaded
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
				_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _loadMovie: " + error, 1);
			}
			
		}
		
		//========================
		//	function _progress
		//========================
		//This function call to _calcProgressive when needed
		private function _progress():void
		{
			try
			{
				//check when the _movie is not null.
				//It takes several milliseconds since the loader.content get a value different than null
				if (_movie == null)
					_movie = MovieClip(_loader.content);
				//when the _movie is not null for the first time we want to handle sound and handle events (like stop/play) that were called when the _movie was still null
				if ((_movie != null) && (!_fMovieInit))
				{
					if (!_fLoadAndPlay)	//videoLoad case
					{
						_movie.stop();
						_movie.alpha = 0;
						_movie.gotoAndStop(1);
						
					}
					else			//videoLoadAndPlay case
					{
						_mcContainer.alpha = 1;
					}
					//handle sound
					setVolume();
					//handle pause in case it was called 
					if (_fIsPaused)
						videoPause();
				
					_fMovieInit = true;
				}
				if (!_fIdle)
					_calcProgressive();
				else	//the movie is not playing and therefore the interval can be cleared
				{
					clearInterval(_intervalID);
					_intervalID = -1;
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _progress: " + error, 1);
			}
		}
		
		//===========================
		//	function _calcProgressive
		//===========================
		private function _calcProgressive():void
		{
			try
			{
				//find the part of how many bytes were loaded from the total bytes
				var loadingProgress = _loader.contentLoaderInfo.bytesLoaded / _loader.contentLoaderInfo.bytesTotal;
				var playingProgress = 0;
				if (_movie != null)
				{
					//in AS3 the playingProgress on frame 1 is not 0. Therefore we set the playingProgress to 0 and will be changes only
					//when the frame is bigger than 1
					if (_movie.currentFrame > 1)
						playingProgress = _movie.currentFrame /  _movie.totalFrames;
					
					// Report the playing progress
					_reportPlayProgress();
					
					//handle the things related to VideoStripComponent
					_handleVideoStrip(playingProgress);
					
						
					//set idle flag
					if (1 <= playingProgress)
						_SetIdle(true);
				}
				
				//check if the user called to ideoSetProgressEventHandler API function
				if (_ProgressEvent != null)
				{
					//trigger the _ProgressEvent callBack
					_ProgressEvent(loadingProgress*100, playingProgress*100);
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _calcProgressive: " + error, 1);
			}
		}
		
		//===========================
		//	function _handleVideoStrip
		//===========================
		private function _handleVideoStrip(playingProgress:Number):void
		{
			try
			{
				//handle video loop if need to 
				if(_nVideoLoopInSec == 0)	//loop the whole movie
				{
					if(playingProgress >= 1)//reach till the end
					{
						_Stop();
						_Play();
						playingProgress = 0;
					}
				}
			
				if(_nVideoLoopInSec > 0)	//loop _nVideoLoopInSec seconds of the movie
				{
					var nSecPass = _movie.currentFrame / _nFrameRate;
					if(_nVideoLoopInSec <= nSecPass)
					{
						_Stop();
						_Play();
					}	
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _handleVideoStrip: " + error, 1);
			}
		}
		
		//===========================
		//	function _Play
		//===========================
		//This function play the video and handles all the things that should happen while the
		//movie is playing i.e. handle reporting
		private function _Play()
		{
			Tracer.debugTrace("SWFVideoLoader: _Play" , 4);
			try
			{
				// Reset the playing progress interactions reporting
				if (_nReportedPlayProgress == 4)
					_nReportedPlayProgress = -1;
					
				//verify that old interval doesn't exist	
				if (_intervalID > -1)
				{
					clearInterval(_intervalID);
					_intervalID = -1;
				}
				//set interval for reporting, playing progress
				_intervalID = setInterval(_progress, 300);
				//display the movie and play it
				_movie.alpha = 1;
				_movie.play();
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _Play: " + error, 1);
			}
		}
		
		//===========================
		//	function _Stop
		//===========================
		//This function stop the video and handles all the things that should happen while the
		//movie is stpped 
		private function _Stop():void
		{
			Tracer.debugTrace("SWFVideoLoader: _Stop" , 4);
			try
			{
				// Reset the playing progress interactions reporting
				_nReportedPlayProgress = -1;
				//stop the movie, not displaying it and transfer it to the beginning
				_movie.stop();
				_movie.alpha = 0;
				_movie.gotoAndStop(1);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _Stop: " + error, 1);
			}
		}
		
		//============================
		//	function _SetIdle
		//============================
		// This function sets the _fIdle flag and starts/ends the play duration timer accordingly
		private function _SetIdle(fIdle):void
		{
			Tracer.debugTrace("SWFVideoLoader: _SetIdle: fIdle: " + fIdle , 4);
			// Start/end the play duration timer in case the movie is loaded
			if (_fIsLoaded)
			{
				if (fIdle)
					_EndVideoPlayDuration();
				else
					_StartVideoPlayDuration();
			}
			// Set the flag
			_fIdle = fIdle;
		}

		//============================
		//	function _reportPlayProgress
		//============================
		// This function reports the playing progress interactions
		private function _reportPlayProgress():void
		{
			try
			{
				// make sure we don't divide by zero
				if (_movie.totalFrames <= 0)
				{
					Tracer.debugTrace("Invalid total frames: _movie.totalFrames must be greater than zero", 3);
					return;
				}
				
				// Check if reporting is enabled
				if (!_fShouldReport)
					return;
				
				// Check if finished playing
				if (_nReportedPlayProgress == 4)
				{
					_nReportedPlayProgress = -1;
					//clear the interval when the movie reached to the end
					if (_intervalID > -1)
					{
						clearInterval(_intervalID);
						_intervalID = -1;
					}
					return;
				}
			
				// Calculate the playing progress
				var flProgress = (_movie.currentFrame / _movie.totalFrames);
				
				// Report the playing progress.
				// Note that no report should be "skipped".
				if ((flProgress > 0) && (_nReportedPlayProgress == -1))
				{
					fscommand("ebVideoInteraction","'ebVideoStarted','" + _nMovieNum + "'");
					_nReportedPlayProgress = 0;
				}
				if ((flProgress >= 0.25) && (_nReportedPlayProgress < 1))
				{
					fscommand("ebVideoInteraction","'eb25Per_Played','" + _nMovieNum + "'");
					_nReportedPlayProgress = 1;
				}
				if ((flProgress >= 0.5) && (_nReportedPlayProgress < 2))
				{
					fscommand("ebVideoInteraction","'eb50Per_Played','" + _nMovieNum + "'");
					_nReportedPlayProgress = 2;
				}
				if ((flProgress >= 0.75) && (_nReportedPlayProgress < 3))
				{
					fscommand("ebVideoInteraction","'eb75Per_Played','" + _nMovieNum + "'");
					_nReportedPlayProgress = 3;
				}
				if ((flProgress >= 1) && (_nReportedPlayProgress < 4))
				{
					// End the playing progress timer since the movie is not playing
					_EndVideoPlayDuration();
			
					fscommand("ebVideoInteraction","'ebVideoFullPlay','" + _nMovieNum + "'");
					_nReportedPlayProgress = 4;
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in _Stop: " + error, 1);
			}
		}

		
		
		//==================================
		//	function _StartVideoPlayDuration
		//==================================
		// Start the playing progress timer
		private function _StartVideoPlayDuration():void
		{
			Tracer.debugTrace("SWFVideoLoader: _StartVideoPlayDuration", 4);
			if (_fShouldReport && !this._fDurationTimerStatus)
			{
				Tracer.debugTrace("Starting ebVideoPlayDuration timer", 3);
				fscommand("ebStartVideoTimer","'ebVideoPlayDuration','" + _nMovieNum + "'");
				//transfer _fDurationTimerStatus to true in order to enable report _EndVideoPlayDuration when needed
				this._fDurationTimerStatus = true;

			}
		}
		
		//============================
		//	function _EndVideoPlayDuration
		//============================
		// End the playing progress timer
		private function _EndVideoPlayDuration():void
		{
			Tracer.debugTrace("SWFVideoLoader: _EndVideoPlayDuration", 4);
			if (_fShouldReport && this._fDurationTimerStatus)
			{
				Tracer.debugTrace("Ending ebVideoPlayDuration timer", 3);
				fscommand("ebEndVideoTimer","'ebVideoPlayDuration','" + _nMovieNum + "'");
				this._fDurationTimerStatus = false;
			}
		}

		//============================
		//	function setVolume
		//============================
		//This function will only be called when the sound object should be set
		private function setVolume():void
		{
			Tracer.debugTrace("SWFVideoLoader: setVolume", 4);
			
			if (_fIsSoundOn)	//The sound is muted (and need to be set on)
				_sound.volume = _nVolume;
			else				//The sound should be muted
				_sound.volume = 0;
			_movie.soundTransform = _sound;
		}
		
		//======================
		//function getMovieNum
		//======================
		//This function retrieve the used movie ordinal number
		//according to its URL.
		//Parameters:
		//	strURL:String - the used movie URL
		function getMovieNum(strURL)
		{
			Tracer.debugTrace("SWFVideoLoader: getMovieNum: strURL: " + strURL, 4);
			
			var nMovieNum = 0;
			//go over all _root.ebMovieX and find the correct one
			//according to its URL.
			for(var i=1 ; i < 11 ; i++)
			{
				if(ebGlobal["ebMovie"+i] == strURL)
				{
					nMovieNum = i;
					break;
				}
			}
			return nMovieNum;
		}

		//======================
		//function completeHandler
		//======================
		//This function is triggered when the swf completely downloaded
		private function completeHandler(event:Event):void
 		{
			Tracer.debugTrace("SWFVideoLoader: completeHandler: the swf was completely downloaded", 3);
			try
			{
				//check the version of the swf file. If it is not in AS3 the movie will be displayed but
				//with an error message for the user that there will be a problem to control it.
				if (_loader.contentLoaderInfo.actionScriptVersion < 3)
				{
					Tracer.debugTrace("Eyeblaster SWFVideoLoader component | When working in AS3, the SWFVideoLoader component can only show other AS3 SWF files. The file you loaded is an AS2 file and might not play properly. Please replace this file with an AS3 one.", 0);
				}
				else //AS3 version of the loaded swf
				{
					//set interval for the function that handles the reporting while the movie is playing
					if (_intervalID > -1)
					{
						clearInterval(_intervalID);
						_intervalID = -1;
					}
					_intervalID = setInterval(_progress, 300);
					
					//indicator that the whole movie was loaded
					_fIsLoaded = true;
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("SWFVideoLoader: error in completeHandler: " + error, 1);
			}
		}
		//======================
		//function progressHandler
		//======================
		//This function is triggered while the movie is downloaded
		private function progressHandler(event:ProgressEvent):void
		{
			//call  to progress function to get indication how many percentage were loaded
			_progress();
		}
	}
}
