package com.novastream.novastream.core.data.models

import kotlinx.serialization.Serializable

@Serializable
data class UserSession(
    val id: String,
    val profileName: String = "NovaStream User",
    val username: String = "",
    val password: String = "",
    val serverUrl: String = "",
    val isDemo: Boolean = false,
    val isM3u: Boolean = false,
    val m3uUrl: String = "",
    val expiryDate: String = "Never (Lifetime)",
    val maxConnections: Int = 5,
    val activeConnections: Int = 1,
    val isTrial: Boolean = false,
    val status: String = "Active",
    val createdAt: Long = System.currentTimeMillis()
)

@Serializable
data class SettingsState(
    val streamFormat: String = "HLS", // "HLS" or "TS"
    val bufferSizeMs: Int = 1500,
    val hardwareAcceleration: Boolean = true,
    val defaultAspectRatio: String = "Fit (16:9)",
    val parentalPin: String = "",
    val parentalEnabled: Boolean = false,
    val hideAdultContent: Boolean = false,
    val incognito: Boolean = false,
    val appLanguage: String = "English"
)

enum class SortOption(val displayName: String) {
    DEFAULT("Default"),
    RATING_DESC("Highest Rated"),
    NAME_ASC("Name (A to Z)"),
    DATE_DESC("Recently Added")
}

data class MediaFilterState(
    val selectedCategory: String? = null,
    val selectedGenre: String? = null,
    val selectedYear: String? = null,
    val sortOption: SortOption = SortOption.DEFAULT,
    val query: String = ""
)
