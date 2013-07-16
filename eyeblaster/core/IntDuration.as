//****************************************************************************
//      eyeblaster.core.IntDuration class
//---------------------------------------
//
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.core
{
	
	import eyeblaster.core.Tracer;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.*;
	
	/**
	 * This class handles measuring the time of the interaction duration
	 */
	public class IntDuration
	{
		private var _startMouse:Number;
		private var _startInteractionTime:Number;
		private var _stopFlag:Boolean;
		private var _pauseFlag:Boolean;
		private var _pauseTime:Number;
		private var _pauseLimit:Number;
		private var _totalTime:Number;
		private var _stage:DisplayObject;
		
		/**
		 * Constructor.
		 * @param	objRef
		 */
		public function IntDuration(objRef:DisplayObjectContainer)
		{
			init(objRef);
		}
		
		/**
		 * Inititalizes class attributes.
		 *
		 * @param	objRef
		 */
		private function init(objRef:DisplayObjectContainer):void
		{
			_stage = objRef;
			_startMouse = _stage.mouseX;
			_startInteractionTime = getTimer();
			_stopFlag = true;
			_pauseFlag = true;
			_pauseTime = getTimer();
			_pauseLimit = 2000;
			_totalTime = 0;
			Tracer.debugTrace("Starting measure interaction duration", -2);
			//calculate the interaction duration
			setInterval(testMouse, 167);
		}
		
		/**
		 * Detects whether there is mouse movement over the asset. If there is no movement it calculates the time the mouse moved till now.
		 */
		private function testMouse():void
		{
			if (_stage.mouseX == _startMouse) // stopped
			{
				if (!_stopFlag)
				{
					_pauseTime = getTimer();
					if (!_pauseFlag)
					{
						_pauseFlag = true;
						if ((_pauseTime - _startInteractionTime) > 0)
						{
							EBBase.handleCommand("ebUpdateTimer", "\"ebintduration\"," + (_pauseTime - _startInteractionTime));
						}
						_startInteractionTime = _pauseTime;
					}
					_stopFlag = (_pauseTime - _startInteractionTime) > _pauseLimit;
				}
			}
			else
			{
				if (_stopFlag)
					_startInteractionTime = getTimer();
				
				_stopFlag = false;
				_pauseFlag = false;
				_startMouse = _stage.mouseX;
			}
		
		}
	}
}
