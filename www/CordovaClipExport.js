var exec = require('cordova/exec');

/*
exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'SwiftRecorded', 'coolMethod', [arg0]);
};
*/

var Replay = {
    isAvailable: function (success, error) {
        exec(success, error, 'CordovaClipExport', 'isAvailable');
    },
    startScreenRecording: function (isMicrophoneEnabled, success, error) {
        exec(success, error, "CordovaClipExport", "startScreenRecording");
    },
    stopScreenRecording: function (success, error) {
        exec(success, error, "CordovaClipExport", "stopScreenRecording");
    },
    isRecording: function (success, error) {
        exec(success, error, "CordovaClipExport", "isRecording");
    },  
    exportClip: function (success, error) {
        exec(success, error, "CordovaClipExport", "exportClip");
    }
};

module.exports = Replay;
