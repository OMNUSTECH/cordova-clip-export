package cordova.clip.export;

import android.Manifest
import android.app.Activity
import android.content.*
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.MediaStore
import android.util.DisplayMetrics
import android.util.Log
import org.apache.cordova.CallbackContext
import org.apache.cordova.CordovaPlugin
import org.apache.cordova.PluginResult
import org.json.JSONArray
import org.json.JSONException
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException


/**
 * This class echoes a string called from JavaScript.
 */
open class CordovaClipExport : CordovaPlugin(), ServiceConnection  {


    private val TAG = "ScreenRecord"
    private var mProjectionManager: MediaProjectionManager? = null
    private var mMediaRecorder: MediaRecorder? = null
    private var mMediaProjection: MediaProjection? = null
    private var mVirtualDisplay: VirtualDisplay? = null
    private var mScreenRecordService: ScreenRecordService? = null


    protected val permission = Manifest.permission.RECORD_AUDIO
    private var context: Context? = null

    private val FRAME_RATE = 60 // fps

    private val SCREEN_RECORD_CODE = 1000
    private val WRITE_EXTERNAL_STORAGE_CODE = 1001

    private var callbackContext: CallbackContext? = null
    private var saveOnGallery: Boolean = false
    private var recordAudio = false
    private var absPath: String? = null
    private var filePath: String? = null
    private var fileName: String? = null
    private var mUri: Uri? = null
    private var mWidth = 0
    private var mHeight = 0
    private val mBitRate = 6000000
    private var mScreenDensity = 0
    private var serviceStarted = false



    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        this.callbackContext = callbackContext;
        this.context = cordova.activity.applicationContext

        if(action == "startCapture") {
            recordAudio = args.getBoolean(0)
            this.startClipRecording();
            return true
        }

        if(action == "stopCapture") {
            saveOnGallery = false
            this.stopRecord();
            return true
        }

        if(action == "stopCaptureOnGallery") {
            saveOnGallery = true
            this.stopRecord();
            return true
        }

        if(action == "isAvailable") {
            callbackContext.success("Option is only available on iOS")
            return true
        }

        if(action == "isRecording") {
            if(serviceStarted) {
                callbackContext.success("Recording")
            }else {
                callbackContext.success("not Recording")
            }
            
            return true
        }


        if (action == "coolMethod") {
            val message = args.getString(0)
            this.coolMethod(message, callbackContext)
            return true
        }
        return false
    }

    private fun coolMethod(message: String?, callbackContext: CallbackContext) {
        if (message != null && message.length > 0) {
            callbackContext.success(message)
        } else {
            callbackContext.error("Expected one non-empty string argument.")
        }
    }


    private fun startClipRecording(){
        if(cordova != null) {
            try {
                if(!serviceStarted) {
                    startForegroundService();
                } else {
                    callScreenRecord();
                }
            } catch (e: IllegalArgumentException) {
                callbackContext?.error("Illegal Argument Exception.")
                val result = PluginResult(PluginResult.Status.ERROR)
                callbackContext?.sendPluginResult(result)
            }
        }
    }


    private fun startForegroundService() {
        val activity = cordova.activity
        val bindIntent = Intent(activity, ScreenRecordService::class.java)
        activity.applicationContext.bindService(bindIntent,
            this, Context.BIND_AUTO_CREATE)
        activity.applicationContext.startService(bindIntent)
    }


    override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
        val binder = service as ScreenRecordService.LocalBinder
        mScreenRecordService = binder.getService()
        serviceStarted = true
        callScreenRecord()
    }

    override fun onServiceDisconnected(name: ComponentName?) {
        serviceStarted = false
    }


    private fun callScreenRecord() {
        val activity: Activity = cordova.activity

        // Create notification
        mScreenRecordService?.showNotification("ClipExport",
            "Recording",cordova.context)

        // Get display metrics
        val displayMetrics = DisplayMetrics()
        activity.windowManager
            .defaultDisplay.getMetrics(displayMetrics)
        mScreenDensity = displayMetrics.densityDpi
        mWidth = displayMetrics.widthPixels
        mHeight = displayMetrics.heightPixels

        // Create Media Recorder object
        mMediaRecorder = MediaRecorder()
        mProjectionManager =
            activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        // Ask for write to external storage permission
        cordova.requestPermission(
            this, WRITE_EXTERNAL_STORAGE_CODE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )

        // Ask for screen recording permission
        val captureIntent: Intent = mProjectionManager!!.createScreenCaptureIntent()
        cordova.startActivityForResult(this, captureIntent, SCREEN_RECORD_CODE)
    }


    @Throws(JSONException::class)
    override fun onRequestPermissionResult(
        requestCode: Int,
        permissions: Array<String?>?, grantResults: IntArray
    ) {
        if (requestCode == WRITE_EXTERNAL_STORAGE_CODE) {
            if (grantResults.size == 1 && grantResults[0] ==
                PackageManager.PERMISSION_GRANTED
            ) {
                Log.d(TAG, "Permission for external storage write granted.")
            } else {
                Log.d(TAG, "Permission for external storage write denied.")
                callbackContext!!.error("Permission for external storage write denied.")
            }
        }
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == SCREEN_RECORD_CODE) {

            // Create output file path
            createVideoFile()

            // Set MediaRecorder options
            try {
                if (recordAudio) {
                    mMediaRecorder!!.setAudioSource(MediaRecorder.AudioSource.DEFAULT)
                    mMediaRecorder!!.setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT)
                }
                mMediaRecorder!!.setVideoSource(MediaRecorder.VideoSource.SURFACE)
                mMediaRecorder!!.setOutputFormat(MediaRecorder.OutputFormat.DEFAULT)

                if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    mMediaRecorder!!.setOutputFile(
                        context!!.contentResolver
                            .openFileDescriptor(mUri!!, "rw")
                            ?.fileDescriptor);
                } else {
                    mMediaRecorder!!.setOutputFile(filePath);
                }
                mMediaRecorder!!.setVideoSize(mWidth, mHeight)
                mMediaRecorder!!.setVideoEncoder(MediaRecorder.VideoEncoder.DEFAULT)
                mMediaRecorder!!.setVideoEncodingBitRate(mBitRate)
                mMediaRecorder!!.setVideoFrameRate(FRAME_RATE)
                mMediaRecorder!!.prepare()
            } catch (e: java.lang.Exception) {
                e.printStackTrace()
            }

            // Create virtual display
            mMediaProjection = mProjectionManager!!.getMediaProjection(resultCode, data!!)
            mMediaProjection!!.createVirtualDisplay(
                "MainActivity",
                mWidth, mHeight, mScreenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mMediaRecorder!!.surface, null, null
            )



            mMediaRecorder!!.setOnErrorListener { mediaRecorder, what, extra ->
                callbackContext!!.error("Error: $what, extra = $what")
                Log.d(
                    TAG,
                    "onError: what = $what extra = $what"
                )
            }

            mMediaRecorder!!.setOnInfoListener { mr, what, extra ->
                Log.i(
                    TAG,
                    "onInfo: what = $what extra = $what"
                )
            }


            // Start recording
            mMediaRecorder!!.start()
            Log.d(TAG, "ClipExport service is running")
            callbackContext!!.success("ClipExport service is running")
            if (mMediaProjection == null) {
                Log.e(TAG, "No screen recording in process")
                callbackContext!!.error("No screen recording in process")
                return
            }
        }
    }

    private fun createVideoFile() {
        try {

            val recordingFile = ("ClipExportREC${System.currentTimeMillis()}.mp4")
            val newPath = cordova.context.cacheDir

            // Create output file path
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues()
                contentValues.put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/" + "Clip")
                contentValues.put(MediaStore.Video.Media.IS_PENDING, true)
                contentValues.put(MediaStore.Video.Media.TITLE, fileName)
                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                mUri = context!!.contentResolver
                    .insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues)
                Log.d(TAG, "Output file: " + mUri.toString())
                filePath = mUri.toString()
            } else {
                val file = File(context!!.getExternalFilesDir("Clip"), recordingFile)
                filePath = file.absolutePath
                Log.d(TAG, "Output file: $filePath")
            }

            absPath  = newPath.absolutePath
            fileName = recordingFile

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }


    private fun stopRecord() {
        if (mVirtualDisplay != null) {
            mVirtualDisplay?.release()
            mVirtualDisplay = null
        }
        if (mMediaProjection != null) {
            mMediaProjection!!.stop()
            mMediaProjection = null
        }
        if (mMediaRecorder != null) {
            mMediaRecorder!!.setOnErrorListener(null)
            mMediaRecorder!!.setOnInfoListener(null)
            mMediaRecorder!!.stop()
            mMediaRecorder!!.reset()
            mMediaRecorder!!.release()
        } else {
            callbackContext!!.error("No screen recording in process")
        }
        mScreenRecordService!!.removeNotification()
        

        if (saveOnGallery) {
            // Add video to gallery

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Update video in gallery
                val contentValues = ContentValues()
                contentValues.put(MediaStore.Video.Media.IS_PENDING, false)
                context!!.contentResolver.update(mUri!!, contentValues, null, null)
                filePath = mUri.toString()
            } else {
                // Add video to gallery
                val contentValues = ContentValues()
                contentValues.put(MediaStore.Video.Media.TITLE, fileName)
                contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
                contentValues.put(MediaStore.Video.Media.DATA, filePath)
                context!!.contentResolver
                    .insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues)
            }

            callbackContext!!.success("Screen recording finished.")
        } else {
            val f = File(filePath)
            val binary = fullyReadFileToBytes(f)
            callbackContext!!.success(binary)
        }
        
        Log.d(TAG, "Screen recording finished.")
        
    }


    @Throws(IOException::class)
    open fun copy(src: File?, dst: File?) {
        FileInputStream(src).use { `in` ->
            FileOutputStream(dst).use { out ->
                // Transfer bytes from in to out
                val buf = ByteArray(1024)
                var len: Int
                while (`in`.read(buf).also { len = it } > 0) {
                    out.write(buf, 0, len)
                }
            }
        }
    }


    @Throws(IOException::class)
    open fun fullyReadFileToBytes(f: File): ByteArray? {
        val size = f.length().toInt()
        val bytes = ByteArray(size)
        val tmpBuff = ByteArray(size)
        val fis = FileInputStream(f)
        try {
            var read = fis.read(bytes, 0, size)
            if (read < size) {
                var remain = size - read
                while (remain > 0) {
                    read = fis.read(tmpBuff, 0, remain)
                    System.arraycopy(tmpBuff, 0, bytes, size - remain, read)
                    remain -= read
                }
            }
        } catch (e: IOException) {
            throw e
        } finally {
            fis.close()
        }
        return bytes
    }
}