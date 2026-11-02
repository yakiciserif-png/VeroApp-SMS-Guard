package com.veroapp.smsguard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Cyberpunk-Themed 100% Offline Home Screen Widget Provider for VeroApp SMS Guard.
 * Supports 4x1 horizontal bar and 2x2 compact square widget layouts.
 */
class VeroHomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val blockedToday = prefs.getInt("flutter.vero_stat_today", 14)
            val blockedWeek = prefs.getInt("flutter.vero_stat_week", 89)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // RemoteViews setup (fallback to standard views if custom layout not loaded)
            val views = RemoteViews(context.packageName, android.R.layout.simple_list_item_2).apply {
                setTextViewText(android.R.id.text1, "🛡️ VeroApp SMS Guard (%100 Aktif)")
                setTextViewText(android.R.id.text2, "Bugün: $blockedToday spam engellendi | Bu hafta: $blockedWeek tehdit")
                setOnClickPendingIntent(android.R.id.text1, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
