package com.novastream.novastream

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.theme.DarkBackground
import com.novastream.novastream.core.theme.NovaStreamTheme
import com.novastream.novastream.ui.navigation.Screen
import com.novastream.novastream.ui.screens.auth.LoginScreen
import com.novastream.novastream.ui.screens.dashboard.DashboardScreen
import com.novastream.novastream.ui.screens.details.MovieDetailsScreen
import com.novastream.novastream.ui.screens.details.SeriesDetailsScreen
import com.novastream.novastream.ui.screens.downloads.DownloadsScreen
import com.novastream.novastream.ui.screens.favorites.FavoritesScreen
import com.novastream.novastream.ui.screens.history.HistoryScreen
import com.novastream.novastream.ui.screens.player.PlayerScreen
import com.novastream.novastream.ui.screens.profile.ProfileScreen
import com.novastream.novastream.ui.screens.search.SearchScreen
import com.novastream.novastream.ui.screens.settings.SettingsScreen
import com.novastream.novastream.ui.screens.startup.InitializationScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as NovaStreamApp
        val repository = app.repository

        setContent {
            NovaStreamTheme {
                Surface(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(DarkBackground),
                    color = DarkBackground
                ) {
                    NovaStreamAppContent(repository)
                }
            }
        }
    }
}

@Composable
fun NovaStreamAppContent(repository: com.novastream.novastream.core.storage.NovaRepository) {
    val navController = rememberNavController()
    val activeSession by repository.activeSession.collectAsStateWithLifecycle()

    NavHost(
        navController = navController,
        startDestination = Screen.Startup,
        enterTransition = { fadeIn(animationSpec = tween(250)) },
        exitTransition = { fadeOut(animationSpec = tween(250)) }
    ) {
        composable<Screen.Startup> {
            InitializationScreen(
                onInitialized = {
                    if (activeSession != null) {
                        navController.navigate(Screen.Dashboard) {
                            popUpTo(Screen.Startup) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.Login) {
                            popUpTo(Screen.Startup) { inclusive = true }
                        }
                    }
                }
            )
        }

        composable<Screen.Login> {
            LoginScreen(
                repository = repository,
                onLoginSuccess = {
                    navController.navigate(Screen.Dashboard) {
                        popUpTo(Screen.Login) { inclusive = true }
                    }
                }
            )
        }

        composable<Screen.Dashboard> {
            DashboardScreen(
                repository = repository,
                onNavigateSearch = { navController.navigate(Screen.Search) },
                onNavigateDownloads = { navController.navigate(Screen.Downloads) },
                onNavigateFavorites = { navController.navigate(Screen.Favorites) },
                onNavigateHistory = { navController.navigate(Screen.History) },
                onNavigateProfile = { navController.navigate(Screen.Profile) },
                onNavigateSettings = { navController.navigate(Screen.Settings) },
                onPlayMedia = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                },
                onOpenMovieDetails = { movieId ->
                    navController.navigate(Screen.MovieDetails(movieId))
                },
                onOpenSeriesDetails = { seriesId ->
                    navController.navigate(Screen.SeriesDetails(seriesId))
                }
            )
        }

        composable<Screen.Search> {
            SearchScreen(
                repository = repository,
                onPlayMedia = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                },
                onOpenMovieDetails = { movieId -> navController.navigate(Screen.MovieDetails(movieId)) },
                onOpenSeriesDetails = { seriesId -> navController.navigate(Screen.SeriesDetails(seriesId)) }
            )
        }

        composable<Screen.Downloads> {
            DownloadsScreen(
                repository = repository,
                onPlayOfflineMedia = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                }
            )
        }

        composable<Screen.Favorites> {
            FavoritesScreen(
                repository = repository,
                onPlayMedia = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                },
                onOpenMovieDetails = { movieId -> navController.navigate(Screen.MovieDetails(movieId)) },
                onOpenSeriesDetails = { seriesId -> navController.navigate(Screen.SeriesDetails(seriesId)) }
            )
        }

        composable<Screen.History> {
            HistoryScreen(
                repository = repository,
                onPlayMedia = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                }
            )
        }

        composable<Screen.Profile> {
            ProfileScreen(
                repository = repository,
                onLogout = {
                    navController.navigate(Screen.Login) {
                        popUpTo(Screen.Dashboard) { inclusive = true }
                    }
                }
            )
        }

        composable<Screen.Settings> {
            SettingsScreen(
                repository = repository
            )
        }

        composable<Screen.MovieDetails> { backStackEntry ->
            val route = backStackEntry.toRoute<Screen.MovieDetails>()
            MovieDetailsScreen(
                movieId = route.movieId,
                repository = repository,
                onBackClick = { navController.popBackStack() },
                onPlayMovie = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                }
            )
        }

        composable<Screen.SeriesDetails> { backStackEntry ->
            val route = backStackEntry.toRoute<Screen.SeriesDetails>()
            SeriesDetailsScreen(
                seriesId = route.seriesId,
                repository = repository,
                onBackClick = { navController.popBackStack() },
                onPlayEpisode = { type, id, title, icon, url ->
                    navController.navigate(
                        Screen.Player(
                            type = type.name,
                            mediaId = id,
                            title = title,
                            imageUrl = icon ?: "",
                            streamUrl = url
                        )
                    )
                }
            )
        }

        composable<Screen.Player> { backStackEntry ->
            val route = backStackEntry.toRoute<Screen.Player>()
            val type = try {
                ContentType.valueOf(route.type)
            } catch (e: Exception) {
                ContentType.MOVIE
            }
            PlayerScreen(
                type = type,
                mediaId = route.mediaId,
                title = route.title,
                imageUrl = route.imageUrl,
                streamUrl = route.streamUrl,
                repository = repository,
                onBackClick = { navController.popBackStack() }
            )
        }
    }
}
