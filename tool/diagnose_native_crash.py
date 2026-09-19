#!/usr/bin/env python3
"""يحلّل تلقائيًا أحدث تعطّل أصلي (native crash) من سجلّ logcat: يستخرج
مسار الاستدعاء (backtrace) من نص debuggerd، يرمّز كل عنوان بالاسم الحقيقي
عبر llvm-addr2line (إن توفّرت معلومات تصحيح)، ويفكّك (disassemble) التعليمة
المسؤولة فعليًا عن التعطّل لعرض السبب التقني الدقيق — دون الحاجة لتكرار هذه
الخطوات يدويًا في كل مرة.

الاستخدام:
    py diagnose_native_crash.py <ملف_سجلّ.txt> [مسار_lib.so]

إن لم يُحدَّد مسار .so، يستخدم افتراضيًا نسخة sherpa_onnx_android الحالية
من pub cache (arm64-v8a) — عدّل SO_PATH أدناه إن تغيّر الإصدار.
"""

import re
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

NDK = Path(r"C:\Users\ismail\AppData\Local\Android\Sdk\ndk\28.2.13676358")
ADDR2LINE = NDK / "toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-addr2line.exe"
OBJDUMP = NDK / "toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-objdump.exe"
READELF = NDK / "toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe"

DEFAULT_SO = Path(
    r"C:\Users\ismail\AppData\Local\Pub\Cache\hosted\pub.dev"
    r"\sherpa_onnx_android-1.12.36\android\src\main\jniLibs\arm64-v8a"
    r"\libsherpa-onnx-c-api.so"
)

BACKTRACE_LINE = re.compile(
    r"#(\d+)\s+pc\s+([0-9a-f]+)\s+.*?!(\S+\.so)\s*(?:\((.*?)\))?"
)
FAULT_LINE = re.compile(r"fault addr (0x[0-9a-fA-F]+)")
CAUSE_LINE = re.compile(r"Cause:\s*(.+)")


def find_build_id(so_path: Path) -> str | None:
    out = subprocess.run([str(READELF), "-n", str(so_path)], capture_output=True, text=True).stdout
    m = re.search(r"Build ID:\s*([0-9a-f]+)", out)
    return m.group(1) if m else None


def extract_latest_crash(log_text: str) -> dict:
    """يأخذ آخر كتلة تعطّل (من *** Native Crash TIME حتى نهاية backtrace)."""
    blocks = log_text.split("Native Crash TIME")
    if len(blocks) < 2:
        sys.exit("لا يوجد تعطّل أصلي في هذا السجلّ.")
    block = "Native Crash TIME" + blocks[-1]

    fault_match = FAULT_LINE.search(block)
    cause_match = CAUSE_LINE.search(block)
    frames = []
    for line in block.splitlines():
        m = BACKTRACE_LINE.search(line)
        if m:
            frames.append({
                "index": int(m.group(1)),
                "pc": m.group(2),
                "lib": m.group(3),
                "extra": m.group(4) or "",
            })

    return {
        "fault_addr": fault_match.group(1) if fault_match else "؟",
        "cause": cause_match.group(1) if cause_match else "غير محدَّد",
        "frames": frames,
    }


def symbolize(so_path: Path, pc_hex: str) -> tuple[str, str]:
    out = subprocess.run(
        [str(ADDR2LINE), "-e", str(so_path), "-f", "-C", "-i", f"0x{pc_hex}"],
        capture_output=True, text=True,
    ).stdout.strip().splitlines()
    func = out[0] if out else "؟"
    loc = out[1] if len(out) > 1 else "؟"
    return func, loc


def disassemble_around(so_path: Path, pc_hex: str, window: int = 0x20) -> str:
    addr = int(pc_hex, 16)
    start = max(0, addr - window)
    stop = addr + 8
    out = subprocess.run(
        [str(OBJDUMP), "-d", f"--start-address=0x{start:x}", f"--stop-address=0x{stop:x}", str(so_path)],
        capture_output=True, text=True,
    ).stdout
    return out


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("الاستخدام: py diagnose_native_crash.py <log.txt> [lib.so]")

    log_path = Path(sys.argv[1])
    so_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_SO

    if not so_path.exists():
        sys.exit(f"مكتبة .so غير موجودة: {so_path}")

    crash = extract_latest_crash(log_path.read_text(encoding="utf-8", errors="ignore"))

    print(f"عنوان العطل (fault addr): {crash['fault_addr']}")
    print(f"السبب المُبلَّغ من النظام: {crash['cause']}")
    print(f"مكتبة .so المُستخدَمة للترميز: {so_path.name}")
    build_id = find_build_id(so_path)
    print(f"Build ID محلي: {build_id}")

    matching_frames = [f for f in crash["frames"] if "sherpa" in f["lib"].lower()]
    if not matching_frames:
        print("\nلا إطارات (frames) من sherpa_onnx في هذا التعطّل — قد يكون خللًا مختلفًا.")
        return

    print(f"\n=== مسار الاستدعاء ({len(matching_frames)} إطارًا) ===")
    for f in matching_frames:
        func, loc = symbolize(so_path, f["pc"])
        tag = " (رمز عام معروف)" if func != "??" else ""
        print(f"  #{f['index']:02d}  0x{f['pc']}  {func}{tag}  [{loc}]")

    closest = matching_frames[0]
    print(f"\n=== تفكيك التعليمات حول نقطة العطل الفعلية (الإطار #{closest['index']}) ===")
    print(disassemble_around(so_path, closest["pc"]))


if __name__ == "__main__":
    main()
