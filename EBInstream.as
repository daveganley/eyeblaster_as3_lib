package
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBInstreamCustomEvent;
	import eyeblaster.events.EBInstreamEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.instream.AnimationObserver;
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Called when the player requests the ad to collapse. Corresponds to
	 * collapseAd in VPAID or similar for other non-VPAID player APIs
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.COLLAPSE_EVENT
	 */
	[Event(name="collapseAd", type="eyeblaster.events.EBInstreamEvent")]

	/**
	 * Called when the player requests the ad to expand. Corresponds to
	 * expandAd in VPAID or similar for other non-VPAID player APIs
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.EXPAND_EVENT
	 */
	[Event(name="expandAd", type="eyeblaster.events.EBInstreamEvent")]

	/**
	 * Called when the player requests the ad to stop/end. Corresponds to
	 * stopAd in VPAID or similar for other non-VPAID player APIs
	 * 
	 * The close notification in EBBase will be called automatically 
	 * after this event being dispatched, so designers should only use
	 * this event when they are doing something specific for instream
	 * that they don't want to do for in-page ads.
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.STOP_EVENT
	 */
	[Event(name="stopAd", type="eyeblaster.events.EBInstreamEvent")]

	/**
	 * Called when the player requests the ad to pause. Corresponds to
	 * pauseAd in VPAID or similar for other non-VPAID player APIs
	 * All UI animations and sounds should be suspended until RESUME_EVENT
	 * is called.
	 *
	 * If the ad is purely a video ad and the video is registered, then
	 * it should not be necessary to listen to this event. However,
	 * for ads with animations, sounds, and other features outside of
	 * registered videos, then it should be necessary to listen to this
	 * event.
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.PAUSE_EVENT
	 */
	[Event(name="pauseAd", type="eyeblaster.events.EBInstreamEvent")]

	/**
	 * Called when the player requests the ad to resume if already paused. 
	 * Corresponds to resumeAd in VPAID or similar for other non-VPAID player APIs
	 *
	 * You should only need to handle this event if you did any special handling
	 * for pauseAd. For normal video ads with registered videos, nothing special
	 * should need to be done for resumeAd.
	 * 
	 * @eventType eyeblaster.events.EBInstreamEvent.RESUME_EVENT
	 */
	[Event(name="resumeAd", type="eyeblaster.events.EBInstreamEvent")]

	/**
	 * Called when the player requests the ad to skip. Corresponds to
	 * skipAd in VPAID2 or similar for other non-VPAID player APIs
	 * Note: This should have the same user experience as stopAd.
	 *
	 * The close notification in EBBase will be called automatically 
	 * after this event being dispatched, so designers should only use
	 * this event when they are doing something specific for instream
	 * that they don't want to do for in-page ads.
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.SKIP_EVENT
	 */
	[Event(name="skipAd", type="eyeblaster.events.EBInstreamEvent")]	

	/**
	 * Called when the player requests the ad to start. Corresponds to
	 * startAd in VPAID or similar for other non-VPAID player APIs
	 *
	 * It isn't usually necessary to listen to this event. 
	 * The creative API should normally handle this event automatically
	 * Only use this event for any special initiation. 
	 * 
	 * Note: gotoAndPlay(2) has already happened at the point this is called.
	 *
	 * @eventType eyeblaster.events.EBInstreamEvent.START_EVENT
	 */
	[Event(name="startAd", type="eyeblaster.events.EBInstreamEvent")]	
	
	/**
	 * EBInstream is the Instream Ad API provided for use with MediaMind creatives. This API gives you the ability to integrate with various video
	 * players supported by the MediaMind platform, including players compatible with the IAB VAST and IAB VPAID APIs.
	 */
	public class EBInstream
	{
		private static function get _creativeHandler():*
		{
			return EBBase.currentAssetRef["eyeblaster_module_instream_CreativeHandler"];
		}
		
		private static function get moduleInstance():Sprite
		{
			return EBBase.currentAssetRef["eyeblaster_module_instream_inst"] as Sprite;
		}
		
		private static var _eventDispatcher:EventDispatcher;
		private static var _customHandlers:Object = {};
		private static var _animationObserver:AnimationObserver;
		
		private static var isHandlingCustomEvents:Boolean = false;
		
		/**
		 * Registers an event listener object with an EventDispatcher object so that the listener receives notification of an event.
		 *
		 * Use eyeblaster.events.EBNotificationEvent for sending/receiving custom events to/from the publisher API of custom loaders
		 */
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{	
			if(moduleInstance != null){
				moduleInstance.addEventListener(type,listener,useCapture,priority,useWeakReference);
				
				if(!isHandlingCustomEvents){
					isHandlingCustomEvents = true;
					_creativeHandler.addEventListener("ebCustomInstreamEvent", _handleCustomEvent);
				}
			}
		}
		
		// Handle events coming from the loader
		// Proxy all events through this method. Don't allow CreativeHandler to dispatch
		// events directly on this class, since we should be pre-filtering what events
		// that designers have access to.
		private static function _handleCustomEvent(e:*):void
		{
			if (e.type == "ebCustomInstreamEvent")
			{
				var ebInstream:EBInstreamCustomEvent = new EBInstreamCustomEvent(e.customName,e.data);
				ebInstream.isFromPlayer = true;
				dispatchEvent(ebInstream);
			}
		}
		
		/**
		 * Dispatches an event into the event flow.
		 */
		public static function dispatchEvent(event:Event):void
		{
			if(moduleInstance != null && _creativeHandler != null)
			{
				if(event is EBInstreamCustomEvent){
					
					var ebInstreamCustomEvent:EBInstreamCustomEvent = event as EBInstreamCustomEvent;
					
					if(!ebInstreamCustomEvent.isFromPlayer){
						
						try {
							var _CustomInstreamEvent:* = getDefinitionByName("eyeblaster.instream.events.CustomInstreamEvent");
							var customEvent:* = new _CustomInstreamEvent(ebInstreamCustomEvent.type, ebInstreamCustomEvent.data);
							_creativeHandler.dispatchEvent(customEvent);
						} catch(e:Error){
							// do nothing
						}
					}
				}
				
				if(event is EBInstreamEvent){
					// do nothing. we need to reference EBInstreamEvent if EBInstream is included
				}
				
				moduleInstance.dispatchEvent(event);
			}
		}
		
		/**
		 * Checks whether the EventDispatcher object has any listeners registered for a specific type of event.
		 */
		public static function hasEventListener(type:String):Boolean
		{
			if(moduleInstance != null){
				return moduleInstance.hasEventListener(type);
			} else {
				return false;
			}
		}
		
		/**
		 * Removes a listener from the EventDispatcher object.
		 */
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			if(moduleInstance != null){
				moduleInstance.removeEventListener(type,listener,useCapture);
			}
		}
		
		/**
		 * Checks whether an event listener is registered with this EventDispatcher object or any of its ancestors for the specified event type.
		 */
		public static function willTrigger(type:String):Boolean
		{
			if(moduleInstance != null){
				return moduleInstance.willTrigger(type);
			} else {
				return false;
			}
		}
		
		
		public static function get Animation():AnimationObserver
		{
			if(_animationObserver == null){
				_animationObserver = new AnimationObserver(_creativeHandler);
			}
			
			return _animationObserver;
		}
		
		/**
		 * Register a video with EBInstream. EBInstream will then dispatch video related events to the Host Video Player automatically.
		 */
		public static function RegisterScreen(videoScreen:IVideoScreen):void
		{
			if(_creativeHandler != null){
				_creativeHandler.registerVideoEvents(videoScreen);
			}
		}
		
		/**
		 * Unregister a video with EBInstream. EBInstream will stop dispatching video related events to the Host Video Player for the given video.
		 */
		public static function UnregisterScreen(videoScreen:IVideoScreen):void
		{
			if(_creativeHandler != null){
				_creativeHandler.unregisterVideoEvents(videoScreen);
			}
		}
		
		/**
		 * Tells the Host Video Player that the ad will be transitioning to Linear mode from Non-Linear
		 * mode. If the ad is also expanding from a collapsed state, there is no need to call this function.
		 */
		public static function StartLinear():void
		{
			if(_creativeHandler != null){
				_creativeHandler.adLoader.startLinear();
				_creativeHandler.isAdLinear = true;
			}
		}
		
		/**
		 * Tells the Host Video Player that the ad will be transitioning to Non-Linear mode from Linear
		 * mode. If the ad is also collapsing from an expanded state, there is no need to call this function.
		 */
		public static function EndLinear():void
		{
			if(_creativeHandler != null){
				_creativeHandler.adLoader.endLinear();
				_creativeHandler.isAdLinear = false;
			}
		}
		
		/**
		 * Returns true if the ad is linear, false otherwise. If this value is in-correct, you can change state via StartLinear and EndLinear API calls.
		 * This value is false by default, unless the ad is currently serving in a linear placement.
		 * 
		 * @see #StartLinear
		 * @see #EndLinear
		 */
		public static function get isLinear():Boolean
		{
			if(_creativeHandler != null){
				if(_creativeHandler.adLoader != null){
					return _creativeHandler.adLoader.isLinear;
				} else {
					return _creativeHandler.isAdLinear;
				}
			} else {
				return false;
			}
		}
		
		/**
		 * Retrieves the current volume from the Host Video Player.
		 * 
		 * @return The volume of the host video player, in a range from 0-100. If no data is provided, we return -1.
		 */
		public static function get playerVolume():Number
		{
			if(_creativeHandler != null){
				return _creativeHandler.adLoader.volume;
			} else {
				return -1;
			}
		}
		
		/**
		 * Sets the volume on the Host Video Player. This method is not guaranteed to work, and you should check
		 * EBInstream.PlayerVolume afterwards to see if the player accepted your volume change request.
		 */
		public static function SetPlayerVolume(num:Number):void
		{
			if(_creativeHandler != null){
				_creativeHandler.adLoader.setVolume(num);
			}
		}
		
		public static function get ReportDurationToPlayer():Boolean
		{
			if(_creativeHandler != null){
				return _creativeHandler.reportDurationToPlayer;
			}
			
			return false;
		}
		
		public static function set ReportDurationToPlayer(value:Boolean):void
		{
			if(_creativeHandler != null){
				_creativeHandler.reportDurationToPlayer = value;
			}
		}
	}
}