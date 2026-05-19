package com.norton.intern.scam_message_detector

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.norton.intern.scam_message_detector/native_health"

        @Volatile
        private var llamaNativeAvailable: Boolean? = null

        /**
         * Tries to load the flutter_llama native dependency graph in a controlled
         * try/catch. Result is cached for the life of the process so we never
         * trigger the buggy load path twice.
         *
         * The `flutter_llama` plugin (1.1.2) silently swallows load failures in
         * its companion init block and then throws `UnsatisfiedLinkError` from
         * a background pool thread the first time a native method is called —
         * which crashes the whole app because Kotlin's `catch (Exception)`
         * doesn't catch `Error`. The probe here lets the Dart layer skip the
         * local-llama path entirely when the libraries aren't usable.
         */
        @Synchronized
        private fun probeLlamaNative(): Boolean {
            llamaNativeAvailable?.let { return it }
            return try {
                System.loadLibrary("c++_shared")
                System.loadLibrary("ggml-base")
                System.loadLibrary("ggml-cpu")
                System.loadLibrary("ggml")
                System.loadLibrary("llama")
                System.loadLibrary("flutter_llama_bridge")
                llamaNativeAvailable = true
                true
            } catch (e: UnsatisfiedLinkError) {
                Log.w(TAG, "flutter_llama native libraries unavailable: ${e.message}")
                llamaNativeAvailable = false
                false
            } catch (e: Throwable) {
                Log.w(TAG, "flutter_llama probe failed: ${e.message}")
                llamaNativeAvailable = false
                false
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installNativeCrashGuard()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isLlamaNativeAvailable" -> result.success(probeLlamaNative())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Installs a default uncaught-exception handler that swallows
     * [UnsatisfiedLinkError] / [LinkageError] coming out of background pool
     * threads. Without this, the broken `flutter_llama` 1.1.2 native bridge
     * can take the whole process down with a `FATAL EXCEPTION` even though
     * we've already guarded the Dart side. Anything else still propagates to
     * Android's default handler.
     */
    private fun installNativeCrashGuard() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            if (isNativeLibraryError(throwable)) {
                Log.e(
                    TAG,
                    "Suppressed native library error from ${thread.name}: " +
                        throwable.message,
                )
                llamaNativeAvailable = false
                return@setDefaultUncaughtExceptionHandler
            }
            previous?.uncaughtException(thread, throwable)
        }
    }

    private fun isNativeLibraryError(t: Throwable?): Boolean {
        var cursor: Throwable? = t
        var depth = 0
        while (cursor != null && depth < 8) {
            if (cursor is UnsatisfiedLinkError || cursor is LinkageError) {
                return true
            }
            cursor = cursor.cause
            depth += 1
        }
        return false
    }
}
