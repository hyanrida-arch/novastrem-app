package com.novastream.novastream.ui.screens.details

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.BookmarkAdd
import androidx.compose.material.icons.outlined.BookmarkAdded
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.storage.entities.DownloadTaskEntity
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.GlassCard
import kotlinx.coroutines.launch

@Composable
fun MovieDetailsScreen(
    movieId: Int,
    repository: NovaRepository,
    onBackClick: () -> Unit,
    onPlayMovie: (ContentType, Int, String, String?, String) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val movieDetails = remember(movieId) { repository.getMovieDetails(movieId) }
    val favorites by repository.allFavorites.collectAsStateWithLifecycle(initialValue = emptyList())
    val downloads by repository.allDownloads.collectAsStateWithLifecycle(initialValue = emptyList())

    val isFavorite = remember(favorites, movieId) {
        favorites.any { it.id == "${ContentType.MOVIE.name}_$movieId" }
    }

    val downloadTask = remember(downloads, movieId) {
        downloads.find { it.id == "${ContentType.MOVIE.name}_$movieId" }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 40.dp)
        ) {
            // Backdrop & Poster Header
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(360.dp)
            ) {
                AsyncImage(
                    model = movieDetails.backdropUrl ?: movieDetails.coverUrl,
                    contentDescription = movieDetails.name,
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

                // Top Actions: Back & Favorite
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
                            .testTag("movie_details_back_btn")
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
                                    type = ContentType.MOVIE,
                                    mediaId = movieId,
                                    title = movieDetails.name,
                                    imageUrl = movieDetails.coverUrl,
                                    streamUrl = movieDetails.streamUrl,
                                    rating = movieDetails.rating
                                )
                            }
                        },
                        modifier = Modifier
                            .background(DarkBackground.copy(alpha = 0.6f), CircleShape)
                            .testTag("movie_details_fav_btn")
                    ) {
                        Icon(
                            imageVector = if (isFavorite) Icons.Default.Favorite else Icons.Outlined.FavoriteBorder,
                            contentDescription = "Favorite",
                            tint = if (isFavorite) NovaPink else TextPrimary
                        )
                    }
                }
            }

            // Movie Details Info
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
            ) {
                Text(
                    text = movieDetails.name,
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Black,
                        color = TextPrimary
                    )
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Metadata Chips: Rating, Duration, Release Date, Quality
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
                                text = String.format("%.1f", movieDetails.rating),
                                style = MaterialTheme.typography.labelMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                        }
                    }

                    if (movieDetails.duration.isNotBlank()) {
                        Text(
                            text = movieDetails.duration,
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )
                        Text("•", color = TextSecondary)
                    }

                    if (movieDetails.releaseDate.isNotBlank()) {
                        Text(
                            text = movieDetails.releaseDate,
                            style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                        )
                        Text("•", color = TextSecondary)
                    }

                    Surface(
                        color = NovaCyan.copy(alpha = 0.2f),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = "4K UHD",
                            color = NovaCyan,
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Action Buttons: Play & Download
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = {
                            val playUrl = if (downloadTask?.status == "COMPLETED" && downloadTask.localFilePath.isNotBlank()) {
                                downloadTask.localFilePath
                            } else {
                                movieDetails.streamUrl
                            }
                            onPlayMovie(ContentType.MOVIE, movieId, movieDetails.name, movieDetails.coverUrl, playUrl)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = NovaCyan, contentColor = DarkBackground),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("play_movie_cta")
                    ) {
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Play Movie",
                            style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold)
                        )
                    }

                    OutlinedButton(
                        onClick = {
                            if (downloadTask == null || downloadTask.status == "FAILED") {
                                repository.downloadManager.startDownload(
                                    DownloadTaskEntity(
                                        id = "${ContentType.MOVIE.name}_$movieId",
                                        mediaId = movieId,
                                        type = ContentType.MOVIE.name,
                                        title = movieDetails.name,
                                        imageUrl = movieDetails.coverUrl,
                                        streamUrl = movieDetails.streamUrl
                                    )
                                )
                            }
                        },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = TextPrimary),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .height(48.dp)
                            .testTag("download_movie_btn")
                    ) {
                        when (downloadTask?.status) {
                            "DOWNLOADING" -> {
                                CircularProgressIndicator(
                                    progress = { downloadTask.progress },
                                    modifier = Modifier.size(18.dp),
                                    color = NovaCyan,
                                    strokeWidth = 2.dp
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("${(downloadTask.progress * 100).toInt()}%")
                            }
                            "COMPLETED" -> {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = NovaCyan,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Downloaded")
                            }
                            else -> {
                                Icon(
                                    imageVector = Icons.Outlined.Download,
                                    contentDescription = null,
                                    tint = NovaCyan,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Download")
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Genres
                if (movieDetails.genre.isNotBlank()) {
                    Text(
                        text = "GENRES",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextSecondary
                        )
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        movieDetails.genre.split(",").forEach { genre ->
                            Surface(
                                color = DarkSurfaceElevated,
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text(
                                    text = genre.trim(),
                                    style = MaterialTheme.typography.bodySmall.copy(
                                        color = TextPrimary
                                    ),
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Plot Synopsis
                Text(
                    text = "SYNOPSIS",
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = FontWeight.Bold,
                        color = TextSecondary
                    )
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = movieDetails.description.ifBlank { "Experience high-octane entertainment with high definition streaming and surround sound audio." },
                    style = MaterialTheme.typography.bodyMedium.copy(
                        color = TextPrimary,
                        lineHeight = 22.sp
                    )
                )

                if (movieDetails.director.isNotBlank()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "DIRECTOR",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextSecondary
                        )
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = movieDetails.director,
                        style = MaterialTheme.typography.bodyMedium.copy(
                            color = TextPrimary,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            }
        }
    }
}
