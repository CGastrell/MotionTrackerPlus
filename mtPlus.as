package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.media.Camera;
	import flash.media.Video;
	
	import flash.events.*;
	import flash.net.URLLoader;

	import flash.utils.Timer;
	import flash.system.Security;
	
	import uk.co.soulwire.math.Random;
	
	import com.greensock.TweenMax;
	import com.greensock.easing.*;
	
	import flash.ui.Mouse;
	
	import com.cg.media.MotionTrackerPlus;
	import com.cg.geom.TempRectangle;
	import com.cg.helpers.outputMonitor;
	import com.cg.helpers.camMonitor;
	import com.cg.helpers.sourceMonitor;

	public class mtPlus extends MovieClip
	{
		//a note about SCALA constant:
		//SCALA represents the scaleX/Y the VIDEO feeding the MotionTracker
		//will need to fit the stage. Why? not sure. I mean, not every cam
		//will be able to throw video at the resolution we need, so,
		//no worries, capture camera at the resolution you can/want
		//and then, through SCALA, it will fit all your stage.
		//In this case i capture cam = stage / SCALA, but think on a scenario
		//where you just have some cheap webcam (not the most recomended)
		//and you need to fill a HD screen... get it?
		//Speed IS a factor here, so if your webcam captures fine 30fps@320x240
		//you SHOULD use it at THAT resolution and then scale all the detection
		//beware: motionTracker has it's own scala for same reason with other uses, do not mix
		private static const SCALA:					Number = 2;
		//ZERO_POINT is somehow a bad/good habit: create once, use as many as i need
		private static const ZERO_POINT:			Point = new Point(0,0);
		private var MAAI:							int = 2100;
		private var MAI:							int = 20;
		
		//this is public so i can access it from Controls.parent._motionTracker
		public var _motionTracker:					MotionTrackerPlus;
		private var _output:						Sprite;
		
		private var config:							XML;
		
		private var detecting:						Boolean = true;
		private var productionState:				Boolean = false;
		
		private var vid:							Video;
		private var isInverted:						Boolean = false;
		private var baseContainer:					Sprite;
		private var controlsContainer:				Sprite;
		private var funcInn:						Function = null;
		private var funcOut:						Function = null;
		private var from:							Point = new Point();
		private var to:								Point = new Point();
		private var cam:							Camera;
		private var floatingItems:					int;
		
		private var Items:							Array = new Array();
		//had to call all the Vectors like these because of a conflict with another lib :(
		private var detectedBlobs:__AS3__.vec.Vector.<TempRectangle> = new __AS3__.vec.Vector.<TempRectangle>;

		public function mtPlus()
		{
			//this should usually be the place were onAddedToStage and init bla bla
			//but it's complicated as it is, so i'll leave it plain for now
			
			//this will fire upon camera activation
			//it's the final event fire which leads to init()
			var onCamera = function(e:Event = null):void
			{
				trace("camera status change");
				cam.removeEventListener(StatusEvent.STATUS,onCamera);
				//give the app some time to skip the first frames from the camera, almost always noisy
				var theTimer:Timer = new Timer(1000,1);
				theTimer.addEventListener(TimerEvent.TIMER_COMPLETE,init);
				theTimer.start();
			}
			//this will fire upon xml(config) load
			var onConfigLoaded = function(e:Event)
			{
				trace("config loaded");
				//ok, i know this is useless here, loading the config from external file
				//is really a pain. When i started this i wanted to do some demo
				//which could be adjusted to really test without having to compile all over again
				//... i know... useless here xD
				config = new XML(e.target.data);
				e.currentTarget.removeEventListener(Event.COMPLETE,onConfigLoaded);
				
				//set values from config, casting from string!!!
				//MAAI, initial speed/force 
				MAAI = int(config.avoiderSettings.MAAI);
				//MAI, return delay
				MAI = int(config.avoiderSettings.MAI);
				productionState = Boolean(int(config.productionState));
				isInverted = Boolean(int(config.horizontalCameraInvert));
				floatingItems = int(config.floatingItems);
				
				trace("init MotionTracker");
				//this could come from config too...
				var camW:int = stage.stageWidth / SCALA << 0;
				var camH:int = stage.stageHeight / SCALA << 0;
				trace(camW,camH);
				
				//get cammera and except
				cam = Camera.getCamera();
				if(!cam) {throw new Error("No camera");return;}
				
				cam.setMode( camW, camH, 30.00, false );
				cam.setQuality(16384,0);
				cam.addEventListener(StatusEvent.STATUS,onCamera);
				//i've been testing with this configs to no avail
				cam.setKeyFrameInterval(15);
				cam.setLoopback(false);
				//get vid to attach camera, then send to MT
				vid = new Video( camW, camH );
				vid.attachCamera( cam );
				// Create the Motion Tracker with vid
				_motionTracker = new MotionTrackerPlus( vid );
				//set MTPlus options
				//returnBlobs true for multipoint, single point otherwise
				_motionTracker.returnBlobs = Boolean(int(config.multiPointDetection));
				//interval, in ms. Don't really need this on enterFrame
				//test for best performance -> edit in MTplus
				_motionTracker.interval = int(config.motionTrackerInterval);
				_motionTracker.brightness = int(config.imageConfig.brightness);
				_motionTracker.contrast = int(config.imageConfig.contrast);
				_motionTracker.blur = int(config.imageConfig.blur);
				_motionTracker.minArea = int(config.imageConfig.minArea);
				//scaleIndex... well, i came up to this idea by realizing the MT took a LOT of
				//time for each frame, so, give it a scale index and the MatrixScale is done
				//(i think) much faster, then process the scaled image
				_motionTracker.scaleIndex = Number(config.motionTrackerScaleIndex);
				
				//this setter handles both the app and the MTPlus instance "flipInput" option
				//flipInput is a SETTER, not a var
				flipInput = isInverted;
				//IMPORTANT: if camera is allowed and remembered, not always will it
				//dispatch the event, so, dispatch it manually
				if(!cam.muted) cam.dispatchEvent(new Event(StatusEvent.STATUS));
			}
			
			//messy, but the only way to make path work for both online and local filesystem
			var urlString:String = "";
			var pathArray = loaderInfo.loaderURL.split("/");
			for(var pathPart:int = 0;pathPart < pathArray.length - 1;pathPart++)
			{
				urlString += pathArray[pathPart] + "/";
			}
			//trace(urlString);
			
			//weak var, onLoaded will set the xml to the global var
			var coco = new URLLoader();
			coco.load(new flash.net.URLRequest(urlString+"mtConfig.xml"));
			coco.addEventListener(Event.COMPLETE,onConfigLoaded);
		}
		
		private function init(e:Event)
		{
			trace("init app");
			//baseContainer... forget about stage, EVERYTHING in the app should be here
			//why? well, as soon as we finish al the gizmos and behaviours, they will all be here
			//right behind the controlsContainer (so, as they should, the controls are always visible)
			//scaling the baseContainer scales all its content, is this bad? video is processed
			//half the size, but the scaleX/Y is done just by stretching...
			baseContainer = new Sprite();
			addChild(baseContainer);
			
			controlsContainer = new Sprite();
			addChild(controlsContainer);
			
			//for this demos this is here, vid could not be seen at all and motionTracker should work fine
			baseContainer.addChild(vid);
			
			//productionState is a switch: if true there are no controls nor previews, can be changed later
			if(!productionState)
			{
				//the motionTracker image output
				_output = new outputMonitor(new Bitmap(_motionTracker.trackingImage),1 / _motionTracker.scaleIndex);
				//should put this on controlsContainer, but then the scale wouldn't affect it
				//place on base container and the remove when necesary
				baseContainer.addChild(_output);
				
				//dammit justin! i was so proud of my minimal comps control xD
				controlsContainer.addChild(new Controls());
				//completely optional, just to see how cam goes
				controlsContainer.addChild(new camMonitor(cam));
				//a preview of the image the MT is using (after applying col matrix)
				controlsContainer.addChild(new sourceMonitor(new Bitmap(_motionTracker.sourceImage)));
			}else{
				Mouse.hide();
			}
			
			//fire some function that will set any stupid thing we want it to do
			tester();
		}
		
		private function tester()
		{
			//for drawing the "blobs"
			var blobsContainer:Sprite = new Sprite();
			//for interactive objects
			var itemsContainer:Sprite = new Sprite();
			itemsContainer.name = "theItemsContainer";
			
			baseContainer.addChild(itemsContainer);
			baseContainer.addChild(blobsContainer);
			
			//let's clear this out of the way...
			baseContainer.mouseEnabled = false;
			itemsContainer.mouseEnabled = false;
			itemsContainer.mouseChildren = false;
			blobsContainer.mouseEnabled = false;
			blobsContainer.mouseChildren = false;
			
			var item;
			for(var i:int = 0;i < floatingItems;i++)
			{
				item = createBall();
				Items.push(item);
				itemsContainer.addChild(item);
				item.cacheAsBitmap = true;
			}
			//function to run on enter_frame
			funcInn = function(e:Event)
			{
				detectedBlobs = _motionTracker.blobs;
				//checkItemsIn(itemsContainer);
				checkItems();
				if(!productionState) drawBlobs(blobsContainer);
			}
			//a function tu run and clean the stage when going productionState
			funcOut = function()
			{
				blobsContainer.graphics.clear();
				baseContainer.removeChild(blobsContainer);
			}
			addEventListener(Event.ENTER_FRAME,funcInn);
		}
		/*
		Just a test object: a ball, filled with 0.5 alpha, 2px border
		return MovieClip
		*/
		function createBall():MovieClip
		{
			var b:MovieClip = new MovieClip();
			b.graphics.lineStyle(2,0xFF0000);
			b.graphics.beginFill(0xFF0000,0.5);
			b.graphics.drawCircle(0,0,25);
			b.graphics.endFill();
			/*
			var b = new ball();
			b.gotoAndStop(1);//just in case
			b.scaleX = b.scaleY = .4;
			*/
			b.dimmer = 0.05;
			b.returnDelay = MAI * Random.float(0.8,1.2);
			b.fleeSpeed = MAAI * Random.float(0.8,1.2);
			b.mouseEnabled = false;
			b.mouseChildren = false;
			//50 is just a safe frame...
			b.x = Random.integer(50,stage.stageWidth / SCALA - 50);
			b.y = Random.integer(50,stage.stageHeight / SCALA - 50);
			b.originalPosition = new Point(b.x,b.y);
			b.currentPosition = new Point(b.x,b.y);
			b.influence = new Point();
			b.influenceForce = 0;
			//b.center = new Point();
			//b.lastCenter = new Point();
			return b;
		}
		
		function hasActivity(rect:Rectangle):Boolean
		{
			//var r:Rectangle = new Rectangle(area.x / SCALA, area.y / SCALA, area.width / SCALA, area.height / SCALA);
			var r:Rectangle = rect;
			r.x *= _motionTracker.scaleIndex;
			r.y *= _motionTracker.scaleIndex;
			r.width *= _motionTracker.scaleIndex;
			r.height *= _motionTracker.scaleIndex;
			var puzzlePiece:BitmapData = new BitmapData(r.width, r.height,false,0);
			puzzlePiece.copyPixels(_motionTracker.trackingImage,r,ZERO_POINT);
			var rColor:Rectangle = puzzlePiece.getColorBoundsRect(0xFFFFFF,0xFFFFFF);
			puzzlePiece.dispose();
			if(rColor.width > 0)
			{
				return true;
			}else{
				return false;
			}
		}
		
		private function checkItems():void
		{
			var index:int = 0;
			var runFrom:TempRectangle;
			var es:int;
			var numBlobs:int = detectedBlobs.length;
			var numItems:int = Items.length;
			//set a startup distance to compare to
			var newDistance:Number = 10000;
			var distance:Number;
			var currentBlob:TempRectangle;
			var dx:Number,dy:Number,ix:Number,iy:Number,force:Number;
			
			/*
			This is the position update for the floating objects. It is a strange
			equation, but couldn't find time to make one better, yet.
			A problem occurs here: when flashplayer gets a lot of calculations (like here)
			he will sacrifice camera fps. To check this: run the movie and keep an eye
			on movie fps, motiontracker process time, and cam fps
			So, when this while turns a bit heavy the cam fps drops to 5 (yikes!)
			and the whole motion detection process becomes sloppy (you'll notice
			the detection can't keep up with your movements... 5fps cam)
			Another heavy impact is graphics: click on SCALE to stretch the video
			to full stage. My guess is this wouldn't happen with GPU support (again, cam drops to 5-7 fps)
			Why flashplayer does this is still a mystery to me.
			*/
			while(index < numItems)
			{
				var thisItem = Items[index];
				es = 0;
				distance = 10000;
				from.x = thisItem.x;
				from.y = thisItem.y;
				runFrom = null;
				while(es < numBlobs)
				{
					currentBlob = detectedBlobs[es];
					to.x = currentBlob.center.x;
					to.y = currentBlob.center.y;
					if(currentBlob.lifeSpan)
					{
						/* determine the nearest blob */
						//this could be avoided with just hitTestObject...
						//but i keep hope i will be able to use distance
						//proportional to the force the item is pushed
						//normalization will be required for that, i think...
						//note: rectangles don't have hitTest, ... intersect?
						newDistance = Point.distance(from,to);
						if(newDistance < distance)
						{
							distance = newDistance;
							runFrom = currentBlob;
						}
					}
					es++;
				}
				//at this point we should have (if any) the closest blob to
				//the item, check if the blob is big enough to influence
				//the item and make calculations
				if(runFrom != null && distance < runFrom.width)
				{
					thisItem.influence.x = runFrom.lastCenter.x;
					thisItem.influence.y = runFrom.lastCenter.y;
					thisItem.influenceForce = 1;
				}
				thisItem.currentPosition.x = thisItem.x;
				thisItem.currentPosition.y = thisItem.y;
				
				//deltas
				dx = thisItem.originalPosition.x - thisItem.x;
				dy = thisItem.originalPosition.y - thisItem.y;
				
				ix = thisItem.influence.x - thisItem.x;
				iy = thisItem.influence.y - thisItem.y;
				force = 0;
				
				//measure the distance from last known influence to thisItem
				//this will runout fast, 20 frames to be precise (look at -= 0.05 below)
				if(thisItem.influenceForce > 0)
				{
					distance = Point.distance(thisItem.influence,thisItem.currentPosition);
					
					force = thisItem.fleeSpeed / (distance * distance) * thisItem.influenceForce;
					
					thisItem.influenceForce -= 0.05;
				}

				thisItem.x = (thisItem.x - ix * force) + dx / thisItem.returnDelay;
				thisItem.y = (thisItem.y - iy * force) + dy / thisItem.returnDelay;
								
				index++;
			}
		}
		
		//this function will check for blobs interacting with objects
		//on Items array. In this method i iterate through getChildAt
		//in a given sprite (itemsContainer), the array version is
		//just above, tests seem to point the array version is faster.
		function checkItemsIn(c:Sprite):void
		{
			var index:int = 0;
			var runFrom:TempRectangle;
			var es:int;
			var numBlobs:int = detectedBlobs.length;
			//set a startup distance to compare to
			var newDistance:Number = 10000;
			var distance:Number;
			var currentBlob:TempRectangle;
			var dx:Number,dy:Number,ix:Number,iy:Number,force:Number;
			
			//ok, i think the problem is here (not to say in Adobe)
			//is it really that much to ask from flashplayer? they aren't that much iterations
			//so, the updated position works fine, even more than 30fps
			//the problem is, when saturated with calculations, the flashplayer
			//sacrifices camera fps...? i can't understand it any other way.
			//run and check for app fps, motionTracker process time and camera fps.
			//When too many balls (7 or 8) are moving camera fps drops down to 5!!!
			//EDIT: 2 balls moving is enough to bring the cam fps down :(
			//and so, the motionTracker just tracks what it can... at 5fps :/
			// ... maybe processing in different apps, one for camera and motionTracker
			// ... another app receiving the blobs, kinda cccv... this is getting pointless :(
			while(index < c.numChildren)
			{
				var thisItem = c.getChildAt(index);
				es = 0;
				distance = 10000;
				from.x = thisItem.x;
				from.y = thisItem.y;
				runFrom = null;
				while(es < numBlobs)
				{
					currentBlob = detectedBlobs[es];
					to.x = currentBlob.center.x;
					to.y = currentBlob.center.y;
					if(currentBlob.lifeSpan)
					{
						/* determine the nearest blob */
						//this could be avoided with just hitTestObject...
						//but i keep hope i will be able to use distance
						//proportional to the force the item is pushed
						//normalization will be required for that, i think...
						//tested: Rectangle doesn't have hitTest, and MovieClip.hitTestObject
						//needs a DO as arg (Rectangle != DisplayObject)
						newDistance = Point.distance(from,to);
						if(newDistance < distance)
						{
							distance = newDistance;
							runFrom = currentBlob;
						}
					}
					es++;
				}
				//at this point we should have (if any) the closest blob to
				//the item, check if the blob is big enough to influence
				//the item and make calculations
				if(runFrom != null && distance < runFrom.width)
				{
					thisItem.influence.x = runFrom.lastCenter.x;
					thisItem.influence.y = runFrom.lastCenter.y;
					thisItem.influenceForce = 1;
				}
				thisItem.currentPosition.x = thisItem.x;
				thisItem.currentPosition.y = thisItem.y;
				
				//deltas
				dx = thisItem.originalPosition.x - thisItem.x;
				dy = thisItem.originalPosition.y - thisItem.y;
				
				ix = thisItem.influence.x - thisItem.x;
				iy = thisItem.influence.y - thisItem.y;
				force = 0;
				
				//measure the distance from last known influence to thisItem
				//this will runout fast, 20 frames to be precise (look at -= 0.05 below)
				if(thisItem.influenceForce > 0)
				{
					distance = Point.distance(thisItem.influence,thisItem.currentPosition);
					
					force = thisItem.fleeSpeed / (distance * distance) * thisItem.influenceForce;
				}

				thisItem.x = (thisItem.x - ix * force) + dx / thisItem.returnDelay;
				thisItem.y = (thisItem.y - iy * force) + dy / thisItem.returnDelay;
				
				thisItem.influenceForce -= 0.05;
				if(thisItem.influenceForce <= 0.05) thisItem.influenceForce = 0;
				
				index++;
			}
		}
		function drawBlobs(addTo:Sprite):void
		{
			//return;
			var b:int = 0;
			var color = 0x000000;
			var s:Sprite = addTo;
			s.graphics.clear();
			var numBlobs:int = detectedBlobs.length;
			while(b < numBlobs)
			{
				color = 0x000000;
				
				if(detectedBlobs[b].lifeSpan) color = 0xFF0000;
				s.graphics.lineStyle(2,color);
				s.graphics.drawCircle(detectedBlobs[b].center.x,
								detectedBlobs[b].center.y,
								detectedBlobs[b].width * 0.5);
				if(detectedBlobs[b].lifeSpan)
				{
					s.graphics.moveTo(detectedBlobs[b].lastCenter.x,detectedBlobs[b].lastCenter.y);
					s.graphics.lineTo(detectedBlobs[b].center.x,detectedBlobs[b].center.y);
					s.graphics.drawCircle(detectedBlobs[b].center.x, detectedBlobs[b].center.y,5);
				}
				b++;
			}
			/* this kills the app... weird, just lines ...
			solved? the first line "return" is supposed to bypass, but kills the app instead, weird again */
			b = 0;
			while(b < Items.length)
			{
				color = 0x00FF00;
				s.graphics.lineStyle(2,color);
				s.graphics.moveTo(Items[b].originalPosition.x,Items[b].originalPosition.y);
				s.graphics.lineTo(Items[b].x,Items[b].y);
				b++;
			}
			/**/
		}
		
		function updateBodies()
		{
			for(var i:int = 0;i < Items.length;i++)
			{
				Items[i].fleeSpeed = MAAI;
				Items[i].returnDelay = MAI;
			}
		}
		
		/*****************************
		HANDLERS - unused
		******************************
		private function onDown(e:MouseEvent){e.currentTarget.startDrag();}
		private function onUp(e:Event)
		{
			e.currentTarget.stopDrag();
			trace(e.currentTarget.x,e.currentTarget.y,e.currentTarget.width,e.currentTarget.height);
		}
		*/
		/*****************************
		PUBLICS, SETTERS & GETTERS, basically to use from controls
		******************************/
		
		public function set maxItems(qty:int):void
		{
			this.detect = false;
			var item;
			var itemsContainer = baseContainer.getChildByName("theItemsContainer");
			if(qty > floatingItems)
			{
				while(floatingItems < qty)
				{
					trace("growing items");
					item = createBall();
					Items.push(item);
					itemsContainer.addChild(item);
					item.cacheAsBitmap = true;
					floatingItems++;
				}
			}else if(qty < floatingItems){
				while(floatingItems > qty)
				{
					trace("items on diet");
					item = Items.pop();
					itemsContainer.removeChild(item);
					floatingItems--;
				}
			}
			//floatingItems = qty;
			this.detect = true;
		}
		public function get maxItems():int {return floatingItems;}
		
		public function get detect():Boolean {return detecting;}
		public function set detect(b:Boolean){_motionTracker.active = detecting = b;}
		public function set detectionInterval(ms:int):void{_motionTracker.interval = ms;}
		public function get detectionInterval():int {return _motionTracker.interval;}
		public function hideOutput(b:Boolean):void{_output.visible = b;}
		public function scaleIt(b:Boolean):void
		{
			if(b)
			{
				TweenMax.to(baseContainer,.5,{scaleX:SCALA,scaleY:SCALA});
			}else{
				TweenMax.to(baseContainer,.5,{scaleX:1,scaleY:1});
			}
		}
		
		public function get flipInput():Boolean {return isInverted;}
		public function set flipInput(b:Boolean)
		{
			_motionTracker.flipInput = b;
			if(b)
			{
				vid.scaleX = -1;
				vid.x = vid.width;
				isInverted = true;
			}else{
				vid.scaleX = 1;
				vid.x = 0;
				isInverted = false;
			}
		}
		
		public function get retraction():int {return MAAI;}
		public function set retraction(t:int) {MAAI = t;updateBodies();}
		public function get attraction():int {return MAI;}
		public function set attraction(t:int) {MAI = t;updateBodies();}
		public function setProductionState()
		{
			removeChild(controlsContainer);
			if(baseContainer.scaleX == 1) scaleIt(true);
			baseContainer.removeChild(_output);
			productionState = true;
			Mouse.hide();
			if(funcOut is Function) funcOut();
		}
	}
}