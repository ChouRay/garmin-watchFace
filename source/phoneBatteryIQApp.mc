using Toybox.Application;
using Toybox.WatchUi;

class phoneBatteryIQApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
         if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new phoneBatteryIQView(), new AnalogDelegate()];
        } else {
            return [new phoneBatteryIQView()];
        }
    }
    
    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }

}