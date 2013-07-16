package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	import eyeblaster.videoPlayer.core.RunLoop;
	
	import eyeblaster.events.EBAudioStateEvent;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/** Base Class for all Slider controls */
	public class SliderBase extends ControlBase
	{
		[Inspectable(type=Boolean,defaultValue=true)]
		public var allowScrub:Boolean = true;
		
		protected var _slider:MovieClip;
		protected var _scrubbar:MovieClip;
		protected var _hitArea:MovieClip;
		
		protected var startX:Number;
		
		protected var isScrubbing:Boolean = false;
		
		private var stageRef:Object;
		protected var _videoInteraction:String = "invalid";
		
		/** @private */
		public function SliderBase()
		{
			this.enabled = false;
			this.buttonMode = true;
		}
		
		/** @private */
		public override function initialize():void
		{
			super.initialize();
			
			startX = _slider.x;
		
			if( _scrubbar ) _scrubbar.addEventListener( MouseEvent.MOUSE_DOWN, _onMouseDown);
			_slider.addEventListener( MouseEvent.MOUSE_DOWN, _onClick );
			///hit area click equals to the slider click
			if(_hitArea!=null)
				_hitArea.addEventListener( MouseEvent.MOUSE_DOWN, _onClick );
			// in instream environments, set mouse listeners on root instead of potentially inaccessible stage
			stageRef = EBBase.urlParams.isInStream ? EBBase._root : stage;
			
		}

		/**
		 * Called when a user presses their mouse from the scrubbar. Subclasses may override this function, but
		 * if a subclass does, it <b>MUST</b> call into the base class for proper functionality
		 * 
		 * @param event:MouseEvent The mouse event provided by Flash
		 * 
		 */
		protected function _onMouseDown( event:MouseEvent ):void
		{		
			if( allowScrub )
			{
				///update the progress volume upon mouse move while the scrubbar is dragged AND user moves the mouse upon the slider
				_scrubbar.addEventListener( MouseEvent.MOUSE_MOVE, _updateUponDrag);
				///update the progress volume upon mouse move while the scrubbar is dragged AND user moves the mouse out of the slider rollOver rect
				stageRef.addEventListener(MouseEvent.MOUSE_MOVE, _updateIfMouseMoveOutOfSlider);
				stageRef.addEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				_slider.addEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				_scrubbar.addEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				if(_hitArea!=null)
					_hitArea.addEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				
				var endDragLocation:Number = _slider.width + startX;
				
				var dragBounds:Rectangle = new Rectangle();
				dragBounds.left = startX;
				dragBounds.top = 0;
				dragBounds.right = endDragLocation;
				dragBounds.bottom = 0;
				
				_scrubbar.startDrag( true, dragBounds );
				isScrubbing = true;
			}
		}
		
		/**
		 * Called when a user drags the scrubbar. Subclasses may override this function, but
		 * if a subclass does, it <b>MUST</b> call into the base class for proper functionality
		 * 
		 * @param event:MouseEvent The mouse event provided by Flash
		 * 
		 */
		protected function _updateUponDrag( event:MouseEvent ):void
		{		
			doAction( _scrubbar.x );
		}
		
		///This function updates the progress volume upon mouse move while the scrubbar is dragged AND user moves the mouse out of the slider rollOver rect
		private function _updateIfMouseMoveOutOfSlider(event:MouseEvent):void 
		{
			//scrubbar rollOver rect
			if( mouseY < - (_scrubbar.height/2) || mouseY > _scrubbar.height/2 )
			{
				//slider rollOver rect
				if( mouseX > startX && mouseX < _slider.width + startX )
				{
					//update value
					_updateUponDrag(event);
				}
			}
		}

		/**
		 * Called when a user releases their mouse from the scrubbar. Subclasses may override this function, but
		 * if a subclass does, it <b>MUST</b> call into the base class for proper functionality
		 * 
		 * @param event:MouseEvent The mouse event provided by Flash
		 * 
		 */
		protected function _onMouseUp( event:MouseEvent ):void
		{
			if( allowScrub )
			{
				///remove all listeners
				stageRef.removeEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				_slider.removeEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				_scrubbar.removeEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				
				_scrubbar.removeEventListener(MouseEvent.MOUSE_MOVE, _updateUponDrag);
				stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, _updateIfMouseMoveOutOfSlider);
				if(_hitArea!=null)
					_hitArea.removeEventListener( MouseEvent.MOUSE_UP, _onMouseUp );
				
				_scrubbar.stopDrag();
				isScrubbing = false;
				
				doAction( _scrubbar.x );
				doTrack();
			}
		}
		
		/**
		 * Called when a user clicks on stage. Subclasses may override this function, but
		 * if a subclass does, it <b>MUST</b> call into the base class for proper functionality
		 * 
		 * @param event:MouseEvent The mouse event provided by Flash
		 * 
		 */
		protected function _onClick( event:MouseEvent ):void
		{	
			if(assignedScreen.isPlaying || assignedScreen.isPaused) 
			{
				if( isScrubbing ) return;			
				if( allowScrub )
				{
					doAction( mouseX );
					doTrack();
				}
			}
		}
		
		
		protected function doTrack():void
		{
			if(!allowScrub) return;
			
			if(_videoInteraction != null && assignedScreen != null){
				assignedScreen.track(_videoInteraction);
			}
		}
		
		/**
		 * Called when a slider subclass should perform an action. SliderBase subclasses
		 * <b>MUST</b> override this function and <b>SHOULD NOT</b> call into the base
		 * implementation
		 * 
		 * @param xPos:Number the "X" position that the action should do work based upon
		 */
		protected function doAction( xPos:Number ):void
		{
			xPos;
			trace("ERROR: doAction not subclassed!");
		}
		
	}
}