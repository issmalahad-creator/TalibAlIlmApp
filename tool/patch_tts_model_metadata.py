"""tool/patch_tts_model_metadata.py — القارئ الصوتي العام.

نموذج Piper VITS المُصدَّر عبر export_onnx القياسي (بما فيه إعادة تعبئة HF
الرسمية لـsherpa_onnx) لا يحمل metadata_props داخل ملف ONNX نفسه — sherpa_onnx
يحتاجها (sample_rate تحديدًا) ويفشل صامتًا (exit code 255، بلا استثناء
يمكن التقاطه في Dart) بدونها. هذا اكتُشِف فقط بتشغيل فعلي على جهاز Android
حقيقي (2026-09-18)، ليس افتراضًا من التوثيق. القيم هنا مأخوذة من
ar_JO-kareem-medium.onnx.json (الملف المرافق نفسه) + القيم الافتراضية
الموثَّقة في k2-fsa/sherpa-onnx#574 لبقية الحقول.

يُستدعى تلقائيًا من tool/fetch_tts_voice.sh بعد كل تنزيل جديد — لا حاجة
لتشغيله يدويًا في المسار العادي.
"""

import json
import onnx

ASSETS_DIR = "assets/tts"
# The model is a content pack (voice.kareem) since 2026-09-29 — lives in packs/.
MODEL_PATH = f"{ASSETS_DIR}/packs/ar_JO-kareem-medium.onnx"
CONFIG_PATH = f"{ASSETS_DIR}/ar_JO-kareem-medium.onnx.json"


def main() -> None:
    with open(CONFIG_PATH, encoding="utf-8") as f:
        config = json.load(f)

    metadata = {
        "noise_scale_w": str(config["inference"]["noise_w"]),
        "noise_scale": str(config["inference"]["noise_scale"]),
        "has_espeak": "1",
        "voice": config["espeak"]["voice"],
        "n_speakers": "1",
        "language": config["language"]["name_english"],
        "sample_rate": str(config["audio"]["sample_rate"]),
        "comment": "piper",
        "version": "1",
        "model_author": "rhasspy",
        "model_type": "vits",
    }

    model = onnx.load(MODEL_PATH)
    existing_keys = {p.key for p in model.metadata_props}

    for key, value in metadata.items():
        if key in existing_keys:
            continue
        entry = model.metadata_props.add()
        entry.key = key
        entry.value = value
        print(f"added metadata: {key} = {value}")

    onnx.save(model, MODEL_PATH)
    print(f"saved: {MODEL_PATH}")


if __name__ == "__main__":
    main()
