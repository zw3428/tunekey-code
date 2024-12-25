package com.spelist.tunekey.ui.student.sLessons.vm;

import android.annotation.SuppressLint;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleMaterialEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.ItemViewModel;

public class StudentLessonsItemViewModel extends ItemViewModel<StudentLessonsViewModelV2> {
    public LessonScheduleEntity data;
    private int pos = 0;
    public ObservableField<String> day = new ObservableField<>("");
    public ObservableField<String> month = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public ObservableField<Integer> timeColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.third));
    public ObservableField<Boolean> isReschedule = new ObservableField<>(false);


    public ObservableField<Boolean> isShowAssignment = new ObservableField<>(false);
    public ObservableField<String> selfStudy = new ObservableField<>(" 0 hrs");
    public ObservableField<String> assignment = new ObservableField<>(" No assignment");
    public ObservableField<Integer> assignmentColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));

    public ObservableField<Boolean> isShowNote = new ObservableField<>(false);
    public ObservableField<String> note = new ObservableField<>("");

    public ObservableField<Integer> noteColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));

    public ObservableField<Boolean> isShowAchievement = new ObservableField<>(false);
    public ObservableField<String> achievement = new ObservableField<>("");
    public ObservableField<Boolean> isShowTip = new ObservableField<>(false);



    public StudentLessonsItemViewModel(@NonNull StudentLessonsViewModelV2 viewModel, int pos, LessonScheduleEntity lesson) {
        super(viewModel);
        this.pos = pos;
        initData(lesson);
    }

    @SuppressLint("DefaultLocale")
    public void initData(LessonScheduleEntity lesson) {
        data = lesson;
        isShowAssignment.set(false);
        isShowNote.set(false);
        isReschedule.set(false);
        isShowAchievement.set(false);
        timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.third));
        day.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "d"));
        month.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "MMM"));
        time.set( TimeUtils.timeFormat(data.getTKShouldDateTime(), "EEE, hh:mm a"));
        isShowTip.set(false);
        //显示 新消息小绿点
        if (!lesson.isStudentReadTeacherNote()&&!data.getTeacherNote().equals("")) {
            isShowTip.set(true);
        }
        if (data.getAchievement().size()>0){
            for (AchievementEntity achievementEntity : data.getAchievement()) {
                if (!achievementEntity.isStudentRead()){
                    isShowTip.set(true);
                    break;
                }
            }
        }
        if (data.getMaterialData().size()>0){
            for (LessonScheduleMaterialEntity materialDatum : data.getMaterialData()) {
                if (!materialDatum.isStudentRead()){
                    isShowTip.set(true);
                    break;
                }
            }
        }

        //显示info信息
        if (data.isCancelled() || (data.isRescheduled() && !data.getRescheduleId().equals(""))) {
            isReschedule.set(true);
            isShowNote.set(true);
            timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
            noteColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
            if (data.isCancelled()) {
                note.set("Canceled");
                if (data.getCancelLessonData() != null) {
                    try {
                        long time = Long.parseLong(data.getCancelLessonData().getCreateTime());
                        note.set("Canceled at " + TimeUtils.timeFormat(time, "hh:mm a, MMM dd"));
                    } catch (Throwable e) {

                    }
                }
            }
            if (data.isRescheduled() && !data.getRescheduleId().equals("")) {
                note.set("Rescheduled");
                if (data.getRescheduleLessonData() != null) {
                    try {

                        long time = Long.parseLong(data.getRescheduleLessonData().getTKAfter());
                        note.set("Rescheduled to " + TimeUtils.timeFormat(time, "hh:mm a, MMM dd"));
                    } catch (Throwable e) {
                    }
                }
            }
        } else {

            if (data.getAchievement().size() > 0) {
                isShowAchievement.set(true);
                achievement.set(data.getAchievement().get(0).getName());
            } else if (!data.getTeacherNote().equals("")) {
                isShowNote.set(true);
                note.set(data.getTeacherNote());
                noteColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
            } else if (!data.getStudentNote().equals("")) {
                isShowNote.set(true);
                note.set(data.getStudentNote());
                noteColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
            } else if (data.getPracticeData().size() > 0) {
                isShowAssignment.set(true);
                List<TKPractice> assignmentData = new ArrayList<>();
                List<TKPractice> studyData = new ArrayList<>();
                for (TKPractice item : data.getPracticeData()) {
                    if (!item.isAssignment()) {
                        studyData.add(item);
                    } else {
                        assignmentData.add(item);
                    }
                }
                double totalTime = 0;
                for (TKPractice item : studyData) {
                    totalTime += item.getTotalTimeLength();
                }
                if (totalTime > 0) {
                    totalTime = totalTime / 60 / 60;
                    if (totalTime <= 0.1) {
                        selfStudy.set(" 0.1 hrs");
                    } else {
                        selfStudy.set(" " + String.format("%.1f", totalTime) + " hrs");
                    }
                } else {
                    selfStudy.set(" 0 hrs");
                }
                if (assignmentData.size() <= 0) {
                    assignment.set(" No assignment");
                    assignmentColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
                    return;
                }
                boolean isComplete = false;
                List<TKPractice> a = new ArrayList<>();
                for (TKPractice item : assignmentData) {
                    int index = -1;
                    for (int i = 0; i < a.size(); i++) {
                        if (a.get(i).getName().equals(item.getName())) {
                            index = i;
                        }
                    }
                    if (index == -1){
                        a.add(item);
                    }else {
                        a.get(index).setDone(item.isDone()||a.get(index).isDone());
                    }


                }
                for (TKPractice item : a) {
                    if (item.isDone()) {


                        isComplete = true;
                        break;
                    }
                }

                assignment.set(isComplete ? " Completed" : (pos == 0 ? " Incomplete" : " Uncompleted"));
                assignmentColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), isComplete ? R.color.kermit_green : R.color.red));

            } else if (data.getLessonType() != null && data.getLessonType().getName() != null && !data.getLessonType().getName().equals("")) {
                isShowNote.set(true);
                note.set(data.getLessonType().getName());
                noteColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
            }
        }
    }

    @Override
    protected void onClickItem(View view) {
        viewModel.clickLesson(data,pos);
    }
}
