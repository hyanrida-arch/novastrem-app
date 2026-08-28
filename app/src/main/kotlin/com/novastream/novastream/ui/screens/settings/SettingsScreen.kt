package com.novastream.novastream.ui.screens.settings

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.novastream.novastream.core.storage.NovaRepository
import com.novastream.novastream.core.theme.*
import com.novastream.novastream.ui.components.GlassCard
import com.novastream.novastream.ui.components.PinDialog
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    repository: NovaRepository
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val settings by repository.settings.collectAsStateWithLifecycle()

    var showPinDialog by remember { mutableStateOf(false) }

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
                text = "Player & App Settings",
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Playback Section
            Text(
                text = "STREAM PLAYBACK ENGINE",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextSecondary
                )
            )
            Spacer(modifier = Modifier.height(8.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Stream Format
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Stream Format",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                            Text(
                                text = "Recommended: HLS (m3u8)",
                                style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                            )
                        }

                        var formatExpanded by remember { mutableStateOf(false) }
                        Box {
                            TextButton(
                                onClick = { formatExpanded = true },
                                modifier = Modifier.testTag("stream_format_selector")
                            ) {
                                Text(settings.streamFormat, color = NovaCyan, fontWeight = FontWeight.Bold)
                            }
                            DropdownMenu(
                                expanded = formatExpanded,
                                onDismissRequest = { formatExpanded = false },
                                modifier = Modifier.background(DarkSurfaceElevated)
                            ) {
                                listOf("HLS", "MPEG-TS", "Auto").forEach { fmt ->
                                    DropdownMenuItem(
                                        text = { Text(fmt, color = TextPrimary) },
                                        onClick = {
                                            formatExpanded = false
                                            coroutineScope.launch {
                                                repository.updateSettings { it.copy(streamFormat = fmt) }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 12.dp))

                    // Buffer Size
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Buffer Size",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                            Text(
                                text = "Lower latency vs smoother playback",
                                style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                            )
                        }

                        var bufferExpanded by remember { mutableStateOf(false) }
                        Box {
                            TextButton(
                                onClick = { bufferExpanded = true },
                                modifier = Modifier.testTag("buffer_size_selector")
                            ) {
                                Text("${settings.bufferSizeMs} ms", color = NovaCyan, fontWeight = FontWeight.Bold)
                            }
                            DropdownMenu(
                                expanded = bufferExpanded,
                                onDismissRequest = { bufferExpanded = false },
                                modifier = Modifier.background(DarkSurfaceElevated)
                            ) {
                                listOf(500, 1500, 3000, 5000).forEach { ms ->
                                    DropdownMenuItem(
                                        text = { Text("$ms ms", color = TextPrimary) },
                                        onClick = {
                                            bufferExpanded = false
                                            coroutineScope.launch {
                                                repository.updateSettings { it.copy(bufferSizeMs = ms) }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 12.dp))

                    // Hardware Acceleration
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Hardware Acceleration",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                            Text(
                                text = "Use GPU video decoder for 4K 60fps",
                                style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                            )
                        }

                        Switch(
                            checked = settings.hardwareAcceleration,
                            onCheckedChange = { isChecked ->
                                coroutineScope.launch {
                                    repository.updateSettings { it.copy(hardwareAcceleration = isChecked) }
                                }
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = NovaViolet,
                                uncheckedTrackColor = DarkCardBorder
                            ),
                            modifier = Modifier.testTag("hardware_accel_switch")
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Privacy & Parental Gate
            Text(
                text = "SECURITY & PRIVACY",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextSecondary
                )
            )
            Spacer(modifier = Modifier.height(8.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    // Parental Controls Lock
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Parental Control Lock",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                            Text(
                                text = if (settings.parentalEnabled) "PIN protection enabled" else "Require 4-digit PIN for restricted content",
                                style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                            )
                        }

                        Switch(
                            checked = settings.parentalEnabled,
                            onCheckedChange = {
                                showPinDialog = true
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = NovaViolet,
                                uncheckedTrackColor = DarkCardBorder
                            ),
                            modifier = Modifier.testTag("parental_switch")
                        )
                    }

                    Divider(color = DarkCardBorder, modifier = Modifier.padding(vertical = 12.dp))

                    // Incognito Mode
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Incognito Mode",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = TextPrimary
                                )
                            )
                            Text(
                                text = "Pause recording to Watch History",
                                style = MaterialTheme.typography.bodySmall.copy(color = TextSecondary)
                            )
                        }

                        Switch(
                            checked = settings.incognito,
                            onCheckedChange = { isChecked ->
                                coroutineScope.launch {
                                    repository.updateSettings { it.copy(incognito = isChecked) }
                                }
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = NovaViolet,
                                uncheckedTrackColor = DarkCardBorder
                            ),
                            modifier = Modifier.testTag("incognito_switch")
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Storage & Maintenance
            Text(
                text = "STORAGE & APPLICATION",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextSecondary
                )
            )
            Spacer(modifier = Modifier.height(8.dp))

            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Button(
                        onClick = {
                            context.cacheDir.deleteRecursively()
                            Toast.makeText(context, "Stream cache cleaned successfully", Toast.LENGTH_SHORT).show()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = DarkSurfaceElevated),
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("clear_cache_btn")
                    ) {
                        Icon(
                            imageVector = Icons.Default.CleaningServices,
                            contentDescription = null,
                            tint = NovaCyan,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Clear Stream Cache", color = TextPrimary)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // App About
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "NovaStream Android v1.0.0",
                    style = MaterialTheme.typography.labelMedium.copy(
                        color = TextSecondary,
                        fontWeight = FontWeight.SemiBold
                    )
                )
                Text(
                    text = "Built with Jetpack Compose & Android Media3",
                    style = MaterialTheme.typography.labelSmall.copy(
                        color = TextDisabled,
                        fontSize = 11.sp
                    )
                )
            }
        }

        if (showPinDialog) {
            PinDialog(
                title = if (settings.parentalEnabled) "Disable Parental Controls" else "Enable Parental Controls",
                subtitle = if (settings.parentalEnabled) "Enter your current PIN to disable" else "Set default PIN: 0000 or enter PIN",
                expectedPin = settings.parentalPin.ifBlank { "0000" },
                onSuccess = {
                    showPinDialog = false
                    coroutineScope.launch {
                        repository.updateSettings {
                            it.copy(
                                parentalEnabled = !it.parentalEnabled,
                                parentalPin = if (it.parentalPin.isBlank()) "0000" else it.parentalPin
                            )
                        }
                    }
                },
                onDismiss = { showPinDialog = false }
            )
        }
    }
}
