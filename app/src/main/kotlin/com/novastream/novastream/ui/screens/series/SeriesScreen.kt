package com.novastream.novastream.ui.screens.series

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.data.models.SortOption
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.CategoryFilterChip
import com.novastream.novastream.ui.components.FilterBottomSheet
import com.novastream.novastream.ui.components.PosterCard
import kotlinx.coroutines.launch

@Composable
fun SeriesScreen(
    repository: NovaRepository,
    onOpenSeriesDetails: (Int) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val categories by repository.seriesCategories.collectAsStateWithLifecycle()
    val seriesList by repository.seriesList.collectAsStateWithLifecycle()
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())

    var selectedCategoryId by remember { mutableStateOf<String?>(null) }
    var selectedSort by remember { mutableStateOf(SortOption.DEFAULT) }
    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }
    var showFilterSheet by remember { mutableStateOf(false) }

    val favoriteIds = remember(favorites) {
        favorites.map { it.id }.toSet()
    }

    val filteredSeries = remember(seriesList, selectedCategoryId, selectedSort, searchQuery) {
        var list = seriesList.filter { series ->
            val matchesCategory = selectedCategoryId == null || series.categoryId == selectedCategoryId
            val matchesQuery = searchQuery.isBlank() || series.name.contains(searchQuery, ignoreCase = true)
            matchesCategory && matchesQuery
        }

        list = when (selectedSort) {
            SortOption.RATING_DESC -> list.sortedByDescending { it.rating }
            SortOption.NAME_ASC -> list.sortedBy { it.name }
            SortOption.DATE_DESC -> list.sortedByDescending { it.lastModified }
            SortOption.DEFAULT -> list
        }
        list
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
                if (!isSearchActive) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.VideoLibrary,
                            contentDescription = null,
                            tint = NovaCyan,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "TV Series",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.Bold,
                                color = TextPrimary
                            )
                        )
                    }

                    Row {
                        IconButton(
                            onClick = { showFilterSheet = true },
                            modifier = Modifier.testTag("series_filter_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Default.FilterList,
                                contentDescription = "Filter",
                                tint = if (selectedCategoryId != null || selectedSort != SortOption.DEFAULT) NovaCyan else TextPrimary
                            )
                        }

                        IconButton(
                            onClick = { isSearchActive = true },
                            modifier = Modifier.testTag("series_search_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Search,
                                contentDescription = "Search",
                                tint = TextPrimary
                            )
                        }
                    }
                } else {
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Search TV shows & series…") },
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
                            .testTag("series_search_input")
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
                            text = "All Series",
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

            // Grid of Series
            if (filteredSeries.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.VideoLibrary,
                            contentDescription = null,
                            tint = TextDisabled,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "No series found",
                            style = MaterialTheme.typography.bodyLarge.copy(color = TextSecondary)
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
                    items(filteredSeries, key = { it.seriesId }) { series ->
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
                            onClick = { onOpenSeriesDetails(series.seriesId) },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }

        if (showFilterSheet) {
            FilterBottomSheet(
                availableCategories = categories.map { it.categoryName },
                selectedCategory = categories.find { it.categoryId == selectedCategoryId }?.categoryName,
                onSelectCategory = { catName ->
                    selectedCategoryId = categories.find { it.categoryName == catName }?.categoryId
                },
                availableYears = emptyList(),
                selectedYear = null,
                onSelectYear = {},
                selectedSort = selectedSort,
                onSelectSort = { selectedSort = it },
                onResetFilters = {
                    selectedCategoryId = null
                    selectedSort = SortOption.DEFAULT
                    searchQuery = ""
                },
                onDismiss = { showFilterSheet = false }
            )
        }
    }
}
