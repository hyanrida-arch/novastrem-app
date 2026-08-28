package com.novastream.novastream.ui.screens.livetv

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LiveTv
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.CategoryFilterChip
import com.novastream.novastream.ui.components.GlassHeader
import com.novastream.novastream.ui.components.LiveChannelCard
import kotlinx.coroutines.launch

@Composable
fun LiveTvScreen(
    repository: NovaRepository,
    onPlayChannel: (Int, String, String?, String) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val categories by repository.liveCategories.collectAsStateWithLifecycle()
    val channels by repository.liveChannels.collectAsStateWithLifecycle()
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())

    var selectedCategoryId by remember { mutableStateOf<String?>(null) }
    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }

    val favoriteIds = remember(favorites) {
        favorites.map { it.id }.toSet()
    }

    val filteredChannels = remember(channels, selectedCategoryId, searchQuery) {
        channels.filter { channel ->
            val matchesCategory = selectedCategoryId == null || channel.categoryId == selectedCategoryId
            val matchesQuery = searchQuery.isBlank() || channel.name.contains(searchQuery, ignoreCase = true)
            matchesCategory && matchesQuery
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
            // Header with title and search toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (!isSearchActive) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.LiveTv,
                            contentDescription = null,
                            tint = NovaCyan,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Live TV",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.Bold,
                                color = TextPrimary
                            )
                        )
                    }

                    IconButton(
                        onClick = { isSearchActive = true },
                        modifier = Modifier.testTag("livetv_search_btn")
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Search,
                            contentDescription = "Search Channels",
                            tint = TextPrimary
                        )
                    }
                } else {
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Search live channels…") },
                        singleLine = true,
                        trailingIcon = {
                            IconButton(onClick = {
                                searchQuery = ""
                                isSearchActive = false
                            }) {
                                Icon(Icons.Default.Close, contentDescription = "Close search", tint = TextSecondary)
                            }
                        },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = NovaCyan,
                            unfocusedBorderColor = DarkCardBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("livetv_search_input")
                    )
                }
            }

            // Categories horizontal bar
            if (categories.isNotEmpty()) {
                LazyRow(
                    modifier = Modifier.fillMaxWidth(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    item {
                        CategoryFilterChip(
                            text = "All Channels",
                            isSelected = selectedCategoryId == null,
                            onClick = { selectedCategoryId = null }
                        )
                    }
                    items(categories) { cat ->
                        CategoryFilterChip(
                            text = cat.categoryName,
                            isSelected = selectedCategoryId == cat.categoryId,
                            onClick = { selectedCategoryId = cat.categoryId }
                        )
                    }
                }
            }

            // Channels List
            if (filteredChannels.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.LiveTv,
                            contentDescription = null,
                            tint = TextDisabled,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No channels found",
                            style = MaterialTheme.typography.bodyLarge.copy(color = TextSecondary)
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 100.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filteredChannels, key = { it.streamId }) { channel ->
                        val isFav = favoriteIds.contains("${ContentType.LIVE.name}_${channel.streamId}")
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
                                onPlayChannel(channel.streamId, channel.name, channel.streamIcon, channel.streamUrl)
                            }
                        )
                    }
                }
            }
        }
    }
}
