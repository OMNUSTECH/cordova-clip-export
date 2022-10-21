//
//  CordovaClipExport.swift
//  
//
//  Created by Diógenes Dauster on 10/10/22.
//

import UIKit
import ReplayKit
import AVFoundation
import Photos

class CordovaClipExport : CDVPlugin
{
    let recorder = RPScreenRecorder.shared()
    
    var videoOutputURL : URL?
    var videoWriter : AVAssetWriter?

    var audioInput:AVAssetWriterInput!
    var videoWriterInput : AVAssetWriterInput?
    var recordAudio: Bool = false;

    
    @objc(isAvailable:)
       func isAvailable(command: CDVInvokedUrlCommand) {
           let recorder = RPScreenRecorder.shared()
           if #available(iOS 11.0, *) {
               let available = recorder.isAvailable;
               let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: available)
               self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
           } else {
               let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: false)
               self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
           }
    }

    @objc(isRecording:)
    func isRecording(_ command: CDVInvokedUrlCommand) {
        let recorder = RPScreenRecorder.shared()
        let recording = recorder.isRecording;
        let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: recording)
        self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
    }

    @objc(startCapture:)
    func startCapture(_ command: CDVInvokedUrlCommand) {

        // Parâmetros de entrada
        
        let isMicOn: Bool = command.arguments[0] as? Bool ?? false

        self.recordAudio = isMicOn

        // Monta o caminho que onde será salvo a video da screen
        
        let nameVideo = "recordClip"
        
        let documentsPath = NSString(format: "%@%@.mp4",NSTemporaryDirectory(), nameVideo) //let documentsPath = NSSearchPathForDirectoriesInDomains(., .userDomainMask, true)[0] as NSString
        
        self.videoOutputURL = URL(fileURLWithPath: documentsPath as String)
        
        // Excluir o registro se já existe
        do {
            try FileManager.default.removeItem(at: self.videoOutputURL!)
        } catch {}

        // Cria o objeto que irar criar o arquivo de media no formato .mp4

        do {
            try videoWriter = AVAssetWriter(outputURL: self.videoOutputURL!, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            print("Error opening video file", writerError);

            let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: false)
            self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)


            self.videoWriter = nil;
            return;
        }


        //Cria as configuraçõesde video
        
        if #available(iOS 11.0, *) {
            
            let codec = AVVideoCodecType.h264;
            
            let screenSize = self.webView.bounds  //UIScreen.main.bounds
            
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : codec,
                AVVideoWidthKey  : screenSize.width,
                AVVideoHeightKey : screenSize.height
            ]
                        
            if(recordAudio){
                
                let audioOutputSettings: [String : Any] = [
                    AVNumberOfChannelsKey : 2,
                    AVFormatIDKey : kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                ]
                
                audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
                videoWriter?.add(audioInput)
            
            }

          //Create the asset writer input object whihc is actually used to write out the video
         videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
         videoWriterInput?.expectsMediaDataInRealTime = true
         videoWriter?.add(videoWriterInput!);
            
        }        


        // Start da captura de tela 

        if #available(iOS 11.0, *) {


            if(recordAudio){
                RPScreenRecorder.shared().isMicrophoneEnabled=true;
            }else{
                RPScreenRecorder.shared().isMicrophoneEnabled=false;

            }
            
            RPScreenRecorder.shared().startCapture(
            handler: { (cmSampleBuffer, rpSampleType, error) in
                guard error == nil else {
                    print("Error starting capture");                    
                    
                    let pluginResult = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAs: false)
                    self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                    return;
                }

            
                switch rpSampleType {
                case RPSampleBufferType.video:
                    print("writing sample....");
                    if self.videoWriter?.status == AVAssetWriter.Status.unknown {

                        if (( self.videoWriter?.startWriting ) != nil) {
                            print("Starting writing unknown");
                            
                            let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: true)
                            self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                            
                            self.videoWriter?.startWriting()
                            self.videoWriter?.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                    }

                    if self.videoWriter?.status == AVAssetWriter.Status.writing {
                        if (self.videoWriterInput?.isReadyForMoreMediaData == true) {
                            print("Writting a sample Video");

                            if  self.videoWriterInput?.append(cmSampleBuffer) == false {
                                print(" we have a problem writing video")                                

                                let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: false)
                                self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                            }
                        }
                    }
                case RPSampleBufferType.audioApp:
                    
                    print("audioApp ....");

                case RPSampleBufferType.audioMic:
                    
                    print("audioMic ....");

                default:
                   print("not a video sample, so ignore");
                }
                
                
                
            } ){(error) in
                        guard error == nil else {
                           //Handle error
                           print("Screen record not allowed");                           
                           let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs: false)
                           self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                           return;
                       }
                   }
        } else {
            //Fallback on earlier versions
        }        

    }

    @objc(stopCapture:)
    func stopCapture(command: CDVInvokedUrlCommand) {
        
        //Para de gravar a screen
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture( handler: { (error) in
                guard error == nil else {
                    print("Error stop capture");                    
                    
                    let pluginResult = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAs: "Error stop capture")
                    self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                    return;
                }
                print("stopping recording");
            })
        } else {
                //  Fallback on earlier versions
        }

        self.videoWriterInput?.markAsFinished();
        self.videoWriter?.finishWriting {
            print("finished writing video");
            
            do {
                let videoRecorded = try Data.init(contentsOf: self.videoOutputURL!)

                let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAsArrayBuffer:  videoRecorded)
                self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)

            }catch {
                let pluginResult = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAs:  "Error to return the binary")
                self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)

            }  
        }
    }


    @objc(stopCaptureOnGallery:)
    func stopCaptureOnGallery(command: CDVInvokedUrlCommand) {
        
        //Para de gravar a screen
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture( handler: { (error) in
                guard error == nil else {
                    print("Error stop capture");                    
                    
                    let pluginResult = CDVPluginResult(status:CDVCommandStatus_ERROR, messageAs: "Error stop capture")
                    self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
                    return;
                }
                print("stopping recording");
            })
        } else {
                //  Fallback on earlier versions
        }

        self.videoWriterInput?.markAsFinished();
        self.videoWriter?.finishWriting {
            print("finished writing video");

            print(self.videoOutputURL!)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL!)
            } completionHandler: { success, error in
                if success == true {
                    self.showAlertMessage(message: "Your video was successfully saved", viewController: self.viewController)
                    print("Saved rolling clip to photos")

                    let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs:  true)
                    self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)    


                } else {
                    print("Error exporting clip to Photos \(String(describing: error))")
            
                    let pluginResult = CDVPluginResult(status:CDVCommandStatus_OK, messageAs:  false)
                    self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)    

                }
            }            
    
        }
    }    


    func showAlertMessage(message:String, viewController: UIViewController) {
        DispatchQueue.main.async {
            let alertMessage = UIAlertController(title: "", message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .cancel)

            alertMessage.addAction(cancelAction)

            viewController.present(alertMessage, animated: true, completion: nil)
        }
    }
    

    func loadFileFromLocalPath(_ localFilePath: String) ->Data? {
       return try? Data(contentsOf: URL(fileURLWithPath: localFilePath))
    }    
    
    
}
