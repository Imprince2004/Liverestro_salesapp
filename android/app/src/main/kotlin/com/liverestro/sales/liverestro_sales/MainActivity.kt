package com.liverestro.sales.liverestro_sales

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.liverestro.sales/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showSmsNotification") {
                val title = call.argument<String>("title") ?: "Messages • LiveRestro"
                val body = call.argument<String>("body") ?: "Your OTP is here"
                val otp = call.argument<String>("otp") ?: ""
                showNativeSmsNotification(title, body, otp)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun showNativeSmsNotification(title: String, body: String, otp: String) {
        val channelId = "liverestro_sms_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "LiveRestro SMS Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Cellular SMS style notifications for LiveRestro OTP"
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.sym_action_chat)
            .setContentTitle(title)
            .setContentText("The LiveRestro OTP is : $otp")
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        notificationManager.notify(1001, notification)
    }
}
