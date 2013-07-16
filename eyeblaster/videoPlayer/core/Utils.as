package eyeblaster.videoPlayer.core {
    
    
    import flash.display.DisplayObject;
    
    public class Utils{
        
        /**
        * Specifies that the entire target be visible in the container 
        * without trying to preserve the original aspect ratio.
        */
        public static const EXACT_FIT:String = "EXACT_FIT";
        
        /**
        * Specifies that the target fill the entire container,
        * without distortion but possibly with some cropping,
        * while maintaining the original aspect ratio of the container.
        */
        public static const NO_BORDER:String = "NO_BORDER";
        
        /**
        * Specifies that the size of the target be fixed,
        * so that it remains unchanged regardless of the size of the container.
        */
        public static const NO_SCALE:String = "NO_SCALE";
        
        /**
        * Specifies that the entire target be visible in the container
        * without distortion while maintaining the original aspect ratio of the target.
        */
        public static const SHOW_ALL:String = "SHOW_ALL";
        
        /**
        * Specifies that the container dimensions be set to that of the target.
        * You should generally only use this with 'flat' objects - the target should not
        * Be a child of the container.
        */
        public static const AUTO:String = "auto";
        
        /**
        * Sets the dimensions of a display object with respect to another display object
        * according to a specifed scale mode.
        * This function does not deal with creating masks for the target and/or container,
        * it only sets the dimensions of them. You will probably want to set your own mask
        * to the size of the container when using NO_BORDER and NO_SCALE.
        * 
        * @param _scaleMode The scale mode to use. Should be one of the ScaleMode class constants.
        * @param _target The display object to scale.
        * @param _paddingH The amount of horizontal padding to apply to BOTH sides of the target.
        * @param _paddingV The amount of vertical padding to apply to BOTH sides of the target.
        * @param _container The display object to scale with respect to.
        * If this is passed, the _target and _container are treated as
        * 'flat' objects - any hierarchy in the display list will be ignored.
        * If _target is a child of _container,
        * you should omit the _container parameter.
        * If this is omitted, the target's parent will be used.
        * If the target doesn't have a parent, then an Error will be thrown.
        */
        public static function scaleToContainer(_scaleMode:String,
                                             _target:DisplayObject,_toStage:Boolean = false,
                                             _paddingH:Number=0,
                                             _paddingV:Number=0,
                                             _container:DisplayObject=null):void{
            var w:Number, h:Number;
            if (_toStage && EBBase._stage !=null) {
				w = EBBase._stage.stageWidth;
                h = EBBase._stage.stageHeight;
			}
			else if(_container){
                w = _container.width;
                h = _container.height;
            }else if(_target.parent){
                w = _target.parent.width;
                h = _target.parent.height;
            }else{
              return ;			  
            }
			
            var ratio:Number, r1:Number, r2:Number;
            switch(_scaleMode){
                case AUTO:
                    if(_container){
                        _container.width = _target.width + _paddingH * 2;
                        _container.height = _target.height + _paddingV * 2;
                    }else if(_target.parent){
                        _target.parent.width = _target.width + _paddingH * 2;
                        _target.parent.height = _target.height + _paddingV * 2;
                    }
                    break;
                case EXACT_FIT:
                    _target.width = w - _paddingH * 2;
                    _target.height = h - _paddingV * 2;
                    break;
                case NO_BORDER:
                    r1 = w / _target.width;
                    r2 = h / _target.height;
                    if(r1 > r2){
                        //fill whole width, crop height
                        ratio = _target.height / _target.width;
                        _target.width = w - _paddingH * 2;
                        _target.height = w * ratio - _paddingV * 2;
                    }else{
                        //fill whole height, crop width
                        ratio = _target.width / _target.height;
                        _target.height = h - _paddingH * 2;
                        _target.width = h * ratio - _paddingV * 2;
                    }
                    break;
                case NO_SCALE:
                    //do nothing					
                    break;
                default: // defaults to ScaleMode.SHOW_ALL
                    r1 = w / _target.width;
                    r2 = h / _target.height;
                    if(r1 > r2){
                        //fill whole height, scale width
                        ratio = _target.width / _target.height;
                        _target.height = h - _paddingH * 2;
                        _target.width = h * ratio - _paddingV * 2;
                    }else{
                        //fill whole width, scale height
                        ratio = _target.height / _target.width;
                        _target.width = w - _paddingH * 2;
                        _target.height = w * ratio - _paddingV * 2;
                    }
            }
        }
		
		

    }
}