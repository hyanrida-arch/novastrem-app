package com.novastream.novastream.ui.screens.player

import android.app.Activity
import android.content.pm.ActivityInfo
import android.net.Uri
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.AspectRatio
import androidx.compose.material.icons.outlined.Forward10
import androidx.compose.material.icons.outlined.Replay10
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.novastream.novastream.core.data.models.ContentType
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale

enum class ScaleMode(val displayName: String, val resizeMode: Int) {
    FIT("Fit (16:9)", AspectRatioFrameLayout.RESIZE_MODE_FIT),
    ZOOM("Zoom / Crop", AspectRatioFrameLayout.RESIZE_MODE_ZOOM),
    FILL("Stretch", AspectRatioFrameLayout.RESIZE_MODE_FILL)
}

@OptIn(UnstableApi::class)
@Composable
fun PlayerScreen(
    type: ContentType,
    mediaId: Int,
    title: String,
    imageUrl: String?,
    streamUrl: String,
    repository: NovaRepository,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var isPlaying by remember { mutableStateOf(true) }
    var showControls by remember { mutableStateOf(true) }
    var currentPosition by remember { mutableLongStateOf(0L) }
    var duration by remember { mutableLongStateOf(0L) }
    var isBuffering by remember { mutableStateOf(true) }
    var playbackError by remember { mutableStateOf<String?>(null) }
    var scaleMode by remember { mutableStateOf(ScaleMode.FIT) }

    val exoPlayer = remember {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                1500, // min buffer
                10000, // max buffer
                500, // buffer for playback
                1000 // buffer for playback after rebuffer
            )
            .build()

        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setUserAgent("NovaStream/1.0 (Android; ExoPlayer)")

        val mediaSourceFactory = DefaultMediaSourceFactory(httpDataSourceFactory)

        ExoPlayer.Builder(context)
            .setMediaSourceFactory(mediaSourceFactory)
            .setLoadControl(loadControl)
            .build()
    }

    // Set orientation to sensor landscape while player is open
    DisposableEffect(Unit) {
        val activity = context as? Activity
        val originalOrientation = activity?.requestedOrientation ?: ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        activity?.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_USER_LANDSCAPE

        onDispose {
            activity?.requestedOrientation = originalOrientation
        }
    }

    // Initialize media and playback
    LaunchedEffect(streamUrl) {
        try {
            val initialPosition = if (type != ContentType.LIVE) {
                repository.getHistoryPosition(type, mediaId)
            } else 0L

            val mediaItem = if (streamUrl.startsWith("/")) {
                MediaItem.fromUri(Uri.fromFile(File(streamUrl)))
            } else {
                MediaItem.fromUri(Uri.parse(streamUrl))
            }

            exoPlayer.setMediaItem(mediaItem, initialPosition)
            exoPlayer.prepare()
            exoPlayer.playWhenReady = true

            exoPlayer.addListener(object : Player.Listener {
                override fun onIsPlayingChanged(playing: Boolean) {
                    isPlaying = playing
                }

                override fun onPlaybackStateChanged(state: Int) {
                    isBuffering = state == Player.STATE_BUFFERING
                    if (state == Player.STATE_READY) {
                        duration = if (exoPlayer.duration == C.TIME_UNSET) 0L else exoPlayer.duration
                        playbackError = null
                    }
                }

                override fun onPlayerError(error: PlaybackException) {
                    playbackError = "Playback error: ${error.errorCodeName}"
                }
            })
        } catch (e: Exception) {
            playbackError = e.localizedMessage ?: "Failed to initialize player"
        }
    }

    // Save history periodically
    LaunchedEffect(isPlaying) {
        while (true) {
            delay(1000)
            if (exoPlayer.playbackState == Player.STATE_READY) {
                currentPosition = exoPlayer.currentPosition
                duration = if (exoPlayer.duration == C.TIME_UNSET) 0L else exoPlayer.duration
                if (type != ContentType.LIVE && currentPosition > 2000) {
                    repository.recordHistory(
                        type = type,
                        mediaId = mediaId,
                        title = title,
                        imageUrl = imageUrl,
                        streamUrl = streamUrl,
                        positionMs = currentPosition,
                        durationMs = duration
                    )
                }
            }
        }
    }

    // Auto-hide controls after 4 seconds
    LaunchedEffect(showControls, isPlaying) {
        if (showControls && isPlaying) {
            delay(4000)
            showControls = false
        }
    }

    val handleBack: () -> Unit = {
        coroutineScope.launch {
            if (type != ContentType.LIVE && currentPosition > 2000) {
                repository.recordHistory(
                    type = type,
                    mediaId = mediaId,
                    title = title,
                    imageUrl = imageUrl,
                    streamUrl = streamUrl,
                    positionMs = currentPosition,
                    durationMs = duration
                )
            }
            exoPlayer.stop()
            exoPlayer.release()
            onBackClick()
        }
    }

    BackHandler {
        handleBack()
    }

    DisposableEffect(Unit) {
        onDispose {
            exoPlayer.release()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .testTag("player_screen")
    ) {
        // Video View
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    layoutParams = FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                    resizeMode = scaleMode.resizeMode
                }
            },
            update = { playerView ->
                playerView.resizeMode = scaleMode.resizeMode
            },
            modifier = Modifier
                .fillMaxSize()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) {
                    showControls = !showControls
                }
        )

        // Buffering Indicator
        if (isBuffering && playbackError == null) {
            CircularProgressIndicator(
                color = NovaCyan,
                modifier = Modifier
                    .size(54.dp)
                    .align(Alignment.Center)
            )
        }

        // Error message & Retry
        if (playbackError != null) {
            Surface(
                color = DarkBackground.copy(alpha = 0.9f),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(24.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        tint = NovaLiveRed,
                        modifier = Modifier.size(36.dp)
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "Unable to Play Stream",
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = playbackError ?: "Stream connection failed",
                        style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            playbackError = null
                            exoPlayer.prepare()
                            exoPlayer.play()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = NovaViolet)
                    ) {
                        Text("Retry Stream")
                    }
                }
            }
        }

        // Controls Overlay
        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                DarkBackground.copy(alpha = 0.8f),
                                Color.Transparent,
                                Color.Transparent,
                                DarkBackground.copy(alpha = 0.85f)
                            )
                        )
                    )
            ) {
                // Top Header: Back button, Title, Type Pill, Aspect Ratio
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f)
                    ) {
                        IconButton(
                            onClick = handleBack,
                            modifier = Modifier
                                .background(DarkBackground.copy(alpha = 0.5f), CircleShape)
                                .testTag("player_back_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back",
                                tint = TextPrimary
                            )
                        }

                        Spacer(modifier = Modifier.width(12.dp))

                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                if (type == ContentType.LIVE) {
                                    Surface(
                                        color = NovaLiveRed,
                                        shape = RoundedCornerShape(4.dp)
                                    ) {
                                        Text(
                                            text = "LIVE STREAM",
                                            color = Color.White,
                                            style = MaterialTheme.typography.labelSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 9.sp
                                            ),
                                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(6.dp))
                                }
                                Text(
                                    text = title,
                                    style = MaterialTheme.typography.titleMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = TextPrimary
                                    ),
                                    maxLines = 1
                                )
                            }
                        }
                    }

                    // Aspect Ratio Button
                    IconButton(
                        onClick = {
                            scaleMode = when (scaleMode) {
                                ScaleMode.FIT -> ScaleMode.ZOOM
                                ScaleMode.ZOOM -> ScaleMode.FILL
                                ScaleMode.FILL -> ScaleMode.FIT
                            }
                        },
                        modifier = Modifier
                            .background(DarkBackground.copy(alpha = 0.5f), CircleShape)
                            .testTag("player_aspect_ratio_btn")
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.AspectRatio,
                            contentDescription = scaleMode.displayName,
                            tint = NovaCyan
                        )
                    }
                }

                // Center Play/Pause & Skip Controls
                Row(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalArrangement = Arrangement.spacedBy(32.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (type != ContentType.LIVE) {
                        IconButton(
                            onClick = {
                                val target = (exoPlayer.currentPosition - 10000L).coerceAtLeast(0L)
                                exoPlayer.seekTo(target)
                            },
                            modifier = Modifier
                                .size(50.dp)
                                .background(DarkBackground.copy(alpha = 0.5f), CircleShape)
                                .testTag("player_rewind_10")
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Replay10,
                                contentDescription = "Rewind 10 seconds",
                                tint = TextPrimary,
                                modifier = Modifier.size(30.dp)
                            )
                        }
                    }

                    IconButton(
                        onClick = {
                            if (exoPlayer.isPlaying) {
                                exoPlayer.pause()
                            } else {
                                exoPlayer.play()
                            }
                        },
                        modifier = Modifier
                            .size(72.dp)
                            .background(NovaViolet, CircleShape)
                            .testTag("player_play_pause_btn")
                    ) {
                        Icon(
                            imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = if (isPlaying) "Pause" else "Play",
                            tint = Color.White,
                            modifier = Modifier.size(40.dp)
                        )
                    }

                    if (type != ContentType.LIVE) {
                        IconButton(
                            onClick = {
                                val target = (exoPlayer.currentPosition + 10000L).coerceAtMost(duration)
                                exoPlayer.seekTo(target)
                            },
                            modifier = Modifier
                                .size(50.dp)
                                .background(DarkBackground.copy(alpha = 0.5f), CircleShape)
                                .testTag("player_forward_10")
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Forward10,
                                contentDescription = "Forward 10 seconds",
                                tint = TextPrimary,
                                modifier = Modifier.size(30.dp)
                            )
                        }
                    }
                }

                // Bottom Seekbar & Time (for VOD/Series)
                if (type != ContentType.LIVE && duration > 0) {
                    Column(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .navigationBarsPadding()
                            .padding(horizontal = 24.dp, vertical = 12.dp)
                    ) {
                        Slider(
                            value = currentPosition.toFloat(),
                            onValueChange = { newPos ->
                                currentPosition = newPos.toLong()
                            },
                            onValueChangeFinished = {
                                exoPlayer.seekTo(currentPosition)
                            },
                            valueRange = 0f..duration.toFloat(),
                            colors = SliderDefaults.colors(
                                thumbColor = NovaCyan,
                                activeTrackColor = NovaCyan,
                                inactiveTrackColor = DarkCardBorder
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("player_seekbar")
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = formatTime(currentPosition),
                                style = MaterialTheme.typography.labelSmall.copy(color = TextPrimary)
                            )
                            Text(
                                text = scaleMode.displayName,
                                style = MaterialTheme.typography.labelSmall.copy(color = NovaCyan)
                            )
                            Text(
                                text = formatTime(duration),
                                style = MaterialTheme.typography.labelSmall.copy(color = TextSecondary)
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun formatTime(millis: Long): String {
    val totalSeconds = millis / 1000
    val seconds = totalSeconds % 60
    val minutes = (totalSeconds / 60) % 60
    val hours = totalSeconds / 3600
    return if (hours > 0) {
        String.format(Locale.getDefault(), "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)
    }
}
