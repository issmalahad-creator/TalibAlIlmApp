package com.sunnahinstitute.talib_alilm

import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * قناة OCR (Tesseract4Android) لكتب "مكتبتي" المصوَّرة بلا طبقة نص —
 * حزمتا Flutter الجاهزتان (flutter_tesseract_ocr، tesseract_ocr) فشلتا فعليًا
 * في البناء على AGP 9 في هذا المشروع (وحدة Gradle قديمة لا تُطبِّق
 * com.android.library)، فكُتِبت هذه القناة يدويًا مباشرة فوق مكتبة
 * Tesseract4Android الأصلية (JitPack) بدل حزمة وسيطة معطوبة.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "talib_alilm/tesseract_ocr"

    /**
     * رجوع من الشاشة الجذرية ← التطبيق إلى الخلفية بدل إنهاء النشاط وفصل
     * محرّك Flutter. إنهاؤه أثناء تجهيز أول تشغيل (استيراد ضخم في SQLite)
     * أبقى الرئيسية عالقة >17 دقيقة عند العودة (قياس 2026-09-26،
     * docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md §3)، وتجعل
     * العودة تشغيلًا دافئًا فوريًا — سلوك Android 12+ الافتراضي لتطبيقات الجذر.
     */
    override fun popSystemNavigator(): Boolean {
        moveTaskToBack(true)
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "extractText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val imagePath = call.argument<String>("imagePath")
                val dataPath = call.argument<String>("dataPath")
                val language = call.argument<String>("language") ?: "ara"
                if (imagePath == null || dataPath == null) {
                    result.error("ARGS", "imagePath و dataPath مطلوبان", null)
                    return@setMethodCallHandler
                }
                // TessBaseAPI غير آمن عبر الخيوط، وOCR بطيء (ثوانٍ) — عن قصد
                // خارج خيط الواجهة حتى لا يُجمِّد التطبيق أثناء المعالجة.
                Thread {
                    try {
                        val text = runOcr(imagePath, dataPath, language)
                        runOnUiThread { result.success(text) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("OCR_FAILED", e.message, null) }
                    }
                }.start()
            }
    }

    private fun runOcr(imagePath: String, dataPath: String, language: String): String {
        val bitmap =
            BitmapFactory.decodeFile(imagePath)
                ?: throw IllegalStateException("تعذّر فك ترميز الصورة: $imagePath")
        val tess = TessBaseAPI()
        try {
            if (!tess.init(dataPath, language)) {
                throw IllegalStateException(
                    "فشل تهيئة Tesseract (dataPath=$dataPath, lang=$language) — " +
                        "تأكّد من وجود $dataPath/tessdata/$language.traineddata"
                )
            }
            tess.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
            tess.setImage(bitmap)
            return tess.utF8Text ?: ""
        } finally {
            tess.recycle()
            bitmap.recycle()
        }
    }
}
