package com.novastream.novastream.ui.screens.details

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.data.models.Episode
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.storage.entities.DownloadTaskEntity
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.CategoryFilterChip
import com.novastream.novastream.ui.components.GlassCard
import kotlinx.coroutines.launch

@Composable
fun SeriesDetailsScreen(
    seriesId: Int,
    repository: NovaRepository,
    onBackClick: () -> Unit,
    onPlayEpisode: (ContentType, Int, String, String?, String) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val seriesDetails = remember(seriesId) { repository.getSeriesDetails(seriesId) }
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())
    val downloads by repository.allDownloads.collectAsStateWithLifecycle(initialValue = emptyList())

    val seasons = remember(seriesDetails) {
        seriesDetails.episodesBySeason.keys.sorted()
    }

    var selectedSeason by remember { mutableIntStateOf(seasons.firstOrNull() ?: 1) }

    val isFavorite = remember(favorites, seriesId) {
        favorites.any { it.id == "${ContentType.SERIES.name}_$seriesId" }
    }

    val episodes = remember(seriesDetails, selectedSeason) {
        seriesDetails.episodesBySeason[selectedSeason] ?: emptyList()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 60.dp)
        ) {
            // Backdrop Header
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(340.dp)
                ) {
                    AsyncImage(
                        model = seriesDetails.backdropUrl ?: seriesDetails.coverUrl,
                        contentDescription = seriesDetails.name,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )

                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        DarkBackground.copy(alpha = 0.5f),
                                        Color.Transparent,
                                        DarkBackground.copy(alpha = 0.7f),
                                        DarkBackground
                                    )
                                )
                            )
                    )

                    // Top Bar Actions
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .statusBarsPadding()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(
                            onClick = onBackClick,
                            modifier = Modifier
                                .background(DarkBackground.copy(alpha = 0.6f), CircleShape)
                                .testTag("series_details_back_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back",
                                tint = TextPrimary
                            )
                        }

                        IconButton(
                            onClick = {
                                coroutineScope.launch {
                                    repository.toggleFavorite(
                                        type = ContentType.SERIES,
                                        mediaId = seriesId,
                                        title = seriesDetails.name,
                                        imageUrl = seriesDetails.coverUrl,
                                        streamUrl = "",
                                        rating = seriesDetails.rating
                                    )
                                }
                            },
                            modifier = Modifier
                                .background(DarkBackground.copy(alpha = 0.6f), CircleShape)
                                .testTag("series_details_fav_btn")
                        ) {
                            Icon(
                                imageVector = if (isFavorite) Icons.Default.Favorite else Icons.Outlined.FavoriteBorder,
                                contentDescription = "Favorite",
                                tint = if (isFavorite) NovaPink else TextPrimary
                            )
                        }
                    }
                }
            }

            // Series Details info
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp)
                ) {
                    Text(
                        text = seriesDetails.name,
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Black,
                            color = TextPrimary
                        )
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            color = DarkSurfaceElevated,
                            shape = RoundedCornerShape(6.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Star,
                                    contentDescription = null,
                                    tint = NovaGold,
                                    modifier = Modifier.size(14.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = String.format("%.1f", seriesDetails.rating),
                                    style = MaterialTheme.typography.labelMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = TextPrimary
                                    )
                                )
                            }
                        }

                        Text(
                            text = "${seasons.size} Season${if (seasons.size > 1) "s" else ""}",
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )

                        Text("•", color = TextSecondary)

                        Text(
                            text = seriesDetails.releaseDate,
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "SYNOPSIS",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextSecondary
                        )
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = seriesDetails.description.ifBlank { "Stream all episodes in high definition." },
                        style = MaterialTheme.typography.bodyMedium.copy(
                            color = TextPrimary,
                            lineHeight = 22.sp
                        )
                    )

                    Spacer(modifier = Modifier.height(20.dp))

                    // Season Selector
                    Text(
                        text = "SEASONS & EPISODES",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextSecondary
                        )
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(seasons) { s ->
                            CategoryFilterChip(
                                text = "Season $s",
                                isSelected = selectedSeason == s,
                                onClick = { selectedSeason = s }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }
            }

            // Episodes List
            items(episodes, key = { it.episodeId }) { ep ->
                val epDownload = downloads.find { it.id == "${ContentType.SERIES.name}_${ep.episodeId}" }

                GlassCard(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 6.dp)
                        .clickable {
                            val playUrl = if (epDownload?.status == "COMPLETED" && epDownload.localFilePath.isNotBlank()) {
                                epDownload.localFilePath
                            } else {
                                ep.streamUrl
                            }
                            onPlayEpisode(
                                ContentType.SERIES,
                                ep.episodeId,
                                "${seriesDetails.name} - S${ep.season}E${ep.episodeNum}: ${ep.title}",
                                ep.coverUrl ?: seriesDetails.coverUrl,
                                playUrl
                            )
                        }
                        .testTag("episode_${ep.episodeId}")
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Episode Thumbnail / Number
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(DarkSurfaceElevated),
                            contentAlignment = Alignment.Center
                        ) {
                            if (!ep.coverUrl.isNullOrBlank()) {
                                AsyncImage(
                                    model = ep.coverUrl,
                                    contentDescription = ep.title,
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier.fillMaxSize()
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .background(DarkBackground.copy(alpha = 0.7f), CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play Episode",
                                    tint = NovaCyan,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "EPISODE ${ep.episodeNum}",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    color = NovaCyan,
                                    fontWeight = FontWeight.Bold
                                )
                            )
                            Text(
                                text = ep.title,
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                ),
                                maxLines = 1,
                                overflow = TextOverflow.ellipsis
                            )
                            if (ep.plot.isNotBlank()) {
                                Text(
                                    text = ep.plot,
                                    style = MaterialTheme.typography.bodySmall.copy(
                                        color = TextSecondary,
                                        fontSize = 11.sp
                                    ),
                                    maxLines = 2,
                                    overflow = TextOverflow.ellipsis
                                )
                            }
                        }

                        // Download Episode Button
                        IconButton(
                            onClick = {
                                if (epDownload == null || epDownload.status == "FAILED") {
                                    repository.downloadManager.startDownload(
                                        DownloadTaskEntity(
                                            id = "${ContentType.SERIES.name}_${ep.episodeId}",
                                            mediaId = ep.episodeId,
                                            type = ContentType.SERIES.name,
                                            title = "${seriesDetails.name} S${ep.season}E${ep.episodeNum}",
                                            imageUrl = ep.coverUrl ?: seriesDetails.coverUrl,
                                            streamUrl = ep.streamUrl
                                        )
                                    )
                                }
                            },
                            modifier = Modifier.testTag("download_ep_${ep.episodeId}")
                        ) {
                            when (epDownload?.status) {
                                "DOWNLOADING" -> {
                                    CircularProgressIndicator(
                                        progress = { epDownload.progress },
                                        modifier = Modifier.size(18.dp),
                                        color = NovaCyan,
                                        strokeWidth = 2.dp
                                    )
                                }
                                "COMPLETED" -> {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = NovaCyan,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                                else -> {
                                    Icon(
                                        imageVector = Icons.Outlined.Download,
                                        contentDescription = "Download Episode",
                                        tint = TextSecondary,
                                        modifier = Modifier.size(20.dp)
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
