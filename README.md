Motion Tracker Plus
----

## Brief
Based on MotionTracker class by [Justin Windle](http://blog.soulwire.co.uk), extended to return multiple points.
## Comments
With some time to review now I can see a series of things that might be confusing. Some of them here:
  * The main class has a lot of setters/getters, product of my inexperience with Controls. Most of them are just public
access wrappers of MotionTrackerPlus class, so they could be called from Controls instance.
  * MotionTrackerPlus class doesn't use ENTER_FRAME but a Timer. When performing tests I saw some improvement
by relaxing detection since camera FPS wouldn't go above 30 EVER. Main movie animates and renders fine @60 fps, so using
a timer would allow me/you to play around with the class without having to adjust movie FPS.
  * Related to above: I tried to make MotionTrackerPlus class as independent as I could. I mean, it doesn't depend on
movie FPS, it can be stopped and reset, resized (captured image). I always wonder if it could be simpler, as it used to
be when soulwire released it. I guess I adjust it to my needs at the time and, I hope, you'll do the same and tell me
about it.
## Features
### Freeze background
Compare video feed against last taken frame or fixed one

	motionTracker.freezeBackground = true/false;
### Return multiple points or unique movement tracker
	motionTracker.returnBlobs = true/false;
### Configurable interval for detecion
	motionTracker.interval = 70;//int,miliseconds
### Scale tracking source
Can increase performance (I think)
	motionTracker.scaleIndex = 0.5;//number,input will be scaled prior to processing the image
## Issues
Flashplayer sacrifices camera fps when dealing with iterations. When camera fps drops, the whole detection
process falls to a laggy response. Hopefully someone will find a cure for this :)
## External classes needed:
[Keith Peter's Minimal Comps](http://www.minimalcomps.com/)

[Greensock's TweenMax Tweening Library](http://www.greensock.com/tweenmax/)

[Grant Skinner's](http://gskinner.com/blog) ColorMatrix (included in this repo)

## Credits, thanks and comments
To Justin Windle, Grant Skinner, Keith Peters, Quasimondo, senocular and many others who offered their knowledge
In case I've done any wrong in publishing this work, please let me know. All I've used I've found in SOURCE
avalability on some of the sites mentioned.
Sorry if my code is somewhat messy, I try to make it clean so others can read it, but sometimes
you'll find yourself reading some derranged thoughts I have as I code.
