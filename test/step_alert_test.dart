import 'package:dhealth/services/background_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// [decideStepAlert] 是純函數。這裡鎖住的行為都是過去真實踩過的：
/// 正常的「還沒達標」不是錯誤；讀不到資料不能當 0 步，更不能憑空恭喜。
void main() {
  const margin = 1000;

  test('達標 → Goal Reached', () {
    expect(decideStepAlert(steps: 6000, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.goalReached);
    expect(decideStepAlert(steps: 9000, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.goalReached);
  });

  test('差一步到差 [margin] 步 → Almost There', () {
    expect(decideStepAlert(steps: 5999, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.almostThere);
    expect(decideStepAlert(steps: 5000, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.almostThere);
  });

  test('差很遠 → 什麼都不發（舊版走 else 發「Error Occurred: Not fit any criteria」）', () {
    expect(decideStepAlert(steps: 100, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.none);
    expect(decideStepAlert(steps: 0, dailyStepGoal: 6000, almostThereMargin: margin), StepAlert.none);
  });

  test('讀不到步數（null）交給錯誤路徑，不是 0 步也不是 999 步', () {
    // 999 這個 sentinel 過去會去跟預設 300 的目標比，發出「Goal Reached! 999 步」。
    expect(decideStepAlert(steps: null, dailyStepGoal: 300, almostThereMargin: margin), StepAlert.none);
  });

  test('目標 0 或負的不會每 15 分鐘恭喜一次', () {
    expect(decideStepAlert(steps: 0, dailyStepGoal: 0, almostThereMargin: margin), StepAlert.none);
    expect(decideStepAlert(steps: 500, dailyStepGoal: -10, almostThereMargin: margin), StepAlert.none);
  });
}
