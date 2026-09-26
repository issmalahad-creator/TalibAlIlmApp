import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/boot/boot_scheduler.dart';

void main() {
  final boot = BootScheduler.instance;
  setUp(boot.resetForTest);
  tearDown(boot.resetForTest);

  test('nothing runs at registration', () async {
    var ran = 0;
    boot.register('a', () async => ran++);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ran, 0);
  });

  test('ensure is idempotent: concurrent and repeated callers share one run', () async {
    var ran = 0;
    boot.register('a', () async {
      ran++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await Future.wait([boot.ensure('a'), boot.ensure('a'), boot.ensure('a')]);
    await boot.ensure('a');
    expect(ran, 1);
  });

  test('unknown id completes immediately', () async {
    await boot.ensure('does-not-exist');
  });

  test('warm-up runs tasks one at a time in priority order', () async {
    final order = <String>[];
    var active = 0;
    var maxActive = 0;
    Future<void> Function() task(String id) => () async {
          active++;
          if (active > maxActive) maxActive = active;
          order.add(id);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
        };
    boot
      ..register('late', task('late'), priority: 60)
      ..register('first', task('first'), priority: 10)
      ..register('mid', task('mid'), priority: 30);
    boot.markHomeReady();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(order, ['first', 'mid', 'late']);
    expect(maxActive, 1);
  });

  test('ensure lets a screen jump the queue ahead of warm-up', () async {
    final order = <String>[];
    boot
      ..register('a', () async => order.add('a'), priority: 10)
      ..register('b', () async => order.add('b'), priority: 20);
    await boot.ensure('b');
    boot.markHomeReady();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(order, ['b', 'a']);
  });

  test('afterHome tasks wait for Home, not the safety timer', () async {
    final order = <String>[];
    boot
      ..register('seed', () async => order.add('seed'), priority: 10)
      ..register('notify', () async => order.add('notify'), priority: 5, afterHome: true)
      ..armSafetyTimer(after: const Duration(milliseconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(order, ['seed']);
    boot.markHomeReady();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(order, ['seed', 'notify']);
    boot.markHomeReady(); // Home reloads — must not re-run anything.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(order, ['seed', 'notify']);
  });

  test('a failing task does not stop the ones after it', () async {
    final order = <String>[];
    boot
      ..register('bad', () async => throw StateError('boom'), priority: 10)
      ..register('good', () async => order.add('good'), priority: 20);
    boot.markHomeReady();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(order, ['good']);
  });
}
