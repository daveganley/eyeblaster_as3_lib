﻿//****************************************************************************
//     class eyeblaster.events.EBVideoEvent 
//------------------------------------------
//This class contains the event types of video components that are used by the users 
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.events
{ 
	import flash.events.Event;
	public class EBVideoEvent extends Event
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private var _playProgress:Number;
		private var _loadProgress:Number;
		private var _bufferProgress:Number;
		private var _statusChanged:String;
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public static const PLAY_PROGRESS:String = "ebPlayProgress";
		public static const LOAD_PROGRESS:String = "ebLoadProgress";
		public static const BUFFER_PROGRESS:String = "ebBufferProgress";
		public static const STATUS_CHANGED:String = "ebStatusChanged";
		public static const MOVIE_START:String = "ebMovieStart";
		public static const MOVIE_SEEK:String = "ebMovieSeek";
		public static const MOVIE_END:String = "ebMovieEnd";
		public static const BUFFER_LOADED:String = "ebBufferLoaded";
		public static const PLAYBACK_START:String = "ebPlaybackStart";
		public static const PLAYBACK_STOP:String = "ebPlaybackStop";
		
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function EBVideoEvent(type:String, value:Object):void
		{
			super(type);
			for (var attr:String in value)
			{
				switch (attr)
				{
					case PLAY_PROGRESS:
						_playProgress = value[attr];
					break;
					case LOAD_PROGRESS:
						_loadProgress = value[attr];
					break;
					case BUFFER_PROGRESS:
						_bufferProgress = value[attr];
					break;
					case STATUS_CHANGED:
						_statusChanged = value[attr];
					break;
				}
			}
		}
		
		//==========================
		//	Getter functions
		//==========================
		public function get playProgress():Number{return this._playProgress;}
		public function get loadProgress():Number{return this._loadProgress;}
		public function get bufferProgress():Number{return this._bufferProgress;}
		public function get statusChanged():String{return this._statusChanged;}
	}	
}

