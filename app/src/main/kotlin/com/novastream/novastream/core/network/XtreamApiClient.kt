package com.novastream.novastream.core.network

import com.novastream.novastream.core.data.models.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class XtreamApiClient(
    private val serverUrl: String,
    private val username: String,
    private val password: String
) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .build()

    private val baseUrl: String = serverUrl.trimEnd('/')

    suspend fun authenticate(): Result<UserSession> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/player_api.php?username=$username&password=$password"
            val request = Request.Builder().url(url).build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) {
                return@withContext Result.failure(Exception("HTTP Error: ${response.code}"))
            }
            val body = response.body?.string() ?: return@withContext Result.failure(Exception("Empty body"))
            val json = JSONObject(body)
            val userInfo = json.optJSONObject("user_info")
                ?: return@withContext Result.failure(Exception("Invalid credentials or server response"))

            val authStatus = userInfo.optInt("auth", 0)
            if (authStatus != 1) {
                return@withContext Result.failure(Exception("Authentication failed"))
            }

            val session = UserSession(
                id = "xtream_${username}_${System.currentTimeMillis()}",
                profileName = username.replaceFirstChar { it.uppercase() },
                username = username,
                password = password,
                serverUrl = baseUrl,
                isDemo = false,
                isM3u = false,
                expiryDate = userInfo.optString("exp_date", "Active"),
                maxConnections = userInfo.optInt("max_connections", 1),
                activeConnections = userInfo.optInt("active_cons", 1),
                isTrial = userInfo.optString("is_trial") == "1",
                status = userInfo.optString("status", "Active")
            )
            Result.success(session)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getLiveCategories(): List<LiveCategory> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_live_categories"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<LiveCategory>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    LiveCategory(
                        categoryId = obj.optString("category_id"),
                        categoryName = obj.optString("category_name")
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getLiveStreams(categoryId: String? = null): List<LiveChannel> = withContext(Dispatchers.IO) {
        try {
            val catParam = if (categoryId != null) "&category_id=$categoryId" else ""
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams$catParam"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<LiveChannel>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val streamId = obj.optInt("stream_id")
                val streamType = obj.optString("stream_type", "live")
                val ext = obj.optString("container_extension", "ts")
                val streamUrl = "$baseUrl/live/$username/$password/$streamId.$ext"
                list.add(
                    LiveChannel(
                        streamId = streamId,
                        name = obj.optString("name"),
                        categoryId = obj.optString("category_id"),
                        streamIcon = obj.optString("stream_icon").takeIf { it.isNotBlank() },
                        streamType = streamType,
                        num = obj.optInt("num", i + 1),
                        epgChannelId = obj.optString("epg_channel_id"),
                        streamUrl = streamUrl
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getVodCategories(): List<VodCategory> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_categories"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<VodCategory>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    VodCategory(
                        categoryId = obj.optString("category_id"),
                        categoryName = obj.optString("category_name")
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getVodStreams(categoryId: String? = null): List<Movie> = withContext(Dispatchers.IO) {
        try {
            val catParam = if (categoryId != null) "&category_id=$categoryId" else ""
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_vod_streams$catParam"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<Movie>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val streamId = obj.optInt("stream_id")
                val ext = obj.optString("container_extension", "mp4")
                val streamUrl = "$baseUrl/movie/$username/$password/$streamId.$ext"
                list.add(
                    Movie(
                        streamId = streamId,
                        name = obj.optString("name"),
                        categoryId = obj.optString("category_id"),
                        streamIcon = obj.optString("stream_icon").takeIf { it.isNotBlank() },
                        rating = obj.optDouble("rating_5based", obj.optDouble("rating", 0.0)),
                        addedAt = obj.optLong("added", System.currentTimeMillis()),
                        containerExtension = ext,
                        streamUrl = streamUrl
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getSeriesCategories(): List<SeriesCategory> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_series_categories"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<SeriesCategory>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    SeriesCategory(
                        categoryId = obj.optString("category_id"),
                        categoryName = obj.optString("category_name")
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun getSeries(categoryId: String? = null): List<Series> = withContext(Dispatchers.IO) {
        try {
            val catParam = if (categoryId != null) "&category_id=$categoryId" else ""
            val url = "$baseUrl/player_api.php?username=$username&password=$password&action=get_series$catParam"
            val response = client.newCall(Request.Builder().url(url).build()).execute()
            val jsonArray = JSONArray(response.body?.string() ?: "[]")
            val list = mutableListOf<Series>()
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    Series(
                        seriesId = obj.optInt("series_id"),
                        name = obj.optString("name"),
                        categoryId = obj.optString("category_id"),
                        cover = obj.optString("cover").takeIf { it.isNotBlank() },
                        rating = obj.optDouble("rating_5based", obj.optDouble("rating", 0.0)),
                        lastModified = obj.optLong("last_modified", System.currentTimeMillis()),
                        numSeasons = obj.optInt("num_seasons", 1)
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }
}
