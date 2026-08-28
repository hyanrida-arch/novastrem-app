package com.novastream.novastream.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.novastream.novastream.core.data.models.SortOption
import com.novastream.novastream.core.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterBottomSheet(
    availableCategories: List<String>,
    selectedCategory: String?,
    onSelectCategory: (String?) -> Unit,
    availableYears: List<String>,
    selectedYear: String?,
    onSelectYear: (String?) -> Unit,
    selectedSort: SortOption,
    onSelectSort: (SortOption) -> Unit,
    onResetFilters: () -> Unit,
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
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Filter & Sort",
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                )

                IconButton(
                    onClick = onResetFilters,
                    modifier = Modifier.testTag("reset_filters_btn")
                ) {
                    Icon(
                        imageVector = Icons.Default.RestartAlt,
                        contentDescription = "Reset Filters",
                        tint = NovaCyan
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Sort By
            Text(
                text = "SORT BY",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    color = TextSecondary
                )
            )
            Spacer(modifier = Modifier.height(8.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(SortOption.entries) { sort ->
                    val isSelected = selectedSort == sort
                    CategoryFilterChip(
                        text = sort.displayName,
                        isSelected = isSelected,
                        onClick = { onSelectSort(sort) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Category Filter
            if (availableCategories.isNotEmpty()) {
                Text(
                    text = "CATEGORY",
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = FontWeight.Bold,
                        color = TextSecondary
                    )
                )
                Spacer(modifier = Modifier.height(8.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    item {
                        CategoryFilterChip(
                            text = "All Categories",
                            isSelected = selectedCategory == null,
                            onClick = { onSelectCategory(null) }
                        )
                    }
                    items(availableCategories) { cat ->
                        CategoryFilterChip(
                            text = cat,
                            isSelected = selectedCategory == cat,
                            onClick = { onSelectCategory(cat) }
                        )
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
            }

            // Year Filter
            if (availableYears.isNotEmpty()) {
                Text(
                    text = "RELEASE YEAR",
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontWeight = FontWeight.Bold,
                        color = TextSecondary
                    )
                )
                Spacer(modifier = Modifier.height(8.dp))
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    item {
                        CategoryFilterChip(
                            text = "All Years",
                            isSelected = selectedYear == null,
                            onClick = { onSelectYear(null) }
                        )
                    }
                    items(availableYears) { year ->
                        CategoryFilterChip(
                            text = year,
                            isSelected = selectedYear == year,
                            onClick = { onSelectYear(year) }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .testTag("apply_filters_btn"),
                colors = ButtonDefaults.buttonColors(containerColor = NovaViolet),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Apply Filters", fontWeight = FontWeight.Bold)
            }
        }
    }
}
