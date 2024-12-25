package com.spelist.tunekey.ui.student.sLessons.vm;

import android.text.Html;
import android.text.Spanned;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleRequestItemVM extends ItemViewModel<StudentRescheduleRequestVM> {
    public ObservableField<String> requestStatus = new ObservableField<>("");
    public ObservableField<Spanned> requestInfo = new ObservableField<>(Html.fromHtml(""));
    public ObservableField<String> requestBeforeTime = new ObservableField<>("");
    public ObservableField<String> requestBeforeDay = new ObservableField<>("");
    public ObservableField<String> requestBeforeMonth = new ObservableField<>("");
    public ObservableField<String> requestAfterTime = new ObservableField<>("");
    public ObservableField<String> requestAfterDay = new ObservableField<>("");
    public ObservableField<String> requestAfterMonth = new ObservableField<>("");
    public ObservableField<Boolean> requestIsShowArrow = new ObservableField<>(true);

    public ObservableField<Boolean> requestIsShowAfterQuestionImg = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowConfirmButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowRescheduleButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowCenterRetractButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowRetractButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowDeclinedButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowCloseButton = new ObservableField<>(false);
    public LessonRescheduleEntity reschedule;


    public StudentRescheduleRequestItemVM(@NonNull StudentRescheduleRequestVM viewModel, LessonRescheduleEntity data) {
        super(viewModel);
        this.reschedule = data;
        initData();
    }

    private void initData() {
        requestBeforeDay.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "d"));
        requestBeforeMonth.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "MMM"));
        requestBeforeTime.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "hh:mm a"));
        String timeAfter = reschedule.getTKAfter();
        String teacherName = "";
        String info = "";
        requestIsShowArrow.set(true);
        requestIsShowAfterQuestionImg.set(false);
        requestIsShowConfirmButton.set(false);
        requestIsShowRescheduleButton.set(false);
        requestIsShowCenterRetractButton.set(false);
        requestIsShowRetractButton.set(false);
        requestIsShowDeclinedButton.set(false);
        requestIsShowCloseButton.set(false);

        if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
            teacherName = "<font color='#71d9c2'> " + viewModel.teacherData.getName() + " </font>";
        }
        if (!reschedule.getTimeAfter().equals("") && Integer.parseInt(reschedule.getTKAfter()) < TimeUtils.getCurrentTime()) {
            timeAfter = "";
        }
        if (!timeAfter.equals("")) {

            requestAfterDay.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "d"));
            requestAfterMonth.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "MMM"));
            requestAfterTime.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "hh:mm a"));
            if (reschedule.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                requestStatus.set("Pending: ");
                if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                    info = "Awaiting rescheduling confirmation " + teacherName;
                } else {
                    info = "Awaiting rescheduling confirmation";
                }
                requestIsShowCenterRetractButton.set(true);
                if (reschedule.getTeacherRevisedReschedule()||reschedule.getStudioManagerRevisedReschedule()) {
                    requestIsShowCenterRetractButton.set(false);
                    requestIsShowRetractButton.set(true);
                    requestStatus.set("");
                    requestIsShowRescheduleButton.set(true);
                    requestIsShowConfirmButton.set(true);
                    if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                        info = teacherName + " sent a reschedule request";
                    } else {
                        info = "Your instructor sent a reschedule request";
                    }

                }
            } else {
                if (reschedule.getStudentRevisedReschedule()) {
                    if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                        info = "Awaiting rescheduling confirmation " + teacherName;
                    } else {
                        info = "Awaiting rescheduling confirmation";
                    }
                    requestStatus.set("Pending: ");

                } else {
                    requestIsShowRescheduleButton.set(true);
                    requestIsShowConfirmButton.set(true);
                    requestStatus.set("");
                    if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                        info = teacherName + " sent a reschedule request";
                    } else {
                        info = "Your instructor sent a reschedule request";
                    }
                }
            }
            if (reschedule.getRetracted()) {
                if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                    info = teacherName + " retracted the reschedule request";
                } else {
                    info = "Retracted the reschedule request";
                }
                requestStatus.set("");
                requestIsShowCloseButton.set(true);
                requestIsShowRetractButton.set(false);
                requestIsShowConfirmButton.set(false);
                requestIsShowCenterRetractButton.set(false);
                requestIsShowRescheduleButton.set(false);
            }
            if (reschedule.isCancelLesson()){
                if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                    info = teacherName + " cancelled this lesson";
                } else {
                    info = "Your instructor cancelled this lesson";
                }
                requestIsShowArrow.set(false);
                requestIsShowCloseButton.set(true);
                requestIsShowRetractButton.set(false);
                requestIsShowConfirmButton.set(false);
                requestIsShowCenterRetractButton.set(false);
                requestIsShowRescheduleButton.set(false);
                requestIsShowAfterQuestionImg.set(false);
                requestAfterDay.set("");
            }
        } else {
            requestIsShowAfterQuestionImg.set(true);
            if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                info = teacherName + " sent a reschedule request";
            } else {
                info = "Your instructor sent a reschedule request";
            }
            if (reschedule.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                requestIsShowRetractButton.set(true);
            }


            if (reschedule.getRetracted()) {
                if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                    info = teacherName + " retracted the reschedule request";
                } else {
                    info = "Retracted the reschedule request";
                }
                requestIsShowCloseButton.set(true);
                requestIsShowRetractButton.set(false);
                requestIsShowConfirmButton.set(false);
                requestIsShowCenterRetractButton.set(false);
                requestIsShowRescheduleButton.set(false);
            }
            if (reschedule.isCancelLesson()){
                if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {
                    info = teacherName + " cancelled this lesson";
                } else {
                    info = "Your instructor cancelled this lesson";
                }
                requestIsShowArrow.set(false);
                requestIsShowCloseButton.set(true);
                requestIsShowRetractButton.set(false);
                requestIsShowConfirmButton.set(false);
                requestIsShowCenterRetractButton.set(false);
                requestIsShowRescheduleButton.set(false);
                requestIsShowAfterQuestionImg.set(false);
                requestAfterDay.set("");
            }
        }
        if (reschedule.getConfirmType() != 0) {
            if (viewModel.teacherData != null && !viewModel.teacherData.getName().equals("")) {

                info = teacherName + "declined the reschedule request";
                if (reschedule.getConfirmType() == 1) {
                    info = teacherName + "confirmed the reschedule request";
                }

            } else {
                info = "Declined the reschedule request";
                if (reschedule.getConfirmType() == 1) {
                    info = "Confirmed the reschedule request";

                }
            }
            requestStatus.set("");
            requestIsShowCloseButton.set(true);
            requestIsShowRetractButton.set(false);
            requestIsShowConfirmButton.set(false);
            requestIsShowCenterRetractButton.set(false);
            requestIsShowRescheduleButton.set(false);
        }
        requestInfo.set(Html.fromHtml(info));

    }

    public BindingCommand clickReschedule = new BindingCommand(() -> {
        viewModel.clickReschedule(reschedule);
    });

    public BindingCommand clickConfirm = new BindingCommand(() -> {
        viewModel.clickConfirm(reschedule);
    });
    public BindingCommand clickRetract = new BindingCommand(() -> {
        viewModel.clickRetract(reschedule);
    });

    public BindingCommand clickClose = new BindingCommand(() -> {
        viewModel.clickClose(reschedule);
    });
}
