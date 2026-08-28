package com.novastream.novastream.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.BookmarkAdd
import androidx.compose.material.icons.outlined.BookmarkAdded
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
import coil.compose.AsyncImage
import com.novastream.novastream.core.data.models.Movie
import com.novastream.novastream.core.theme.*
import kotlinx.coroutines.delay

@Composable
fun HeroBannerCarousel(
    featuredMovies: List<Movie>,
    modifier: Modifier = Modifier,
    onMovieClick: (Movie) -> Unit,
    onPlayClick: (Movie) -> Unit,
    onMyListToggle: (Movie) -> Unit,
    isFavorite: (Movie) -> Boolean
) {
    if (featuredMovies.isEmpty()) return

    val pagerState = rememberPagerState(pageCount = { featuredMovies.size })

    LaunchedEffect(featuredMovies.size) {
        if (featuredMovies.size > 1) {
            while (true) {
                delay(6000)
                val nextPage = (pagerState.currentPage + 1) % featuredMovies.size
                pagerState.animateScrollToPage(nextPage)
            }
        }
    }

    Column(modifier = modifier.fillMaxWidth()) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier
                .fillMaxWidth()
                .height(380.dp)
        ) { page ->
            val movie = featuredMovies[page]
            val favorite = isFavorite(movie)

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable { onMovieClick(movie) }
                    .testTag("hero_slide_$page")
            ) {
                // Backdrop Image
                AsyncImage(
                    model = movie.streamIcon ?: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&q=80",
                    contentDescription = movie.name,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )

                // Top & Bottom Scrim Gradient
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    DarkBackground.copy(alpha = 0.6f),
                                    Color.Transparent,
                                    DarkBackground.copy(alpha = 0.7f),
                                    DarkBackground
                                )
                            )
                        )
                )

                // Featured Tag
                Surface(
                    color = NovaViolet.copy(alpha = 0.85f),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .padding(top = 48.dp, start = 16.dp)
                        .align(Alignment.TopStart)
                ) {
                    Text(
                        text = "FEATURED PREMIERE",
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        ),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }

                // Info & Action Buttons
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(16.dp)
                ) {
                    // Rating & Category
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            color = DarkSurfaceElevated.copy(alpha = 0.9f),
                            shape = RoundedCornerShape(6.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
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
                                    text = String.format("%.1f", if (movie.rating > 0) movie.rating else 8.2),
                                    style = MaterialTheme.typography.labelMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = TextPrimary
                                    )
                                )
                            }
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Text(
                            text = "4K Ultra HD • 5.1 Surround",
                            style = MaterialTheme.typography.labelMedium.copy(
                                color = NovaCyan,
                                fontWeight = FontWeight.SemiBold
                            )
                        )
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = movie.name,
                        style = MaterialTheme.typography.headlineSmall.copy(
                            fontWeight = FontWeight.Black,
                            color = TextPrimary
                        ),
                        maxLines = 2,
                        overflow = TextOverflow.ellipsis
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    // Buttons: Play Now & My List
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Button(
                            onClick = { onPlayClick(movie) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = NovaCyan,
                                contentColor = DarkBackground
                            ),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier
                                .weight(1f)
                                .height(44.dp)
                                .testTag("hero_play_btn")
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = null,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Play",
                                style = MaterialTheme.typography.labelLarge.copy(
                                    fontWeight = FontWeight.Bold
                                )
                            )
                        }

                        OutlinedButton(
                            onClick = { onMyListToggle(movie) },
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = TextPrimary
                            ),
                            border = ButtonDefaults.outlinedButtonBorder.copy(
                                brush = Brush.linearGradient(listOf(NovaViolet, NovaCyan))
                            ),
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier
                                .weight(1f)
                                .height(44.dp)
                                .testTag("hero_my_list_btn")
                        ) {
                            Icon(
                                imageVector = if (favorite) Icons.Outlined.BookmarkAdded else Icons.Outlined.BookmarkAdd,
                                contentDescription = null,
                                tint = if (favorite) NovaCyan else TextPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (favorite) "In My List" else "+ My List",
                                style = MaterialTheme.typography.labelLarge.copy(
                                    fontWeight = FontWeight.SemiBold
                                )
                            )
                        }
                    }
                }
            }
        }

        // Pager indicator dots
        if (featuredMovies.size > 1) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(featuredMovies.size) { index ->
                    val isSelected = pagerState.currentPage == index
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 3.dp)
                            .height(4.dp)
                            .width(if (isSelected) 20.dp else 6.dp)
                            .clip(CircleShape)
                            .background(if (isSelected) NovaCyan else DarkCardBorder)
                    )
                }
            }
        }
    }
}
