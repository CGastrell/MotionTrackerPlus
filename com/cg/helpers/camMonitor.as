package com.cg.helpers
{
	/**/
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ActivityEvent;
	import flash.media.Camera;

	public class camMonitor extends Sprite
	{
		//private var parentClass;
		private var c:Camera;
		
		private var p:Panel;
		
		public function camMonitor(cam = null) 
		{
			c = cam;
			if(!cam) throw new Error("need a cam for this");
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
			addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//parentClass = parent.parent;
			
			Style.PANEL = 0x333333;
			Style.BUTTON_FACE = 0x333333;
			Style.LABEL_TEXT = 0xF6F6F6;
			
			p = new Panel(this);
			p.width = 250;
			p.height = 230;
			p.alpha = .75;
			this.x = stage.stageWidth - p.width;
			this.y = stage.stageHeight - p.height;
			this.addEventListener(MouseEvent.MOUSE_DOWN,function(e:MouseEvent){e.currentTarget.startDrag();});
			this.addEventListener(MouseEvent.MOUSE_UP,function(e:MouseEvent){e.currentTarget.stopDrag();});
			
			var line:int = 14;
			var currentLine:int = 2;
			
			var l:Label = new Label(p,30,line * 0.25,'Camera (this box is draggable)');
			
			l = new Label(p,10,line * currentLine,'activityLevel:');
			l = new Label(p,100,line * currentLine,String(c.activityLevel));l.name = 'activityLevel';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'bandwidth:');
			l = new Label(p,100,line * currentLine,String(c.bandwidth));l.name = 'bandwidth';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'currentFPS:');
			l = new Label(p,100,line * currentLine,String(c.currentFPS));l.name = 'currentFPS';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'fps:');
			l = new Label(p,100,line * currentLine,String(c.fps));l.name = 'fps';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'height:');
			l = new Label(p,100,line * currentLine,String(c.height));l.name = 'height';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'index:');
			l = new Label(p,100,line * currentLine,String(c.index));l.name = 'index';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'keyFrameInterval:');
			l = new Label(p,100,line * currentLine,String(c.keyFrameInterval));l.name = 'keyFrameInterval';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'loopback:');
			l = new Label(p,100,line * currentLine,String(c.loopback));l.name = 'loopback';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'motionLevel:');
			l = new Label(p,100,line * currentLine,String(c.motionLevel));l.name = 'motionLevel';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'motionTimeout:');
			l = new Label(p,100,line * currentLine,String(c.motionTimeout));l.name = 'motionTimeout';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'muted:');
			l = new Label(p,100,line * currentLine,String(c.muted));l.name = 'muted';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'name:');
			l = new Label(p,100,line * currentLine,String(c.name));l.name = 'name';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'quality:');
			l = new Label(p,100,line * currentLine,String(c.quality));l.name = 'quality';
			
			currentLine++;
			l = new Label(p,10,line * currentLine,'width:');
			l = new Label(p,100,line * currentLine,String(c.width));l.name = 'width';
			
			addEventListener(Event.ENTER_FRAME,updateOnFrame);
			//if this isn't set, the activityLevel does not update
			c.addEventListener(ActivityEvent.ACTIVITY,activityHandler);
		}
		
		//public function set f(i:int){Label(p.getChildByName('otroCounter')).text = 'Lap in: ' + String(i);}
		
		private function destroy(e:Event = null):void
		{
			removeEventListener(Event.ENTER_FRAME,updateOnFrame);
		}
		
		private function updateOnFrame(e:Event = null):void
		{
			setValue('activityLevel',c.activityLevel);
			setValue('bandwidth',c.bandwidth);
			setValue('currentFPS',c.currentFPS);
		}
		
		private function setValue(propertyName:String,getValue:*)
		{
			Label(p.getChildByName(propertyName)).text = String(getValue);
		}
		
		private function activityHandler(e:ActivityEvent)
		{
			//trace(e);
		}
	}
	
}