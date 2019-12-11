using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.ActivityMonitor;
using Toybox.Application;

using Toybox.Time;
using Toybox.Time.Gregorian;


var partialUpdatesAllowed = false;

class phoneBatteryIQView extends WatchUi.WatchFace {
	var fontSmall,fontMedium,font;
	var selectedFont; 
	var fullScreenRefresh;
	var offscreenBuffer = null;
	var dateBuffer = null;
	var isAwake;	    
	var screenShape;
	var screenCenterPoint;
	var screenWidth;
	var screenHeight;

	var topX = 115;
	var topY = 5;
	
	var rightTopX = 135;
	var rightTopY = 40;
	
	var hourX = 45;
	var hourY = 11;
	var minuteX = 150;
	var minuteY = 80;

	var leftBottomX = 110;
	var leftBottomY = 155;
	
    function initialize() {
        WatchFace.initialize();
        font = WatchUi.loadResource(Rez.Fonts.fntHuge);
		screenShape = System.getDeviceSettings().screenShape;
		partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
        fullScreenRefresh = true;		
    }
	
	function loadFont(){
		if(selectedFont != Application.getApp().getProperty("Font")){
			selectedFont = Application.getApp().getProperty("Font");
			switch(selectedFont){
				case 1:
					fontMedium = WatchUi.loadResource(Rez.Fonts.fntMedium);
					fontSmall = WatchUi.loadResource(Rez.Fonts.fntSmall);
					break;
				case 2:
					fontMedium = WatchUi.loadResource(Rez.Fonts.mediumJannScript);  // 36px
        			fontSmall = WatchUi.loadResource(Rez.Fonts.smallJannScript);  // 26px
					break;
				case 3:
					fontMedium = WatchUi.loadResource(Rez.Fonts.mediumStiffBrush); // 35px
        			fontSmall = WatchUi.loadResource(Rez.Fonts.smallStiffBrush); // 26px
					break;
				case 4:
					fontMedium = WatchUi.loadResource(Rez.Fonts.mediumKeyVirtue); // 35px
        			fontSmall = WatchUi.loadResource(Rez.Fonts.smallKeyVirtue); // 26px
        			break;
			}
			//System.println("new font loaded");
    	}else{
    		//System.println("no need to load font");
    	}
	}
	
    function getSmallFont(){
    	//loadFont();
    	return fontSmall;
	}

    // Load your resources here
    function onLayout(dc) {
		System.println("*****onLayout******");
		loadFont();

		// If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            // Allocate a full screen size buffer with a palette of only 4 colors to draw
            // the background image of the watchface.  This is used to facilitate blanking
            // the second hand during partial updates of the display
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_DK_GRAY,
                    Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE
                ]
        	});
			// Allocate a buffer tall enough to draw the date into the full width of the
            // screen. This buffer is also used for blanking the second hand. This full
            // color buffer is needed because anti-aliased fonts cannot be drawn into
            // a buffer with a reduced color palette
            dateBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>Graphics.getFontHeight(Graphics.FONT_MEDIUM)
            });		
		}
	
		screenWidth = dc.getWidth();
		screenHeight = dc.getHeight();
		System.println("w:" + screenWidth);
		System.println("h:"+screenHeight);

		screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
		drawHugeWatches(dc);
		// if(ifScreen(215,180,2)){
		// 	draw_fr230_fr235(dc);
		// }
		// else if(ifScreen(208,208,1)){
		// 	draw_fr45(dc);
		// }
		// else if(ifScreen(260,260,1)){
		// 	draw_fenix6(dc);
		// }
		// else if(ifScreen(280,280,1)){
		// 	draw_fenix6xpro(dc);
		// } else {
		// 	drawHugeWatches(dc);			
		// }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	System.println("*****onShow*****");
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	System.println("onHide");
    }

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
		System.println("****onEnterSleep****");
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
		System.println("****onExitSleep****");
    }
	
	function getHours() {
		var hours = System.getClockTime().hour;
		if(Application.getApp().getProperty("Use12Hours") && hours >12){
			hours = hours-12;
		}
		return hours.format("%02d").toCharArray();
	}
	
	function showDays(){
		return Application.getApp().getProperty("ShowDays");
	}
	
	function showBottomLeft(){
		return Application.getApp().getProperty("ShowBottomLeft");
	}	
	
	function getMonthName(number){
		
		switch(number){
			case 8: return "Aug";
			case 9: return "Sep";
			case 10: return "Oct";
			case 11: return "Nov";
			case 12: return "Dec";
			case 1: return "Jan";
			case 2: return "Feb";
			case 3: return "Mar";
			case 4: return "Apr";
			case 5: return "May";
			case 6: return "Jun";
			case 7: return "Jul";			
		}
	}
	
	function getWeekdayName(number){
		
		switch(number){
			case 1: return "Sun";
			case 2: return "Mon";
			case 3: return "Tue";
			case 4: return "Wed";
			case 5: return "Thu";
			case 6: return "Fri";
			case 7: return "Sat";			
		}
	}
	
	function drawWeekDay(dc,x,y,offset){
		var time = null;
		if(offset==0){
			time = Time.now();
		}else if (offset<0){
			time = Time.now().subtract(new Time.Duration(3600 *24 * (-offset)));
		}else if (offset>0){
			time = Time.now().add(new Time.Duration(3600 *24 * offset));
		}       	
    	var day = Gregorian.info(time, Time.FORMAT_SHORT);    	

    	dc.drawText(x,y, getSmallFont(), Lang.format(
	    	"$1$ $2$",
		    	[
			        getWeekdayName(day.day_of_week),
			        day.day.format("%02d")
			        
			    ]
		), Graphics.TEXT_JUSTIFY_LEFT);
	}

	function drawBackground(dc) {
		// var width = dc.getWidth();
        // var height = dc.getHeight();

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
			//System.println("*******draw offscreenBuffer******");
        }

        // Draw the date
        if( null != dateBuffer ) {
            // If the date is saved in a Buffered Bitmap, just copy it from there.
            dc.drawBitmap(0, 0, dateBuffer );			
			//System.println("*****draw from Buffered Bitmap******");
        } else {
            // Otherwise, draw it from scratch.
            drawDateString( dc);
			//System.println("**** Otherwise, draw it from scratch*****");
        }
	}

	function drawDateString(dc) {
		var clockTime = System.getClockTime();
        var minutes = clockTime.min.format("%02d").toCharArray();
        //var notifications = System.getDeviceSettings().notificationCount;
        var monitorInfo = ActivityMonitor.getInfo();
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
	    var battery = Lang.format("$1$$2$",[System.getSystemStats().battery.format("%d")+"%", "battr"]);
	    var steps = Lang.format("$1$/$2$",[monitorInfo.steps, monitorInfo.stepGoal]);
		var calories = Lang.format("$1$$2$",[monitorInfo.calories, "kcal"]);
	    var topLabel = Lang.format("$1$ $2$",[getMonthName(date.month),date.year]);	        
	    var hours = getHours();

		///use white draw datafield
	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
	    
	    dc.drawText(topX,topY, fontMedium, topLabel, Graphics.TEXT_JUSTIFY_CENTER);
		
	   	drawWeekDay(dc,rightTopX,rightTopY,0);
	    
	    dc.drawText(hourX,hourY, font, hours[0], Graphics.TEXT_JUSTIFY_CENTER);
	    dc.drawText(hourX+45,hourY, font, hours[1], Graphics.TEXT_JUSTIFY_CENTER);	    
	    
	    dc.drawText(minuteX,minuteY, font, minutes[0], Graphics.TEXT_JUSTIFY_CENTER);
	    dc.drawText(minuteX+45,minuteY-20, font, minutes[1], Graphics.TEXT_JUSTIFY_CENTER);
	    
		dc.drawText(leftBottomX+2,leftBottomY, getSmallFont(),steps,Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(leftBottomX+5,leftBottomY+20, getSmallFont(),battery, Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(leftBottomX+12,leftBottomY+40, getSmallFont(), calories, Graphics.TEXT_JUSTIFY_RIGHT);
	}

	function drawHugeWatches(dc){
		topX = 115;
	    topY = 5;
		rightTopX = 135;
	    rightTopY = 40;
		hourX = 45;
		hourY = 11;
		minuteX = 150;
		minuteY = 80;
	    leftBottomX = 110;
	    leftBottomY = 155;
	}
	
	function draw_fr45(dc){
		topX = 110;
        topY = 5;	
		rightTopX = 118;
      	rightTopY = 28;      	
		hourX = 35;
		hourY = -2;
		minuteX = 120;
		minuteY = 70;
      	leftBottomX = 95;
      	leftBottomY = 135;
	}

	function draw_fenix6(dc){
        topX = 115;
        topY = 5;	
		rightTopX = 130;
      	rightTopY = 40;
    
		hourX = 45;
		hourY = 15;
		minuteX = 170;
		minuteY = 100;
      	leftBottomX = 135;
      	leftBottomY = 165;
	}
	
	function draw_fenix6xpro(dc){
        topX = 125;
        topY = 10;
	
		rightTopX = 140;
      	rightTopY = 40;
    
		hourX = 45;
		hourY = 15;
		minuteX = 185;
		minuteY = 120;

      	leftBottomX = 145;
      	leftBottomY = 170;
	}
	
	function draw_fr230_fr235(dc){
		topX = 110;
		topY = 3;
		rightTopX = 135;
		rightTopY = 40;
		hourX = 35;
		hourY = -20;
		minuteX = 130;
		minuteY = 25;
		leftBottomX = 90;
		leftBottomY = 120;		
	}
	
	function ifScreen(screenWidth,screenHeight,screenShape){
		return 
			screenWidth == screenWidth &&
			screenHeight == screenHeight &&	
			screenShape == screenShape;
	}

	function onPartialUpdate( dc ) {
		// If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
		if (!fullScreenRefresh) {
			drawBackground(dc);			
		}
		
		//System.println(ActivityMonitor.HeartRateSample.heartRate);
		//System.println(System.getClockTime().sec);

		dc.setClip(rightTopX, rightTopY+20, 55, 40);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

		dc.drawText(rightTopX,rightTopY+20, getSmallFont(), Lang.format(
	    	"$1$ $2$",
		    	[
					"hr",
			        Activity.getActivityInfo().currentHeartRate			        
			    ]
		), Graphics.TEXT_JUSTIFY_LEFT);
		dc.drawText(rightTopX,rightTopY+40, getSmallFont(), Lang.format(
	    	"$1$",
		    	[
			        System.getClockTime().sec.format("%02d")			        
			    ]
		), Graphics.TEXT_JUSTIFY_LEFT);
	}
	
    // Update the view
    function onUpdate(dc) {		
		
		var targetDc = null;

		// We always want to refresh the full screen when we get a regular onUpdate call.
		fullScreenRefresh = true;	
		if(null != offscreenBuffer) {
            dc.clearClip();
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }	

		// Fill the entire background with Black.
		targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // If we have an offscreen buffer that we are using for the date string,
        // Draw the date into it. If we do not, the date will get drawn every update
        // after blanking the second hand.
        if( null != dateBuffer ) {
            var dateDc = dateBuffer.getDc();

            //Draw the background image buffer into the date buffer to set the background
            dateDc.drawBitmap(0, 0, offscreenBuffer);

            //Draw the date string into the buffer.
            drawDateString( dateDc);
			//System.println("######Draw dateBuffer********");
        }
		// Output the offscreen buffers to the main display if required.
        drawBackground(dc);

		drawDateString(dc);

		if( partialUpdatesAllowed ) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate( dc );	
        } else if (isAwake) {
			/////? test test
			// Otherwise, if we are out of sleep mode, draw the second hr
            // directly in the full update method.			
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(rightTopX,rightTopY+20, getSmallFont(), Lang.format(
	    	"$1$ $2$",
		    	[
					"hr",
			        Activity.getActivityInfo().currentHeartRate			        
			    ]
			), Graphics.TEXT_JUSTIFY_LEFT);
			dc.drawText(rightTopX,rightTopY+40, getSmallFont(), Lang.format(
	    		"$1$",
		    		[
				        System.getClockTime().sec.format("%02d")			        
				    ]
			), Graphics.TEXT_JUSTIFY_LEFT);
		}
		
		fullScreenRefresh = false;		
    }
}

class AnalogDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
