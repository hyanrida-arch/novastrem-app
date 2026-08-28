package com.novastream.novastream.core.network

import android.content.Context
import com.novastream.novastream.core.storage.dao.DownloadsDao
import com.novastream.novastream.core.storage.entities.DownloadTaskEntity
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap

class DownloadManager(
    private val context: Context,
    private val downloadsDao: DownloadsDao
) {
    private val client = OkHttpClient()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val activeJobs = ConcurrentHashMap<String, Job>()

    fun startDownload(task: DownloadTaskEntity) {
        if (activeJobs.containsKey(task.id)) return

        val job = scope.launch {
            try {
                downloadsDao.insertDownload(
                    task.copy(status = "DOWNLOADING")
                )

                val downloadDir = File(context.filesDir, "downloads")
                if (!downloadDir.exists()) downloadDir.mkdirs()

                val fileName = "media_${task.type}_${task.mediaId}.mp4"
                val destFile = File(downloadDir, fileName)

                val request = Request.Builder().url(task.streamUrl).build()
                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    downloadsDao.updateProgress(
                        id = task.id,
                        progress = 0f,
                        downloadedBytes = 0L,
                        fileSizeBytes = 0L,
                        status = "FAILED",
                        localFilePath = ""
                    )
                    return@launch
                }

                val body = response.body
                val totalBytes = body?.contentLength() ?: 1024L * 1024L * 10L // estimate
                var downloadedBytes = 0L

                val inputStream = body?.byteStream()
                val outputStream = FileOutputStream(destFile)

                val buffer = ByteArray(8 * 1024)
                var bytesRead: Int
                var lastProgressUpdate = System.currentTimeMillis()

                inputStream?.use { input ->
                    outputStream.use { output ->
                        while (input.read(buffer).also { bytesRead = it } != -1) {
                            if (!isActive) {
                                output.flush()
                                return@launch
                            }
                            output.write(buffer, 0, bytesRead)
                            downloadedBytes += bytesRead

                            val now = System.currentTimeMillis()
                            if (now - lastProgressUpdate > 300) {
                                val progress = if (totalBytes > 0) (downloadedBytes.toFloat() / totalBytes).coerceIn(0f, 1f) else 0.5f
                                downloadsDao.updateProgress(
                                    id = task.id,
                                    progress = progress,
                                    downloadedBytes = downloadedBytes,
                                    fileSizeBytes = totalBytes,
                                    status = "DOWNLOADING",
                                    localFilePath = destFile.absolutePath
                                )
                                lastProgressUpdate = now
                            }
                        }
                    }
                }

                downloadsDao.updateProgress(
                    id = task.id,
                    progress = 1f,
                    downloadedBytes = downloadedBytes,
                    fileSizeBytes = totalBytes,
                    status = "COMPLETED",
                    localFilePath = destFile.absolutePath
                )
            } catch (e: Exception) {
                if (e is CancellationException) {
                    downloadsDao.updateProgress(
                        id = task.id,
                        progress = 0f,
                        downloadedBytes = 0L,
                        fileSizeBytes = 0L,
                        status = "PAUSED",
                        localFilePath = ""
                    )
                } else {
                    downloadsDao.updateProgress(
                        id = task.id,
                        progress = 0f,
                        downloadedBytes = 0L,
                        fileSizeBytes = 0L,
                        status = "FAILED",
                        localFilePath = ""
                    )
                }
            } finally {
                activeJobs.remove(task.id)
            }
        }
        activeJobs[task.id] = job
    }

    fun cancelDownload(taskId: String) {
        activeJobs[taskId]?.cancel()
        activeJobs.remove(taskId)
        scope.launch {
            downloadsDao.deleteDownloadById(taskId)
        }
    }
}
