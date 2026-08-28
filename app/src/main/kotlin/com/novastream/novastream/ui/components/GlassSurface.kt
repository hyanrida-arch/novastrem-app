package com.novastream.novastream.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.novastream.novastream.core.theme.*

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    borderColor: Color = DarkCardBorder.copy(alpha = 0.6f),
    borderWidth: Dp = 1.dp,
    backgroundColor: Color = DarkCard.copy(alpha = 0.85f),
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier
            .clip(shape)
            .border(borderWidth, borderColor, shape),
        color = backgroundColor,
        shape = shape
    ) {
        content()
    }
}

@Composable
fun GlassHeader(
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        DarkBackground.copy(alpha = 0.95f),
                        DarkBackground.copy(alpha = 0.75f),
                        Color.Transparent
                    )
                )
            )
            .statusBarsPadding()
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            content = content
        )
    }
}
