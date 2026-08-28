package com.novastream.novastream.ui.screens.dashboard

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.MenuBottomSheet
import com.novastream.novastream.ui.screens.home.HomeScreen
import com.novastream.novastream.ui.screens.livetv.LiveTvScreen
import com.novastream.novastream.ui.screens.movies.MoviesScreen
import com.novastream.novastream.ui.screens.series.SeriesScreen

enum class DashboardTab(
    val title: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    HOME("Home", Icons.Filled.Home, Icons.Outlined.Home),
    LIVE_TV("Live TV", Icons.Filled.LiveTv, Icons.Outlined.LiveTv),
    MOVIES("Movies", Icons.Filled.Movie, Icons.Outlined.Movie),
    SERIES("Series", Icons.Filled.VideoLibrary, Icons.Outlined.VideoLibrary),
    MENU("Menu", Icons.Filled.Menu, Icons.Outlined.Menu)
}

@Composable
fun DashboardScreen(
    repository: NovaRepository,
    onNavigateSearch: () -> Unit,
    onNavigateDownloads: () -> Unit,
    onNavigateFavorites: () -> Unit,
    onNavigateHistory: () -> Unit,
    onNavigateProfile: () -> Unit,
    onNavigateSettings: () -> Unit,
    onPlayMedia: (ContentType, Int, String, String?, String) -> Unit,
    onOpenMovieDetails: (Int) -> Unit,
    onOpenSeriesDetails: (Int) -> Unit
) {
    var selectedTab by remember { mutableStateOf(DashboardTab.HOME) }
    var showMenuSheet by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = DarkBackground,
        bottomBar = {
            NavigationBar(
                containerColor = DarkSurfaceElevated.copy(alpha = 0.95f),
                tonalElevation = 8.dp,
                modifier = Modifier
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
                    .testTag("dashboard_nav_bar")
            ) {
                DashboardTab.entries.forEach { tab ->
                    val isSelected = selectedTab == tab && tab != DashboardTab.MENU
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = {
                            if (tab == DashboardTab.MENU) {
                                showMenuSheet = true
                            } else {
                                selectedTab = tab
                            }
                        },
                        icon = {
                            Icon(
                                imageVector = if (isSelected) tab.selectedIcon else tab.unselectedIcon,
                                contentDescription = tab.title,
                                modifier = Modifier.size(24.dp)
                            )
                        },
                        label = {
                            Text(
                                text = tab.title,
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                    fontSize = 11.sp
                                )
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = NovaCyan,
                            selectedTextColor = NovaCyan,
                            indicatorColor = NovaVioletDark.copy(alpha = 0.6f),
                            unselectedIconColor = TextSecondary,
                            unselectedTextColor = TextSecondary
                        ),
                        modifier = Modifier.testTag("nav_tab_${tab.name.lowercase()}")
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (selectedTab) {
                DashboardTab.HOME -> {
                    HomeScreen(
                        repository = repository,
                        onNavigateLiveTv = { selectedTab = DashboardTab.LIVE_TV },
                        onNavigateMovies = { selectedTab = DashboardTab.MOVIES },
                        onNavigateSeries = { selectedTab = DashboardTab.SERIES },
                        onNavigateSearch = onNavigateSearch,
                        onNavigateDownloads = onNavigateDownloads,
                        onPlayMedia = onPlayMedia,
                        onOpenMovieDetails = onOpenMovieDetails,
                        onOpenSeriesDetails = onOpenSeriesDetails
                    )
                }
                DashboardTab.LIVE_TV -> {
                    LiveTvScreen(
                        repository = repository,
                        onPlayChannel = { id, name, icon, url ->
                            onPlayMedia(ContentType.LIVE, id, name, icon, url)
                        }
                    )
                }
                DashboardTab.MOVIES -> {
                    MoviesScreen(
                        repository = repository,
                        onOpenMovieDetails = onOpenMovieDetails
                    )
                }
                DashboardTab.SERIES -> {
                    SeriesScreen(
                        repository = repository,
                        onOpenSeriesDetails = onOpenSeriesDetails
                    )
                }
                DashboardTab.MENU -> {
                    // Handled by bottom sheet
                }
            }
        }

        if (showMenuSheet) {
            MenuBottomSheet(
                onNavigateProfile = onNavigateProfile,
                onNavigateSettings = onNavigateSettings,
                onNavigateFavorites = onNavigateFavorites,
                onNavigateHistory = onNavigateHistory,
                onNavigateDownloads = onNavigateDownloads,
                onDismiss = { showMenuSheet = false }
            )
        }
    }
}
