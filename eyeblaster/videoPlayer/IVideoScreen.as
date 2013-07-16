package eyeblaster.videoPlayer
{
	import flash.events.IEventDispatcher;
	import flash.media.Video;
	import flash.net.NetStream;
	
	/**
	 * This interface is used to reference the VideoScreen component without having to compile it in when not using the VideoScreen component.
	 */
	public interface IVideoScreen extends IEventDispatcher
	{
		/** @private */
		function initialize(id:int):void;
		
		/**
		 * Downloads the specified video file by asset id.
		 * 
		 * @param movieNum:Number The video number. For example, insert number 2 for an asset whose ordinal number is 2. If you want to use the default
		 * 		video, do not specify this parameter.
		 * 
		 * @example The following code illustrates how to download a video file whose ordinal number is 2 on a VideoScreen instance named videoInst:<br>
		 * 		<code>videoInst.load(2)</code>
		 */
		function load(movieNum:Number = -1):void;
		
		/**
		 * Downloads and plays a video file.
		 * 
		 * @param movieNum:Number The video number. For example, insert number 2 for an asset whose ordinal number is 2. If you want to use the default
		 * 		video, do not specify this parameter.
		 * 
		 * @example The following code illustrates how to download and play a video file whose ordinal number is 2 on a VideoScreen instance named videoInst:<br>
		 * 		<code>videoInst.loadAndPlay(2)</code>
		 * 
		 * @see #load()
		 */
		function loadAndPlay(movieNum:Number = -1):void;
		
		/**
		 * If the movie was placed on an external server due to size limitations, downloads the external media file.
		 * 
		 * @param movieURL:String The external media file URL
		 * 
		 * @example The following code illustrates how to download an external URL:<br>
		 * <code>videoInst.loadExt("http://www.movieurl.com/movie.flv")</code>
		 */
		function loadExt(movieURL:String):void;
		
		/**
		 * If the movie was placed on an external server due to size limitations, this method downloads and plays the external media file.
		 * 
		 * @param movieURL:String The external media file URL.
		 * 
		 * @example The following code illustrates how to download and play an external URL:
		 * <code>videoInst.loadAndPlayExt("http://www.movieurl.com/movie.flv")</code>
		 * 
		 */
		function loadAndPlayExt(movieURL:String):void;
		
		/**
		 * Plays the video if paused, or the last played video if stopped.
		 */
		function play():void;
		
		/**
		 * Unmutes the audio of the playing video
		 */
		function unmute():void;
		
		/**
		 * Mutes the audio of the playing video.
		 */
		function mute():void;
		
		/**
		 * Pauses the video
		 */
		function pause():void;
		
		/**
		 * Pauses the video while video/audio scrubbar is dragged
		 */
		function pauseForSlider():void; ///Pauses the video while video scrubbar is dragged
		
		/**
		 * Resumes the video after the video/audio scrubbar has been released
		 */
		function playAfterPauseForSlider():void; ///Resumes the video after the video scrubbar has been released
		
		/**
		 * Stops the video
		 */
		function stop():void;
		
		/**
		 * Stops the video and clears the screen.
		 */
		function stopAndClear():void;
		
		/**
		 * Replays the video, optionally unmuting the video.
		 * 
		 * @param turnAudioOn:Boolean If true, this will unmute the video at replay
		 */
		function replay( turnAudioOn:Boolean = true ):void;
		
		/**
		 * If the video is muted, this will unmute the video. If the video is unmuted, this will mute the video.
		 */
		function audioToggle():void;
		
		/**
		 * If the video is playing, this will pause the video. If the video is paused, this will unpause the video. If the video is stopped, this will replay the video.
		 */
		function videoToggle():void;
		
		/**
		 * Seeks the specified number of seconds into the video that is currently playing from the beginning of the video
		 * 
		 * @param timeInSeconds:Number The number of the seconds from the beginning of the video to seek.
		 * 
		 * @example To seek to 6 seconds in the video, use <code>videoInst.seek(6)</code>. However, to seek forward 6 seconds, use <code>videoInst.seek(videoInst.time + 6)</code>
		 */
		function seek(timeInSeconds:Number):void;
		
		/** @private */
		function track(interactionName:String,isAuto:Boolean = false):void;
		
		/**
		 * Opens or closes the fullscreen according to the value that was received as a parameter. If true, opens in fullscreen, if false, closes the fullscreen.
		 */
		function setFullScreen(fullScreen:Boolean):void;
		
		/**
		 * Sets the FMS URL for the use of external FLV streaming file. <em>Note: this method should be called before the <code>loadAndPlayExt</code> or <code>loadExt</code> methods.</em>
		 * 
		 * @param strFMSURL:String The URL to the Flash Media Server (FMS)
		 * 
		 * @see loadExt()
		 * @see loadAndPlayExt()
		 */
		function setFMS(strFMSURL:String):void;
		
		/**
		 * Resizes the VideoScreen component
		 * 
		 * @param width:Number Width to set the component to
		 * @param height:Number Height to set the component to
		 */
		function setSize(width:Number, height:Number):void;
		
		/**
		 * Returns true if the volume is at 0%, false if volume is greater than 0%.
		 */
		function get isMuted():Boolean;
		
		/**
		 * @private
		 * Returns the volume level of the component. Possible values are between 0 for 0% and 100 for 100%.
		 */
		function get volume():int;
		
		/**
		 * Sets the volume level of the component.
		 * 
		 * @param volumeLevel:int The volume level to set the component to. Possible values are between 0 for 0% and 100 for 100%.
		 */
		function set volume(volumeLevel:int):void;
		
		/**
		 * Returns the total number of bytes loaded from the server. Returns 0 if the video is being played from Flash Media Server
		 */
		function get bytesLoaded():Number;
		
		/**
		 * Returns the total number of bytes for the video file. Returns 0 if the video is being played from Flash Media Server
		 */
		function get bytesTotal():Number;
		
		/**
		 * Returns true if the video is paused, false otherwise
		 */
		function get isPaused():Boolean;
		
		/**
		 * Returns true if the video is playing, false otherwise
		 */
		function get isPlaying():Boolean;
		
		/**
		 * Returns true if the video is stopped, false otherwise
		 */
		function get isStopped():Boolean;
		
		/**
		 * @private
		 */
		function get length():Number;
		
		/**
		 * Sets the length of the playing video in seconds. Set this value if length is 0 after EBMetadataEvent.METADATA_RECEIEVED is dispatched because the duration
		 * is not properly encoded into the video file.
		 * 
		 * @param value:Number the length of the video in seconds
		 */
		function set length(value:Number):void;
		
		/**
		 * Returns the playhead time in seconds of the playing video.
		 */
		function get time():Number;
		
		/**
		 * Returns true if the video is fullscreen, false otherwise.
		 */
		function get isFullScreen():Boolean;
		
		/**
		 * Returns true if the video is buffering, false otherwise. Note: this value can also be true if the video is set to auto-play
		 * but the video file hasn't begun loading yet
		 */
		function get isBuffering():Boolean;
		
		/**
		 * Returns true if the video will be paused on the last frame, i.e., nOnMovieEnd parameter is set to '2'. If nOnMovieEnd is set to a value other than '2', then
		 * pauseOnLastFrame will be false.
		 */
		function get pauseOnLastFrame():Boolean;
		
		/**
		 * If pauseOnLastFrame is set to true, then nOnMovieEnd will be set to '2'. If pauseOnLastFrame is set to false, and nOnMovieEnd is set to '2', then nOnMovieEnd will
		 * be set to '0'
		 */
		function set pauseOnLastFrame(value:Boolean):void;
		
		/**
		 * Returns true if the video is currently paused on its last frame
		 */
		function get isPausedOnLastFrame():Boolean;
		
		/**
		 * Set isPausedOnLastFrame
		 */
		function set isPausedOnLastFrame(value:Boolean):void;
		
		/**
		 * Returns the instance name of the component
		 */
		function get name():String;
		
		/**
		 * Retrieves the instance of the Flash Video object used by the component
		 */
		function get video():Video;
		
		/**
		 * Retrieves the instance of the NetStream object used by the component
		 */
		function get netStream():NetStream;
		
		/**
		 * Retrieves if the video is currently being smoothed when the video is stretched.
		 */
		function get smoothing():Boolean;
		
		/**
		 * Sets the value to determine whether or not to smooth the video when the video is stretched.
		 */
		function set smoothing(value:Boolean):void;
	}
}