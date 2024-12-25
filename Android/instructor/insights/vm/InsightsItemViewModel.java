package com.spelist.tunekey.ui.teacher.insights.vm;

import android.annotation.SuppressLint;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.utils.MemoryManager;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.StatusHistoryEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.insights.adapter.ViewPagerBindingAdapter;
import com.spelist.tunekey.ui.teacher.insights.fragments.InsightsFragment;
import com.spelist.tunekey.ui.teacher.insights.adapter.ViewPagerBindingAdapter;
import com.spelist.tunekey.ui.teacher.insights.fragments.InsightsFragment;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.ItemViewModel;

public class InsightsItemViewModel extends ItemViewModel<InsightsViewModel> {
    public MutableLiveData<Integer> promptToBeProLayoutVisibility = new MutableLiveData<>();
    public boolean isPro = true;
    public InsightsViewModel insightsViewModel;
    public ViewPagerBindingAdapter adapter;
    public InsightsFragment insightsFragment;

    public InsightsItemViewModel(@NonNull InsightsViewModel viewModel,
                                 InsightsFragment insightsFragment, int i) {
        super(viewModel);
        this.insightsViewModel = viewModel;
        this.insightsFragment = insightsFragment;
//        initData(i);
    }

    public void initData(int position, ViewPagerBindingAdapter adapter) {

        this.adapter = adapter;
        promptToBeProLayoutVisibility.setValue(View.VISIBLE);
//        if (isPro) {
//            promptToBeProLayoutVisibility.setValue(8);
//        }else {
//            promptToBeProLayoutVisibility.setValue(0);
//        }
        if (position == 0) {
            getWeeklyTargetHours();
        } else if (position == 1) {
            getWeeklyStudents();
        } else if (position == 2) {
            getWeeklyLearning();
        }
    }

    // teaching
    public String period = "Weekly";
    public String duration = "0";
    public String capacity = "0";

    // earning
    public String studentsAvg = "0";
    public String earnings = "0";

    // learning
    public String practice = "0";
    public String achievements = "0";


    // data connection
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
    public int capacityPercent = 0;
    public List<String> workHourChartData = new ArrayList<>();
    public List<String> capacityChartData = new ArrayList<>();
    public int averageStudentsCount = 0;
    public double totalEarning = 0;
    public List<String> studentsChartData = new ArrayList<>();
    public List<String> earningsChartData = new ArrayList<>();
    public List<String> practiceChartData = new ArrayList<>();
    public List<String> achievementsChartData = new ArrayList<>();
    public List<StudentListEntity> studentList = new ArrayList<>();
    public List<LessonScheduleEntity> lessonList = new ArrayList<>();
    private int tempWorkHour = 0;
    private long oneDay = 24 * 60 * 60 * 1000L;
    public List<LessonTypeEntity> lessonTypeList = new ArrayList<>();
    public String userCreateTime;

    /**
     * teaching 数据清空
     */
    public void clearHourAndCapacity() {
        totalTargetHour = 0;
        totalWorkHour = 0;
        capacityPercent = 0;
        workHourChartData.clear();
        capacityChartData.clear();
        tempWorkHour = 0;
        lessonTypeList.clear();
    }

    /**
     * earning 数据清空
     */
    public void clearStudentsAndEarning() {
        averageStudentsCount = 0;
        totalEarning = 0;
        studentList.clear();
        studentsChartData.clear();
        earningsChartData.clear();
    }

    /**
     * learning 数据清空
     */
    public void clearPracticeAndAchievements() {
        practiceChartData.clear();
        achievementsChartData.clear();
    }

    /**
     * 获取每周目标工作时间
     */
    @SuppressLint("CheckResult")
    private void getWeeklyTargetHours() {
        clearHourAndCapacity();
        UserService
                .getInstance()
                .getPolicy()
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(),true)
                .subscribe(policyEntity -> {
                    lessonHours = policyEntity.getLessonHours();
                    if (lessonHours.size() > 0) {
                        sun = (double) lessonHours.get(0);
                        mon = (double) lessonHours.get(1);
                        tue = (double) lessonHours.get(2);
                        wed = (double) lessonHours.get(3);
                        thu = (double) lessonHours.get(4);
                        fri = (double) lessonHours.get(5);
                        sat = (double) lessonHours.get(6);
                    }
                    getTeacherLessonTypeList();
                }, throwable -> {
                    Logger.e("===== 获取 policy 失败" + throwable.getMessage());
                });
    }

    /**
     * 获取每周平均学生数
     */
    @SuppressLint("CheckResult")
    private void getWeeklyStudents() {
        clearStudentsAndEarning();
        UserService
                .getInstance()
                .getStudentListForTeacher(false)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(list -> {
                    studentList = list;
//                    getTeacherAccountStartTime();
                    calculateActiveStudentsEveryDay();
                }, throwable -> {
                    Logger.e("-*-*-*-*-*-*-*- 获取 student_list 失败: " + throwable.getMessage());
                });
    }

    /**
     * 获取每周平均盈利
     */
    @SuppressLint("CheckResult")
    private void getWeeklyEarnings() {
        LessonService
                .getInstance()
                .getTeacherLessonScheduleList(false, UserService.getInstance().getCurrentUserId(),(int) (insightsViewModel.rangeStartTime / 1000L), (int) (insightsViewModel.rangeEndTime / 1000L))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessons -> {
                    lessonList = lessons;
                    calculateEarningsEveryday();
                }, throwable -> {
                    Logger.e("-*-*-*-*-*-*-*- 获取 Lesson 失败: " + throwable.getMessage());
                });
    }

    /**
     * 获取每周平均练习数
     */
    private void getWeeklyLearning() {
        clearPracticeAndAchievements();
    }

    /**
     * 获取每周平均练习数
     */
    private void getWeeklyAchievement() {

    }

    /**
     * 获取该教师注册账号的时间
     */
    @SuppressLint("CheckResult")
    private void getTeacherAccountStartTime() {
        UserService
                .getInstance()
                .getUserEntity()
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(entity ->{
                    userCreateTime = entity.getCreateTime();
//                    calculateActiveStudentsEveryDay();
                }, throwable -> {
                   Logger.e("-*-*-*-*-*-*-*- 获取用户失败: " + throwable.getMessage());
                });
    }

    /**
     * 计算每天 active 的学生数
     */
    private void calculateActiveStudentsEveryDay() {
        String jsFile = FuncUtils.getJsFuncStr(insightsViewModel.getApplication(), "calculate.status.history");
        V8 v8 = V8.createV8Runtime();
        MemoryManager scope = new MemoryManager(v8);
        v8.executeVoidScript(jsFile);
        int daysBetween = TimeUtils.getDaysBetween(insightsViewModel.rangeStartTime, insightsViewModel.rangeEndTime);
        // 循环 date
        for (int t = 0; t <= daysBetween; t++) {
            int count = 0;
            // 循环 student
            for (int i = 0; i < studentList.size(); i++) {
                V8Array statusHistory = new V8Array(v8);
                List<StatusHistoryEntity> statusHistoryFromEntity = studentList.get(i).getStatusHistory();
                String start = "";
                if (statusHistoryFromEntity.size() > 0) {
                    for (int w = 0; w < statusHistoryFromEntity.size(); w++) {
                        StatusHistoryEntity entity = statusHistoryFromEntity.get(w);
                        String changeTime = entity.getChangeTime();
                        String ymd = TimeUtils.getTimestampFormatYMD((Double.valueOf(changeTime).intValue()) * 1000L);
                        if (w == 0) {
                            start = entity.getChangeTime();
                        }
                        V8Object statusFromJava = new V8Object(v8)
                                .add("changeTime", ymd)
                                .add("status", entity.getStatus());
                        statusHistory.push(statusFromJava);
                    }
                }

                if (!start.equals("")) {
                    long startTime = (Double.valueOf(start).intValue()) * 1000L;
                    long endTime = insightsViewModel.rangeStartTime + oneDay * t;
                    if (startTime <= endTime) {
                        V8Object configFromJava = new V8Object(v8)
                                .add("timeArr", statusHistory)
                                .add("start", TimeUtils.getTimestampFormatYMD(startTime))
                                .add("end", TimeUtils.getTimestampFormatYMD(endTime));


                        V8Array param = new V8Array(v8).push(configFromJava);
                        boolean status = v8.executeBooleanFunction("calcStatus", param);
                        if (status) {
                            count++;
                        }
                    }
                }
            }
            studentsChartData.add(String.valueOf((count)));
            if (count > averageStudentsCount) {
                averageStudentsCount = count;
            }
        }
        Logger.e("-*-*-*-*-*-*-*- average Student count: " + averageStudentsCount);
        scope.release();
        getWeeklyEarnings();
    }

    /**
     * 计算每天的 earning
     */
    private void calculateEarningsEveryday() {
        int daysBetween = TimeUtils.getDaysBetween(insightsViewModel.rangeStartTime, insightsViewModel.rangeEndTime);
        // 循环 date
        for (int t = 0;t <= daysBetween;t++){
            double earnings = 0;
            for (int i = 0; i < lessonList.size(); i++) {
                long shouldDateTime = ((int) lessonList.get(i).getTKShouldDateTime()) * 1000L;
                if ((shouldDateTime >= insightsViewModel.rangeStartTime + oneDay * t) && (shouldDateTime < (insightsViewModel.rangeStartTime + oneDay * (t + 1)))) {
                    String lessonTypeId = lessonList.get(i).getLessonTypeId();
                    for (int j = 0; j < lessonTypeList.size(); j++) {
                        if (lessonTypeList.get(j).getId().equals(lessonTypeId)) {
                            earnings += Double.parseDouble(lessonTypeList.get(j).getPrice());
                        }
                    }
                }
            }
            earningsChartData.add(String.valueOf((earnings)));
            totalEarning += earnings;
        }

        adapter.updateStudentAndEarningCardValue(String.valueOf(averageStudentsCount), String.valueOf(totalEarning), studentsChartData, earningsChartData);
    }

    /**
     * 获取 lesson_type 列表
     */
    @SuppressLint("CheckResult")
    private void getTeacherLessonTypeList() {
        UserService
                .getStudioInstance()
                .getLessonTypeList(false)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessonTypes -> {
                    if (lessonTypes != null && lessonTypes.size() > 0) {
                        lessonTypeList = lessonTypes;
                        getLessonScheduleBasedOnRange(insightsViewModel.rangeStartTime, insightsViewModel.rangeEndTime);
                    }
                }, throwable -> {
                    Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonType 列表失败，throwable: " + throwable);
                });
    }

    /**
     * 获取范围内课程
     * @param start
     * @param end
     */
    @SuppressLint("CheckResult")
    private void getLessonScheduleBasedOnRange (long start, long end) {
        int daysBetween = TimeUtils.getDaysBetween(start, end);
        LessonService
                .getInstance()
                .getTeacherLessonScheduleList(false,UserService.getInstance().getCurrentUserId(), (int)(start / 1000L), (int)(end / 1000L))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(lessonList -> {
                    for (int i = 0; i <= daysBetween; i++) {
                        tempWorkHour = 0;
                        long timestamp = start + oneDay * i;
                        int index = TimeUtils.getDayOfWeek(timestamp);
                        totalTargetHour += getSpecificDayTargetHour(index);

                        for (LessonScheduleEntity item: lessonList) {
                            if (TimeUtils.getTimestampFormatYMD(item.getTKShouldDateTime() * 1000L).equals(TimeUtils.getTimestampFormatYMD(timestamp))) {
                                for (LessonTypeEntity lessonType: lessonTypeList) {
                                    if (lessonType.getId().equals(item.getLessonTypeId())) {
                                        totalWorkHour += lessonType.getTimeLength();
                                    }
                                }
                                tempWorkHour += item.getShouldTimeLength();
                            }
                        }

                        workHourChartData.add(String.valueOf(((double) (tempWorkHour / 60))));
                        capacityChartData.add(String.valueOf(((int) ((tempWorkHour / 60) / getSpecificDayTargetHour(index) * 100))));
                    }

                    capacityPercent = (int) (totalWorkHour / 60 / totalTargetHour * 100);
                    duration = String.valueOf(totalWorkHour / 60);
                    capacity = String.valueOf(capacityPercent);

//                    Logger.e(" ----- totalWorkHour: " + totalWorkHour);
//                    Logger.e(" ----- total work hour: " + duration);
//                    Logger.e(" ----- total target hour: " + totalTargetHour);
//                    Logger.e(" ----- capacity: " + capacity);

                    adapter.updateHourAndCapacityCardValue(duration, capacity, workHourChartData, capacityChartData);

                }, throwable -> {
                    Logger.e("===== 获取 lesson schedule 失败" + throwable.getMessage());
                });
    }

    /**
     * 获取某一天的目标时长
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
