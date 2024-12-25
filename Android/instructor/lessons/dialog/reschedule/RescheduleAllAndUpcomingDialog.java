package com.spelist.tunekey.ui.teacher.lessons.dialog.reschedule;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;

import com.google.firebase.functions.FirebaseFunctions;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BottomPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.customView.dialog.selectLessonV2.SelectLessonV2Dialog;
import com.spelist.tunekey.databinding.DialogRescheduleAllAndUpcomingBinding;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.bus.Messenger;

/**
 * com.spelist.tunekey.ui.teacher.lessons.dialog.reschedule
 * 2022/4/6
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleAllAndUpcomingDialog extends BottomPopupView implements View.OnClickListener {
    private DialogRescheduleAllAndUpcomingBinding binding;
    private boolean isFirstSetRecurrence = true;
    private List<Integer> selectRecurrenceWeekly = new ArrayList<>();
    private long selectTime = 0;
    private int repeatType = 1;
    private boolean isRepeat = false;
    //没有截止日期: 0, 某天截止: 1, 重复几次后结束: 2
    private int endType = 0;
    private int endCount = 10;
    private int endTime = 0;
    private int webSelectEndTime = 0;
    public BaseActivity activity;
    private SubmitButton submitButton1;
    private LessonScheduleConfigEntity configData;
    private LessonScheduleEntity lessonData;
    private String title = "";
    private BaseViewModel viewModel;

    public RescheduleAllAndUpcomingDialog(@NonNull Context context, BaseActivity activity, BaseViewModel viewModel, LessonScheduleConfigEntity scheduleConfigEntity, LessonScheduleEntity scheduleEntity, String title) {
        super(context);
        this.activity = activity;
        configData = scheduleConfigEntity;
        lessonData = scheduleEntity;
        this.viewModel = viewModel;
        this.title = title;

    }

    @SuppressLint("NonConstantResourceId")
    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.weekly1:
            case R.id.biweekly1:
                setRepeatTypeWeekDay(0);
                break;
            case R.id.weekly2:
            case R.id.biweekly2:
                setRepeatTypeWeekDay(1);
                break;
            case R.id.weekly3:
            case R.id.biweekly3:
                setRepeatTypeWeekDay(2);
                break;
            case R.id.weekly4:
            case R.id.biweekly4:
                setRepeatTypeWeekDay(3);
                break;
            case R.id.weekly5:
            case R.id.biweekly5:
                setRepeatTypeWeekDay(4);
                break;
            case R.id.weekly6:
            case R.id.biweekly6:
                setRepeatTypeWeekDay(5);
                break;
            case R.id.weekly7:
            case R.id.biweekly7:
                setRepeatTypeWeekDay(6);
                break;
        }
    }


    protected int getImplLayoutId() {
        return R.layout.dialog_reschedule_all_and_upcoming;
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate() {
        super.onCreate();
        binding = DataBindingUtil.bind(getPopupImplView());
        if (binding == null) {
            return;
        }
        binding.backButton.setClickListener(v -> {

            dismiss();
        });
        binding.confirmButton.setClickListener(v -> {
            String type = "";
            if (title.equals("This & following lessons")) {
                type = "THIS_AND_FOLLOWING_LESSONS";
            } else {
                type = "ALL_LESSONS";
            }
            saveData(type, configData, (int) selectTime, lessonData.getId());

        });
        binding.titleTv.setText("For " + title.toLowerCase() + ":");
        selectTime = lessonData.getTKShouldDateTime();

        isRepeat = configData.getRepeatType() != 0;
        if (isRepeat) {
            repeatType = configData.getRepeatType();
        }
        endType = configData.getEndType();
        if (configData.getEndCount() != 0) {
            endCount = configData.getEndCount();
        }
        if (configData.getEndDate() > TimeUtils.getCurrentTime()) {
            endTime = configData.getEndDate();
        }

        int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(configData.getStartDateTime() * 1000L);
        List<Integer> week = new ArrayList<>();
        for (Integer integer : configData.getRepeatTypeWeekDay()) {
            int i = integer + (-diff);
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            week.add(i);
        }
        configData.setRepeatTypeWeekDay(week);


        for (Integer integer : configData.getRepeatTypeWeekDay()) {
            setRepeatTypeWeekDay(integer);
        }
        binding.startTime.setText(TimeUtils.timeFormat(selectTime, "MM/dd/yyyy hh:mm aaa"));
        binding.linStartTime.setOnClickListener(v -> {
            showStartTimeDialog();
        });
        initRecurrenceView();
//        initRecurrenceData();


    }

    private void saveData(String type, LessonScheduleConfigEntity scheduleConfigEntity, int startTime, String lessonId) {
        if (scheduleConfigEntity == null) {
            SLToast.error("Please check your connection and try again.");

            return;
        }
        activity.showDialog();
        Logger.e("type==>%s", type);
        Map<String, Object> data = new HashMap<>();
        data.put("rescheduleType", type);
        data.put("scheduleConfigId", scheduleConfigEntity.getId());
        data.put("selectedLessonScheduleId", lessonId);
        Logger.e("data==>%s", data.toString());

        int diff = TimeUtils.getUTCWeekdayDiff(selectTime * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : selectRecurrenceWeekly) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }

        LessonScheduleConfigEntity configEntity = CloneObjectUtils.cloneObject(configData);
        configEntity.setId(IDUtils.getId());
        configEntity.setRrule("");
        configEntity.setDelete(false);
        configEntity.setStartDateTime((int) selectTime);
        configEntity.setRepeatType(isRepeat ? repeatType : 0);
        configEntity.setRepeatTypeWeekDay(weekDays);
        configEntity.setEndType(endType);
        configEntity.setEndDate(endTime);
        configEntity.setEndCount(endCount);
        configEntity.setCreateTime(TimeUtils.getCurrentTimeString());
        configEntity.setUpdateTime(TimeUtils.getCurrentTimeString());
        configEntity.setLocation(scheduleConfigEntity.getLocation());
        configEntity.setStudioId(scheduleConfigEntity.getStudioId());


        data.put("newScheduleConfig", SLJsonUtils.toMaps(SLJsonUtils.toJsonString(configEntity)));

        FirebaseFunctions
                .getInstance()
                .getHttpsCallable("lessonService-rescheduleLessonsWithTypeV2")
                .call(data)
                .addOnCompleteListener(task -> {
                    dismiss();
                    activity.dismissDialog();
                    if (task.getException() == null) {
                        SLToast.success("Rescheduled successfully!");
                        Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                        Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.REFRESH_LESSON);
                        activity.finish();
                    } else {
                        SLToast.error("Please check your connection and try again.");
                        Logger.e("失败==>%s", task.getException().getMessage());
                    }
                });


    }

//        scheduleConfigEntity.setStartDateTime(startTime1);
//        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
//
//
//        int starTime = scheduleConfigEntity.getStartDateTime();
//        String studentId = scheduleConfigEntity.getStudentId();
//        Map<String, Object> map = new HashMap<>();
//        map.put("time", TimeUtils.getCurrentTime());
//        map.put("configId", scheduleConfigEntity.getId());
//        map.put("studentId", studentId);
//        map.put("teacherId", scheduleConfigEntity.getTeacherId());
//        scheduleConfigEntity.setId(IDUtils.getId());
//        map.put("newScheduleData", SLJsonUtils.toJsonString(scheduleConfigEntity));
//
//
//        if ((scheduleConfigEntity.getRepeatType() == 0 && starTime >= (System.currentTimeMillis() / 1000)) || starTime >= (System.currentTimeMillis() / 1000)) {
//            map.put("isUpdate", false);
//        } else {
//            map.put("isUpdate", true);
//        }
//    showDialog();
//        CloudFunctions
//                .deleteLessonScheduleConfig(map)
//                .addOnCompleteListener(task -> {
//                    dismissDialog();
//                    if (task.isSuccessful()) {
//                        if (task.getResult() != null && task.getResult()) {
//                            Logger.e("====成功");
//
//                            SLToast.success("Rescheduled successfully!");
//                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
//                            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.REFRESH_LESSON);
//                            finish();
//                        }
//                    } else {
//
//                        SLToast.error("Please check your connection and try again.");
//                    }
//                });


    private void showStartTimeDialog() {
//        String oldConfigId = "NO";
//        if (configData != null && configData.getId() != null) {
//            oldConfigId = configData.getId();
//        }
//
//        long t = 0;
//        if (selectTime > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
//            t = selectTime * 1000L;
//        }
//        SelectLessonDialog.Builder builder = new SelectLessonDialog.Builder(getContext())
//                .create(UserService.getInstance().getCurrentUserId(),
//                        t,
//                        lessonData.getShouldTimeLength(), oldConfigId, title.equals("This & following lessons"));
//        builder.clickConfirm(tkButton -> {
////            builder.selectTime;
////            showSendMessage(lessonScheduleEntities, builder.getSelectTime() + "");
//            selectTime = builder.getSelectTime();
//            binding.startTime.setText(TimeUtils.timeFormat(selectTime, "yyyy/MM/dd hh:mm aaa"));
//
//            binding.linRecurrence.setVisibility(View.VISIBLE);
//            long time = selectTime * 1000L;
//            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
//            this.endTime = (int) (endTim / 1000L);
////            oldEndTimeFromWebView = endTim / 1000L;
////            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
//            binding.rInfoEndTimeString.setText(com.spelist.tools.tools.TimeUtils.getDateForMMMTime(endTim));
//
//            builder.dismiss();
//        });
        SelectLessonV2Dialog.Type type = SelectLessonV2Dialog.Type.STUDIO_SHOW;
        boolean isShowSelectSelectTeacher = true;
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher)) {
            type = SelectLessonV2Dialog.Type.TEACHER_SHOW;
            isShowSelectSelectTeacher = false;
        }
        SelectLessonV2Dialog dialog = new SelectLessonV2Dialog(getContext(), type, activity, viewModel, null, configData, isShowSelectSelectTeacher);
        dialog.showDialog();
        dialog.setClickConfirm(data -> {
            Logger.e("==>%s", SLJsonUtils.toJsonString(data));

            selectTime = data.getSelectedTimestamp();
            binding.startTime.setText(TimeUtils.timeFormat(selectTime, "yyyy/MM/dd hh:mm aaa"));

            if (!data.getId().equals("SetLater")){
                configData.setLocation(data.toTKLocation()) ;
            }else {
                configData.setLocation(new TKLocation()) ;
            }



            binding.linRecurrence.setVisibility(View.VISIBLE);
            long time = selectTime * 1000L;
            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
            this.endTime = (int) (endTim / 1000L);
//            oldEndTimeFromWebView = endTim / 1000L;
//            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
            binding.rInfoEndTimeString.setText(com.spelist.tools.tools.TimeUtils.getDateForMMMTime(endTim));
            int dayOfWeek = com.spelist.tunekey.utils.TimeUtils.getDayOfWeek(selectTime * 1000L) - 1;
            clearRepeatTypeWeekDay();
            selectRecurrenceWeekly.clear();
            setRepeatTypeWeekDay(dayOfWeek);
            dialog.dismiss();

            return null;

        });

    }


    public void showDialog() {
        new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .enableDrag(false)
                .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(true)
                .asCustom(this)
                .show();
    }


    /**
     * 初始化RecurrenceView
     */
    private void initRecurrenceView() {
        binding.rInfoSwitch.setOnToggleChanged(on -> {
            isRepeat = on;
            if (on) {
                binding.rInfoEndLayout.setVisibility(VISIBLE);
                binding.rInfoWeeklyDetailsLayout.setVisibility(VISIBLE);
            } else {
                binding.rInfoEndLayout.setVisibility(GONE);
                binding.rInfoWeeklyDetailsLayout.setVisibility(GONE);
            }
        });
        binding.rInfoEndSwitch.setOnToggleChanged(on -> {
            if (on) {
                endType = binding.rInfoEndRadioGroup.getCheckedRadioButtonId() == binding.rInfoEndTimeRButton.getId() ? 1 : 2;
                binding.rInfoEndInfoLayout.setVisibility(VISIBLE);
            } else {
                endType = 0;
                binding.rInfoEndInfoLayout.setVisibility(GONE);
            }
        });
        binding.rInfoWeeklyLayout.setOnClickListener(view -> {
            repeatType = 1;
            binding.rInfoWeeklySelectImg.setVisibility(VISIBLE);
            binding.rInfoBiWeeklySelectImg.setVisibility(GONE);
            binding.rInfoBiWeeklyInfoLayout.setVisibility(GONE);
            binding.rInfoWeeklyInfoLayout.setVisibility(VISIBLE);
        });
        binding.rInfoBiWeeklyLayout.setOnClickListener(view -> {
            repeatType = 2;
            binding.rInfoWeeklySelectImg.setVisibility(GONE);
            binding.rInfoBiWeeklySelectImg.setVisibility(VISIBLE);

            binding.rInfoBiWeeklyInfoLayout.setVisibility(VISIBLE);
            binding.rInfoWeeklyInfoLayout.setVisibility(GONE);
        });


        binding.weekly1.setOnClickListener(this);
        binding.weekly2.setOnClickListener(this);
        binding.weekly3.setOnClickListener(this);
        binding.weekly4.setOnClickListener(this);
        binding.weekly5.setOnClickListener(this);
        binding.weekly6.setOnClickListener(this);
        binding.weekly7.setOnClickListener(this);
        binding.biweekly1.setOnClickListener(this);
        binding.biweekly2.setOnClickListener(this);
        binding.biweekly3.setOnClickListener(this);
        binding.biweekly4.setOnClickListener(this);
        binding.biweekly5.setOnClickListener(this);
        binding.biweekly6.setOnClickListener(this);
        binding.biweekly7.setOnClickListener(this);
        binding.rInfoEndRadioGroup.setOnCheckedChangeListener((radioGroup, i) -> {
            if (radioGroup.getId() == binding.rInfoEndTimeRButton.getId()) {
                endType = 1;
            } else {
                endType = 2;
            }
        });
        binding.rInfoEndTimeString.setOnClickListener(view -> {
            showSelectEntTime();
        });
        binding.rInfoEndCountString.setOnClickListener(view -> {
            showSetEndCount();
        });

        binding.rInfoSwitch.setToggle(isRepeat);
        if (isRepeat) {
            binding.rInfoEndLayout.setVisibility(VISIBLE);
            binding.rInfoWeeklyDetailsLayout.setVisibility(VISIBLE);
            if (repeatType == 1) {
                binding.rInfoWeeklySelectImg.setVisibility(VISIBLE);
                binding.rInfoBiWeeklySelectImg.setVisibility(GONE);
                binding.rInfoBiWeeklyInfoLayout.setVisibility(GONE);
                binding.rInfoWeeklyInfoLayout.setVisibility(VISIBLE);
            } else if (repeatType == 2) {
                binding.rInfoWeeklySelectImg.setVisibility(GONE);
                binding.rInfoBiWeeklySelectImg.setVisibility(VISIBLE);
                binding.rInfoBiWeeklyInfoLayout.setVisibility(VISIBLE);
                binding.rInfoWeeklyInfoLayout.setVisibility(GONE);
            }
        } else {
            binding.rInfoEndLayout.setVisibility(GONE);
            binding.rInfoWeeklyDetailsLayout.setVisibility(GONE);
        }
        if (endType == 0) {
            binding.rInfoEndSwitch.setToggle(false);
            binding.rInfoEndInfoLayout.setVisibility(GONE);
        } else if (endType == 1) {
            binding.rInfoEndSwitch.setToggle(true);
            binding.rInfoEndInfoLayout.setVisibility(VISIBLE);
            binding.rInfoEndTimeRButton.setChecked(true);
            binding.rInfoEndCountRButton.setChecked(false);
        } else if (endType == 2) {
            binding.rInfoEndSwitch.setToggle(true);
            binding.rInfoEndInfoLayout.setVisibility(VISIBLE);
            binding.rInfoEndTimeRButton.setChecked(false);
            binding.rInfoEndCountRButton.setChecked(true);
        }

        LessonTypeEntity lessonTypeEntity = configData.getLessonType();
        if (lessonTypeEntity == null) {
            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                for (LessonTypeEntity lessonType : ListenerService.shared.teacherData.getLessonTypes()) {
                    if (lessonType.getId().equals(configData.getLessonTypeId())) {
                        lessonTypeEntity = lessonType;
                        break;
                    }
                }
            } else {
                for (LessonTypeEntity lessonType : ListenerService.shared.studioData.getLessonTypesData()) {
                    if (lessonType.getId().equals(configData.getLessonTypeId())) {
                        lessonTypeEntity = lessonType;
                        break;
                    }
                }
            }
        }
        if (lessonTypeEntity.get_package() != 0) {
            binding.endsPackageLayout.setVisibility(View.VISIBLE);
            binding.endsNoneLayout.setVisibility(View.GONE);
            binding.endsAfterPackage.setText("Ends after " + lessonTypeEntity.get_package() + " lessons");
        }
        binding.rInfoEndCountString.setText(endCount + "");
        binding.rInfoEndTimeString.setText(TimeUtils.timeFormat(endTime, "MMM d ，yyyy"));

    }


    private void showSetEndCount() {
        Dialog bottomDialog = new Dialog(getContext(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getContext()).inflate(R.layout.schedue_toast, null);
        //获取Dialog的监听

        InputView text = contentView.findViewById(R.id.tv_name);
        TextView confirm = contentView.findViewById(R.id.tv_confirm);
        TextView cancel = contentView.findViewById(R.id.tv_cancel);

        if (!text.getInputText().equals("10")) {
            text.setInputText((String) binding.rInfoEndCountString.getText());
        } else {
            text.setInputText("10");
        }
        cancel.setOnClickListener(v -> {
            if (bottomDialog.isShowing()) {
                bottomDialog.dismiss();
            }
        });

        confirm.setOnClickListener(v -> {
            if (text.getInputText().length() > 0) {
                binding.rInfoEndCountString.setText(text.getInputText());
                endCount = Integer.parseInt(text.getInputText());
                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
                }
            }
        });
        text.setFocus();
        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗
    }

    private void showSelectEntTime() {
        Dialog endDialog = new Dialog(getContext(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getContext()).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        TextView cancel = contentView.findViewById(R.id.tv_cancel);

        WebView webView1 = contentView.findViewById(R.id.web_view);
        submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.html");
        RescheduleAllAndUpcomingHost webHost1 = new RescheduleAllAndUpcomingHost(this);
        webView1.addJavascriptInterface(webHost1, "js");
        String endDate = com.spelist.tools.tools.TimeUtils.timestampToString(endTime, "yyyy/MM/dd");
        String startDate = com.spelist.tools.tools.TimeUtils.timestampToString(selectTime + 86400, "yyyy/MM/dd");
        webView1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView1.evaluateJavascript("getCalendarStartYMD('" + startDate + "','" + endDate + "')", s -> {
                });

            }

        });
        cancel.setOnClickListener(v -> {
            submitButton1 = null;
            endDialog.dismiss();
        });
        submitButton1.setOnClickListener(v -> {
            submitButton1 = null;
            endTime = webSelectEndTime;
            binding.rInfoEndTimeString.setText(TimeUtils.timeFormat(endTime, "MMM d ，yyyy"));
            endDialog.dismiss();
        });
        endDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        endDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        endDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        endDialog.show();//显示弹窗
    }

    public void setEndTime(String yymmd) {
        activity.runOnUiThread(() -> {
            if (submitButton1 == null) {
                return;
            }
            long timeStamp = com.spelist.tools.tools.TimeUtils.getStringToDate(yymmd, "yyyy-MM-dd") / 1000L;
            webSelectEndTime = (int) timeStamp;
            if (webSelectEndTime == 0) {
                submitButton1.setButtonStatus(1);
            } else {
                submitButton1.setButtonStatus(0);
            }


//        if (endTimeFromWebView.equals("")) {
//            submitButton1.setButtonStatus(1);
//        } else {
//            submitButton1.setButtonStatus(0);
//        }
        });
    }

    public void setRepeatTypeWeekDay(int weekDay) {
        boolean isAdd = true;
        for (int i = selectRecurrenceWeekly.size() - 1; i >= 0; i--) {
            if (selectRecurrenceWeekly.get(i) == weekDay) {
                isAdd = false;
                selectRecurrenceWeekly.remove(i);
            }
        }

        if (isAdd) {
            selectRecurrenceWeekly.add(weekDay);
        }
        initWeekCheckEnable();
        initWeekCheck(weekDay, isAdd);
    }

    public void clearRepeatTypeWeekDay() {
        binding.weekly1.setChecked(false);
        binding.weekly2.setChecked(false);
        binding.weekly3.setChecked(false);
        binding.weekly4.setChecked(false);
        binding.weekly5.setChecked(false);
        binding.weekly6.setChecked(false);
        binding.weekly7.setChecked(false);
        binding.biweekly1.setChecked(false);
        binding.biweekly2.setChecked(false);
        binding.biweekly3.setChecked(false);
        binding.biweekly4.setChecked(false);
        binding.biweekly5.setChecked(false);
        binding.biweekly6.setChecked(false);
        binding.biweekly7.setChecked(false);
    }

    private void initWeekCheckEnable() {
        if (selectRecurrenceWeekly.size() == 1) {
            switch (selectRecurrenceWeekly.get(0)) {
                case 0:
                    binding.weekly1.setClickable(false);
                    binding.biweekly1.setClickable(false);
                    break;
                case 1:
                    binding.weekly2.setClickable(false);
                    binding.biweekly2.setClickable(false);
                    break;
                case 2:
                    binding.weekly3.setClickable(false);
                    binding.biweekly3.setClickable(false);
                    break;
                case 3:
                    binding.weekly4.setClickable(false);
                    binding.biweekly4.setClickable(false);
                    break;
                case 4:
                    binding.weekly5.setClickable(false);
                    binding.biweekly5.setClickable(false);
                    break;
                case 5:
                    binding.weekly6.setClickable(false);
                    binding.biweekly6.setClickable(false);
                    break;
                case 6:
                    binding.weekly7.setClickable(false);
                    binding.biweekly7.setClickable(false);
                    break;
            }
        } else {
            binding.weekly1.setClickable(true);
            binding.weekly2.setClickable(true);
            binding.weekly3.setClickable(true);
            binding.weekly4.setClickable(true);
            binding.weekly5.setClickable(true);
            binding.weekly6.setClickable(true);
            binding.weekly7.setClickable(true);
            binding.biweekly1.setClickable(true);
            binding.biweekly2.setClickable(true);
            binding.biweekly3.setClickable(true);
            binding.biweekly4.setClickable(true);
            binding.biweekly5.setClickable(true);
            binding.biweekly6.setClickable(true);
            binding.biweekly7.setClickable(true);
        }
    }

    private void initWeekCheck(int weekDay, boolean isAdd) {
        switch (weekDay) {
            case 0:
                binding.weekly1.setChecked(isAdd);
                binding.biweekly1.setChecked(isAdd);
                break;
            case 1:
                binding.weekly2.setChecked(isAdd);
                binding.biweekly2.setChecked(isAdd);
                break;
            case 2:
                binding.weekly3.setChecked(isAdd);
                binding.biweekly3.setChecked(isAdd);
                break;
            case 3:
                binding.weekly4.setChecked(isAdd);
                binding.biweekly4.setChecked(isAdd);
                break;
            case 4:
                binding.weekly5.setChecked(isAdd);
                binding.biweekly5.setChecked(isAdd);
                break;
            case 5:
                binding.weekly6.setChecked(isAdd);
                binding.biweekly6.setChecked(isAdd);
                break;
            case 6:
                binding.weekly7.setChecked(isAdd);
                binding.biweekly7.setChecked(isAdd);
                break;
        }
    }


}
