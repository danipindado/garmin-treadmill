//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;

class FitContributor {
    // FIT Contributions variables
    hidden var mCurrentRunningPower = null;
    var mTimerRunning = false;
    

    // Constructor
    function initialize(dataField) {
        mCurrentRunningPower = dataField.createField("RunningPower", 1, Fit.DATA_TYPE_SINT16, { :nativeNum=>7, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"W" });

        mCurrentRunningPower.setData(0);
    }

    function compute(sensor) 
    {
        if( sensor != null ) 
        {
            // Hemoglobin Concentration is stored in 1/100ths g/dL fixed point
            mCurrentRunningPower.setData( sensor[0] );

            if( mTimerRunning ) 
            {
                // Update lap/session data and record counts

                // Updatea lap/session FIT Contributions
            }
        }
    }

    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
    }

    function onTimerReset() {
    }

}