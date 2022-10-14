var exec = require('cordova/exec');


var ClipExport = {
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
    },
    coolMethod: function (arg0, onSuccess, onError) {
        exec(onSuccess, onError, "CordovaClipExport", "coolMethod", [arg0]);
    }
};

module.exports = ClipExport;
