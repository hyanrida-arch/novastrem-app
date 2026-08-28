package com.novastream.novastream.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.novastream.novastream.core.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MenuBottomSheet(
    onNavigateProfile: () -> Unit,
    onNavigateSettings: () -> Unit,
    onNavigateFavorites: () -> Unit,
    onNavigateHistory: () -> Unit,
    onNavigateDownloads: () -> Unit,
    onDismiss: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = DarkSurface,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 10.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(DarkCardBorder)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = "Menu",
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                ),
                modifier = Modifier.padding(bottom = 12.dp)
            )

            MenuTile(
                icon = Icons.Outlined.Person,
                title = "Profile",
                subtitle = "Account details & connection status",
                tag = "menu_profile",
                onClick = {
                    onDismiss()
                    onNavigateProfile()
                }
            )

            MenuTile(
                icon = Icons.Outlined.Settings,
                title = "Settings",
                subtitle = "Player format, buffer, parental gate",
                tag = "menu_settings",
                onClick = {
                    onDismiss()
                    onNavigateSettings()
                }
            )

            MenuTile(
                icon = Icons.Outlined.FavoriteBorder,
                title = "My List",
                subtitle = "Your favorite channels, movies & series",
                tag = "menu_favorites",
                onClick = {
                    onDismiss()
                    onNavigateFavorites()
                }
            )

            MenuTile(
                icon = Icons.Outlined.History,
                title = "Watch History",
                subtitle = "Resume unfinished streams & recent activity",
                tag = "menu_history",
                onClick = {
                    onDismiss()
                    onNavigateHistory()
                }
            )

            MenuTile(
                icon = Icons.Outlined.Download,
                title = "Downloads",
                subtitle = "Offline movies & series episodes",
                tag = "menu_downloads",
                onClick = {
                    onDismiss()
                    onNavigateDownloads()
                }
            )
        }
    }
}

@Composable
private fun MenuTile(
    icon: ImageVector,
    title: String,
    subtitle: String,
    tag: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 8.dp)
            .testTag(tag),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(NovaViolet.copy(alpha = 0.15f), RoundedCornerShape(10.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = NovaCyan,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.width(16.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium.copy(
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall.copy(
                    color = TextSecondary,
                    fontSize = 12.sp
                )
            )
        }

        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = TextSecondary,
            modifier = Modifier.size(20.dp)
        )
    }
}
