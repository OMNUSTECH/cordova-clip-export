var exec = require('cordova/exec');


var ClipExport = {
    isAvailable: function (success, error) {
        exec(success, error, 'CordovaClipExport', 'isAvailable');
    },
    isRecording: function (success, error) {
        exec(success, error, "CordovaClipExport", "isRecording");
    },
    coolMethod: function (arg0, onSuccess, onError) {
        exec(onSuccess, onError, "CordovaClipExport", "coolMethod", [arg0]);
    },
    startCapture: function (isMicrophone, success, error) {
        exec(success, error, "CordovaClipExport", "startCapture",[isMicrophone]);
    },
    stopCapture: function (success, error) {
        exec(success, error, "CordovaClipExport", "stopCapture");
    }
};

module.exports = ClipExport;
