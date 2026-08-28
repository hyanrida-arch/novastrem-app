package com.novastream.novastream.core.data.models

import kotlinx.serialization.Serializable

@Serializable
data class LiveCategory(
    val categoryId: String,
    val categoryName: String
)

@Serializable
data class LiveChannel(
    val streamId: Int,
    val name: String,
    val categoryId: String,
    val streamIcon: String? = null,
    val streamType: String = "live",
    val num: Int = 0,
    val epgChannelId: String? = null,
    val streamUrl: String = ""
)

@Serializable
data class EpgProgram(
    val title: String,
    val startTime: Long,
    val endTime: Long,
    val description: String = ""
) {
    val progress: Float
        get() {
            val now = System.currentTimeMillis()
            if (now <= startTime) return 0f
            if (now >= endTime) return 1f
            val total = (endTime - startTime).toFloat()
            return if (total > 0) ((now - startTime) / total).coerceIn(0f, 1f) else 0f
        }
}

@Serializable
data class VodCategory(
    val categoryId: String,
    val categoryName: String
)

@Serializable
data class Movie(
    val streamId: Int,
    val name: String,
    val categoryId: String,
    val streamIcon: String? = null,
    val rating: Double = 0.0,
    val addedAt: Long = System.currentTimeMillis(),
    val containerExtension: String = "mp4",
    val streamUrl: String = ""
)

@Serializable
data class MovieDetails(
    val streamId: Int,
    val name: String,
    val description: String = "",
    val genre: String = "",
    val director: String = "",
    val releaseDate: String = "",
    val rating: Double = 0.0,
    val duration: String = "",
    val coverUrl: String? = null,
    val backdropUrl: String? = null,
    val streamUrl: String = ""
)

@Serializable
data class SeriesCategory(
    val categoryId: String,
    val categoryName: String
)

@Serializable
data class Series(
    val seriesId: Int,
    val name: String,
    val categoryId: String,
    val cover: String? = null,
    val rating: Double = 0.0,
    val lastModified: Long = System.currentTimeMillis(),
    val numSeasons: Int = 1
)

@Serializable
data class SeriesDetails(
    val seriesId: Int,
    val name: String,
    val description: String = "",
    val genre: String = "",
    val releaseDate: String = "",
    val rating: Double = 0.0,
    val coverUrl: String? = null,
    val backdropUrl: String? = null,
    val episodesBySeason: Map<Int, List<Episode>> = emptyMap()
)

@Serializable
data class Episode(
    val episodeId: Int,
    val title: String,
    val season: Int,
    val episodeNum: Int,
    val duration: String = "",
    val plot: String = "",
    val coverUrl: String? = null,
    val streamUrl: String = ""
)
