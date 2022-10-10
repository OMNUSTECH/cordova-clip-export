var exec = require('cordova/exec');

/*
exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'SwiftRecorded', 'coolMethod', [arg0]);
};
*/

var Replay = {
    isAvailable: function (success, error) {
        exec(success, error, 'CordovaReplay', 'isAvailable');
    },
    startRecording: function (isMicrophoneEnabled, success, error) {
        exec(success, error, "CordovaReplay", "startRecording", [isMicrophoneEnabled]);
    },
    stopRecording: function (success, error) {
        exec(success, error, "CordovaReplay", "stopRecording");
    },
    isRecording: function (success, error) {
        exec(success, error, "CordovaReplay", "isRecording");
    },
    startBroadcast: function (success, error) {
        exec(success, error, "CordovaReplay", "startBroadcast");
    },
    stopBroadcast: function (success, error) {
        exec(success, error, "CordovaReplay", "stopBroadcast");
    },
    isBroadcasting: function (success, error) {
        exec(success, error, "CordovaReplay", "isBroadcasting");
    },
    isBroadcastAvailable: function (success, error) {
        exec(success, error, "CordovaReplay", "isBroadcastAvailable");
    }
};

module.exports = Replay;
