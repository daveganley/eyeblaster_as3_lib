package eyeblaster.instream
{
	import flash.utils.getDefinitionByName;

	/**
	 * AnimationObserver lets the ad notify the Host Video Player about certain actions its doing. This is normally used when the ad is using animations instead of videos,
	 * since most of these events are automatic for registered videos.
	 */
	public class AnimationObserver
	{
		private var _creativeHandler:*;
		private var _instreamLoader:*;
		
		private var _InstreamApiEvent:*;
		
		public function AnimationObserver(creativeHandler:*)
		{
			_creativeHandler = creativeHandler;
			_instreamLoader = _creativeHandler.adLoader;
			
			try {
				_InstreamApiEvent = getDefinitionByName("eyeblaster.instream.events.InstreamApiEvent");
			} catch (e:Error){
				// do nothing
			}
		}
		
		/**
		 * Updates the Host Video Player with the ad's play time.
		 * 
		 * @param currentTime:Number The current time, in seconds, for the ad
		 * @param totalTime:Number The total time the ad will be playing
		 */
		public function SetProgress(currentTime:Number, totalTime:Number):void
		{
			if(_instreamLoader != null){
				_instreamLoader.setProgress(currentTime, totalTime);
			}
		}
		
		/**
		 * Notifies the Host Video Player that the ad is playing
		 */
		public function Play():void
		{
			if(_InstreamApiEvent != null){
				var evt = new _InstreamApiEvent("playing");
				_creativeHandler.dispatchEvent(evt);
			}
		}
		
		/**
		 * Notifies the Host Video Player that the ad is paused
		 */
		public function Pause():void
		{
			if(_InstreamApiEvent != null){
				var evt = new _InstreamApiEvent("paused");
				_creativeHandler.dispatchEvent(evt);
			}
		}
		
		/**
		 * Notifies the Host Video Player that the ad is resuming
		 */
		public function Resume():void
		{
			if(_InstreamApiEvent != null){
				var evt = new _InstreamApiEvent("resume");
				_creativeHandler.dispatchEvent(evt);
			}
		}
		
		/**
		 * Notifies the Host Video Playre that the ad is replaying
		 */
		public function Replay():void
		{
			if(_InstreamApiEvent != null){
				var evt = new _InstreamApiEvent("replaying");
				_creativeHandler.dispatchEvent(evt);
			}
		}
		
		/**
		 * Notifies the Host Video Player that the ad is seeking
		 */
		public function Seek():void
		{
			if(_InstreamApiEvent != null){
				var evt = new _InstreamApiEvent("seek");
				_creativeHandler.dispatchEvent(evt);
			}
		}
	}
}