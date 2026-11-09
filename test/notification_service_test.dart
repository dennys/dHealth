import 'package:dhealth/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 節流與通知時段是**純邏輯**，也是本案最容易錯、錯了最難發現的一段
/// （錯的表現是「該發的沒發、不該發的一直發」，只有真機看得見）。
/// `decideStepAlert` 已有 step_alert_test；這個檔補的是另外兩塊。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // canSend/markSent 自己 new SharedPreferencesAsync()，所以要換掉 platform instance
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('NotificationWindow.contains', () {
    DateTime at(int hour) => DateTime(2026, 11, 9, hour, 15);

    test('一般視窗（7–23）：兩端含進去，外面不發', () {
      const window = NotificationWindow(startHour: 7, endHour: 23);
      expect(window.contains(at(7)), isTrue);
      expect(window.contains(at(23)), isTrue);
      expect(window.contains(at(8)), isTrue);
      expect(window.contains(at(6)), isFalse);
      expect(window.contains(at(0)), isFalse);
    });

    test('跨午夜（22–7）：晚上與凌晨都發，白天不發', () {
      const window = NotificationWindow(startHour: 22, endHour: 7);
      expect(window.contains(at(22)), isTrue);
      expect(window.contains(at(23)), isTrue);
      expect(window.contains(at(0)), isTrue);
      expect(window.contains(at(7)), isTrue);
      expect(window.contains(at(8)), isFalse);
      expect(window.contains(at(12)), isFalse);
    });

    // 鎖住現況：start==end 走的是「一般」分支，所以變成「只有那個小時發得出去」，
    // 不是全天、也不是整天關閉。DEVICE_TEST B-2d 要對照的就是這個行為。
    test('start == end（例 0–0）只有那個小時發得出來', () {
      const window = NotificationWindow(startHour: 0, endHour: 0);
      expect(window.contains(at(0)), isTrue);
      expect(window.contains(at(1)), isFalse);
    });
  });

  group('canSend 節流', () {
    // 0–23 涵蓋所有小時 → 這一組只測節流，不受時段影響
    const allDay = NotificationWindow(startHour: 0, endHour: 23);
    final t0 = DateTime(2026, 11, 9, 12);

    test('從沒發過 → 可以發', () async {
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0), isTrue);
    });

    test('剛發過就再問 → 不發（同一類）', () async {
      await NotificationService.markSent('reach_goal', now: t0);
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0.add(const Duration(minutes: 14))), isFalse);
    });

    test('隔到間隔才放行（15 分鐘：14 分不發、15 分發）', () async {
      await NotificationService.markSent('reach_goal', now: t0);
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0.add(const Duration(minutes: 15))), isTrue);
    });

    test('不同類各走各的節流槽', () async {
      await NotificationService.markSent('reach_goal', now: t0);
      expect(await NotificationService.canSend('motivation', 15, allDay, now: t0), isTrue);
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0), isFalse);
    });

    // 這一條是當初那個 bug 的網：舊版在「判斷能不能發」的當下就寫時間戳，
    // 於是權限沒給、建立通知失敗那幾種情況也會把節流槽燒掉 ——
    // 使用者一顆通知都沒看到，卻要再等一個 frequencyMinutes。
    test('canSend 只判斷、不留記錄（要發成功了才由 markSent 記）', () async {
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0), isTrue);
      expect(await NotificationService.canSend('reach_goal', 15, allDay, now: t0), isTrue);
    });

    test('時段外就算沒發過也不發', () async {
      const nightOnly = NotificationWindow(startHour: 22, endHour: 7);
      expect(await NotificationService.canSend('reach_goal', 15, nightOnly, now: t0), isFalse);
    });
  });
}
