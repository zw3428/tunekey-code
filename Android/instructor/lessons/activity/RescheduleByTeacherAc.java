package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.app.Dialog;
import android.os.Bundle;
import android.text.InputType;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.databinding.DataBindingUtil;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;

import com.spelist.tools.tools.SLStringUtils;

import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.customView.dialog.selectLessonV2.SelectLessonV2Dialog;
import com.spelist.tunekey.databinding.ActivityRescheduleByTeacherBinding;
import com.spelist.tunekey.databinding.DialogRescheduleSendMessageBinding;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.teacher.lessons.vm.RescheduleByTeacherVM;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class RescheduleByTeacherAc extends BaseActivity<ActivityRescheduleByTeacherBinding, RescheduleByTeacherVM> {

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_reschedule_by_teacher;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        List<LessonScheduleEntity> data = (List<LessonScheduleEntity>) getIntent().getSerializableExtra("data");
        int defSelect = getIntent().getIntExtra("defSelect", 0);
//        Logger.e("数据%s", data.size());
        viewModel.initData(data, defSelect);
    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickReschedule.observe(this, new Observer<List<LessonScheduleEntity>>() {
            @Override
            public void onChanged(List<LessonScheduleEntity> lessonScheduleEntities) {
                if (lessonScheduleEntities.size() == 1) {
//
//                    if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
//                    }else {
//                        showSelectTime(lessonScheduleEntities);
//                    }
                    showSelectTimeV2(lessonScheduleEntities.get(0));

                } else {
                    showSendMessage(lessonScheduleEntities, "");
                }
            }
        });
        viewModel.uc.showErrorDialog.observe(this, s -> {
            String title = s.get("title");
            String content = s.get("content");
            Dialog dialog = SLDialogUtils.showOneButton(this,
                    title,
                    content,
                    "OK");
            TextView button = dialog.findViewById(R.id.button);
            button.setOnClickListener(v -> dialog.dismiss());
        });
    }

    private void showSelectTimeV2(LessonScheduleEntity lessonScheduleEntities) {
//        if (lessonScheduleEntities.locationIsNull()) {
//            lessonScheduleEntities.setLocation(lessonScheduleEntities.getConfigEntity().getLocation());
//        }
        SelectLessonV2Dialog.Type type = SelectLessonV2Dialog.Type.STUDIO_SHOW;
        boolean isShowSelectSelectTeacher = true;
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher)) {
            type = SelectLessonV2Dialog.Type.TEACHER_SHOW;
            isShowSelectSelectTeacher = false;
        }
        SelectLessonV2Dialog dialog = new SelectLessonV2Dialog(this, type, this, viewModel, lessonScheduleEntities, null, isShowSelectSelectTeacher);
        dialog.showDialog();
        dialog.setClickConfirm(locationData -> {
            Logger.e("==>%s", SLJsonUtils.toJsonString(locationData));
            dialog.getTimeUtils.close();
            dialog.getTimeUtils = null;
            dialog.dismiss();
            viewModel.sentRescheduleV2("", lessonScheduleEntities, locationData);
            return null;
        });
    }

    /**
     * 老版本 选择时间弹窗
     *
     * @param lessonScheduleEntities
     */
    private void showSelectTime(List<LessonScheduleEntity> lessonScheduleEntities) {
        long t = 0;
        if (lessonScheduleEntities.get(0).getTKShouldDateTime() > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
            t = lessonScheduleEntities.get(0).getTKShouldDateTime() * 1000L;
        }
        SelectLessonDialog.Builder builder = new SelectLessonDialog.Builder(this)
                .createByReschedule(UserService.getInstance().getCurrentUserId(),
                        t,
                        lessonScheduleEntities.get(0).getShouldTimeLength(), lessonScheduleEntities.get(0).getId(), "NO");
        builder.clickConfirm(tkButton -> {
//            builder.selectTime;
//            int selectTime = 1671678000;
            int selectTime = builder.getSelectTime();
            Logger.e("selectTime==>%s", selectTime);
            int diff = 0;
            if (lessonScheduleEntities.get(0).getLessonScheduleData() != null) {
                diff = TimeUtils.getRescheduleDiff(lessonScheduleEntities.get(0).getLessonScheduleData().getStartDateTime(), selectTime);
            } else {
                List<LessonScheduleConfigEntity> collect = new ArrayList<>();
                if (ListenerService.shared.user.getRoleIds().contains("1")) {
                    collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(lessonScheduleEntities.get(0).getLessonScheduleConfigId())).collect(Collectors.toList());
                } else {
                    collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(lessonScheduleEntities.get(0).getLessonScheduleConfigId())).collect(Collectors.toList());
                }
                if (collect.size() > 0) {
                    diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectTime);
                }
            }
            selectTime = selectTime + (diff * 3600);
            Logger.e("diff==>%s", diff);
            showSendMessage(lessonScheduleEntities, selectTime + "");
            builder.dismiss();
        });


    }

    private void showSendMessage(List<LessonScheduleEntity> lessonScheduleEntities, String afterTime) {
        Dialog bottomDialog = new Dialog(this, R.style.BottomDialog);
        DialogRescheduleSendMessageBinding binding = DataBindingUtil.inflate(LayoutInflater.from(this), R.layout.dialog_reschedule_send_message, null, false);
        View contentView = binding.getRoot();
        if (afterTime.equals("")) {
            binding.confirmNowButton.setVisibility(View.GONE);
        } else {
            binding.confirmNowButton.setVisibility(View.VISIBLE);
            binding.confirmNowButton.setText(SLStringUtils.getSpan(binding.confirmNowButton.getText().toString(), ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main), "Confirm Now"));
            binding.confirmNowButton.setOnClickListener(view -> {
                viewModel.confirmNowReschedule(lessonScheduleEntities.get(0), afterTime);
                bottomDialog.dismiss();
            });
        }
        //获取Dialog的监听
        binding.closeButton.setOnClickListener(v -> {
            bottomDialog.dismiss();
        });
        //only this lesson
        //This and all future lessons
        //All lessons
        binding.message.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        binding.sendButton.setClickListener(tkButton -> {
            String s = binding.message.getText().toString();
            viewModel.sendReschedule(s, afterTime, lessonScheduleEntities);
            bottomDialog.dismiss();
        });
        binding.message.setFocusable(true);
        binding.message.setFocusableInTouchMode(true);//设置触摸聚焦
        binding.message.requestFocus();
        FuncUtils.toggleSoftInput(binding.message, true);

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗


    }
}