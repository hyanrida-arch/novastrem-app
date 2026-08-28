package com.novastream.novastream.ui.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.data.models.LiveChannel
import com.novastream.novastream.core.data.models.Movie
import com.novastream.novastream.core.data.models.Series
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.*
import kotlinx.coroutines.launch

@Composable
fun HomeScreen(
    repository: NovaRepository,
    onNavigateLiveTv: () -> Unit,
    onNavigateMovies: () -> Unit,
    onNavigateSeries: () -> Unit,
    onNavigateSearch: () -> Unit,
    onNavigateDownloads: () -> Unit,
    onPlayMedia: (ContentType, Int, String, String?, String) -> Unit,
    onOpenMovieDetails: (Int) -> Unit,
    onOpenSeriesDetails: (Int) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val movies by repository.movies.collectAsStateWithLifecycle()
    val seriesList by repository.seriesList.collectAsStateWithLifecycle()
    val liveChannels by repository.liveChannels.collectAsStateWithLifecycle()
    val historyList by repository.allHistory.collectAsStateWithLifecycle(initialValue = emptyList())
    val favoritesList by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())

    val favoriteIds = remember(favoritesList) {
        favoritesList.map { it.id }.toSet()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 100.dp)
        ) {
            // Hero Banner Carousel
            item {
                HeroBannerCarousel(
                    featuredMovies = movies,
                    onMovieClick = { movie -> onOpenMovieDetails(movie.streamId) },
                    onPlayClick = { movie ->
                        onPlayMedia(ContentType.MOVIE, movie.streamId, movie.name, movie.streamIcon, movie.streamUrl)
                    },
                    onMyListToggle = { movie ->
                        coroutineScope.launch {
                            repository.toggleFavorite(
                                type = ContentType.MOVIE,
                                mediaId = movie.streamId,
                                title = movie.name,
                                imageUrl = movie.streamIcon,
                                streamUrl = movie.streamUrl,
                                rating = movie.rating
                            )
                        }
                    },
                    isFavorite = { movie -> favoriteIds.contains("${ContentType.MOVIE.name}_${movie.streamId}") }
                )
            }

            // Continue Watching Rail
            if (historyList.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader(
                        title = "Continue Watching",
                        subtitle = "Pick up right where you left off"
                    )
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp)
                    ) {
                        items(historyList) { item ->
                            ContinueWatchingCard(
                                title = item.title,
                                type = item.type,
                                imageUrl = item.imageUrl,
                                positionMs = item.positionMs,
                                durationMs = item.durationMs,
                                onClick = {
                                    val type = try {
                                        ContentType.valueOf(item.type)
                                    } catch (e: Exception) {
                                        ContentType.MOVIE
                                    }
                                    onPlayMedia(type, item.mediaId, item.title, item.imageUrl, item.streamUrl)
                                }
                            )
                        }
                    }
                }
            }

            // Live Channels Now Rail
            if (liveChannels.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader(
                        title = "Live Channels",
                        subtitle = "Broadcasting now in crystal clear HD",
                        actionLabel = "See All",
                        onActionClick = onNavigateLiveTv
                    )
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp)
                    ) {
                        items(liveChannels.take(5)) { channel ->
                            val isFav = favoriteIds.contains("${ContentType.LIVE.name}_${channel.streamId}")
                            Box(modifier = Modifier.width(260.dp)) {
                                LiveChannelCard(
                                    channelName = channel.name,
                                    channelNum = channel.num,
                                    imageUrl = channel.streamIcon,
                                    epgProgram = repository.getEpgForChannel(channel.streamId),
                                    isFavorite = isFav,
                                    onFavoriteToggle = {
                                        coroutineScope.launch {
                                            repository.toggleFavorite(
                                                type = ContentType.LIVE,
                                                mediaId = channel.streamId,
                                                title = channel.name,
                                                imageUrl = channel.streamIcon,
                                                streamUrl = channel.streamUrl
                                            )
                                        }
                                    },
                                    onClick = {
                                        onPlayMedia(ContentType.LIVE, channel.streamId, channel.name, channel.streamIcon, channel.streamUrl)
                                    }
                                )
                            }
                        }
                    }
                }
            }

            // Popular Movies Rail
            if (movies.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader(
                        title = "Top Movies",
                        subtitle = "Blockbuster hits & critical acclaim",
                        actionLabel = "See All",
                        onActionClick = onNavigateMovies
                    )
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp)
                    ) {
                        items(movies) { movie ->
                            val isFav = favoriteIds.contains("${ContentType.MOVIE.name}_${movie.streamId}")
                            PosterCard(
                                title = movie.name,
                                imageUrl = movie.streamIcon,
                                rating = movie.rating,
                                isFavorite = isFav,
                                onFavoriteToggle = {
                                    coroutineScope.launch {
                                        repository.toggleFavorite(
                                            type = ContentType.MOVIE,
                                            mediaId = movie.streamId,
                                            title = movie.name,
                                            imageUrl = movie.streamIcon,
                                            streamUrl = movie.streamUrl,
                                            rating = movie.rating
                                        )
                                    }
                                },
                                onClick = { onOpenMovieDetails(movie.streamId) }
                            )
                        }
                    }
                }
            }

            // Trending Series Rail
            if (seriesList.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader(
                        title = "Trending Series",
                        subtitle = "Binge-worthy original dramas and shows",
                        actionLabel = "See All",
                        onActionClick = onNavigateSeries
                    )
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp)
                    ) {
                        items(seriesList) { series ->
                            val isFav = favoriteIds.contains("${ContentType.SERIES.name}_${series.seriesId}")
                            PosterCard(
                                title = series.name,
                                imageUrl = series.cover,
                                rating = series.rating,
                                subtitle = "${series.numSeasons} Season${if (series.numSeasons > 1) "s" else ""}",
                                isFavorite = isFav,
                                onFavoriteToggle = {
                                    coroutineScope.launch {
                                        repository.toggleFavorite(
                                            type = ContentType.SERIES,
                                            mediaId = series.seriesId,
                                            title = series.name,
                                            imageUrl = series.cover,
                                            streamUrl = "",
                                            rating = series.rating
                                        )
                                    }
                                },
                                onClick = { onOpenSeriesDetails(series.seriesId) }
                            )
                        }
                    }
                }
            }
        }

        // Top Navigation / Header Bar
        GlassHeader {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Surface(
                    color = NovaViolet.copy(alpha = 0.2f),
                    shape = CircleShape,
                    modifier = Modifier.size(36.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.LiveTv,
                            contentDescription = null,
                            tint = NovaCyan,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "NOVASTREAM",
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.5.sp,
                        color = TextPrimary
                    )
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(
                    onClick = onNavigateSearch,
                    modifier = Modifier.testTag("home_search_btn")
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Search,
                        contentDescription = "Search",
                        tint = TextPrimary
                    )
                }

                IconButton(
                    onClick = onNavigateDownloads,
                    modifier = Modifier.testTag("home_downloads_btn")
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Download,
                        contentDescription = "Downloads",
                        tint = TextPrimary
                    )
                }
            }
        }
    }
}
