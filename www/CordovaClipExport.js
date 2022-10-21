var exec = require('cordova/exec');


var ClipExport = {
    isAvailable: function (onSuccess, error) {
        exec(onSuccess, error, 'CordovaClipExport', 'isAvailable');
    },
    isRecording: function (onSuccess, error) {
        exec(onSuccess, error, "CordovaClipExport", "isRecording");
    },
    startCapture: function (isMicrophone, onSuccess, error) {
        exec(onSuccess, error, "CordovaClipExport", "startCapture",[isMicrophone]);
    },
    stopCapture: function (onSuccess, error) {
        exec(onSuccess, error, "CordovaClipExport", "stopCapture");
    },
    stopCaptureOnGallery: function (onSuccess, error) {
        exec(onSuccess, error, "CordovaClipExport", "stopCaptureOnGallery");
    }

};

module.exports = ClipExport;
