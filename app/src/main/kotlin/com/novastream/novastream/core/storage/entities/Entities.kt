package com.novastream.novastream.core.storage.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favorites")
data class FavoriteEntity(
    @PrimaryKey val id: String, // "$type-$mediaId"
    val mediaId: Int,
    val type: String, // LIVE, MOVIE, SERIES
    val title: String,
    val imageUrl: String? = null,
    val streamUrl: String? = null,
    val rating: Double = 0.0,
    val categoryName: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "history")
data class HistoryEntity(
    @PrimaryKey val id: String, // "$type-$mediaId"
    val mediaId: Int,
    val type: String, // LIVE, MOVIE, SERIES
    val title: String,
    val imageUrl: String? = null,
    val streamUrl: String,
    val positionMs: Long = 0L,
    val durationMs: Long = 0L,
    val updatedAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "downloads")
data class DownloadTaskEntity(
    @PrimaryKey val id: String,
    val mediaId: Int,
    val type: String,
    val title: String,
    val imageUrl: String? = null,
    val streamUrl: String,
    val localFilePath: String = "",
    val progress: Float = 0f,
    val status: String = "QUEUED", // QUEUED, DOWNLOADING, COMPLETED, FAILED, PAUSED
    val fileSizeBytes: Long = 0L,
    val downloadedBytes: Long = 0L,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "user_session")
data class UserSessionEntity(
    @PrimaryKey val id: String,
    val profileName: String,
    val username: String,
    val password: String,
    val serverUrl: String,
    val isDemo: Boolean,
    val isM3u: Boolean,
    val m3uUrl: String,
    val expiryDate: String,
    val maxConnections: Int,
    val activeConnections: Int,
    val isTrial: Boolean,
    val status: String,
    val createdAt: Long
)

@Entity(tableName = "settings")
data class SettingsEntity(
    @PrimaryKey val id: Int = 1,
    val streamFormat: String = "HLS",
    val bufferSizeMs: Int = 1500,
    val hardwareAcceleration: Boolean = true,
    val defaultAspectRatio: String = "Fit (16:9)",
    val parentalPin: String = "",
    val parentalEnabled: Boolean = false,
    val hideAdultContent: Boolean = false,
    val incognito: Boolean = false,
    val appLanguage: String = "English"
)
