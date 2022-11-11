package cordova.clip.export;

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder


class ScreenRecordService : Service() {
    private val TAG = "ScreenRecordService"
    private var mNotificationManager: NotificationManager? = null

    private var pendingIntent: PendingIntent? = null
    private val NOTIFICATION = 1000
    private val nCHANNELID = "cordova.clip.export"

    // Binder given to clients
    private val binder = LocalBinder()

    /**
     * Class used for the client Binder.  Because we know this service always
     * runs in the same process as its clients, we don't need to deal with IPC.
     */
    inner class LocalBinder: Binder() {
        // Return this instance of LocalService so clients can call public methods
        fun getService(): ScreenRecordService = this@ScreenRecordService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        mNotificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Screen Recording"
            val chan = NotificationChannel(
                nCHANNELID, channelName,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            mNotificationManager!!.createNotificationChannel(chan)
        }
    }

    fun showNotification(title:CharSequence, text: CharSequence, context: Context) {

        try {
            var mainActivity: Class<*>
            val launchIntent: Intent? = context.packageManager.
            getLaunchIntentForPackage(context.packageName)
            val className: String? = launchIntent?.component?.className
            Class.forName(className!!).also {  mainActivity = it };

            pendingIntent =
                Intent(this, mainActivity).let { notificationIntent ->
                    PendingIntent.getActivity(this, 0, notificationIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT)
                }

            val notiBuilder: Notification.Builder = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this,nCHANNELID)
            } else {
                Notification.Builder(this)
            }
            val notification: Notification = notiBuilder
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pendingIntent)
                .build()

            startForeground(NOTIFICATION, notification)
        }catch (e: Exception) {
            e.printStackTrace()
        }

    }

    fun removeNotification(){

        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(Service.STOP_FOREGROUND_REMOVE)
        }else {
            stopSelf(NOTIFICATION)
        }
        mNotificationManager!!.cancel(NOTIFICATION)
    }


}