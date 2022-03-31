using Toybox.Application as App;
using Toybox.BluetoothLowEnergy as Ble;

class GarminTreadmillApp extends App.AppBase {

    hidden var _bleDevice;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        _bleDevice = new TreadmillDelegate();
        Ble.setDelegate(_bleDevice);
        _bleDevice.open();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        _bleDevice.close();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new GarminTreadmillView(_bleDevice) ];
    }   

}