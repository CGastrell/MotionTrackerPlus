package  
{
	/**/
	import com.bit101.components.CheckBox;
	import com.bit101.components.PushButton;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	import com.bit101.components.HSlider;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	//import flash.display.MovieClip;

	/**
	 * ...
	 * @author Eugene Zatepyakin
	 */
	public class Controls extends Sprite
	{
		private var parentClass;
		private var _timer : uint;
		private var _fps : uint;
		private var _ms : uint;
		private var _ms_prev : uint;
		private var activeControls:Boolean = false;
		
		private var p:Panel;
		
		public function Controls() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//this might not work fine for everyone... check
			parentClass = parent.parent;
			
			Style.PANEL = 0x333333;
			Style.BUTTON_FACE = 0x333333;
			Style.LABEL_TEXT = 0xF6F6F6;
			
			p = new Panel(this);
			p.width = 1280;
			p.height = 40;
			p.alpha = 0.75;
			
			var lb:Label = new Label(p, 10, 5);
			lb.name = 'fps_txt';
			lb = new Label(p,10,20);
			lb.name = 'ms_txt';
			
			//lb = new Label(this, 40, 5, 'CLICK TO SWITCH BETWEEN RENDER MODES');
			//lb.x = 10;
			//lb.y = Main.sh + 15;
			
			var ns:NumericStepper = new NumericStepper(p, 90, 2, onBlurChange);
			ns.value = parentClass._motionTracker.blur;
			ns.max = 25; ns.min = 0;
			ns.labelPrecision = 0;
			lb = new Label(p,ns.x + 82,ns.y,'Blur');
			//ns.width = 180;
			
			ns = new NumericStepper(p, 90, 20, onMinareaChange);
			ns.value = parentClass._motionTracker.minArea;
			ns.max = 40; ns.min = 2;
			ns.labelPrecision = 0;
			lb = new Label(p,ns.x + 82,ns.y,'Min Area');
			
			ns = new NumericStepper(p, 235, 2, onContrastChange);
			ns.value = parentClass._motionTracker.contrast;
			ns.max = 200; ns.min = 0;
			ns.labelPrecision = 0;
			lb = new Label(p,ns.x + 82,ns.y,'Contrast');
			
			ns = new NumericStepper(p, 235, 20, onBrightnessChange);
			ns.value = parentClass._motionTracker.brightness;
			ns.max = 51; ns.min = -50;
			ns.labelPrecision = 0;
			lb = new Label(p,ns.x + 82,ns.y,'Bright.');
			
			var chk:CheckBox;
			chk = new CheckBox(p, 380, 22, 'FREEZE BG', onFreezeChange);
			chk.selected = parentClass._motionTracker.freezeBackground;
			chk.name = 'freeze';
			
			chk = new CheckBox(p, 455, 9, 'SCALE', onScaleChange);
			chk.name = 'scale';
			chk = new CheckBox(p, 455, 22, 'OUTPUT', onOutputChange);
			chk.selected = true;
			chk.name = 'output';
			
			chk = new CheckBox(p, 510, 9, 'ON/OFF', onOnoffChange);
			chk.name = 'onoff';
			//chk.selected = parentClass._motionTracker.active;
			chk.selected = parentClass.detect;
			chk = new CheckBox(p, 510, 22, 'H. INV.', onHinvChange);
			chk.name = 'hinv';
			chk.selected = parentClass._motionTracker.flipInput;
			
			var pb:PushButton = new PushButton(p,595,2,'Next',onNext);
			pb.height = 15;
			pb.width = 50;
			pb = new PushButton(p,595,20,'Hide',onHide);
			pb.height = 15;
			pb.width = 50;
			
			
			ns = new NumericStepper(p, 660, 2, onTimerChange);
			ns.value = parentClass.detectionInterval;
			ns.max = 500; ns.min = 20;
			ns.step = 10;
			ns.labelPrecision = 0;
			lb = new Label(p,ns.x + 82,ns.y,'DetectionTimer(ms)');
			lb = new Label(p,660,20,'000');
			lb.name = 'mtProcessingTime';
			
			var sl = new HSlider(p,840,5,onMAAIChange);
			sl.tick = 10;
			sl.maximum = 2500;
			sl.minimum = 500;
			lb = new Label(p,sl.x + sl.width,sl.y-5,'Flee Speed');
			lb.name = "maai";
			sl.value = parentClass.retraction;
			
			sl = new HSlider(p,840,20,onMAIChange);
			sl.tick = 5;
			sl.maximum = 600;
			sl.minimum = 10;
			lb = new Label(p,sl.x + sl.width,sl.y-5,'Return delay');
			lb.name = "mai";
			sl.value = parentClass.attraction;
			
			ns = new NumericStepper(p,1050,2,onItemsChange);
			ns.step = 1;
			ns.labelPrecision = 0;
			ns.max = 40;
			ns.min = 0;
			lb = new Label(p,ns.x + 82,ns.y,'Floating Items');
			lb.name = "items";
			ns.value = parentClass.maxItems;
			
			activeControls = true;
			addEventListener(Event.ENTER_FRAME, countFrameTime);
		}
		
		//public function set f(i:int){Label(p.getChildByName('otroCounter')).text = 'Lap in: ' + String(i);}
		
		private function destroy(e:Event = null):void
		{
			removeEventListener(Event.ENTER_FRAME,countFrameTime);
		}
		private function onItemsChange(e:Event):void
		{
			if(!activeControls) return;
			parentClass.maxItems = e.currentTarget.value;
			Label(p.getChildByName('items')).text = "Floating Items: " + e.currentTarget.value;
		}
		private function onMAAIChange(e:Event):void
		{
			parentClass.retraction = e.currentTarget.value;
			Label(p.getChildByName('maai')).text = "Flee Speed: " + e.currentTarget.value;
		}
		private function onMAIChange(e:Event):void
		{
			parentClass.attraction = e.currentTarget.value;
			Label(p.getChildByName('mai')).text = "Return delay: " + e.currentTarget.value;
		}
		
		private function onNext(e:Event):void
		{
			//parentClass._motionTracker.scaleIndex = 0.25;
		}
		private function onHide(e:Event = null):void
		{
			//destroy();
			parentClass.setProductionState();
		}
		
		private function onBlurChange(e:Event):void
		{
			parentClass._motionTracker.blur = e.currentTarget.value;
		}
		
		private function onBrightnessChange(e:Event):void
		{
			parentClass._motionTracker.brightness = e.currentTarget.value;
		}
		
		private function onContrastChange(e:Event):void
		{
			parentClass._motionTracker.contrast = e.currentTarget.value;
		}
		
		private function onMinareaChange(e:Event):void
		{
			parentClass._motionTracker.minArea = e.currentTarget.value;
		}
		
		private function onOnoffChange(e:Event):void
		{
			parentClass.detect = e.currentTarget.selected;
		}
		
		private function onHinvChange(e:Event):void
		{
			parentClass.flipInput = e.currentTarget.selected;
		}
		
		private function onOutputChange(e:Event):void
		{
			parentClass.hideOutput(e.currentTarget.selected);
		}
		
		private function onScaleChange(e:Event):void
		{
			parentClass.scaleIt(e.currentTarget.selected);
		}
		
		private function onFreezeChange(e:Event):void
		{
			parentClass._motionTracker.freezeBackground = e.currentTarget.selected;
		}
		private function onTimerChange(e:Event):void
		{
			parentClass.detectionInterval = e.currentTarget.value;
		}
		
		private function countFrameTime(e:Event = null):void
		{
			_timer = getTimer();
			if( _timer - 1000 >= _ms_prev )
			{
				_ms_prev = _timer;
				
				Label(p.getChildByName('fps_txt')).text = 'FPS: ' + _fps + ' / ' + stage.frameRate;
				
				_fps = 0;
			}
			
			_fps ++;
			Label(p.getChildByName('ms_txt')).text = 'MS/Frame: ' + (_timer - _ms);
			_ms = _timer;
			
			Label(p.getChildByName('mtProcessingTime')).text = "MotionTracker (ms): "+parentClass._motionTracker.workingTime;
		}
	}
	
}