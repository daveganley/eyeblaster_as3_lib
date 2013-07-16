package eyeblaster.videoPlayer.core
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBNotificationEvent;
	
	import flash.events.Event;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	/** @private */
	public class RunLoop
	{
		private var functions:Array;
		
		private static var runloop:RunLoop = null;
		private var interval:uint;
		
		/** @private */
		public function RunLoop()
		{
			functions = new Array();
			interval = setInterval( run, 100 );
			EBBase.addEventListener(EBNotificationEvent.NOTIFICATION,OnNotification);
		}
		
		private function run():void
		{			
			for( var i:int = 0; i < functions.length; i++)
			{
				var func:Function = functions[i];
				func();
			}
			
		}
		
		public static function addFunction( funcref:Function ):void
		{
			if(runloop == null){
				runloop = new RunLoop();
			}
			
			runloop.functions.push( funcref );
		}
		
		private function OnNotification( event:EBNotificationEvent ):void
		{
			if(event.subtype == EBNotificationEvent.CLOSE){
				clearInterval(interval);
				runloop = null;
			}
		}
	}
}