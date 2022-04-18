using Toybox.System as Sys;
using Toybox.WatchUi;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

class FtmsTreadmillBleDelegate extends Ble.BleDelegate 
{
    
    var _parent = null;
    
    function initialize(parent) 
    {
        BleDelegate.initialize();
        _parent = parent;
        System.println("BleDelegate.initialize");
    }
    
    function onCharacteristicChanged(char, value) 
    {
        System.println("BleDelegate.onCharacteristicChanged");
        BleDelegate.onCharacteristicChanged(char, value);
        if (_parent != null)
        {
            _parent.onCharacteristicChanged(char, value);
        }
    }

    function onCharacteristicRead(char, value) 
    {
        System.println("BleDelegate.onCharacteristicRead");
        BleDelegate.onCharacteristicRead(char, value);
        if (_parent != null)
        {
            _parent.onCharacteristicRead(char, value);
        }
    }

    function onCharacteristicWrite(char, value) 
    {
        System.println("BleDelegate.onCharacteristicWrite");
        BleDelegate.onCharacteristicChanged(char, value);
        
        if (_parent != null)
        {
            _parent.onCharacteristicWrite(char, value);
        }
    }

    function onConnectedStateChanged(device, state) 
    {
        System.println("BleDelegate.onConnectedStateChanged");
        if (_parent != null)
        {
            _parent.onConnectedStateChanged(device, state);
        }
    }

    function onDescriptorRead(descriptor, status) 
    {
        System.println("BleDelegate.onDescriptorRead");
        if (_parent != null)
        {        
            _parent.onDescriptorRead(descriptor, status);
        }        
    }

    function onDescriptorWrite(descriptor, status) 
    {
        System.println("BleDelegate.onDescriptorWrite");
        if (_parent != null)
        {        
            _parent.onDescriptorWrite(descriptor, status);
        }
    }

    function onProfileRegister(uuid, status) 
    {
        System.println("BleDelegate.onProfileRegister");
        if (_parent != null)
        {
            _parent.onProfileRegister(uuid, status);
        }
    }

    function onScanResults(scanResults) 
    {
        System.println("BleDelegate.onScanResults");
        if (_parent != null)
        {
            _parent.onScanResults(scanResults);
        }
    }
    
    function onScanStateChange(scanState, status)
    {
        System.println("BleDelegate.onScanStateChange");
        if (_parent != null)
        {
            _parent.onScanStateChange(scanState, status);
        }
    }
}

