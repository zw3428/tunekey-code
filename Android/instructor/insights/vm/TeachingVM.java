package com.spelist.tunekey.ui.teacher.insights.vm;

import android.annotation.SuppressLint;
import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * com.spelist.tunekey.ui.insights.vm
 * 2021/5/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class TeachingVM extends BaseViewModel {

    public ObservableField<String> duration = new ObservableField<>("0");
    public ObservableField<String> capacity = new ObservableField<>("0");
    public ObservableField<Boolean> isShowValue = new ObservableField<>(true);
    public int capacityPercent = 0;
    public List<String> workHourChartData = new ArrayList<>();
    public List<String> capacityChartData = new ArrayList<>();
    public List<Integer> lessonHours = new ArrayList<>();
    public double sun = 8;
    public double mon = 8;
    public double tue = 8;
    public double wed = 8;
    public double thu = 8;
    public double fri = 8;
    public double sat = 8;
    public double totalTargetHour = 0;
    public double totalWorkHour = 0;
    private double tempWorkHour = 0;
    private long oneDay = 24 * 60 * 60 * 1000L;
    public List<LessonTypeEntity> lessonTypeList = new ArrayList<>();
    public long rangeStartTime = TimeUtils.getDaysBeforeOrAfter(-7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());
    public boolean isUpdate = false;

    public TeachingVM(@NonNull @NotNull Application application) {
        super(application);
        initData();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_POLICY_CHANGED, () -> {
//            lessonHours = ListenerService.shared.teacherData.getPolicyEntity().getLessonHours();
            Logger.e("======%s", "刷新" + isUpdate);
            if (!isUpdate) {
                initData();
            }
            isUpdate = false;

        });
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_TYPE_CHANGED, () -> {
//            lessonHours = ListenerService.shared.teacherData.getPolicyEntity().getLessonHours();
            initData();
        });
        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, this::initData);
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_SCHEDULE_CONFIG_CHANGED, this::initData);
    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> update = new SingleLiveEvent<>();
    }

    public void initData() {
        workHourChartData.clear();
        capacityChartData.clear();
        totalTargetHour = 0;
        if (ListenerService.shared.teacherData.getPolicyEntity() !=null){


            lessonHours = ListenerService.shared.teacherData.getPolicyEntity().getLessonHours();
            if (lessonHours.size() == 0) {
                for (int i = 0; i < 7; i++) {
                    lessonHours.add(8);
                }
                ListenerService.shared.teacherData.getPolicyEntity().setLessonHours(lessonHours);
            }
        }
        if (lessonHours.size() > 0) {
            sun = (double) lessonHours.get(0);
            mon = (double) lessonHours.get(1);
            tue = (double) lessonHours.get(2);
            wed = (double) lessonHours.get(3);
            thu = (double) lessonHours.get(4);
            fri = (double) lessonHours.get(5);
            sat = (double) lessonHours.get(6);
        }
        lessonTypeList = ListenerService.shared.teacherData.getLessonTypes();
        getLessonScheduleBasedOnRange(rangeStartTime, rangeEndTime);

    }

    public void updatePolicies() {

        isUpdate = true;
        Map<String, Object> map = new HashMap<>();
        map.put("lessonHours", lessonHours);
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .updatePolicy(map)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("======%s", "更新成功");
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    @SuppressLint("DefaultLocale")
    private void getLessonScheduleBasedOnRange(long start, long end) {
        int daysBetween = TimeUtils.getDaysBetween(start, end);
        addSubscribe(LessonService
                .getInstance()
                .getTeacherLessonScheduleList(false, UserService.getInstance().getCurrentUserId(), (int) (start / 1000L), (int) (end / 1000L))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessonList -> {
                    duration.set("0");
                    capacity.set("0");
                    totalWorkHour = 0;
                    for (int i = 0; i <= daysBetween; i++) {
                        tempWorkHour = 0;
                        long timestamp = start + oneDay * i;
                        int index = TimeUtils.getDayOfWeek(timestamp);
                        double specificDayTargetHour = 1;
                        if (getSpecificDayTargetHour(index) != 0) {
                            specificDayTargetHour = getSpecificDayTargetHour(index);
                        }
                        totalTargetHour += specificDayTargetHour;

                        for (LessonScheduleEntity item : lessonList) {
                            if (!item.isCancelled() && !(item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                                if (TimeUtils.getTimestampFormatYMD(item.getShouldDateTime() * 1000L).equals(TimeUtils.getTimestampFormatYMD(timestamp))) {
                                    totalWorkHour += item.getShouldTimeLength();
                                    tempWorkHour += item.getShouldTimeLength();
                                }
                            }

                        }

                        workHourChartData.add(String.valueOf(((tempWorkHour / 60))));

                        capacityChartData.add(String.valueOf(((int) ((tempWorkHour / 60) / specificDayTargetHour * 100))));
                    }

                    capacityPercent = (int) (totalWorkHour / 60 / totalTargetHour * 100);
                    duration.set(String.format("%.1f", totalWorkHour / 60));
                    capacity.set(String.valueOf(capacityPercent));
                    uc.update.call();
//                    adapter.updateHourAndCapacityCardValue(duration, capacity, workHourChartData, capacityChartData);

                }, throwable -> {
                    totalWorkHour = 0;
                    duration.set("0");
                    capacity.set("0");
                    Logger.e("===== 获取 lesson schedule 失败" + throwable.getMessage());
                }));
    }

    /**
     * 获取某一天的目标时长
     *
     * @param index
     * @return
     */
    private double getSpecificDayTargetHour(int index) {
        int i = index - 1;
        if (i > 6) {
            i = i % 7;
        }
        double hour = 0;
        switch (i) {
            case 0:
                hour = sun;
                break;
            case 1:
                hour = mon;
                break;
            case 2:
                hour = tue;
                break;
            case 3:
                hour = wed;
                break;
            case 4:
                hour = thu;
                break;
            case 5:
                hour = fri;
                break;
            case 6:
                hour = sat;
                break;
        }
        return hour;
    }
}
