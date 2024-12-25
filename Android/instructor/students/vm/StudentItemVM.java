package com.spelist.tunekey.ui.teacher.students.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableInt;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class StudentItemVM extends ItemViewModel<StudentsItemFragmentVM> {
    private StudentListEntity studentListEntity = new StudentListEntity();
    public MutableLiveData<StudentListEntity> data = new MutableLiveData<>();
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> info = new ObservableField<>();
    public ObservableField<String> actionRequiredString = new ObservableField<>("");
    public ObservableField<Boolean> isShowActionRequired = new ObservableField<>(false);
    public ObservableField<Boolean> isShowView3 = new ObservableField<>(false);


    public ObservableField<String> userId = new ObservableField<>();
    public ObservableInt inviteVisibility = new ObservableInt();
    public ObservableInt next = new ObservableInt();
    public ObservableInt circleType = new ObservableInt(0);
    private int position;
    public ObservableInt checkedVisibility = new ObservableInt(8);
    public ObservableInt uncheckedVisibility = new ObservableInt(8);
    public boolean isEdit = false;
    public boolean isSelect = false;

    public ObservableField<Boolean> isShowMessage = new ObservableField<>(false);

    public ObservableField<String> unReadMessageCount = new ObservableField<>("");
    public ObservableField<Boolean> isShowUnReadMessageCount = new ObservableField<>(false);
    public ObservableField<String> lastMessage = new ObservableField<>("");
    public ObservableField<String> lastMessageTime = new ObservableField<>("");

    /**
     * 0 无button
     * 1 invite
     * 2 add lesson
     * 3 resend
     * 4 rejected
     * 5 new lesson
     */
    public StudentItemVM(@NonNull StudentsItemFragmentVM viewModel, StudentListEntity studentListEntity, int pos) {
        super(viewModel);
        this.studentListEntity = studentListEntity;
        this.circleType.set(0);
        position = pos;
        data.setValue(studentListEntity);
        userId.set(studentListEntity.getStudentId());
        name.set(studentListEntity.getName());
        info.set(studentListEntity.getEmail());
        inviteVisibility.set(View.VISIBLE);
        next.set(View.VISIBLE);

        if (studentListEntity.getStudentApplyStatus() == 1) {
            //Accept
            circleType.set(6);

        } else if (studentListEntity.getUnConfirmedLessonConfig().size() > 0) {
            //confirm lesson
            circleType.set(7);
        } else if (studentListEntity.getInvitedStatus().equals("-1")) {
            if (!studentListEntity.getLessonTypeId().equals("")) {
                circleType.set(1);
            } else {
                circleType.set(2);
            }
        } else if (studentListEntity.getInvitedStatus().equals("0")) {
            circleType.set(3);
        } else if (studentListEntity.getInvitedStatus().equals("1")) {
            circleType.set(0);
        } else if (studentListEntity.getInvitedStatus().equals("2")) {
            circleType.set(4);
        } else if (studentListEntity.getInvitedStatus().equals("3")) {
            circleType.set(5);
        }
        isShowActionRequired.set(false);
        if (studentListEntity.getLatestSigninTimestamp() != 0) {
            info.set(TimeUtils.getStrOfTimeTillNowBySeen((long) studentListEntity.getLatestSigninTimestamp()));
        } else {
            if (circleType.get() != 6 && circleType.get() != 7) {
                if (studentListEntity.getInvitedStatus().equals("-1") || studentListEntity.getInvitedStatus().equals("0")) {
                    info.set("Action required:");
                    isShowActionRequired.set(true);
                    actionRequiredString.set("Sign in with " + studentListEntity.getEmail());
                } else {
                    info.set(studentListEntity.getEmail());
                }
            }

        }


        if (studentListEntity.getConversation() != null) {
            isShowMessage.set(true);
            if (studentListEntity.getUnReadCount() > 0) {
                isShowUnReadMessageCount.set(true);
                if (studentListEntity.getUnReadCount() > 9) {
                    unReadMessageCount.set("9+");
                } else {
                    unReadMessageCount.set(studentListEntity.getUnReadCount() + "");
                }
            } else {
                isShowUnReadMessageCount.set(false);
                unReadMessageCount.set("");
            }
            if (studentListEntity.getConversation().getLatestMessage() != null) {
                lastMessage.set(studentListEntity.getConversation().getLatestMessage().messageText(false));
                lastMessageTime.set(TimeUtils.getStrOfTimeTillNow((long) studentListEntity.getConversation().getLatestMessage().getDatetime()));
                if (studentListEntity.getConversation().getLatestMessage().messageText(false).equals("")) {
                    isShowMessage.set(false);
                }
            } else {
                isShowMessage.set(false);
            }

        } else {
            isShowMessage.set(false);
        }
        isShowView3.set(isShowMessage.get() && isShowActionRequired.get());
    }

    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
        if (isEdit) {
            if (checkedVisibility.get() == View.VISIBLE) {
                checkedVisibility(View.GONE);
                uncheckedVisibility(View.VISIBLE);
                isSelect = false;
            } else {
                checkedVisibility(View.VISIBLE);
                uncheckedVisibility(View.GONE);
                isSelect = true;
            }
        } else {
            viewModel.clickItem(position);
        }
    });

    public BindingCommand<View> invite = new BindingCommand<>(view -> {
        viewModel.clickRightButton(data.getValue());
    });

    public BindingCommand<View> check = new BindingCommand<>(view -> {
        viewModel.clickItem(position);
        checkedVisibility(View.GONE);
        uncheckedVisibility(View.VISIBLE);
        isSelect = false;
    });


    public BindingCommand<View> unCheck = new BindingCommand<>(view -> {
        viewModel.clickItem(position);
        checkedVisibility(View.VISIBLE);
        uncheckedVisibility(View.GONE);
        isSelect = true;
    });

    /**
     * 设置checked图片 显示状态
     *
     * @param visibility
     */
    public void checkedVisibility(int visibility) {
        checkedVisibility.set(visibility);
    }

    /**
     * 设置checked图片 显示状态
     *
     * @param visibility
     */
    public void uncheckedVisibility(int visibility) {
        uncheckedVisibility.set(visibility);
    }


    public BindingCommand clickMessage = new BindingCommand(() -> {
        studentListEntity.setUnReadCount(0);
        isShowUnReadMessageCount.set(false);
        viewModel.toConversion(studentListEntity.getConversation());

    });
}
