package com.novastream.novastream.core.data

import com.novastream.novastream.core.data.models.*

object DemoCatalog {

    val liveCategories = listOf(
        LiveCategory("demo-news", "News (Demo)"),
        LiveCategory("demo-entertainment", "Entertainment (Demo)"),
        LiveCategory("demo-sports", "Sports (Demo)"),
        LiveCategory("demo-kids", "Kids (Demo)"),
        LiveCategory("demo-movies-live", "Movies (Demo)")
    )

    val liveChannels = listOf(
        LiveChannel(
            streamId = 9001,
            name = "NovaStream News HD",
            categoryId = "demo-news",
            streamIcon = "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400&q=80",
            streamUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        ),
        LiveChannel(
            streamId = 9002,
            name = "NovaStream Kids Planet",
            categoryId = "demo-kids",
            streamIcon = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&q=80",
            streamUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
        ),
        LiveChannel(
            streamId = 9003,
            name = "NovaStream Cinema 1 4K",
            categoryId = "demo-movies-live",
            streamIcon = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400&q=80",
            streamUrl = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        ),
        LiveChannel(
            streamId = 9004,
            name = "NovaStream Entertainment MAX",
            categoryId = "demo-entertainment",
            streamIcon = "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80",
            streamUrl = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        ),
        LiveChannel(
            streamId = 9005,
            name = "NovaStream Sports Live",
            categoryId = "demo-sports",
            streamIcon = "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&q=80",
            streamUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        )
    )

    val vodCategories = listOf(
        VodCategory("demo-action", "Action & Adventure"),
        VodCategory("demo-scifi", "Sci-Fi & Fantasy"),
        VodCategory("demo-animation", "Animation & Family")
    )

    val movies = listOf(
        Movie(
            streamId = 9101,
            name = "Big Buck Bunny (2008)",
            categoryId = "demo-animation",
            rating = 7.8,
            streamIcon = "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80",
            addedAt = System.currentTimeMillis() - (2L * 86400000L),
            streamUrl = "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"
        ),
        Movie(
            streamId = 9102,
            name = "Tears of Steel (2012)",
            categoryId = "demo-scifi",
            rating = 7.2,
            streamIcon = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&q=80",
            addedAt = System.currentTimeMillis() - (5L * 86400000L),
            streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4"
        ),
        Movie(
            streamId = 9103,
            name = "Sintel: Dragon Quest (2010)",
            categoryId = "demo-action",
            rating = 8.1,
            streamIcon = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80",
            addedAt = System.currentTimeMillis() - (40L * 86400000L),
            streamUrl = "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4"
        ),
        Movie(
            streamId = 9104,
            name = "Elephants Dream: Infinite Realm (2006)",
            categoryId = "demo-scifi",
            rating = 7.0,
            streamIcon = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&q=80",
            addedAt = System.currentTimeMillis() - (120L * 86400000L),
            streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
        )
    )

    val movieDetails = mapOf(
        9101 to MovieDetails(
            streamId = 9101,
            name = "Big Buck Bunny (2008)",
            description = "A giant rabbit deals with three bullying forest rodents, in this fan-favorite Blender Foundation open movie. Features stunning high resolution animation and comedic escapades.",
            genre = "Animation, Comedy, Adventure",
            director = "Sacha Goedegebure",
            releaseDate = "2008-04-10",
            rating = 7.8,
            duration = "10m",
            coverUrl = "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&q=80",
            streamUrl = "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"
        ),
        9102 to MovieDetails(
            streamId = 9102,
            name = "Tears of Steel (2012)",
            description = "A group of futuristic warriors and scientists gather in dystopian Amsterdam to stage a crucial event from the past to prevent an AI apocalypse.",
            genre = "Sci-Fi, Cyberpunk",
            director = "Ian Hubert",
            releaseDate = "2012-09-26",
            rating = 7.2,
            duration = "12m",
            coverUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1200&q=80",
            streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4"
        ),
        9103 to MovieDetails(
            streamId = 9103,
            name = "Sintel: Dragon Quest (2010)",
            genre = "Fantasy, Adventure, Drama",
            description = "A lonely young woman, Sintel, helps and befriends an injured baby dragon whom she names Scales. When Scales is kidnapped, she embarks on a dangerous worldwide quest across icy peaks and deserts to reclaim her companion.",
            director = "Colin Levy",
            releaseDate = "2010-09-30",
            rating = 8.1,
            duration = "15m",
            coverUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1200&q=80",
            streamUrl = "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4"
        ),
        9104 to MovieDetails(
            streamId = 9104,
            name = "Elephants Dream: Infinite Realm (2006)",
            description = "Two strange characters, Emo and Proog, explore a capricious and seemingly infinite mechanical universe within the belly of a sentient machine.",
            genre = "Sci-Fi, Surrealism, Animation",
            director = "Bassam Kurdali",
            releaseDate = "2006-03-24",
            rating = 7.0,
            duration = "11m",
            coverUrl = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&q=80",
            streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
        )
    )

    val seriesCategories = listOf(
        SeriesCategory("demo-originals", "NovaStream Originals (Demo)"),
        SeriesCategory("demo-drama", "Drama Series")
    )

    val seriesList = listOf(
        Series(
            seriesId = 9201,
            name = "NovaStream Originals: Cosmos (2024)",
            categoryId = "demo-originals",
            cover = "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=400&q=80",
            rating = 7.9,
            lastModified = System.currentTimeMillis() - (3L * 86400000L),
            numSeasons = 1
        ),
        Series(
            seriesId = 9202,
            name = "Nova Chronicles: Horizons (2023)",
            categoryId = "demo-originals",
            cover = "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=400&q=80",
            rating = 7.4,
            lastModified = System.currentTimeMillis() - (90L * 86400000L),
            numSeasons = 1
        )
    )

    val seriesDetails = mapOf(
        9201 to SeriesDetails(
            seriesId = 9201,
            name = "NovaStream Originals: Cosmos (2024)",
            description = "A two-part cinematic anthology series demonstrating NovaStream's seamless season and episode navigation with high fidelity video streaming.",
            genre = "Sci-Fi, Anthology, Mystery",
            releaseDate = "2024-01-12",
            rating = 7.9,
            coverUrl = "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1200&q=80",
            episodesBySeason = mapOf(
                1 to listOf(
                    Episode(
                        episodeId = 9301,
                        title = "Pilot: The Cosmic Beacon",
                        season = 1,
                        episodeNum = 1,
                        duration = "10m",
                        plot = "Deep space listening post intercepts an ancient repeating pulse from the Andromeda galaxy.",
                        coverUrl = "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=400&q=80",
                        streamUrl = "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"
                    ),
                    Episode(
                        episodeId = 9302,
                        title = "Episode 2: The Quantum Rift",
                        season = 1,
                        episodeNum = 2,
                        duration = "12m",
                        plot = "The exploration crew discovers a temporal rift orbiting a dying star.",
                        coverUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&q=80",
                        streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4"
                    )
                )
            )
        ),
        9202 to SeriesDetails(
            seriesId = 9202,
            name = "Nova Chronicles: Horizons (2023)",
            description = "A compelling exploration drama across distant alien planetary settlements and frontier space stations.",
            genre = "Adventure, Drama",
            releaseDate = "2023-11-03",
            rating = 7.4,
            coverUrl = "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=800&q=80",
            backdropUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&q=80",
            episodesBySeason = mapOf(
                1 to listOf(
                    Episode(
                        episodeId = 9303,
                        title = "Episode 1: Awakening",
                        season = 1,
                        episodeNum = 1,
                        duration = "11m",
                        plot = "Settlers awake from cryosleep above a mysterious terrestrial anomaly.",
                        coverUrl = "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=400&q=80",
                        streamUrl = "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
                    ),
                    Episode(
                        episodeId = 9304,
                        title = "Episode 2: Echoes of Eternity",
                        season = 1,
                        episodeNum = 2,
                        duration = "15m",
                        plot = "First contact team navigates the mysterious crystalline valleys.",
                        coverUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80",
                        streamUrl = "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4"
                    )
                )
            )
        )
    )

    private val epgRotation = mapOf(
        9001 to listOf("Morning World Bulletin", "Global News Live", "Business Insight", "Evening Prime Edition", "Late Night Wrap-Up"),
        9002 to listOf("Cartoon Carnival Fun", "Kids' Galaxy Adventure", "Storytime Special", "Puzzle Playhouse"),
        9003 to listOf("Blockbuster 4K Premiere", "Cinema Classic", "Director's Spotlight", "Hollywood Tonight"),
        9004 to listOf("Talk of the Town", "Prime Variety Special", "The Late Night Show", "Top 40 Music Video Countdown"),
        9005 to listOf("Matchday Stadium Live", "Post-Game Analysis", "Sports Highlights Recap", "Motorsport Championship")
    )

    fun getEpgForChannel(streamId: Int): EpgProgram {
        val titles = epgRotation[streamId] ?: listOf("NovaStream Programming", "Featured Entertainment")
        val now = System.currentTimeMillis()
        val slotDuration = 30 * 60 * 1000L // 30 mins
        val slotStart = (now / slotDuration) * slotDuration
        val slotEnd = slotStart + slotDuration
        val slotIndex = ((slotStart / slotDuration) % titles.size).toInt()
        val title = titles[slotIndex]

        return EpgProgram(
            title = title,
            startTime = slotStart,
            endTime = slotEnd,
            description = "Now streaming on NovaStream channel $streamId. Crystal clear HD broadcast."
        )
    }

    fun getStreamUrl(id: Int): String {
        return when (id) {
            9001, 9005 -> "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
            9002 -> "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
            9003, 9004 -> "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
            9101, 9301 -> "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4"
            9102, 9302 -> "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4"
            9103, 9304 -> "https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4"
            9104, 9303 -> "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4"
            else -> "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        }
    }
}
