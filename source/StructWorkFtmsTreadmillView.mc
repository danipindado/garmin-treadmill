using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity as activity;

class StructWorkFtmsTreadmillView extends Ui.DataField 
{

    hidden var _treadmillProfile;
    hidden var elapsedTime = 0; 
    hidden var lastComputeTime = 0;
    var _fitContributor;

    function initialize() 
    {
        DataField.initialize();
        _treadmillProfile = new BasicFtmsTreadmill();
        _treadmillProfile.scanFor(_treadmillProfile.FITNESS_MACHINE_SERVICE);
        _fitContributor = new FitContributor(self);
    }
    
    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) 
    {   
        elapsedTime = info.timerTime != null ? info.timerTime : 0;
        // hrValue = info.currentHeartRate != null ? info.currentHeartRate : 0;        
        if(elapsedTime != lastComputeTime)
        {
            lastComputeTime = elapsedTime;
            // _fitContributor.compute([currentPower]);
            _fitContributor.compute([0.0]);
        }
        // System.println("currentPower: " + currentPower);
        // System.println("lapPower: " + lapPower);
        // System.println("averagePower: " + averagePower);

        // System.println("elapsedTime: " + elapsedTime);
        // System.println("lapTime: " + lapTime);
        // System.println("elapsedEnergy: " + elapsedEnergy);
        // System.println("averagePower: " + averagePower);
    }
    
    function onTimerLap()
    {
        // lapStartDistance = elapsedDistance;
    }

    function dumpValue( label, value) 
    {
        System.println("label: " + label);
        System.println("value: " + value);
    }

    function dumpEnumValue( label, value, names) 
    {
        if (0 <= value && value < names.size()) 
        {
            value = names[value];
        }
        else 
        {
            value = "INVALID";
        }

        dumpValue( label, value);
    }

    function dumpWorkoutStep( field, workoutStep) 
    {
        dumpValue( field, workoutStep);

        if (workoutStep != null) 
        {
            if (workoutStep has :durationType) 
            {
                dumpEnumValue( "durationType", workoutStep.durationType, DURATION_NAMES);
            }
            if (workoutStep has :durationValue) 
            {
                dumpValue( "durationValue", workoutStep.durationValue);
            }
            if (workoutStep has :targetType) 
            {
                dumpEnumValue( "targetType", workoutStep.targetType, TARGET_NAMES);
            }
            if (workoutStep has :targetValueLow) 
            {
                dumpValue( "targetValueLow", workoutStep.targetValueLow);
            }
            if (workoutStep has :targetValueHigh) 
            {
                dumpValue( "targetValueHigh", workoutStep.targetValueHigh);
            }
        }
    }

    function dumpWorkoutIntervalStep( name, intervalStep) 
    {
        dumpValue( name, intervalStep);

        if (intervalStep != null) 
        {
            if (intervalStep has :activeStep) 
            {
                dumpWorkoutStep( "activeStep", intervalStep.activeStep);
            }
            if (intervalStep has :repititionNumber) 
            {
                dumpValue( "repititionNumber", intervalStep.repititionNumber);
            }
            if (intervalStep has :restStep) 
            {
                dumpWorkoutStep( "restStep", intervalStep.restStep);
            }
        }
    }

    function dumpWorkoutStepInfo(workoutStepInfo) 
    {
        dumpValue( "workoutStepInfo", workoutStepInfo);

        if (workoutStepInfo != null) 
        {

            var step;
            var targetSpeed = 0.0; 

            if (workoutStepInfo has :step) 
            {
                if (workoutStepInfo.step instanceof Activity.WorkoutStep) 
                {
                    System.println("Activity.WorkoutStep");
                    step = workoutStepInfo.step;
                }
                else 
                {
                    System.println("!Activity.WorkoutStep");
                    if (workoutStepInfo.step has :activeStep) 
                    {
                        step = workoutStepInfo.step.activeStep;
                    }
                    else
                    {
                        System.println("unexpected workoutStepInfo");
                        return;
                    }
                }


                if (step has :targetType) 
                {                    
                    System.println("has :targetType");
                    System.println(step.targetType);
                    System.println(activity.WORKOUT_STEP_TARGET_SPEED);
                    System.println(activity.WORKOUT_STEP_TARGET_SPEED_LAP);

                    if( step.targetType == activity.WORKOUT_STEP_TARGET_SPEED || step.targetType == activity.WORKOUT_STEP_TARGET_SPEED_LAP)
                    {
                        if (step has :targetValueLow) 
                        {
                            System.println("speed.targetValueLow:"+step.targetValueLow);
                            targetSpeed = step.targetValueLow;
                        }
                        if (step has :targetValueHigh) 
                        {
                            System.println("speed.targetValueHigh:"+step.targetValueHigh);
                            targetSpeed = (targetSpeed + step.targetValueHigh)/ 2.0;
                        }

                        System.println("targetSpeed:"+targetSpeed);
                        _treadmillProfile.setSpeed(targetSpeed);
                    }
                }
                else
                {
                    System.println("!has :targetType");
                }
            }
        }
    }

    function onWorkoutStarted() 
    {
        System.println("onWorkoutStarted");

        if (Activity has :getCurrentWorkoutStep) 
        {
            System.println("has :getCurrentWorkoutStep");
            var workoutStepInfo = Activity.getCurrentWorkoutStep();
            dumpWorkoutStepInfo(workoutStepInfo);
        }

        WatchUi.requestUpdate();
    }

    function onWorkoutStepComplete()
    {
        System.println("onWorkoutStepComplete");
        onTimerLap();
        if (Activity has :getCurrentWorkoutStep) 
        {
            System.println("has :getCurrentWorkoutStep");
            var workoutStepInfo = Activity.getCurrentWorkoutStep();
            dumpWorkoutStepInfo(workoutStepInfo);
        }

        WatchUi.requestUpdate();

    }
    
    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) 
    {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var backgroundColor = getBackgroundColor();
        var valueColor = backgroundColor == Graphics.COLOR_WHITE ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var labelColor = backgroundColor == Graphics.COLOR_WHITE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var valueSize = Graphics.FONT_LARGE;
        var labelSize = Graphics.FONT_TINY;
        var distanceYPosition = (height > 214) ? height * .04 : height * .03;
        // Set the background color
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(0, 0, width, height);
        // Draw grid
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(0, height * .2, width, height * .2);
        dc.drawLine(0, height * .5, width, height * .5);
        dc.drawLine(0, height * .8, width, height * .8);
        dc.drawLine(width * .5, height * .2, width * .5, height * .8);
        // this is going up here because we're gonna shift some stuff based on distance
        // var distanceUnit = "km";
        // if(System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE)
        // {
        //     distanceValue = elapsedDistance * 0.000621371;
        //     distanceUnit = "mi";
        // }
        // var distanceLabelX = (distanceValue > 10.0) ? width * .675 : width * .6375;
        // var distanceXPosition = (distanceValue > 10.0) ? width / 2 : width * .4625;
        // Draw Labels
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        // dc.drawText(distanceLabelX, height * .0725, labelSize, distanceUnit, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .33, height * .0725, labelSize, "Dist", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .25, height * .22, labelSize, "Timer", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .75, height * .22, labelSize, "Power", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .25, height * .52, labelSize, "Avg. Power", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .75, height * .52, labelSize, "Lap Power", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width * .33, height * .82, labelSize, "HR", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        var tmp = 10.0;
        var distanceText;
        distanceText = tmp.format("%d");
        dc.drawText(width / 2, height * .04, valueSize, distanceText, Graphics.TEXT_JUSTIFY_CENTER);

        var timeText;
        timeText = tmp.format("%d");
        dc.drawText(width * .25, height * .31, Graphics.FONT_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER);
        var powerText;
        if (tmp == 0) 
        {
            powerText = "--";
        } 
        else 
        {
            powerText = tmp.format("%d");
        }
        dc.drawText(width * .75, height * .315, valueSize, powerText, Graphics.TEXT_JUSTIFY_CENTER);
        //System.println("power: " + currentPower);

        var lapPowerText;
        lapPowerText = tmp.format("%d");        
        dc.drawText(width * .75, height * .615, valueSize, lapPowerText, Graphics.TEXT_JUSTIFY_CENTER);
        var avgPowerText;
        avgPowerText = tmp.format("%d");        
        dc.drawText(width * .25, height * .615, valueSize, avgPowerText, Graphics.TEXT_JUSTIFY_CENTER);
        // System.println("Avg. Power " + averagePower);
        var hrText;
        hrText = tmp.format("%d");        
        dc.drawText(width / 2, height * .82, valueSize, hrText, Graphics.TEXT_JUSTIFY_CENTER);

    }

    function onTimerStart() 
    {
        _fitContributor.setTimerRunning(true);
    }

    function onTimerStop() 
    {
        _fitContributor.setTimerRunning(false);
    }

    function onTimerPause() 
    {
        _fitContributor.setTimerRunning(false);
    }

    function onTimerResume() 
    {
        _fitContributor.setTimerRunning(true);
    }    

}
