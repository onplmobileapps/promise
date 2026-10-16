package com.onnetwork.hrms.app

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Files the app makes for the user, such as attendance reports: saved to
 * the phone's Downloads, in a PROMISE folder, then opened or shared.
 */
object Downloads {
    private const val FOLDER = "PROMISE"

    /** Thrown when Android 9 or older hasn't let the app write to storage. */
    class NeedsPermission : Exception("Storage permission is needed")

    /** Saves [bytes] as [name] in Downloads; gives the file's content URI. */
    fun save(activity: Activity, name: String, mime: String, bytes: ByteArray): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveToMediaStore(activity, name, mime, bytes)
        } else {
            saveToFolder(activity, name, mime, bytes)
        }

    private fun saveToMediaStore(
        activity: Activity,
        name: String,
        mime: String,
        bytes: ByteArray,
    ): String {
        val resolver = activity.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mime)
            put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$FOLDER")
            // Hidden from other apps until it is written.
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Downloads refused the file")
        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Couldn't write the file")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        return uri.toString()
    }

    @Suppress("DEPRECATION")
    private fun saveToFolder(
        activity: Activity,
        name: String,
        mime: String,
        bytes: ByteArray,
    ): String {
        val granted = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) throw NeedsPermission()
        val folder = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            FOLDER,
        )
        folder.mkdirs()
        val file = unused(folder, name)
        file.writeBytes(bytes)
        // The scanner lists it in Downloads and gives a URI other apps can
        // open, which a plain file path no longer is.
        var scanned: Uri? = null
        val done = CountDownLatch(1)
        MediaScannerConnection.scanFile(activity, arrayOf(file.path), arrayOf(mime)) { _, uri ->
            scanned = uri
            done.countDown()
        }
        done.await(10, TimeUnit.SECONDS)
        return (scanned ?: throw IllegalStateException("The file wasn't listed")).toString()
    }

    /** [name] in [folder], numbered if a file already has it. */
    private fun unused(folder: File, name: String): File {
        var file = File(folder, name)
        val stem = name.substringBeforeLast('.')
        val extension = name.substringAfterLast('.', "")
        var count = 1
        while (file.exists()) {
            file = File(folder, "$stem ($count).$extension")
            count++
        }
        return file
    }

    /** Opens the saved file in an app that shows it; false if none can. */
    fun open(activity: Activity, uri: String, mime: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(Uri.parse(uri), mime)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Offers the saved file to other apps, such as WhatsApp or email. */
    fun share(activity: Activity, uri: String, mime: String, title: String): Boolean {
        val send = Intent(Intent.ACTION_SEND)
            .setType(mime)
            .putExtra(Intent.EXTRA_STREAM, Uri.parse(uri))
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            activity.startActivity(Intent.createChooser(send, title))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
