// A minimal binding to the ONNX Runtime C API, for small models the app
// runs itself (today: the Arabic diacritizer, `arabic_diacritizer.dart`).
//
// No new native library: it uses the `libonnxruntime` that sherpa_onnx
// already ships for the reading voice (1.28.2 on Android). Only the handful
// of OrtApi functions we call are bound, by their index in `struct OrtApi`
// (append-only across releases; indices read from onnxruntime_c_api.h 1.28.2
// and checked by test/arabic_diacritizer_test.dart against the real library).
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _GetApiN = Pointer<Pointer<Void>> Function(Uint32);
typedef _GetApiD = Pointer<Pointer<Void>> Function(int);
typedef _GetVersionN = Pointer<Utf8> Function();

typedef _StatusOutN = Pointer<Void> Function(Pointer<Pointer<Void>>);
typedef _StatusOutD = Pointer<Void> Function(Pointer<Pointer<Void>>);
typedef _CreateEnvN = Pointer<Void> Function(Int32, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _CreateEnvD = Pointer<Void> Function(int, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _SetIntN = Pointer<Void> Function(Pointer<Void>, Int32);
typedef _SetIntD = Pointer<Void> Function(Pointer<Void>, int);
typedef _FromArrayN = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Size, Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FromArrayD = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int, Pointer<Void>, Pointer<Pointer<Void>>);
typedef _CpuInfoN = Pointer<Void> Function(Int32, Int32, Pointer<Pointer<Void>>);
typedef _CpuInfoD = Pointer<Void> Function(int, int, Pointer<Pointer<Void>>);
typedef _TensorN = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Size, Pointer<Int64>, Size, Int32, Pointer<Pointer<Void>>);
typedef _TensorD = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, int, Pointer<Int64>, int, int, Pointer<Pointer<Void>>);
typedef _RunN = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Pointer<Void>>, Size,
    Pointer<Pointer<Utf8>>, Size, Pointer<Pointer<Void>>);
typedef _RunD = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Pointer<Void>>, int,
    Pointer<Pointer<Utf8>>, int, Pointer<Pointer<Void>>);
typedef _DataN = Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _CountN = Pointer<Void> Function(Pointer<Void>, Pointer<Size>);
typedef _CountD = Pointer<Void> Function(Pointer<Void>, Pointer<Size>);
typedef _DimsN = Pointer<Void> Function(Pointer<Void>, Pointer<Int64>, Size);
typedef _DimsD = Pointer<Void> Function(Pointer<Void>, Pointer<Int64>, int);
typedef _MsgN = Pointer<Utf8> Function(Pointer<Void>);
typedef _ReleaseN = Void Function(Pointer<Void>);
typedef _ReleaseD = void Function(Pointer<Void>);

/// `struct OrtApi` member indices (onnxruntime_c_api.h, 1.28.2).
abstract final class _I {
  static const getErrorMessage = 2;
  static const createEnv = 3;
  static const createSessionFromArray = 8;
  static const run = 9;
  static const createSessionOptions = 10;
  static const setSessionGraphOptimizationLevel = 23;
  static const setIntraOpNumThreads = 24;
  static const setInterOpNumThreads = 25;
  static const createTensorWithDataAsOrtValue = 49;
  static const getTensorMutableData = 51;
  static const getDimensionsCount = 61;
  static const getDimensions = 62;
  static const getTensorTypeAndShape = 65;
  static const createCpuMemoryInfo = 69;
  static const releaseEnv = 92;
  static const releaseStatus = 93;
  static const releaseMemoryInfo = 94;
  static const releaseSession = 95;
  static const releaseValue = 96;
  static const releaseTensorTypeAndShapeInfo = 99;
  static const releaseSessionOptions = 100;
}

class OrtException implements Exception {
  OrtException(this.message);
  final String message;
  @override
  String toString() => 'OrtException: $message';
}

/// The loaded runtime (one per isolate). [open] returns null when the
/// library is not available on this platform — callers fall back cleanly.
class OrtRuntime {
  OrtRuntime._(this._api, this.version);

  final Pointer<Pointer<Void>> _api;
  final String version;
  Pointer<Void>? _env;

  /// API version requested from GetApi — old enough for every function we bind.
  static const _apiVersion = 16;

  static OrtRuntime? open({String? libraryPath}) {
    try {
      final DynamicLibrary lib;
      if (libraryPath != null) {
        lib = DynamicLibrary.open(libraryPath);
      } else if (Platform.isAndroid || Platform.isLinux) {
        lib = DynamicLibrary.open('libonnxruntime.so');
      } else if (Platform.isWindows) {
        lib = DynamicLibrary.open('onnxruntime.dll');
      } else {
        lib = DynamicLibrary.process(); // iOS / macOS: linked into the app
      }
      final base = lib.lookupFunction<Pointer<Pointer<Void>> Function(), Pointer<Pointer<Void>> Function()>('OrtGetApiBase')();
      final getApi = base[0].cast<NativeFunction<_GetApiN>>().asFunction<_GetApiD>();
      final getVersion = base[1].cast<NativeFunction<_GetVersionN>>().asFunction<Pointer<Utf8> Function()>();
      final api = getApi(_apiVersion);
      if (api == nullptr) return null;
      return OrtRuntime._(api, getVersion().toDartString());
    } catch (_) {
      return null;
    }
  }

  Pointer<NativeFunction<T>> _fn<T extends Function>(int index) => _api[index].cast<NativeFunction<T>>();

  void _check(Pointer<Void> status) {
    if (status == nullptr) return;
    final msg = _fn<_MsgN>(_I.getErrorMessage).asFunction<Pointer<Utf8> Function(Pointer<Void>)>()(status).toDartString();
    _release(_I.releaseStatus, status);
    throw OrtException(msg);
  }

  void _release(int index, Pointer<Void> p) {
    if (p == nullptr) return;
    _fn<_ReleaseN>(index).asFunction<_ReleaseD>()(p);
  }

  Pointer<Void> _envPtr() {
    final existing = _env;
    if (existing != null) return existing;
    return using((arena) {
      final out = arena<Pointer<Void>>();
      // ORT_LOGGING_LEVEL_ERROR = 3
      _check(_fn<_CreateEnvN>(_I.createEnv).asFunction<_CreateEnvD>()(3, 'talib'.toNativeUtf8(allocator: arena), out));
      return _env = out.value;
    });
  }

  /// A session over the model bytes (the bytes may be freed afterwards).
  OrtSession createSession(Uint8List model, {int threads = 1}) {
    return using((arena) {
      final opts = arena<Pointer<Void>>();
      _check(_fn<_StatusOutN>(_I.createSessionOptions).asFunction<_StatusOutD>()(opts));
      try {
        final setInt = _fn<_SetIntN>(_I.setIntraOpNumThreads).asFunction<_SetIntD>();
        _check(setInt(opts.value, threads));
        _check(_fn<_SetIntN>(_I.setInterOpNumThreads).asFunction<_SetIntD>()(opts.value, 1));
        _check(_fn<_SetIntN>(_I.setSessionGraphOptimizationLevel).asFunction<_SetIntD>()(opts.value, 99)); // ORT_ENABLE_ALL
        final buf = arena<Uint8>(model.length);
        buf.asTypedList(model.length).setAll(0, model);
        final session = arena<Pointer<Void>>();
        _check(_fn<_FromArrayN>(_I.createSessionFromArray).asFunction<_FromArrayD>()(
            _envPtr(), buf.cast(), model.length, opts.value, session));
        return OrtSession._(this, session.value);
      } finally {
        _release(_I.releaseSessionOptions, opts.value);
      }
    });
  }

  void dispose() {
    final env = _env;
    if (env != null) _release(_I.releaseEnv, env);
    _env = null;
  }
}

class OrtSession {
  OrtSession._(this._rt, this._session);
  final OrtRuntime _rt;
  Pointer<Void> _session;

  /// One int64 input `[1, n]` → one float32 output; returns (data, shape).
  (Float32List, List<int>) runInt64ToFloat(String inputName, List<int> ids, String outputName) {
    if (_session == nullptr) throw OrtException('session disposed');
    final rt = _rt;
    return using((arena) {
      final mem = arena<Pointer<Void>>();
      // OrtArenaAllocator = 1, OrtMemTypeDefault = 0
      rt._check(rt._fn<_CpuInfoN>(_I.createCpuMemoryInfo).asFunction<_CpuInfoD>()(1, 0, mem));
      final input = arena<Pointer<Void>>();
      final outputs = arena<Pointer<Void>>();
      final info = arena<Pointer<Void>>();
      try {
        final data = arena<Int64>(ids.length);
        data.asTypedList(ids.length).setAll(0, ids);
        final shape = arena<Int64>(2)
          ..[0] = 1
          ..[1] = ids.length;
        // ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64 = 7
        rt._check(rt._fn<_TensorN>(_I.createTensorWithDataAsOrtValue).asFunction<_TensorD>()(
            mem.value, data.cast(), ids.length * 8, shape, 2, 7, input));
        final inNames = arena<Pointer<Utf8>>()..value = inputName.toNativeUtf8(allocator: arena);
        final outNames = arena<Pointer<Utf8>>()..value = outputName.toNativeUtf8(allocator: arena);
        outputs.value = nullptr;
        rt._check(rt._fn<_RunN>(_I.run).asFunction<_RunD>()(_session, nullptr, inNames, input, 1, outNames, 1, outputs));

        rt._check(rt._fn<_DataN>(_I.getTensorTypeAndShape).asFunction<Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>)>()(outputs.value, info));
        final count = arena<Size>();
        rt._check(rt._fn<_CountN>(_I.getDimensionsCount).asFunction<_CountD>()(info.value, count));
        final dims = arena<Int64>(count.value);
        rt._check(rt._fn<_DimsN>(_I.getDimensions).asFunction<_DimsD>()(info.value, dims, count.value));
        final outShape = [for (var i = 0; i < count.value; i++) dims[i]];
        final n = outShape.fold(1, (a, b) => a * b);
        final ptr = arena<Pointer<Void>>();
        rt._check(rt._fn<_DataN>(_I.getTensorMutableData).asFunction<Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>)>()(outputs.value, ptr));
        final result = Float32List.fromList(ptr.value.cast<Float>().asTypedList(n));
        return (result, outShape);
      } finally {
        rt._release(_I.releaseTensorTypeAndShapeInfo, info.value);
        rt._release(_I.releaseValue, outputs.value);
        rt._release(_I.releaseValue, input.value);
        rt._release(_I.releaseMemoryInfo, mem.value);
      }
    });
  }

  void dispose() {
    _rt._release(_I.releaseSession, _session);
    _session = nullptr;
  }
}
