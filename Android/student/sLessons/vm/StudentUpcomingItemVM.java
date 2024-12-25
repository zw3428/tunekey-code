package com.spelist.tunekey.ui.student.sLessons.vm;

import android.annotation.SuppressLint;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKStudioEvent;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/17
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentUpcomingItemVM extends StudentUpcomingMultiItemViewModel<StudentUpcomingVM> {
    public LessonScheduleEntity data;
    private int pos = 0;
    public ObservableField<String> day = new ObservableField<>("");
    public ObservableField<String> month = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public ObservableField<Integer> timeColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
    public ObservableField<Integer> infoColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.third));

    public ObservableField<Boolean> isReschedule = new ObservableField<>(false);
    public ObservableField<Boolean> isShowLocation = new ObservableField<>(false);

    public ObservableField<String> note = new ObservableField<>("");
    public ObservableField<Integer> noteColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
    public ObservableField<Boolean> isShowArrow = new ObservableField<>(true);

    public ObservableField<String> leftButton = new ObservableField<>("CANCEL LESSON");
    public ObservableField<String> centerButton = new ObservableField<>("MAKE UP");
    public ObservableField<String> rightButton = new ObservableField<>("RESCHEDULE");

    public ObservableField<Boolean> isShowLeftButton = new ObservableField<>(true);
    public ObservableField<Boolean> isShowCenterButton = new ObservableField<>(false);
    public ObservableField<Boolean> isShowRightButton = new ObservableField<>(true);

    public ObservableField<Boolean> isExpand = new ObservableField<>(false);

    public StudentUpcomingItemVM(@NonNull StudentUpcomingVM viewModel, int pos, Type type, LessonScheduleEntity lessonData, TKStudioEvent event) {
        super(viewModel, pos, type, lessonData, event);
        this.pos = pos;

        initData(lessonData);
    }


//    public StudentUpcomingItemVM(@NonNull StudentUpcomingVM viewModel, int pos, LessonScheduleEntity lesson) {
//        super(viewModel);
//        this.pos = pos;
//
//        initData(lesson);
//    }

    @SuppressLint("DefaultLocale")
    public void initData(LessonScheduleEntity lesson) {
        data = lesson;

        if (viewModel.studentData.getStudioId().equals("") && (viewModel.studentData.getTeacherId().equals("") || viewModel.studentData.getStudentApplyStatus() == 1)) {
            leftButton.set("DELETE LESSON");
            if (viewModel.studentData.getStudentApplyStatus() == 1) {
                rightButton.set("RE-INVITE");
            } else {
                rightButton.set("ADD INSTRUCTOR");
            }
        }
        isReschedule.set(false);
        isShowArrow.set(true);
        isShowLocation.set(true);
        timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
        infoColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.third));
        day.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "d"));
        month.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "MMM"));
        time.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "EEE, hh:mm a"));
        if (lesson.getLocation() != null&& lesson.getLocation().getId().equals("") && lesson.getLocation().getType().equals(TKLocation.LocationType.remote)) {
            lesson.getLocation().setId(lesson.getLocation().getRemoteLink());
        }
        if (lesson.getLocation() != null && !lesson.getLocation().getId().equals("")) {
            String locationTitle = lesson.getLocation().getLocationTitle(lesson.getTeacherId());
            if (!locationTitle.equals("")) {
                noteColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
                note.set(locationTitle);
                isShowLocation.set(true);
            }
        }
        if (data.isCancelled() || data.isRescheduled()) {
            isShowLocation.set(false);
            isReschedule.set(true);
            isShowArrow.set(false);
            timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.third));
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
                isShowCenterButton.set(true);
                isShowLeftButton.set(false);
                isShowRightButton.set(false);
            }
            if (data.isRescheduled()) {
                note.set("Rescheduled");
                if (data.getRescheduleLessonData() != null) {
                    try {
                        if (!data.getRescheduleId().equals("")) {
                            long time = Long.parseLong(data.getRescheduleLessonData().getTKAfter());
                            note.set("Rescheduled to " + TimeUtils.timeFormat(time, "hh:mm a, MMM dd"));
                        } else {
                            note.set("Pending");
                            long time = Long.parseLong(data.getRescheduleLessonData().getTKAfter());
                            note.set("(Pending) Rescheduled to " + TimeUtils.timeFormat(time, "hh:mm a, MMM dd"));
                        }
                    } catch (Throwable e) {
                        Logger.e("===??===%s", e.getMessage());
                    }
                }
            }
        }
    }

    public BindingCommand clickLeftButton = new BindingCommand(() -> {
        viewModel.clickItemLeftButton(data, pos);
        expand();
    });
    public BindingCommand clickRightButton = new BindingCommand(() -> {
        viewModel.clickItemRightButton(data, pos);
        expand();
    });
    public BindingCommand clickCenterButton = new BindingCommand(() -> {
        viewModel.clickItemCenterButton(data, pos);
        expand();
    });
    public BindingCommand clickLeft = new BindingCommand(() -> {
        if (data.getConfigEntity().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group){
            return;
        }
        if (data.isRescheduled() && !data.getRescheduleId().equals("")) {
            if (data.getRescheduleId().equals("") && data.getRescheduleLessonData() != null) {
                viewModel.clickRescheduleItem(pos);

            }
            return;
        }
        expand();
    });


    private void expand() {
        if (isExpand.get() != null) {
//            if (isExpand.get()) {
//                viewModel.clickExpandItem(-1);
//            } else {
//                viewModel.clickExpandItem(pos);
//            }
            if (isExpand.get()) {
                viewModel.clickExpandItem("");
            } else {
                viewModel.clickExpandItem(data.getId());
            }
            isExpand.set(!isExpand.get());
        }
    }

    @Override
    protected void onClickItem(View view) {
        super.onClickItem(view);
        if (!data.isCancelled() && !data.isRescheduled()) {
            viewModel.toDetails(data);
        }
    }
}
