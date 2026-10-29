package com.net.convertix.scissor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        criarCanalDeAvisos()
    }

    /**
     * Canal dos pushes do Razor (RAZ-11), o mesmo que a API manda em android.notification.channel_id.
     * Conteúdo privado na tela bloqueada: com bloqueio seguro aparece só que há um aviso do app.
     */
    private fun criarCanalDeAvisos() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel("razor_avisos", "Avisos do Razor", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Lembretes, confirmações e mudanças nos seus horários"
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(canal)
    }
}
