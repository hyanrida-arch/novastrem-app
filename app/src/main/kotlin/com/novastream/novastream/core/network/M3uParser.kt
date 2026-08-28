package com.novastream.novastream.core.network

import com.novastream.novastream.core.data.models.LiveCategory
import com.novastream.novastream.core.data.models.LiveChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.BufferedReader
import java.io.StringReader

data class M3uParseResult(
    val categories: List<LiveCategory>,
    val channels: List<LiveChannel>
)

object M3uParser {
    private val client = OkHttpClient()

    suspend fun parseFromUrl(url: String): M3uParseResult = withContext(Dispatchers.IO) {
        val request = Request.Builder().url(url).build()
        val response = client.newCall(request).execute()
        val content = response.body?.string() ?: ""
        parse(content)
    }

    fun parse(content: String): M3uParseResult {
        val reader = BufferedReader(StringReader(content))
        val channels = mutableListOf<LiveChannel>()
        val categories = mutableMapOf<String, LiveCategory>()

        var line: String?
        var currentTvgId: String? = null
        var currentTvgName: String? = null
        var currentTvgLogo: String? = null
        var currentGroupTitle: String = "General"
        var currentChannelName: String = ""
        var streamIdCounter = 1

        val groupTitleRegex = """group-title="([^"]*)"""".toRegex(RegexOption.IGNORE_CASE)
        val tvgLogoRegex = """tvg-logo="([^"]*)"""".toRegex(RegexOption.IGNORE_CASE)
        val tvgNameRegex = """tvg-name="([^"]*)"""".toRegex(RegexOption.IGNORE_CASE)
        val tvgIdRegex = """tvg-id="([^"]*)"""".toRegex(RegexOption.IGNORE_CASE)

        while (reader.readLine().also { line = it } != null) {
            val trimmed = line!!.trim()
            if (trimmed.startsWith("#EXTINF:", ignoreCase = true)) {
                // Parse attributes
                groupTitleRegex.find(trimmed)?.let { currentGroupTitle = it.groupValues[1].ifBlank { "General" } }
                tvgLogoRegex.find(trimmed)?.let { currentTvgLogo = it.groupValues[1] }
                tvgNameRegex.find(trimmed)?.let { currentTvgName = it.groupValues[1] }
                tvgIdRegex.find(trimmed)?.let { currentTvgId = it.groupValues[1] }

                val commaIndex = trimmed.lastIndexOf(',')
                currentChannelName = if (commaIndex != -1) {
                    trimmed.substring(commaIndex + 1).trim()
                } else {
                    currentTvgName ?: "Channel $streamIdCounter"
                }

                val categoryId = currentGroupTitle.lowercase().replace(" ", "_")
                if (!categories.containsKey(categoryId)) {
                    categories[categoryId] = LiveCategory(categoryId, currentGroupTitle)
                }
            } else if (trimmed.isNotBlank() && !trimmed.startsWith("#")) {
                // Stream URL line
                val categoryId = currentGroupTitle.lowercase().replace(" ", "_")
                channels.add(
                    LiveChannel(
                        streamId = streamIdCounter,
                        name = currentChannelName.ifBlank { "Channel $streamIdCounter" },
                        categoryId = categoryId,
                        streamIcon = currentTvgLogo,
                        epgChannelId = currentTvgId,
                        num = streamIdCounter,
                        streamUrl = trimmed
                    )
                )
                streamIdCounter++
                // Reset for next
                currentGroupTitle = "General"
                currentTvgLogo = null
                currentTvgId = null
                currentTvgName = null
                currentChannelName = ""
            }
        }

        return M3uParseResult(
            categories = categories.values.toList(),
            channels = channels
        )
    }
}
