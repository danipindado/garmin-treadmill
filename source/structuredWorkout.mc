using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

const INTENSITY_NAMES = [
    "ACTIVE",
    "REST",
    "WARMUP",
    "COOLDOWN",
    "RECOVERY",
    "INTERVAL"
];

const DURATION_NAMES = [
    "TIME",
    "DISTANCE",
    "HR_LESS_THAN",
    "HR_GREATER_THAN",
    "CALORIES",
    "OPEN",
    "REPEAT_UNTIL_STEPS_COMPLETE",
    "REPEAT_UNTIL_TIME",
    "REPEAT_UNTIL_DISTANCE",
    "REPEAT_UNTIL_CALORIES",
    "REPEAT_UNTIL_HR_LESS_THAN",
    "REPEAT_UNTIL_HR_GREATER_THAN",
    "REPEAT_UNTIL_POWER_LESS_THAN",
    "REPEAT_UNTIL_POWER_GREATER_THAN",
    "POWER_LESS_THAN",
    "POWER_GREATER_THAN",
    "TRAINING_PEAKS_TRAINING_STRESS_SCORE",
    "REPEAT_UNTIL_POWER_LAST_LAP_LESS_THAN",
    "REPEAT_UNTIL_MAX_POWER_LAST_LAP_LESS_THAN",
    "POWER_3S_LESS_THAN",
    "POWER_10S_LESS_THAN",
    "POWER_30S_LESS_THAN",
    "POWER_3S_GREATER_THAN",
    "POWER_10S_GREATER_THAN",
    "POWER_30S_GREATER_THAN",
    "POWER_LAP_LESS_THAN",
    "POWER_LAP_GREATER_THAN",
    "REPEAT_UNTIL_TRAINING_PEAKS_TRAINING_STRESS_SCORE",
    "REPETITION_TIME",
    "REPS",
];

const TARGET_NAMES = [
    "SPEED",
    "HEART_RATE",
    "OPEN",
    "CADENCE",
    "POWER",
    "GRADE",
    "RESISTANCE",
    "POWER_3S",
    "POWER_10S",
    "POWER_30S",
    "POWER_LAP",
    "SWIM_STROKE",
    "SPEED_LAP",
    "HEART_RATE_LAP",
    "INHALE_DURATION",
    "INHALE_HOLD_DURATION",
    "EXHALE_DURATION",
    "EXHALE_HOLD_DURATION",
    "POWER_CURVE",
];

const SPORT_NAMES = [
    "GENERIC",
    "RUNNING",
    "CYCLING",
    "TRANSITION",
    "FITNESS_EQUIPMENT",
    "SWIMMING",
    "BASKETBALL",
    "SOCCER",
    "TENNIS",
    "AMERICAN_FOOTBALL",
    "TRAINING",
    "WALKING",
    "CROSS_COUNTRY_SKIING",
    "ALPINE_SKIING",
    "SNOWBOARDING",
    "ROWING",
    "MOUNTAINEERING",
    "HIKING",
    "MULTISPORT",
    "PADDLING",
    "FLYING",
    "E_BIKING",
    "MOTORCYCLING",
    "BOATING",
    "DRIVING",
    "GOLF",
    "HANG_GLIDING",
    "HORSEBACK_RIDING",
    "HUNTING",
    "FISHING",
    "INLINE_SKATING",
    "ROCK_CLIMBING",
    "SAILING",
    "ICE_SKATING",
    "SKY_DIVING",
    "SNOWSHOEING",
    "SNOWMOBILING",
    "STAND_UP_PADDLEBOARDING",
    "SURFING",
    "WAKEBOARDING",
    "WATER_SKIING",
    "KAYAKING",
    "RAFTING",
    "WINDSURFING",
    "KITESURFING",
    "TACTICAL",
    "JUMPMASTER",
    "BOXING",
    "FLOOR_CLIMBING",
    "BASEBALL",
    "SOFTBALL_FAST_PITCH",
    "SOFTBALL_SLOW_PITCH",
    "SHOOTING",
    "AUTO_RACING",
];

const SUB_SPORT_NAMES = [
    "GENERIC",
    "TREADMILL",
    "STREET",
    "TRAIL",
    "TRACK",
    "SPIN",
    "INDOOR_CYCLING",
    "ROAD",
    "MOUNTAIN",
    "DOWNHILL",
    "RECUMBENT",
    "CYCLOCROSS",
    "HAND_CYCLING",
    "TRACK_CYCLING",
    "INDOOR_ROWING",
    "ELLIPTICAL",
    "STAIR_CLIMBING",
    "LAP_SWIMMING",
    "OPEN_WATER",
    "FLEXIBILITY_TRAINING",
    "STRENGTH_TRAINING",
    "WARM_UP",
    "MATCH",
    "EXERCISE",
    "CHALLENGE",
    "INDOOR_SKIING",
    "CARDIO_TRAINING",
];

class WorkoutStepsView extends WatchUi.DataField {

    hidden var _cx;
    hidden var _cy;
    hidden var _font;
    hidden var _font_height;
    hidden var _justification;
    hidden var _step;
    hidden var _lines;

    function initialize() {
        DataField.initialize();
        _step = 0;
        _lines = [];
    }

    function onLayout(dc) {
        _cx = dc.getWidth() / 2;
        _cy = dc.getHeight() / 2;
        _font = Graphics.FONT_XTINY;
        _font_height = dc.getFontHeight(_font);
        _justification = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    }

    function dumpValue(depth, label, value, lines) {
        var s = "";

       for (var i = 0; i < depth; ++i) {
            s += " ";
        }

        lines.add(Lang.format("$1$$2$: $3$", [ s, label, value ]));
    }

    function dumpEnumValue(depth, label, value, names, lines) {
        if (0 <= value && value < names.size()) {
            value = names[value];
        }
        else {
            value = "INVALID";
        }

        dumpValue(depth, label, value, lines);
    }

    function dumpWorkoutStep(depth, field, workoutStep, lines) {
        dumpValue(depth, field, workoutStep, lines);
        depth += 1;

        if (workoutStep != null) {
            if (workoutStep has :durationType) {
                dumpEnumValue(depth, "durationType", workoutStep.durationType, DURATION_NAMES, lines);
            }
            if (workoutStep has :durationValue) {
                dumpValue(depth, "durationValue", workoutStep.durationValue, lines);
            }
            if (workoutStep has :targetType) {
                dumpEnumValue(depth, "targetType", workoutStep.targetType, TARGET_NAMES, lines);
            }
            if (workoutStep has :targetValueLow) {
                dumpValue(depth, "targetValueLow", workoutStep.targetValueLow, lines);
            }
            if (workoutStep has :targetValueHigh) {
                dumpValue(depth, "targetValueHigh", workoutStep.targetValueHigh, lines);
            }
        }
    }

    function dumpWorkoutIntervalStep(depth, name, intervalStep, lines) {
        dumpValue(depth, name, intervalStep, lines);
        depth += 1;

        if (intervalStep != null) {
            if (intervalStep has :activeStep) {
                dumpWorkoutStep(depth, "activeStep", intervalStep.activeStep, lines);
            }
            if (intervalStep has :repititionNumber) {
                dumpValue(depth, "repititionNumber", intervalStep.repititionNumber, lines);
            }
            if (intervalStep has :restStep) {
                dumpWorkoutStep(depth, "restStep", intervalStep.restStep, lines);
            }
        }
    }

    function dumpWorkoutStepInfo(depth, workoutStepInfo, lines) {
        dumpValue(depth, "workoutStepInfo", workoutStepInfo, lines);
        depth += 1;

        if (workoutStepInfo != null) {
            if (workoutStepInfo has :intensity) {
                dumpEnumValue(depth, "intensity", workoutStepInfo.intensity, INTENSITY_NAMES, lines);
            }
            if (workoutStepInfo has :name) {
                dumpValue(depth, "name", workoutStepInfo.name, lines);
            }
            if (workoutStepInfo has :notes) {
                dumpValue(depth, "notes", workoutStepInfo.notes, lines);
            }
            if (workoutStepInfo has :sport) {
                dumpEnumValue(depth, "sport", workoutStepInfo.sport, SPORT_NAMES, lines);
            }
            if (workoutStepInfo has :subSport) {
                dumpEnumValue(depth, "subSport", workoutStepInfo.subSport, SUB_SPORT_NAMES, lines);
            }
            if (workoutStepInfo has :step) {
                if (workoutStepInfo.step instanceof Activity.WorkoutStep) {
                    dumpWorkoutStep(depth, "workoutStep", workoutStepInfo.step, lines);
                }
                else {
                    dumpWorkoutIntervalStep(depth, "workoutIntervalStep", workoutStepInfo.step, lines);
                }
            }
        }
    }

    function onWorkoutStarted() {
        _step = 1;
        _lines = [];

        if (Activity has :getCurrentWorkoutStep) {
            var workoutStepInfo = Activity.getCurrentWorkoutStep();
            dumpWorkoutStepInfo(1, workoutStepInfo, _lines);
        }
        if (Activity has :getNextWorkoutStep) {
            var workoutStepInfo = Activity.getNextWorkoutStep();
            dumpWorkoutStepInfo(1, workoutStepInfo, _lines);
        }

        WatchUi.requestUpdate();
    }

    function onWorkoutStepComplete() {
        ++_step;
        _lines = [];

        if (Activity has :getCurrentWorkoutStep) {
            var workoutStepInfo = Activity.getCurrentWorkoutStep();
            dumpWorkoutStepInfo(1, workoutStepInfo, _lines);
        }
        if (Activity has :getNextWorkoutStep) {
            var workoutStepInfo = Activity.getNextWorkoutStep();
            dumpWorkoutStepInfo(1, workoutStepInfo, _lines);
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var cy = _cy - (_lines.size() * _font_height) / 2;

        for (var i = 0; i < _lines.size(); ++i) {
            dc.drawText(_cx, cy + (_font_height * i), _font, _lines[i], _justification);
        }
    }

}

class WorkoutStepsApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new WorkoutStepsView() ];
    }

}