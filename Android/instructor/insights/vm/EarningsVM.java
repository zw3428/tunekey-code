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
import com.spelist.tunekey.entity.StatusHistoryEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;

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
public class EarningsVM extends BaseViewModel {
    public ObservableField<String> studentsString = new ObservableField<>("0");
    public ObservableField<String> earningsString = new ObservableField<>("0");
    public ObservableField<Boolean> isShowValue = new ObservableField<>(true);
    private long oneDay = 24 * 60 * 60 * 1000L;
    public long rangeStartTime = TimeUtils.addDay(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis(), -7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());
    public List<StudentListEntity> studentList = new ArrayList<>();
    public List<LessonScheduleEntity> lessonList = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypeList = new ArrayList<>();
    public int averageStudentsCount = 0;
    public double totalEarning = 0;

    public List<String> studentsChartData = new ArrayList<>();
    public List<String> earningsChartData = new ArrayList<>();

    public TeachingVM.UIEventObservable uc = new TeachingVM.UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> update = new SingleLiveEvent<>();
    }

    public EarningsVM(@NonNull @NotNull Application application) {
        super(application);
        initData();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_TYPE_CHANGED, this::initData);
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_STUDENT_LIST_CHANGED, this::initData);
        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, this::initData);
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_SCHEDULE_CONFIG_CHANGED, this::initData);
    }

    public void initData() {
        studentList.clear();
        averageStudentsCount = 0;
        totalEarning = 0;
        lessonTypeList = ListenerService.shared.teacherData.getLessonTypes();
        studentList.addAll(ListenerService.shared.teacherData.getStudentList());
        Logger.e("studentList==>%s",studentList.size());
        calculateActiveStudentsEveryDay();
    }

    /**
     * 计算每天 active 的学生数
     */
    private void calculateActiveStudentsEveryDay() {
        averageStudentsCount = 0;
        studentsChartData.clear();
//        String jsFile = FuncUtils.getJsFuncStr(getApplication(), "calculate.status.history");
//        V8 v8 = V8.createV8Runtime();
//        MemoryManager scope = new MemoryManager(v8);
//        v8.executeVoidScript(jsFile);
        int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
        int count = 0;
        boolean tempStatus = false;
        int tempTimestamp = (int) (rangeStartTime / 1000L);
        int studentsCount = 0;
        for (int i = 0; i <= daysBetween; i++) {
            studentsChartData.add("0");
        }


        for (StudentListEntity item : studentList) {
            boolean isHaveActive = false;
            count = 0;
            tempStatus = false;
            tempTimestamp = (int) (rangeStartTime / 1000L);
            List<StatusHistoryEntity> arr = item.getStatusHistory();
            if (arr.size() <= 0) {
                continue;
            }
            boolean isLoad = false;
            arr.sort((o1, o2) -> (int) (Double.parseDouble(o1.getChangeTime()) - Double.parseDouble(o2.getChangeTime())));
            for (int i = 0; i < arr.size(); i++) {
                StatusHistoryEntity statusHistoryEntity = arr.get(i);
                double changeDate = Double.parseDouble(statusHistoryEntity.getChangeTime());
                if (TimeUtils.getStartDay((int) changeDate).getTimeInMillis() >= rangeStartTime) {
                    if (!isLoad) {
                        isLoad = true;
                        count = i + 1;
                    }
                }
                if (TimeUtils.getStartDay((int) changeDate).getTimeInMillis() < rangeStartTime) {
                    tempStatus = statusHistoryEntity.getStatus() == 1;
                }
            }
            while (tempTimestamp <= rangeEndTime / 1000L) {
                if (arr.size() > 0) {
                    if (count <= arr.size() - 1) {
                        if (tempTimestamp == (TimeUtils.getStartDay(Integer.parseInt(arr.get(count).getChangeTime())).getTimeInMillis() / 1000)) {
                            tempStatus = arr.get(count).getStatus() == 1;
                            count += 1;
                        }

                    }
                }
                if (tempStatus) {
                    if (!isHaveActive) {
                        isHaveActive = true;
                        studentsCount += 1;
                    }
                    int index = TimeUtils.getDaysBetween(rangeStartTime, tempTimestamp * 1000L);
                    if (index >= 0 && index < studentsChartData.size()) {
                        studentsChartData.set(index, Integer.parseInt(studentsChartData.get(index)) + 1 + "");
                    }
                }

                tempTimestamp +=( oneDay / 1000);

            }


        }
        if (studentsCount != 0) {
            averageStudentsCount = studentsCount;
        }


        // 循环 date
//        for (int t = 0; t <= daysBetween; t++) {
//            int count = 0;
//            // 循环 student
//            for (int i = 0; i < studentList.size(); i++) {
//                V8Array statusHistory = new V8Array(v8);
//                List<StatusHistoryEntity> statusHistoryFromEntity = studentList.get(i).getStatusHistory();
//                String start = "";
//                if (statusHistoryFromEntity.size() > 0) {
//                    for (int w = 0; w < statusHistoryFromEntity.size(); w++) {
//                        StatusHistoryEntity entity = statusHistoryFromEntity.get(w);
//                        String changeTime = entity.getChangeTime();
//                        String ymd = TimeUtils.getTimestampFormatYMD((Double.valueOf(changeTime).intValue()) * 1000L);
//                        if (w == 0) {
//                            start = entity.getChangeTime();
//                        }
//                        V8Object statusFromJava = new V8Object(v8)
//                                .add("changeTime", ymd)
//                                .add("status", entity.getStatus());
//                        statusHistory.push(statusFromJava);
//                    }
//                }
//
//                if (!start.equals("")) {
//                    long startTime = (Double.valueOf(start).intValue()) * 1000L;
//                    long endTime = rangeStartTime + oneDay * t;
//                    if (startTime <= endTime) {
//                        V8Object configFromJava = new V8Object(v8)
//                                .add("timeArr", statusHistory)
//                                .add("start", TimeUtils.getTimestampFormatYMD(startTime))
//                                .add("end", TimeUtils.getTimestampFormatYMD(endTime));
//
//                        Logger.e("-*-*-*-*-*-*-*- start ymd: " + TimeUtils.getTimestampFormatYMD(startTime) + ", end ymd: " + TimeUtils.getTimestampFormatYMD(endTime));
//
//                        V8Array param = new V8Array(v8).push(configFromJava);
//                        boolean status = v8.executeBooleanFunction("calcStatus", param);
//                        Logger.e("-*-*-*-*-*-*-*- student status: " + status);
//                        if (status) {
//                            count++;
//                        }
//                    }
//                }
//            }
//            Logger.e("-*-*-*-*-*-*-*- days " + t + ": " + count);
//            studentsChartData.add(String.valueOf((count)));
//            if (count > averageStudentsCount) {
//                averageStudentsCount = count;
//            }
//        }
//        scope.release();
        getWeeklyEarnings();
    }


    /**
     * 获取每周平均盈利
     */
    @SuppressLint("CheckResult")
    private void getWeeklyEarnings() {
        LessonService
                .getInstance()
                .getTeacherLessonScheduleList(UserService.getInstance().getCurrentUserId(), (int) (rangeStartTime / 1000L), (int) (rangeEndTime / 1000L))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessons -> {
                    lessons.removeIf(LessonScheduleEntity::isCancelled);
                    lessonList = lessons;
                    calculateEarningsEveryday();
                }, throwable -> {
                    Logger.e("-*-*-*-*-*-*-*- 获取 Lesson 失败: " + throwable.getMessage());
                });
    }


    /**
     * 计算每天的 earning
     */
    private void calculateEarningsEveryday() {
        earningsChartData.clear();
        totalEarning = 0;
        int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
        // 循环 date
        for (int t = 0; t <= daysBetween; t++) {
            double earnings = 0;
            for (int i = 0; i < lessonList.size(); i++) {

                long shouldDateTime = ((int) lessonList.get(i).getTKShouldDateTime()) * 1000L;
                if ((shouldDateTime >= rangeStartTime + oneDay * t) && (shouldDateTime < (rangeStartTime + oneDay * (t + 1)))) {
                    String lessonTypeId = lessonList.get(i).getLessonTypeId();
                    double specialPrice = 0;
                    if (lessonList.get(i).getConfigEntity()!=null) {
                         specialPrice = lessonList.get(i).getConfigEntity().getSpecialPrice();
                    }
                    for (int j = 0; j < lessonTypeList.size(); j++) {
                        if (lessonTypeList.get(j).getId().equals(lessonTypeId)) {
                            if (specialPrice>0){
                                earnings += specialPrice;
                            }else {
                                earnings += Double.parseDouble(lessonTypeList.get(j).getPrice());
                            }

                        }
                    }
                }
            }
            earningsChartData.add(String.valueOf((earnings)));
            totalEarning += earnings;
        }
        studentsString.set(String.valueOf(averageStudentsCount));
        earningsString.set(String.valueOf(totalEarning));
        uc.update.call();
//        adapter.updateStudentAndEarningCardValue(String.valueOf(averageStudentsCount), String.valueOf(totalEarning), studentsChartData, earningsChartData);
    }
}
