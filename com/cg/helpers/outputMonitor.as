package com.cg.helpers
{
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import com.greensock.TweenMax;
	
	public class outputMonitor extends Sprite
	{
		private var b:Bitmap;
		private var s:Sprite;
		private var d:int = 11;
		private var scaleIndex:Number;
		
		public function outputMonitor(bitmap:Bitmap,s:Number)
		{
			b = bitmap;
			scaleIndex = s;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,init);
			addChild(b);
			b.blendMode = "add";
			Style.LABEL_TEXT = 0xFFFFFF;
			s = new Sprite();
			s.addEventListener(MouseEvent.CLICK,onScale);
			s.graphics.beginFill(0xFF0000,0.25);
			s.graphics.lineStyle(1,0xFF0000,1);
			s.graphics.drawRect(0,0,d,d);
			s.graphics.endFill();
			s.graphics.moveTo(d * 2,d);
			s.graphics.lineTo(-25,d);
			s.graphics.moveTo(d,d * 2);
			s.graphics.lineTo(d,-25);
			this.addChild(s);
			s.x = b.width - d;
			s.y = b.height - d;
			var pb = new Label(s,0,-4,'<>');
		}
		
		private function onScale(e:MouseEvent):void
		{
			var scale:Number = scaleIndex / b.scaleX;
			
			TweenMax.to(s,0.5,{x:b.width / b.scaleX * scale - d,y:b.height / b.scaleY * scale - d});
			TweenMax.to(b,0.5,{scaleX:scale,scaleY:scale});
			//trace(scale,b.width * scale - d);
		}
	}
}