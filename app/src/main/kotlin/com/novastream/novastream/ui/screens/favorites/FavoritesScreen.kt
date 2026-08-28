package com.novastream.novastream.ui.screens.favorites

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.PosterCard
import kotlinx.coroutines.launch

@Composable
fun FavoritesScreen(
    repository: NovaRepository,
    onPlayMedia: (ContentType, Int, String, String?, String) -> Unit,
    onOpenMovieDetails: (Int) -> Unit,
    onOpenSeriesDetails: (Int) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())
    var selectedTab by remember { mutableIntStateOf(0) } // 0: All, 1: Movies, 2: Series, 3: Live TV

    val filteredFavorites = remember(favorites, selectedTab) {
        when (selectedTab) {
            1 -> favorites.filter { it.type == ContentType.MOVIE.name }
            2 -> favorites.filter { it.type == ContentType.SERIES.name }
            3 -> favorites.filter { it.type == ContentType.LIVE.name }
            else -> favorites
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Favorite,
                        contentDescription = null,
                        tint = NovaPink,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "My List",
                        style = MaterialTheme.typography.titleLarge.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                    )
                }

                if (favorites.isNotEmpty()) {
                    IconButton(
                        onClick = {
                            coroutineScope.launch { repository.clearFavorites() }
                        },
                        modifier = Modifier.testTag("clear_favorites_btn")
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Clear all favorites",
                            tint = TextSecondary
                        )
                    }
                }
            }

            // Tabs
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = DarkSurfaceElevated,
                contentColor = NovaCyan,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
                    .clip(RoundedCornerShape(12.dp))
            ) {
                listOf("All", "Movies", "Series", "Live").forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = {
                            Text(
                                title,
                                fontWeight = if (selectedTab == index) FontWeight.Bold else FontWeight.Normal
                            )
                        },
                        modifier = Modifier.testTag("fav_tab_$index")
                    )
                }
            }

            // Content Grid
            if (filteredFavorites.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Favorite,
                            contentDescription = null,
                            tint = TextDisabled,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Your list is currently empty",
                            style = MaterialTheme.typography.bodyLarge.copy(color = TextSecondary)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Save movies, series and channels to watch anytime",
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )
                    }
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(130.dp),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 100.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filteredFavorites, key = { it.id }) { item ->
                        val type = try {
                            ContentType.valueOf(item.type)
                        } catch (e: Exception) {
                            ContentType.MOVIE
                        }

                        PosterCard(
                            title = item.title,
                            imageUrl = item.imageUrl,
                            rating = item.rating,
                            isFavorite = true,
                            onFavoriteToggle = {
                                coroutineScope.launch {
                                    repository.toggleFavorite(
                                        type = type,
                                        mediaId = item.mediaId,
                                        title = item.title,
                                        imageUrl = item.imageUrl,
                                        streamUrl = item.streamUrl,
                                        rating = item.rating
                                    )
                                }
                            },
                            onClick = {
                                when (type) {
                                    ContentType.MOVIE -> onOpenMovieDetails(item.mediaId)
                                    ContentType.SERIES -> onOpenSeriesDetails(item.mediaId)
                                    ContentType.LIVE -> onPlayMedia(type, item.mediaId, item.title, item.imageUrl, item.streamUrl ?: "")
                                }
                            },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }
}
