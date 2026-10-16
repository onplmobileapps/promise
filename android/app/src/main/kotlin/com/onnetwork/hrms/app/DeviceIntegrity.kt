package com.onnetwork.hrms.app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Signs that the phone can't be trusted to say where it is: root (which
 * lets fake GPS apps hide), or an emulator.
 */
object DeviceIntegrity {
    private val suPaths = listOf(
        "/system/bin/su", "/system/xbin/su", "/sbin/su", "/system/su",
        "/system/bin/.ext/.su", "/system/usr/we-need-root/su",
        "/system/app/Superuser.apk", "/data/local/xbin/su", "/data/local/bin/su",
        "/data/local/su", "/su/bin/su", "/system/sd/xbin/su",
        "/system/bin/failsafe/su", "/cache/su", "/data/su", "/dev/su",
        "/sbin/.magisk", "/data/adb/magisk", "/data/adb/ksu", "/data/adb/ap",
    )

    /** Root managers and hooking frameworks; listed in the manifest's queries. */
    private val rootPackages = listOf(
        "com.topjohnwu.magisk", "io.github.vvb2060.magisk", "io.github.huskydg.magisk",
        "me.weishu.kernelsu", "me.bmax.apatch", "eu.chainfire.supersu",
        "com.noshufou.android.su", "com.noshufou.android.su.elite",
        "com.koushikdutta.superuser", "com.thirdparty.superuser", "com.yellowes.su",
        "com.kingroot.kinguser", "com.kingo.root", "com.smedialink.oneclickroot",
        "com.zhiqupk.root.global", "com.alephzain.framaroot",
        "de.robv.android.xposed.installer", "org.lsposed.manager",
        "org.meowcat.edxposed.manager",
    )

    fun check(context: Context): Map<String, Any> {
        val reasons = mutableListOf<String>()
        if (Build.TAGS?.contains("test-keys") == true) reasons += "test-keys build"
        suPaths.firstOrNull { File(it).exists() }?.let { reasons += "found $it" }
        if (suRuns()) reasons += "su on the path"
        rootPackages.firstOrNull { installed(context, it) }?.let { reasons += "installed $it" }
        if (prop("ro.secure") == "0") reasons += "ro.secure=0"
        val emulator = isEmulator()
        return mapOf(
            "rooted" to reasons.isNotEmpty(),
            "emulator" to emulator,
            "reasons" to (reasons + if (emulator) listOf("emulator") else emptyList()),
        )
    }

    private fun installed(context: Context, name: String): Boolean = try {
        context.packageManager.getPackageInfo(name, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun suRuns(): Boolean = run("which", "su").isNotBlank()

    private fun prop(name: String): String = run("getprop", name).trim()

    private fun run(vararg command: String): String = try {
        val process = ProcessBuilder(*command).redirectErrorStream(true).start()
        val out = process.inputStream.bufferedReader().use { it.readText() }
        process.waitFor(2, TimeUnit.SECONDS)
        if (process.exitValue() == 0) out else ""
    } catch (_: Exception) {
        ""
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.orEmpty()
        val model = Build.MODEL.orEmpty()
        val product = Build.PRODUCT.orEmpty()
        val hardware = Build.HARDWARE.orEmpty()
        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator") ||
            fingerprint.contains("sdk_gphone") ||
            model.contains("Emulator") ||
            model.contains("Android SDK built for") ||
            model.startsWith("sdk_gphone") ||
            Build.MANUFACTURER.orEmpty().contains("Genymotion") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            product.startsWith("sdk_") ||
            product.contains("emulator") ||
            product.contains("simulator") ||
            (Build.BRAND.orEmpty().startsWith("generic") &&
                Build.DEVICE.orEmpty().startsWith("generic")) ||
            prop("ro.kernel.qemu") == "1"
    }
}
