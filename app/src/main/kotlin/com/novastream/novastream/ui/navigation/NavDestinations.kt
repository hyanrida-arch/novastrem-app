package com.novastream.novastream.ui.navigation

import kotlinx.serialization.Serializable

sealed interface Screen {
    @Serializable
    data object Startup : Screen

    @Serializable
    data object Login : Screen

    @Serializable
    data object Dashboard : Screen

    @Serializable
    data object Search : Screen

    @Serializable
    data object Downloads : Screen

    @Serializable
    data object Favorites : Screen

    @Serializable
    data object History : Screen

    @Serializable
    data object Profile : Screen

    @Serializable
    data object Settings : Screen

    @Serializable
    data class MovieDetails(val movieId: Int) : Screen

    @Serializable
    data class SeriesDetails(val seriesId: Int) : Screen

    @Serializable
    data class Player(
        val type: String,
        val mediaId: Int,
        val title: String,
        val imageUrl: String = "",
        val streamUrl: String
    ) : Screen
}
