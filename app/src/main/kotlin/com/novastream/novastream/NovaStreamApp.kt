package com.novastream.novastream

import android.app.Application
import com.novastream.novastream.core.storage.AppDatabase
import com.novastream.novastream.core.storage.NovaRepository

class NovaStreamApp : Application() {
    lateinit var repository: NovaRepository
        private set

    override fun onCreate() {
        super.onCreate()
        val database = AppDatabase.getDatabase(this)
        repository = NovaRepository(this, database)
    }
}
