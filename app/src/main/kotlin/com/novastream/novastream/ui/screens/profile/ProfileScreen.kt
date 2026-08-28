package com.novastream.novastream.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.GlassCard
import kotlinx.coroutines.launch

@Composable
fun ProfileScreen(
    repository: NovaRepository,
    onLogout: () -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val session by repository.activeSession.collectAsStateWithLifecycle()
    var showLogoutDialog by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp)
                .padding(bottom = 80.dp)
        ) {
            Text(
                text = "Account & Profile",
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
            )

            Spacer(modifier = Modifier.height(20.dp))

            // User Info Card
            GlassCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("profile_card"),
                backgroundColor = DarkSurfaceElevated
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        color = NovaViolet,
                        shape = CircleShape,
                        modifier = Modifier.size(56.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    Column {
                        Text(
                            text = session?.profileName ?: "NovaStream User",
                            style = MaterialTheme.typography.titleMedium.copy(
                                fontWeight = FontWeight.Bold,
                                color = TextPrimary
                            )
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Surface(
                            color = if (session?.isDemo == true) NovaCyan.copy(alpha = 0.2f) else NovaVioletDark.copy(alpha = 0.4f),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text(
                                text = if (session?.isDemo == true) "DEMO PROFILE" else if (session?.isM3u == true) "M3U PLAYLIST" else "XTREAM PRO",
                                color = NovaCyan,
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "SUBSCRIPTION DETAILS",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextSecondary
                )
            )

            Spacer(modifier = Modifier.height(10.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    InfoRow(
                        icon = Icons.Outlined.Cloud,
                        label = "Server Endpoint",
                        value = session?.serverUrl ?: "https://novastream.tv"
                    )
                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 10.dp))
                    InfoRow(
                        icon = Icons.Outlined.AccountCircle,
                        label = "Username",
                        value = session?.username ?: "demo_user"
                    )
                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 10.dp))
                    InfoRow(
                        icon = Icons.Outlined.CalendarToday,
                        label = "Expiration Date",
                        value = session?.expiryDate ?: "Unlimited"
                    )
                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 10.dp))
                    InfoRow(
                        icon = Icons.Outlined.Devices,
                        label = "Allowed Connections",
                        value = "${session?.activeConnections ?: 1} / ${session?.maxConnections ?: 5} active"
                    )
                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 10.dp))
                    InfoRow(
                        icon = Icons.Outlined.CheckCircle,
                        label = "Account Status",
                        value = session?.status ?: "Active"
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Sign Out Button
            Button(
                onClick = { showLogoutDialog = true },
                colors = ButtonDefaults.buttonColors(containerColor = NovaLiveRed.copy(alpha = 0.85f)),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .testTag("sign_out_btn")
            ) {
                Icon(
                    imageVector = Icons.Default.Logout,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Sign Out Account",
                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold)
                )
            }
        }

        if (showLogoutDialog) {
            AlertDialog(
                onDismissRequest = { showLogoutDialog = false },
                containerColor = DarkSurface,
                title = { Text("Sign Out", color = TextPrimary, fontWeight = FontWeight.Bold) },
                text = { Text("Are you sure you want to disconnect and switch profiles?", color = TextSecondary) },
                confirmButton = {
                    Button(
                        onClick = {
                            showLogoutDialog = false
                            coroutineScope.launch {
                                repository.logout()
                                onLogout()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = NovaLiveRed)
                    ) {
                        Text("Sign Out")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showLogoutDialog = false }) {
                        Text("Cancel", color = TextSecondary)
                    }
                }
            )
        }
    }
}

@Composable
private fun InfoRow(
    icon: ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = NovaCyan,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium.copy(color = TextSecondary),
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium.copy(
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
        )
    }
}
