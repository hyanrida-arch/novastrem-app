package com.novastream.novastream.core.storage

import android.content.Context
import com.novastream.novastream.core.data.DemoCatalog
import com.novastream.novastream.core.data.models.*
import com.novastream.novastream.core.network.DownloadManager
import com.novastream.novastream.core.network.M3uParser
import com.novastream.novastream.core.network.XtreamApiClient
import com.novastream.novastream.core.storage.entities.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class NovaRepository(
    private val context: Context,
    private val database: AppDatabase
) {
    private val scope = CoroutineScope(Dispatchers.IO)
    val downloadManager = DownloadManager(context, database.downloadsDao())

    val activeSession: StateFlow<UserSession?> = database.userSessionDao().getActiveSession()
        .map { entity ->
            entity?.let {
                UserSession(
                    id = it.id,
                    profileName = it.profileName,
                    username = it.username,
                    password = it.password,
                    serverUrl = it.serverUrl,
                    isDemo = it.isDemo,
                    isM3u = it.isM3u,
                    m3uUrl = it.m3uUrl,
                    expiryDate = it.expiryDate,
                    maxConnections = it.maxConnections,
                    activeConnections = it.activeConnections,
                    isTrial = it.isTrial,
                    status = it.status,
                    createdAt = it.createdAt
                )
            }
        }
        .stateIn(scope, SharingStarted.Eagerly, null)

    val settings: StateFlow<SettingsState> = database.settingsDao().getSettings()
        .map { entity ->
            if (entity != null) {
                SettingsState(
                    streamFormat = entity.streamFormat,
                    bufferSizeMs = entity.bufferSizeMs,
                    hardwareAcceleration = entity.hardwareAcceleration,
                    defaultAspectRatio = entity.defaultAspectRatio,
                    parentalPin = entity.parentalPin,
                    parentalEnabled = entity.parentalEnabled,
                    hideAdultContent = entity.hideAdultContent,
                    incognito = entity.incognito,
                    appLanguage = entity.appLanguage
                )
            } else {
                SettingsState()
            }
        }
        .stateIn(scope, SharingStarted.Eagerly, SettingsState())

    val allFavorites = database.favoritesDao().getAllFavorites()
    val allHistory = database.historyDao().getAllHistory()
    val allDownloads = database.downloadsDao().getAllDownloads()

    // Dynamic Catalog Data
    private val _liveCategories = MutableStateFlow<List<LiveCategory>>(emptyList())
    val liveCategories: StateFlow<List<LiveCategory>> = _liveCategories.asStateFlow()

    private val _liveChannels = MutableStateFlow<List<LiveChannel>>(emptyList())
    val liveChannels: StateFlow<List<LiveChannel>> = _liveChannels.asStateFlow()

    private val _vodCategories = MutableStateFlow<List<VodCategory>>(emptyList())
    val vodCategories: StateFlow<List<VodCategory>> = _vodCategories.asStateFlow()

    private val _movies = MutableStateFlow<List<Movie>>(emptyList())
    val movies: StateFlow<List<Movie>> = _movies.asStateFlow()

    private val _movieDetailsMap = MutableStateFlow<Map<Int, MovieDetails>>(emptyMap())

    private val _seriesCategories = MutableStateFlow<List<SeriesCategory>>(emptyList())
    val seriesCategories: StateFlow<List<SeriesCategory>> = _seriesCategories.asStateFlow()

    private val _seriesList = MutableStateFlow<List<Series>>(emptyList())
    val seriesList: StateFlow<List<Series>> = _seriesList.asStateFlow()

    private val _seriesDetailsMap = MutableStateFlow<Map<Int, SeriesDetails>>(emptyMap())

    private var xtreamClient: XtreamApiClient? = null

    init {
        scope.launch {
            activeSession.collect { session ->
                if (session != null) {
                    loadCatalogForSession(session)
                } else {
                    clearCatalog()
                }
            }
        }
    }

    suspend fun loginWithDemo(): Result<UserSession> {
        val demoSession = UserSession(
            id = "demo_account",
            profileName = "Demo Explorer",
            username = "demo_user",
            serverUrl = "https://novastream.tv",
            isDemo = true,
            expiryDate = "Unlimited (Demo Mode)",
            maxConnections = 5,
            activeConnections = 1,
            isTrial = false,
            status = "Active"
        )
        saveSessionToDb(demoSession)
        loadCatalogForSession(demoSession)
        return Result.success(demoSession)
    }

    suspend fun loginWithXtream(serverUrl: String, username: String, password: String, profileName: String?): Result<UserSession> {
        val client = XtreamApiClient(serverUrl, username, password)
        val authResult = client.authenticate()
        return if (authResult.isSuccess) {
            val session = authResult.getOrThrow().let {
                if (!profileName.isNullOrBlank()) it.copy(profileName = profileName) else it
            }
            xtreamClient = client
            saveSessionToDb(session)
            loadCatalogForSession(session)
            Result.success(session)
        } else {
            authResult
        }
    }

    suspend fun loginWithM3u(m3uUrl: String, playlistName: String?): Result<UserSession> {
        return try {
            val session = UserSession(
                id = "m3u_${System.currentTimeMillis()}",
                profileName = playlistName?.ifBlank { "M3U Playlist" } ?: "M3U Playlist",
                serverUrl = m3uUrl,
                isDemo = false,
                isM3u = true,
                m3uUrl = m3uUrl,
                expiryDate = "Active (M3U)",
                status = "Connected"
            )
            saveSessionToDb(session)
            loadCatalogForSession(session)
            Result.success(session)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun saveSessionToDb(session: UserSession) {
        database.userSessionDao().saveSession(
            UserSessionEntity(
                id = session.id,
                profileName = session.profileName,
                username = session.username,
                password = session.password,
                serverUrl = session.serverUrl,
                isDemo = session.isDemo,
                isM3u = session.isM3u,
                m3uUrl = session.m3uUrl,
                expiryDate = session.expiryDate,
                maxConnections = session.maxConnections,
                activeConnections = session.activeConnections,
                isTrial = session.isTrial,
                status = session.status,
                createdAt = session.createdAt
            )
        )
    }

    suspend fun logout() {
        database.userSessionDao().clearSession()
        clearCatalog()
    }

    private suspend fun loadCatalogForSession(session: UserSession) {
        if (session.isDemo) {
            _liveCategories.value = DemoCatalog.liveCategories
            _liveChannels.value = DemoCatalog.liveChannels
            _vodCategories.value = DemoCatalog.vodCategories
            _movies.value = DemoCatalog.movies
            _movieDetailsMap.value = DemoCatalog.movieDetails
            _seriesCategories.value = DemoCatalog.seriesCategories
            _seriesList.value = DemoCatalog.seriesList
            _seriesDetailsMap.value = DemoCatalog.seriesDetails
        } else if (session.isM3u && session.m3uUrl.isNotBlank()) {
            try {
                val parsed = M3uParser.parseFromUrl(session.m3uUrl)
                _liveCategories.value = parsed.categories
                _liveChannels.value = parsed.channels
                // Also create demo VOD/Series so the full UI remains vibrant
                _vodCategories.value = DemoCatalog.vodCategories
                _movies.value = DemoCatalog.movies
                _movieDetailsMap.value = DemoCatalog.movieDetails
                _seriesCategories.value = DemoCatalog.seriesCategories
                _seriesList.value = DemoCatalog.seriesList
                _seriesDetailsMap.value = DemoCatalog.seriesDetails
            } catch (e: Exception) {
                // Fallback to Demo catalog on network issue
                _liveCategories.value = DemoCatalog.liveCategories
                _liveChannels.value = DemoCatalog.liveChannels
            }
        } else {
            val client = xtreamClient ?: XtreamApiClient(session.serverUrl, session.username, session.password).also { xtreamClient = it }
            val liveCats = client.getLiveCategories()
            _liveCategories.value = if (liveCats.isNotEmpty()) liveCats else DemoCatalog.liveCategories
            val liveStreams = client.getLiveStreams()
            _liveChannels.value = if (liveStreams.isNotEmpty()) liveStreams else DemoCatalog.liveChannels

            val vodCats = client.getVodCategories()
            _vodCategories.value = if (vodCats.isNotEmpty()) vodCats else DemoCatalog.vodCategories
            val vodStreams = client.getVodStreams()
            _movies.value = if (vodStreams.isNotEmpty()) vodStreams else DemoCatalog.movies
            _movieDetailsMap.value = DemoCatalog.movieDetails

            val sCats = client.getSeriesCategories()
            _seriesCategories.value = if (sCats.isNotEmpty()) sCats else DemoCatalog.seriesCategories
            val sList = client.getSeries()
            _seriesList.value = if (sList.isNotEmpty()) sList else DemoCatalog.seriesList
            _seriesDetailsMap.value = DemoCatalog.seriesDetails
        }
    }

    private fun clearCatalog() {
        _liveCategories.value = emptyList()
        _liveChannels.value = emptyList()
        _vodCategories.value = emptyList()
        _movies.value = emptyList()
        _seriesCategories.value = emptyList()
        _seriesList.value = emptyList()
        _movieDetailsMap.value = emptyMap()
        _seriesDetailsMap.value = emptyMap()
    }

    fun getMovieDetails(streamId: Int): MovieDetails {
        return _movieDetailsMap.value[streamId] ?: DemoCatalog.movieDetails[streamId] ?: run {
            val movie = _movies.value.find { it.streamId == streamId }
            MovieDetails(
                streamId = streamId,
                name = movie?.name ?: "Movie $streamId",
                description = "High definition stream available on NovaStream.",
                genre = "Featured Cinema",
                releaseDate = "2024",
                rating = movie?.rating ?: 7.5,
                duration = "1h 45m",
                coverUrl = movie?.streamIcon,
                backdropUrl = movie?.streamIcon,
                streamUrl = movie?.streamUrl ?: DemoCatalog.getStreamUrl(streamId)
            )
        }
    }

    fun getSeriesDetails(seriesId: Int): SeriesDetails {
        return _seriesDetailsMap.value[seriesId] ?: DemoCatalog.seriesDetails[seriesId] ?: run {
            val series = _seriesList.value.find { it.seriesId == seriesId }
            SeriesDetails(
                seriesId = seriesId,
                name = series?.name ?: "Series $seriesId",
                description = "Explore full seasons and episodes in high resolution.",
                genre = "TV Series",
                releaseDate = "2024",
                rating = series?.rating ?: 7.5,
                coverUrl = series?.cover,
                backdropUrl = series?.cover,
                episodesBySeason = mapOf(
                    1 to listOf(
                        Episode(
                            episodeId = 9301,
                            title = "Episode 1: Pilot",
                            season = 1,
                            episodeNum = 1,
                            duration = "45m",
                            plot = "The premiere episode.",
                            coverUrl = series?.cover,
                            streamUrl = DemoCatalog.getStreamUrl(9301)
                        )
                    )
                )
            )
        }
    }

    fun getEpgForChannel(streamId: Int): EpgProgram {
        return DemoCatalog.getEpgForChannel(streamId)
    }

    fun isFavorite(id: String): Flow<Boolean> = database.favoritesDao().isFavorite(id)

    suspend fun toggleFavorite(
        type: ContentType,
        mediaId: Int,
        title: String,
        imageUrl: String?,
        streamUrl: String?,
        rating: Double = 0.0,
        categoryName: String? = null
    ) {
        val id = "${type.name}_$mediaId"
        val exists = database.favoritesDao().isFavoriteSync(id)
        if (exists) {
            database.favoritesDao().deleteFavoriteById(id)
        } else {
            database.favoritesDao().insertFavorite(
                FavoriteEntity(
                    id = id,
                    mediaId = mediaId,
                    type = type.name,
                    title = title,
                    imageUrl = imageUrl,
                    streamUrl = streamUrl,
                    rating = rating,
                    categoryName = categoryName
                )
            )
        }
    }

    suspend fun recordHistory(
        type: ContentType,
        mediaId: Int,
        title: String,
        imageUrl: String?,
        streamUrl: String,
        positionMs: Long,
        durationMs: Long
    ) {
        if (settings.value.incognito) return
        val id = "${type.name}_$mediaId"
        database.historyDao().insertHistory(
            HistoryEntity(
                id = id,
                mediaId = mediaId,
                type = type.name,
                title = title,
                imageUrl = imageUrl,
                streamUrl = streamUrl,
                positionMs = positionMs,
                durationMs = durationMs,
                updatedAt = System.currentTimeMillis()
            )
        )
    }

    suspend fun getHistoryPosition(type: ContentType, mediaId: Int): Long {
        val id = "${type.name}_$mediaId"
        return database.historyDao().getHistoryById(id)?.positionMs ?: 0L
    }

    suspend fun clearHistory() {
        database.historyDao().clearHistory()
    }

    suspend fun clearFavorites() {
        database.favoritesDao().clearFavorites()
    }

    suspend fun updateSettings(transform: (SettingsState) -> SettingsState) {
        val newSettings = transform(settings.value)
        database.settingsDao().saveSettings(
            SettingsEntity(
                id = 1,
                streamFormat = newSettings.streamFormat,
                bufferSizeMs = newSettings.bufferSizeMs,
                hardwareAcceleration = newSettings.hardwareAcceleration,
                defaultAspectRatio = newSettings.defaultAspectRatio,
                parentalPin = newSettings.parentalPin,
                parentalEnabled = newSettings.parentalEnabled,
                hideAdultContent = newSettings.hideAdultContent,
                incognito = newSettings.incognito,
                appLanguage = newSettings.appLanguage
            )
        )
    }
}
