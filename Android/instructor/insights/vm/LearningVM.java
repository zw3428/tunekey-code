package com.spelist.tunekey.ui.teacher.insights.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKPractice;
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
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.insights.vm
 * 2021/5/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LearningVM extends BaseViewModel {
    public ObservableField<String> practiceString = new ObservableField<>("0");
    public ObservableField<String> achievementsString = new ObservableField<>("0");
    public ObservableField<Boolean> isShowValue = new ObservableField<>(true);
    private long oneDay = 24 * 60 * 60 * 1000L;
    public long rangeStartTime = TimeUtils.addDay(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis(), -7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());
    public List<StudentListEntity> studentList = new ArrayList<>();

    public UIEventObservable uc = new UIEventObservable();

    public List<AchievementEntity> achievementData = new ArrayList<>();
    public List<TKPractice> assignmentData = new ArrayList<>();

    public List<Integer> achievementChartData = new ArrayList<>();
    public List<Double> assignmentChartData = new ArrayList<Double>();
    public Map<String, Double> studentMap = new HashMap<>();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> update = new SingleLiveEvent<>();
    }

    public LearningVM(@NonNull @NotNull Application application) {
        super(application);
        initData();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_STUDENT_LIST_CHANGED, () -> {
            initData();
        });
    }

    public void initData() {
        achievementChartData.clear();
        assignmentChartData.clear();
        assignmentData.clear();
        studentList.clear();
        achievementData.clear();
        studentList.addAll(ListenerService.shared.teacherData.getStudentList());
        Logger.e("更新");
        int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
        for (int i = 0; i <= daysBetween; i++) {
            assignmentChartData.add(0D);
        }
        getAssignmentData();
        getAchievement();

    }

    private void getAssignmentData() {
        List<String> studentIds = new ArrayList<>();

        for (StudentListEntity studentListEntity : studentList) {
            studentMap.put(studentListEntity.getId(), 0D);
            studentIds.add(studentListEntity.getStudentId());
        }

        addSubscribe(
                LessonService
                        .getInstance()
                        .getPracticeByStudentIdsAndTimes(studentIds, (int) (rangeStartTime / 1000L), (int) (rangeEndTime / 1000L))
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            assignmentChartData.clear();
                            assignmentData.clear();
                            assignmentData = data;
                            initPracticeData();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    private void initPracticeData() {
        int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
        for (int i = 0; i <= daysBetween; i++) {
            assignmentChartData.add(0D);
        }
        studentMap.clear();
        double totalTimeLength = 0;
        for (TKPractice item : assignmentData) {
            int index = TimeUtils.getDaysBetween(rangeStartTime, item.getStartTime() * 1000L);
            if (index >= 0 && index < assignmentChartData.size()) {

                if (studentMap.get(item.getStudentId()) != null) {
                    studentMap.put(item.getStudentId(), studentMap.get(item.getStudentId()) + item.getTotalTimeLength());
                } else {
                    studentMap.put(item.getStudentId(), item.getTotalTimeLength());
                }
                totalTimeLength += item.getTotalTimeLength();
                assignmentChartData.set(index, assignmentChartData.get(index) + item.getTotalTimeLength());
            }
        }
        studentMap.forEach((s, aDouble) -> {
            double time = 0;
            if (aDouble/ 60D / 60D > 0) {
                if (aDouble / 60D / 60D < 0.1) {
                    time = 0.1;
                } else {
                    time = aDouble / 60D / 60D;
                }
            }
            studentMap.put(s,time);
        });

        for (int i = 0; i < assignmentChartData.size(); i++) {
            double time = 0;
            if (assignmentChartData.get(i)/ 60D / 60D > 0) {
                if (assignmentChartData.get(i) / 60D / 60D < 0.1) {
                    time = 0.1;
                } else {
                    time = assignmentChartData.get(i) / 60D / 60D;
                }
            }
            assignmentChartData.set(i,time);
        }
        if (totalTimeLength/ 60D / 60D > 0) {
            if (totalTimeLength / 60D / 60D < 0.1) {
                totalTimeLength = 0.1;
            } else {
                totalTimeLength = totalTimeLength / 60D / 60D;
            }
        }




        practiceString.set(String.format("%.1f", totalTimeLength));
        uc.update.call();
        initStudentList();
    }

    private void initStudentList() {
        observableList.clear();
        for (StudentListEntity studentListEntity : studentList) {
            if (studentMap.get(studentListEntity.getStudentId()) != null) {
                studentListEntity.setPracticeTime(studentMap.get(studentListEntity.getStudentId()));
            }
            LearningStudentItemVM learningStudentItemVM = new LearningStudentItemVM(this, studentListEntity);
            observableList.add(learningStudentItemVM);
        }
    }

    private void getAchievement() {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleAchievementByTeacherIdAndInTime(UserService.getInstance().getCurrentUserId(), (int) (rangeStartTime / 1000L), (int) (rangeEndTime / 1000L))
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            achievementChartData.clear();
                            int daysBetween = TimeUtils.getDaysBetween(rangeStartTime, rangeEndTime);
                            for (int i = 0; i <= daysBetween; i++) {
                                achievementChartData.add(0);
                            }
//                            isSuccess.set(true);
                            achievementData = data;
                            for (StudentListEntity studentListEntity : studentList) {
                                studentListEntity.setAchievementCount(0);
                            }
                            for (AchievementEntity item : achievementData) {
                                int index = TimeUtils.getDaysBetween(rangeStartTime, item.getShouldDateTime() * 1000L);
                                if (index >= 0 && index < achievementChartData.size()) {
                                    achievementChartData.set(index, achievementChartData.get(index) + 1);
                                }
                                for (int i = 0; i < studentList.size(); i++) {
                                    if (studentList.get(i).getStudentId().equals(item.getStudentId()) && item.getShouldDateTime() >= (rangeStartTime / 1000L)
                                            && item.getShouldDateTime() <= (rangeEndTime / 1000L)) {
                                        studentList.get(i).setAchievementCount(studentList.get(i).getAchievementCount() + 1);
                                    }
                                }
                            }
                            int total = 0;
                            for (Integer item : achievementChartData) {
                                total += item;
                            }
                            achievementsString.set(total + "");
                            uc.update.call();
                            initStudentList();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    //给RecyclerView添加ObservableList
    public ObservableList<LearningStudentItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<LearningStudentItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_learning_student));


}
