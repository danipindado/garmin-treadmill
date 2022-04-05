using Toybox.System as Sys;
using Toybox.WatchUi;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang;

class TreadmillProfile
{
    private var _bleDelegate;

    var _device;
    private var _profileManagerStuff;
    private var _instantaneousSpeed = 0l;
    private var _averageSpeed = 0l;
    // private var _totalDistance = 0l;
    private var _inclination = 0l;
    // private var _elevation = 0l; 
    // private var _instantaneousPace = 0;
    // private var _averagePace = 0;
    private var _expEnergy = 0l;
    private var _heartRate = 0;
    // private var _metabolic = 0;
    // private var _elapsedTime = 0l;
    // private var _remainingTime = 0l;
    // private var _forceBelt = 0l;

    private var _rawIncline = 0l;
    private var _speed = 0;  
    private var _totalDistance = 0l;
    private var _incline = 0;
    private var _elevationGain = 0;
    private var _totalEnergy = 0;
    
    private var _isConnected = false;
    
    private var stack = new[0];
    
    //
    var scanForUuid = null;
    var writeBusy = false;
    
    public function wordToUuid(uuid)
    {
        
        return Ble.longToUuid(0x0000000000001000l + ((uuid & 0xffff).toLong() << 32), 0x800000805f9b34fbl);
    }
    
    hidden const DEVICE_NAME = "Domyos-TC-0751";
    public const FITNESS_MACHINE_SERVICE                = wordToUuid(0x1826);
    public const TREADMILL_DATA_CHARACTERISTIC          = wordToUuid(0x2acd);
    public const FITNESS_MACHINE_FEATURE_CHARACTERISTIC = wordToUuid(0x2acc);
    public const TREADMILL_CONTROL_POINT                = wordToUuid(0x2ad9);
    
    // https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides/td-0000001050147077
    public const TREADMILL_DATA_FLAG_MOREDATA       = 0x0001;                
    public const TREADMILL_DATA_FLAG_AVGSPEED       = 0x0002;
    public const TREADMILL_DATA_FLAG_TOTALDISTANCE  = 0x0004;
    public const TREADMILL_DATA_FLAG_INCLINATION    = 0x0008;
    public const TREADMILL_DATA_FLAG_ELEVATION      = 0x0010;
    public const TREADMILL_DATA_FLAG_INSTANTPACE    = 0x0020;
    public const TREADMILL_DATA_FLAG_AVERAGEPACE    = 0x0040;
    public const TREADMILL_DATA_FLAG_EXPENERGY      = 0x0080;
    public const TREADMILL_DATA_FLAG_HEARTRATE      = 0x0100;
    public const TREADMILL_DATA_FLAG_METABOLIC      = 0x0200;
    public const TREADMILL_DATA_FLAG_ELAPSEDTIME    = 0x0400;
    public const TREADMILL_DATA_FLAG_REMAININGTIME  = 0x0800;
    public const TREADMILL_DATA_FLAG_FORCEBELT      = 0x1000;

    // https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides/fmcp-0000001050147089
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_REQUESTCONTROL            = 0x00;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_RESET                     = 0x01;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETSPEED            = 0x02;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETINCLINATION      = 0x03;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETRESISTANCELEVEL  = 0x04;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETPOWER            = 0x05;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_STARTORRESUME             = 0x07;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_STOPORPAUSE               = 0x08;
    public const FITNESS_MACHINE_CONTROL_POINT_OPCODE_RESPONSECODE              = 0x80;

    function isConnected()
    {
        return _isConnected;
    }
    
    function getRawSpeed() 
    {
        return _instantaneousSpeed;
    }

    function getSpeed() 
    {
        return _speed;
    }

    function getRawIncline() 
    {
        return _rawIncline;
    }

    function getIncline() 
    {
        return _incline;
    }
    
       function getRunningMets()
       {
           var mpm = _speed * 26.8224;
        return (0.2 * mpm + 0.9 * mpm * _incline/100 + 3.5)/3.5;
       }
   
    function getTotalDistance() 
    {
        return _totalDistance;
    }

    function getElevationGain() 
    {
        return _elevationGain;
    }
    private const _fitnessProfileDef = 
    {
        :uuid => FITNESS_MACHINE_SERVICE,
        :characteristics => [
        {
            :uuid => TREADMILL_DATA_CHARACTERISTIC,:descriptors => [Ble.cccdUuid()]
        },
        {
            :uuid => FITNESS_MACHINE_FEATURE_CHARACTERISTIC                
            
        },
        {
            :uuid => TREADMILL_CONTROL_POINT                
            
        }]
    };
 
    function unpair() 
    {
        Ble.unpairDevice(_device);
        _device = null;
        System.println("Unpaired");
    }
    
    function scanFor(serviceToScanFor)
    {
        
        System.println("ScanMenuDelegate.starting scan");
        scanForUuid = serviceToScanFor;
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }

    function initialize()
    {
        System.println("initialize");
        Ble.registerProfile(_fitnessProfileDef);
        _bleDelegate = new TreadmillDelegate(self);  //pass it this
        Ble.setDelegate(_bleDelegate);
     
    }
    
    private function activateNextNotification() 
    {
        System.println("TreadmillProfile.activateNextNotification");
        var service = _device.getService(_parent.FITNESS_MACHINE_SERVICE);    
        var characteristic = service.getCharacteristic(_parent.TREADMILL_DATA_CHARACTERISTIC);
        var cccd = characteristic.getDescriptor(Ble.cccdUuid());
        cccd.requestWrite([0x01, 0x00]b);
        
    }

    function pushWrite(obj)   //need this so BLE doesn't throw exception if two writerequests come-in before BLE can process them
    {    
        stack.add(obj);
        handleStack();
    }

    function handleStack()
    {
        if (stack.size() == 0) {return;} // nothing to do
        if (writeBusy == true) {return;}// already busy.  nothing to do
        // https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides/fmcp-0000001050147089
        // https://github.com/cagnulein/qdomyos-zwift/blob/5bf7864efb074d59179813bd6b331e8bfb75ed8a/src/technogymmyruntreadmill.cpp#L225
        var characteristic = _device.getService(FITNESS_MACHINE_SERVICE).getCharacteristic(TREADMILL_CONTROL_POINT);
        try
        {
            writeBusy = true;
            characteristic.requestWrite(stack[0],{:writeType=>BluetoothLowEnergy.WRITE_TYPE_DEFAULT});
        
           //characteristic.requestRead();
        }
        catch (ex)
        {
            System.println("EXCEPTION: " + ex.getErrorMessage());
        }
    }

    function onCharacteristicWrite(char, value)    //called after write is complete
    {
        System.println("TreadmillProfile.onCharacteristicWrite");
        System.println("**callback characteristic Write.  SI: " + stack.size() + "Characteristic: " + char + ".  Value: " + value);
        if (stack.size() == 0) 
        {
            System.println("onCharasteristic write called in error si=0");
            return;
        }
        writeBusy = false;
        
        stack = stack.slice(1,null);
        if (stack.size() > 0) {handleStack();}
       //pop-off
        var ch = char;
        var v = value;
        
    }

    function onCharacteristicRead(char, value) 
    {
        var ch = char;
        var v = value;
        
    }

    function onCharacteristicChanged(char, value)
    {

        var name = _device.getName();
        var cu = char.getUuid();
        System.println("cu:"+cu);
        System.println("value:"+value);
        System.println("name:"+name);
        
        // https://github.com/cagnulein/qdomyos-zwift/blob/dd9526631ef0a8fbf5d16ea446a9ce6ce74ea934/src/solef80treadmill.cpp#L499
        if (cu.equals(TREADMILL_DATA_CHARACTERISTIC))
        {
            var offset = 0;
            var flags = value[offset] + 256 * value[offset+1];
            offset += 2;

            if ((flags & TREADMILL_DATA_FLAG_MOREDATA) != TREADMILL_DATA_FLAG_MOREDATA) 
            {
                _instantaneousSpeed = (value[offset] + 256.0 * value[offset+1]) / 100.0;
                System.println("_instantaneousSpeed:"+_instantaneousSpeed);
                offset += 2;
            }

            if ((flags & TREADMILL_DATA_FLAG_AVGSPEED) == TREADMILL_DATA_FLAG_AVGSPEED) 
            {
                _averageSpeed = (value[offset] + 256.0 * value[offset+1]) / 100.0;
                System.println("_averageSpeed:"+_averageSpeed);
                offset += 2;
            }

            if ((flags & TREADMILL_DATA_FLAG_TOTALDISTANCE) == TREADMILL_DATA_FLAG_TOTALDISTANCE) 
            {
                //todo
                System.println("_totalDistance:");
                offset += 3;
            }

            if ((flags & TREADMILL_DATA_FLAG_INCLINATION) == TREADMILL_DATA_FLAG_INCLINATION) 
            {
                _inclination = (value[offset] + 256.0 * value[offset+1]) / 10.0;
                System.println("_inclination:"+_inclination);
                offset += 4; // Inclination + Ramp Angle Setting
            }

            if ((flags & TREADMILL_DATA_FLAG_ELEVATION) == TREADMILL_DATA_FLAG_ELEVATION) 
            {
                //todo
                System.println("_elevation:");
                offset += 4; // Positive Elevation Gain + Negative Elevation Gain
            }

            if ((flags & TREADMILL_DATA_FLAG_INSTANTPACE) == TREADMILL_DATA_FLAG_INSTANTPACE) 
            {
                //todo
                System.println("_instantPace:");
                offset += 1;
            }

            if ((flags & TREADMILL_DATA_FLAG_AVERAGEPACE) == TREADMILL_DATA_FLAG_AVERAGEPACE) 
            {
                //todo
                System.println("_averagePace:");
                offset += 1;
            }

            if ((flags & TREADMILL_DATA_FLAG_EXPENERGY) == TREADMILL_DATA_FLAG_EXPENERGY) 
            {
                _expEnergy = (value[offset] + 256.0 * value[offset+1]);
                System.println("_expEnergy:"+_expEnergy);
                offset += 5; //Total Energy + Energy Per Hour + Energy Per Minute
            }

            if ((flags & TREADMILL_DATA_FLAG_HEARTRATE) == TREADMILL_DATA_FLAG_HEARTRATE) 
            {
                _heartRate = value[offset];
                System.println("_heartRate:"+_heartRate);
                offset += 1; 
            }

            if ((flags & TREADMILL_DATA_FLAG_METABOLIC) == TREADMILL_DATA_FLAG_METABOLIC) 
            {
                //todo
                System.println("_metabolic:");
                offset += 1; 
            }

            if ((flags & TREADMILL_DATA_FLAG_ELAPSEDTIME) == TREADMILL_DATA_FLAG_ELAPSEDTIME) 
            {
                //todo
                System.println("_elapsedTime:");
                offset += 2;
            }

            if ((flags & TREADMILL_DATA_FLAG_REMAININGTIME) == TREADMILL_DATA_FLAG_REMAININGTIME) 
            {
                //todo
                System.println("_remainingTime:");
                offset += 2;
            }

            if ((flags & TREADMILL_DATA_FLAG_FORCEBELT) == TREADMILL_DATA_FLAG_FORCEBELT) 
            {
                //todo
                System.println("_forceBelt:");
                offset += 4;
            }            
        }
    }
    
    function setSpeed (speed)
    {
        System.println("setSpeed");

        // https://github.com/cagnulein/qdomyos-zwift/blob/a8935e11f1bce424094101b6b668ec600a1ea409/src/shuaa5treadmill.cpp#L145
        if (speed < 0.0) {speed = 0.0;}
        if (speed > 14.0) {speed = 14.0;}
        
        var i = [FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETSPEED, 0x00, 0x00];
        var lsb = speed * 100.0;
        var msb = speed * 100.0 / 256.0; 
        i[1] = (0x00FF)&(lsb.toNumber());
        i[2] = (0x00FF)&(msb.toNumber());

        pushWrite(i);
    }

    function setIncline (incline)
    {
        var incl = incline * 10.0;
        var long1 = incl.toLong();//convert to kph and multiply by one humdred
        var b1 = [FITNESS_MACHINE_CONTROL_POINT_OPCODE_SETTARGETINCLINATION,0,0]b;   //starting with 2 means set speed
        b1.encodeNumber(long1,Lang.NUMBER_FORMAT_UINT16,{:offset=>1,:endianness=>Lang.ENDIAN_LITTLE});
        
           System.println("incline");
           pushWrite(b1);
    }
    
    function onConnectedStateChanged(device, state)
    {
        System.println("TreadmillProfile.onConnectedStateChanged");
        if (state == Ble.CONNECTION_STATE_CONNECTED)
        {
            _isConnected = true;
            WatchUi.requestUpdate();
            _device = device;
            System.println("CONNECTION_STATE_CONNECTED");
            var service = device.getService(FITNESS_MACHINE_SERVICE);
            
            var characteristic = service.getCharacteristic(TREADMILL_DATA_CHARACTERISTIC);
            var cccd = characteristic.getDescriptor(Ble.cccdUuid());
            cccd.requestWrite([0x01, 0x00]b);
        }
        if (state == Ble.CONNECTION_STATE_DISCONNECTED)
        {
            _isConnected = false;
            System.println("CONNECTION_STATE_DISCONNECTED");
        }
    }
    
    private function contains(iter, obj) 
    {
        for(var uuid = iter.next(); uuid != null; uuid = iter.next()) 
        {
            if(uuid.equals(obj)) 
            {
                return true;
            }
        }
        return false;
    }

    function onScanResults(scanResults)
    {
        System.println("TreadmillProfile.onScanResults");
        
    	for( var result = scanResults.next(); result != null; result = scanResults.next()) 
        {
            if( contains(result.getServiceUuids(), scanForUuid)) 
            {            		
        		 Ble.setScanState(Ble.SCAN_STATE_OFF);
    			var d = Ble.pairDevice(result);
            }
        }
    }

    function onDescriptorWrite(descriptor, status) 
    {

    }
    
    /*
    
function onDescriptorWrite(descriptor, status) 
    {
        if(Ble.cccdUuid().equals(descriptor.getUuid())) 
        {
            processCccdWrite(status);
        }
        else
        {
        
        }
    }

    private function processCccdWrite(status) 
    {
        if(_pendingNotifies.size() > 1) 
        {
            _pendingNotifies = _pendingNotifies.slice(1,_pendingNotifies.size());
            activateNextNotification();
        }
        else {
            _pendingNotifies = [];
        }
    }
   
    */

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

class TreadmillDelegate extends Ble.BleDelegate 
{
    
    var _parent = null;
    
    function initialize(parent) 
    {
        BleDelegate.initialize();
        _parent = parent;
        System.println("BleDelegate.initialize");
    }
    
    function onScanResults(scanResults) 
    {
        System.println("BleDelegate.onScanResults");
        if (_parent != null)
        {
            _parent.onScanResults(scanResults);
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

    function onDescriptorWrite(descriptor, status) 
    {
        System.println("BleDelegate.onDescriptorWrite");
        if (_parent != null)
        {        
            _parent.onDescriptorWrite(descriptor, status);
        }
    }

    function onDescriptorRead(descriptor, status) 
    {
        System.println("BleDelegate.onDescriptorRead");
        var q = 42;
        
    }
}

