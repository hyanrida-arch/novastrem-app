package com.novastream.novastream.ui.screens.search

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.CategoryFilterChip
import com.novastream.novastream.ui.components.LiveChannelCard
import com.novastream.novastream.ui.components.PosterCard
import com.novastream.novastream.ui.components.SectionHeader
import kotlinx.coroutines.launch

@Composable
fun SearchScreen(
    repository: NovaRepository,
    onPlayMedia: (ContentType, Int, String, String?, String) -> Unit,
    onOpenMovieDetails: (Int) -> Unit,
    onOpenSeriesDetails: (Int) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    var searchQuery by remember { mutableStateOf("") }
    var selectedFilter by remember { mutableStateOf("All") } // All, Channels, Movies, Series

    val channels by repository.liveChannels.collectAsStateWithLifecycle()
    val movies by repository.movies.collectAsStateWithLifecycle()
    val seriesList by repository.seriesList.collectAsStateWithLifecycle()
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())

    val favoriteIds = remember(favorites) {
        favorites.map { it.id }.toSet()
    }

    val matchedChannels = remember(channels, searchQuery, selectedFilter) {
        if (searchQuery.isBlank() || (selectedFilter != "All" && selectedFilter != "Channels")) emptyList()
        else channels.filter { it.name.contains(searchQuery, ignoreCase = true) }
    }

    val matchedMovies = remember(movies, searchQuery, selectedFilter) {
        if (searchQuery.isBlank() || (selectedFilter != "All" && selectedFilter != "Movies")) emptyList()
        else movies.filter { it.name.contains(searchQuery, ignoreCase = true) }
    }

    val matchedSeries = remember(seriesList, searchQuery, selectedFilter) {
        if (searchQuery.isBlank() || (selectedFilter != "All" && selectedFilter != "Series")) emptyList()
        else seriesList.filter { it.name.contains(searchQuery, ignoreCase = true) }
    }

    val totalMatches = matchedChannels.size + matchedMovies.size + matchedSeries.size

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
            // Search Input Field
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search channels, movies, shows…") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = null,
                            tint = NovaCyan
                        )
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear", tint = TextSecondary)
                            }
                        }
                    },
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = NovaCyan,
                        unfocusedBorderColor = DarkCardBorder,
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("global_search_input")
                )
            }

            // Filter Chips
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("All", "Channels", "Movies", "Series").forEach { filterName ->
                    item {
                        CategoryFilterChip(
                            text = filterName,
                            isSelected = selectedFilter == filterName,
                            onClick = { selectedFilter = filterName }
                        )
                    }
                }
            }

            if (searchQuery.isBlank()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = null,
                            tint = TextDisabled,
                            modifier = Modifier.size(54.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Find your favorite entertainment",
                            style = MaterialTheme.typography.bodyLarge.copy(
                                color = TextSecondary,
                                fontWeight = FontWeight.Medium
                            )
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Search across thousands of Live TV channels, Movies & Series",
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )
                    }
                }
            } else if (totalMatches == 0) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No results found for \"$searchQuery\"",
                        style = MaterialTheme.typography.bodyLarge.copy(color = TextSecondary)
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 100.dp)
                ) {
                    // Channels Section
                    if (matchedChannels.isNotEmpty()) {
                        item {
                            SectionHeader(title = "Live Channels (${matchedChannels.size})")
                        }
                        items(matchedChannels) { channel ->
                            val isFav = favoriteIds.contains("${ContentType.LIVE.name}_${channel.streamId}")
                            Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
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

                    // Movies Section
                    if (matchedMovies.isNotEmpty()) {
                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                            SectionHeader(title = "Movies (${matchedMovies.size})")
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                contentPadding = PaddingValues(horizontal = 16.dp)
                            ) {
                                items(matchedMovies) { movie ->
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

                    // Series Section
                    if (matchedSeries.isNotEmpty()) {
                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                            SectionHeader(title = "TV Series (${matchedSeries.size})")
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                contentPadding = PaddingValues(horizontal = 16.dp)
                            ) {
                                items(matchedSeries) { series ->
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
            }
        }
    }
}
