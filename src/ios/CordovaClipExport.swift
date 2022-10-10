//
//  CordovaClipExport.swift
//  
//
//  Created by PEDRO HENRIQUE FLORENCIO SOARES on 10/10/22.
//

import UIKit
import ReplayKit
import Photos

@available(iOS 15.0, *)
class CordovaClipExport : CDVPlugin, NSObject,  RPScreenRecorderDelegate, RPPreviewViewControllerDelegate
{
    var recorder = RPScreenRecorder.shared()
    var fileName: String = ""
    var videoRecorded: NSData? = nil
    
    
    @objc func startScreenRecording(command: CDVInvokedUrlCommand) {

        var pluginResult = CDVPluginResult(
        status: CDVCommandStatus_ERROR
        )

        if isRecording() {

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsString: "Attempting To start recording while recording is in progress"
            )

            self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: command.callbackId
            )            


            print("Attempting To start recording while recording is in progress")
            return
        }
        if #available(iOS 15.0, *) {
            recorder.startClipBuffering { err in
                if err != nil {

                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAsString: "Attempting To start recording while recording is in progress"
                    )

                    self.commandDelegate!.sendPluginResult(
                    pluginResult,
                    callbackId: command.callbackId)   

                    print("Error Occured trying to start rolling clip: \(String(describing: err))")
                    //Would be ideal to let the user know about this with an alert
                }

                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsString: "Rolling Clip started successfully"
                )

                self.commandDelegate!.sendPluginResult(
                pluginResult,
                callbackId: command.callbackId
                )     


                print("Rolling Clip started successfully")
            }
        }
    }
    
    @objc  func stopScreenRecording(command: CDVInvokedUrlCommand) {
        if !isRecording() {
            
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsString: "Attempting the stop recording without an on going recording session"
            )

            self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: command.callbackId
            )

            
            print("Attempting the stop recording without an on going recording session")
            return
        }
        if #available(iOS 15.0, *) {
            recorder.stopClipBuffering { [self] err in
                if err != nil {
                    
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_ERROR,
                        messageAsString: "Failed to stop screen recording"
                    )

                    self.commandDelegate!.sendPluginResult(
                    pluginResult,
                    callbackId: command.callbackId)
                    
                    print("Failed to stop screen recording")
                    // Would be ideal to let user know about this with an alert
                }
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsString: "Rolling Clip stopped successfully"
                )

                self.commandDelegate!.sendPluginResult(
                pluginResult,
                callbackId: command.callbackId
                )

                print("Rolling Clip stopped successfully")
                
            }
        }
    }
    
    // Provide the URL to which the clip needs to be extracted to
    // Would be preferred to add it to the NSTemporaryDirectory
    @objc  func exportClip(command: CDVInvokedUrlCommand) {
        if !isRecording() {
            
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsString: "Attemping to export clip while rolling clip buffer is turned off"
            )

            self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: command.callbackId
            )
            
            print("Attemping to export clip while rolling clip buffer is turned off")
            return videoRecorded!
        }
        // internal for which the clip is to be extracted
        // Max Value: 15 sec
        let interval = TimeInterval(15)
        
        let clipURL = getDirectory()
        
        print("Generating clip at URL: ", clipURL)
        if #available(iOS 15.0, *) {
            recorder.exportClip(to: clipURL, duration: interval) {[weak self]error in
                if error != nil {
                    
                    pluginResult = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAsString: "Error attempting export clip"
                    )

                    self.commandDelegate!.sendPluginResult(
                    pluginResult,
                    callbackId: command.callbackId
                    )
                    
                    print("Error attempting export clip")
                    // would be ideal to show an alert letting user know about the failure
                }
                self?.saveToPhotos(tempURL: clipURL)
                self?.videoRecorded = NSData(contentsOf: clipURL)
            }
        }

        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAsArrayBuffer: videoRecorded!
        )
        //return videoRecorded!
    }
    
    private func isRecording() -> Bool {
        return recorder.isRecording
    }
    
    private func getDirectory() -> URL {
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let stringDate = formatter.string(from: Date())
        fileName = String.localizedStringWithFormat("output-%@", stringDate)
        tempPath.appendPathComponent(String.localizedStringWithFormat("output-%@.mp4", stringDate))
        return tempPath 
    }

    
    private func saveToPhotos(tempURL: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
        } completionHandler: { success, error in
            if success == true {
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsString: "Saved rolling clip to photos"
                )

                self.commandDelegate!.sendPluginResult(
                pluginResult,
                callbackId: command.callbackId
                )
                
                print("Saved rolling clip to photos")
                
            } else {
                
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAsString: "Error exporting clip to Photos \(String(describing: error))"
                )

                self.commandDelegate!.sendPluginResult(
                pluginResult,
                callbackId: command.callbackId
                )
                print("Error exporting clip to Photos \(String(describing: error))")
            }
        }
    }
   
    
}
