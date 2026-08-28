package com.novastream.novastream.core.data.models

import kotlinx.serialization.Serializable

@Serializable
enum class ContentType {
    LIVE,
    MOVIE,
    SERIES
}
