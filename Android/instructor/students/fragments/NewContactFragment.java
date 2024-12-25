package com.spelist.tunekey.ui.teacher.students.fragments;


import static com.spelist.tools.tools.TimeUtils.getWeek;
import static com.spelist.tools.tools.TimeUtils.isLastDayOfMonth;

import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.custom.SwitchButton;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.databinding.FragmentNewContactBinding;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.SetLessonConfigEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonTypeActivity;
import com.spelist.tunekey.ui.teacher.students.activity.NewContactActivity;
import com.spelist.tunekey.ui.teacher.students.vm.NewContactFragmentViewModel;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * A simple {@link Fragment} subclass.
 */
public class NewContactFragment extends BaseFragment<FragmentNewContactBinding, NewContactFragmentViewModel> {

    public int position;
    public static final int REQUEST_CODE = 1;
    private Dialog bottomDialog;
    private Dialog startTimeDialog;
    private Dialog endDialog;
    private int lessonMinuteLength;
    private Gson gson;
    private GsonBuilder builder;
    public String studentId;

    public long oldStartTimeFromWebView = 0;
    public long startTimeFromWebView = 0;
    private WebView startWebView;

    public long oldEndTimeFromWebView = 0;
    public long endTimeFromWebView = 0;
    private SubmitButton submitButton1;
    public boolean isComplete = false;
    public NewContactActivity contactActivity;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_new_contact;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();

        viewModel.initData1(0);
        viewModel.studentId = studentId;
        binding.linStartTime.setVisibility(View.GONE);
        binding.linRecurrence.setVisibility(View.GONE);
        //设定初始化折叠，默认展开
        binding.swRec.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                Logger.e("======%s", on);
                if (on) {
                    binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                    binding.layoutEnds.setVisibility(View.VISIBLE);
                    binding.linWeekly.setVisibility(View.VISIBLE);
                    binding.imgWeekly.setVisibility(View.VISIBLE);
                    binding.linBi.setVisibility(View.GONE);
                    binding.imgBi.setVisibility(View.GONE);
                    binding.linMonthly.setVisibility(View.GONE);
                    binding.imgMonthly.setVisibility(View.GONE);
                    viewModel.setRepeatType(1);
                } else {
                    binding.linRecurrenceDetail.setVisibility(View.GONE);
                    binding.layoutEnds.setVisibility(View.GONE);
                    viewModel.setRepeatType(0);
                }
            }
        });
        binding.swEnd.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                if (on) {
                    binding.linEnd.setVisibility(View.VISIBLE);
                    viewModel.scheduleConfigEntity.setEndType(1);
                    binding.rb3.setChecked(true);
                    binding.rb4.setChecked(false);

                } else {
                    binding.linEnd.setVisibility(View.GONE);
                    viewModel.scheduleConfigEntity.setEndType(0);
                }
            }
        });
    }


    @Override
    public void initViewObservable() {
        viewModel.lessonData.observe(this, agendaOnWebViewEntities -> {
            if (startWebView != null) {
                startWebView.evaluateJavascript("getAgenda(" + SLJsonUtils.toJsonString(agendaOnWebViewEntities) + ")", s -> {

                });
            }

        });

        viewModel.lessonTypeEntityMutableLiveData.observe(this, new Observer<LessonTypeEntity>() {
            @Override
            public void onChanged(LessonTypeEntity lessonTypeEntity) {
                binding.tvName.setText(lessonTypeEntity.getName());
                binding.tvInfo.setText(lessonTypeEntity.getInfo());
                RequestOptions placeholder = new RequestOptions()
                        .placeholder(R.drawable.ic_logo)
                        .error(R.drawable.ic_logo);
                Glide.with(binding.lessonTypeImage.getContext())
                        .load(lessonTypeEntity.getInstrumentPath())
                        .apply(placeholder)
                        .into(binding.lessonTypeImage);
            }
        });

        viewModel.liveData.observe(this, lessonScheduleConfigEntity -> {
            Logger.e("=======lessonScheduleConfigEntity======" + lessonScheduleConfigEntity);
            binding.tvStartTime.setText(TimeUtils.getCurrentTime(lessonScheduleConfigEntity.getStartDateTime()));
            if (lessonScheduleConfigEntity.getRepeatType() == 0) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.GONE);
                binding.layoutEnds.setVisibility(View.GONE);
            } else if (lessonScheduleConfigEntity.getRepeatType() == 1) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.VISIBLE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                for (int i = 0; i < lessonScheduleConfigEntity.getRepeatTypeWeekDay().size(); i++) {
                    switch (lessonScheduleConfigEntity.getRepeatTypeWeekDay().get(i)) {
                        case 0:
                            binding.weekly1.setChecked(true);
                            break;
                        case 1:
                            binding.weekly2.setChecked(true);
                            break;
                        case 2:
                            binding.weekly3.setChecked(true);
                            break;
                        case 3:
                            binding.weekly4.setChecked(true);
                            break;
                        case 4:
                            binding.weekly5.setChecked(true);
                            break;
                        case 5:
                            binding.weekly6.setChecked(true);
                            break;
                        case 6:
                            binding.weekly7.setChecked(true);
                            break;
                    }
                }
            } else if (lessonScheduleConfigEntity.getRepeatType() == 2) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linBi.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.VISIBLE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                for (int i = 0; i < lessonScheduleConfigEntity.getRepeatTypeWeekDay().size(); i++) {
                    switch (lessonScheduleConfigEntity.getRepeatTypeWeekDay().get(i)) {
                        case 0:
                            binding.biweekly1.setChecked(true);
                            break;
                        case 1:
                            binding.biweekly2.setChecked(true);
                            break;
                        case 2:
                            binding.biweekly3.setChecked(true);
                            break;
                        case 3:
                            binding.biweekly4.setChecked(true);
                            break;
                        case 4:
                            binding.biweekly5.setChecked(true);
                            break;
                        case 5:
                            binding.biweekly6.setChecked(true);
                            break;
                        case 6:
                            binding.biweekly7.setChecked(true);
                            break;
                    }
                }
            } else if (lessonScheduleConfigEntity.getRepeatType() == 3) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linMonthly.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.month1.setText(lessonScheduleConfigEntity.getRepeatTypeMonthDay());
            }
        });


        viewModel.uc.currenceTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                showUpPop();
            }
        });


        viewModel.uc.startTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                if (viewModel.scheduleConfigEntity.getRepeatTypeWeekDay() == null || viewModel.scheduleConfigEntity.getRepeatTypeWeekDay().size() == 0) {
                    binding.weekly4.setChecked(true);
                    binding.biweekly4.setChecked(true);
                    viewModel.setRepeatType(0);
                    viewModel.setRepeatTypeWeekDay(3);
                }
                showStartTime();
            }
        });

        viewModel.uc.endTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                showEndDialog();
            }
        });

        viewModel.uc.selectLessonType.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                Intent intent = new Intent(getActivity(), LessonTypeActivity.class);
                intent.putExtra("flag", REQUEST_CODE);
                startActivityForResult(intent, REQUEST_CODE);
            }
        });


        viewModel.uc.recWeekly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.VISIBLE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.VISIBLE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(1);
            }
        });

        viewModel.uc.recBiWeekly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.VISIBLE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.VISIBLE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(2);
            }
        });

        viewModel.uc.recMonthly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.VISIBLE);
                viewModel.setRepeatType(3);
            }
        });


    }

    public void selectLessonType(LessonTypeEntity lessonTypeEntity) {
        lessonMinuteLength = lessonTypeEntity.getTimeLength();
        viewModel.getLessonId(lessonTypeEntity.getId());
        viewModel.scheduleConfigEntity.setLessonType(lessonTypeEntity);
        binding.linSelectLesson.setVisibility(View.GONE);
        binding.linLessonType.setVisibility(View.VISIBLE);
        binding.tvName.setText(lessonTypeEntity.getName());
        binding.tvInfo.setText(lessonTypeEntity.getInfo());
        RequestOptions placeholder = new RequestOptions()
                .placeholder(R.drawable.ic_logo)
                .error(R.drawable.ic_logo);
        Glide.with(binding.lessonTypeImage.getContext())
                .load(lessonTypeEntity.getInstrumentPath())
                .apply(placeholder)
                .into(binding.lessonTypeImage);
        binding.linStartTime.setVisibility(View.VISIBLE);
        if (binding.linRecurrence.getVisibility() == View.VISIBLE) {
            refreshData(true);
        }
        if (lessonTypeEntity.get_package() == 0) {
            binding.endsPackageLayout.setVisibility(View.GONE);
            binding.endsNoneLayout.setVisibility(View.VISIBLE);
            viewModel.scheduleConfigEntity.setEndType(0);
        } else {
            binding.endsPackageLayout.setVisibility(View.VISIBLE);
            binding.endsNoneLayout.setVisibility(View.GONE);
            binding.endsAfterPackage.setText("Ends after " + lessonTypeEntity.get_package() + " lessons");
            viewModel.scheduleConfigEntity.setEndType(2);
            viewModel.scheduleConfigEntity.setEndCount(lessonTypeEntity.get_package());
        }
    }

    private void showEndDialog() {
        endDialog = new Dialog(getActivity(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        WebView webView1 = contentView.findViewById(R.id.web_view);
        submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.html");
        WebHost webHost1 = new WebHost(getActivity(), this);
        webView1.addJavascriptInterface(webHost1, "js");
        String endDate = TimeUtils.timestampToString(endTimeFromWebView, "yyyy/MM/dd");
        String startDate = TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd");
        webView1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView1.evaluateJavascript("getCalendarStartYMD('" + startDate + "','" + endDate + "')", s -> {
                });

            }

        });
        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                submitButton1 = null;
                endDialog.dismiss();
            }
        });
        submitButton1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                endTimeFromWebView = oldEndTimeFromWebView;
                viewModel.scheduleConfigEntity.setEndDate((int) (endTimeFromWebView));
                binding.tvEndsDate.setText(TimeUtils.timestampToString(endTimeFromWebView, "MMM d ，yyyy"));
                submitButton1 = null;
                endDialog.dismiss();
            }
        });
        endDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        endDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        endDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        endDialog.show();//显示弹窗
    }

    private void refreshData(boolean isLessonType) {
        if (isLessonType) {
            binding.tvStartTime.setText("Tap to select time");
            oldStartTimeFromWebView = 0;
            startTimeFromWebView = 0;
            binding.linRecurrence.setVisibility(View.GONE);
//            submitButton.setButtonStatus(1);
            isComplete = false;
        } else {
            isComplete = true;
        }
        Logger.e("=====fragment=%s", isComplete);
        contactActivity.changeData(position, isComplete);

        viewModel.scheduleConfigEntity.setRepeatType(0);
        viewModel.scheduleConfigEntity.setEndType(0);
        viewModel.scheduleConfigEntity.setStartDateTime(0);
        binding.linRecurrenceDetail.setVisibility(View.GONE);
        binding.swEnd.setToggleOff();
        binding.linWeekly.setVisibility(View.VISIBLE);
        binding.imgWeekly.setVisibility(View.VISIBLE);
        binding.linBi.setVisibility(View.GONE);
        binding.imgBi.setVisibility(View.GONE);
        binding.linMonthly.setVisibility(View.GONE);
        binding.imgMonthly.setVisibility(View.GONE);
        binding.rb3.setChecked(true);
        binding.rb4.setChecked(false);
        binding.swRec.setToggleOff();
        binding.linEnd.setVisibility(View.GONE);
        binding.layoutEnds.setVisibility(View.GONE);
        if (viewModel.scheduleConfigEntity.getLessonType().get_package() == 0) {
            viewModel.scheduleConfigEntity.setEndType(0);
        } else {
            viewModel.scheduleConfigEntity.setEndType(2);
            viewModel.scheduleConfigEntity.setEndCount(viewModel.scheduleConfigEntity.getLessonType().get_package());
        }


    }

    public void showStartTime() {
//        startTimeDialog = new Dialog(getActivity(), R.style.BottomDialog);
//        View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.layout_start_time_dialog, null);
//        //获取Dialog的监听
//        startWebView = contentView.findViewById(R.id.web_view);
//        submitButton = contentView.findViewById(R.id.tv_confirm);
//        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);
//        submitButton.setButtonStatus(1);
//
//        //传该日期前后三个月内的课程数据lessonData，日历第一天的时间戳 timestamp，老师设置的课程时长 minuteLength
//        FuncUtils.initWebViewSetting(startWebView, "file:///android_asset/web/3-day-lesson.for.popup.html");
//        WebHost webHost = new WebHost(getActivity(), this);
//        startWebView.addJavascriptInterface(webHost, "js");
//        builder = new GsonBuilder();
//        gson = builder.create();
//        Type type = new TypeToken<List<LessonScheduleEntity>>() {
//        }.getType();
//
//        String lessonScheduleJson = gson.toJson(viewModel.lessonData.getValue(), type);
//        long oldTime = startTimeFromWebView * 1000;
//
//        startWebView.setWebViewClient(new WebViewClient() {
//            @Override
//            public void onPageFinished(WebView view, String url) {
//                super.onPageFinished(view, url);
//                startWebView.evaluateJavascript("getAgenda(" + lessonScheduleJson + "," + oldTime + "," + lessonMinuteLength + ")", s -> {
//                });
//            }
//        });
//
////        Logger.e("-----" + viewModel.lessonData.getValue() + "-----" + lessonMinuteLength);
//        cancel.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                if (startTimeDialog.isShowing()) {
//                    submitButton = null;
//                    startWebView = null;
//                    startTimeDialog.dismiss();
//                }
//            }
//        });
//
//        submitButton.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                startTimeFromWebView = oldStartTimeFromWebView;
//                binding.tvStartTime.setText(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
//                viewModel.getStartTime((int) startTimeFromWebView);
//                submitButton.setButtonStatus(0);
//                binding.linRecurrence.setVisibility(View.VISIBLE);
//                long time = startTimeFromWebView * 1000L;
//                long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
//                endTimeFromWebView = endTim / 1000L;
//                oldEndTimeFromWebView = endTim / 1000L;
//                viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
//                binding.tvEndsDate.setText(TimeUtils.getDateForMMMTime(endTim));
//
//                submitButton = null;
//                startWebView = null;
////                binding.submitButton.setButtonStatus(0);
//                String weekAndDay = "On" + " " + getWeek(time) + " " + TimeUtils.getDate(time);
//                String lastWeek = "On the last " + TimeUtils.getDate(time);
//                //判断是否是本月最后一周
//                if (isLastDayOfMonth(time)) {
//                    binding.month1.setText(lastWeek);
//                    viewModel.getRepeatTypeMonthDay(2);
//                } else {
//                    binding.month1.setText(weekAndDay);
//                    viewModel.getRepeatTypeMonthDay(1);
//                }
//                if (isLastDayOfMonth(time)) {
//                    viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(time)));
//                } else {
//                    viewModel.setRepeatTypeMonthType(getWeek(time).substring(0, 1) + ":" + TimeUtils.getDay(time));
//                }
//                refreshData(false);
//                startTimeDialog.dismiss();
//            }
//        });
//
//        startTimeDialog.setContentView(contentView);
//        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
//        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
//        contentView.setLayoutParams(layoutParams);
//        startTimeDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
//        startTimeDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
//        startTimeDialog.show();//显示弹窗
        long t = 0;
        if (startTimeFromWebView > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
            t = startTimeFromWebView * 1000L;
        }
        SelectLessonDialog.Builder builder = new SelectLessonDialog.Builder(getActivity())
                .create(UserService.getInstance().getCurrentUserId(),
                        t,
                        lessonMinuteLength);
        builder.clickConfirm(tkButton -> {
//            builder.selectTime;
//            showSendMessage(lessonScheduleEntities, builder.getSelectTime() + "");
            startTimeFromWebView = builder.getSelectTime();
            binding.tvStartTime.setText(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
            viewModel.getStartTime((int) startTimeFromWebView);
//            submitButton.setButtonStatus(0);
            binding.linRecurrence.setVisibility(View.VISIBLE);
            long time = startTimeFromWebView * 1000L;
            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
            endTimeFromWebView = endTim / 1000L;
            oldEndTimeFromWebView = endTim / 1000L;
            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
            binding.tvEndsDate.setText(TimeUtils.getDateForMMMTime(endTim));

//            submitButton = null;
            startWebView = null;
//                binding.submitButton.setButtonStatus(0);
            String weekAndDay = "On" + " " + getWeek(time) + " " + TimeUtils.getDate(time);
            String lastWeek = "On the last " + TimeUtils.getDate(time);
            //判断是否是本月最后一周
            if (isLastDayOfMonth(time)) {
                binding.month1.setText(lastWeek);
                viewModel.getRepeatTypeMonthDay(2);
            } else {
                binding.month1.setText(weekAndDay);
                viewModel.getRepeatTypeMonthDay(1);
            }
            if (isLastDayOfMonth(time)) {
                viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(time)));
            } else {
                viewModel.setRepeatTypeMonthType(getWeek(time).substring(0, 1) + ":" + TimeUtils.getDay(time));
            }
            refreshData(false);
            builder.dismiss();
        });
    }


    public void getWebViewStartTime(int startTime) {

//        getActivity().runOnUiThread(() -> {
//            if (submitButton != null) {
//                oldStartTimeFromWebView = startTime;
//
//                if (oldStartTimeFromWebView == 0) {
//                    submitButton.setButtonStatus(1);
//                } else {
//                    submitButton.setButtonStatus(0);
//                }
//            }
//        });
    }

    public void changeCalendarTime(long startTime) {
        viewModel.changeCalendarTime(startTime);
    }

    public void getWebViewEndTime(String endTime) {

        getActivity().runOnUiThread(() -> {
            if (submitButton1 != null) {
                long timeStamp = TimeUtils.getStringToDate(endTime, "yyyy-MM-dd") / 1000L;
                viewModel.scheduleConfigEntity.setEndDate((int) timeStamp);
                oldEndTimeFromWebView = timeStamp;
                if (oldEndTimeFromWebView == 0) {
                    submitButton1.setButtonStatus(1);
                } else {
                    submitButton1.setButtonStatus(0);
                }
            }
        });
    }


    public void showUpPop() {
        bottomDialog = new Dialog(getActivity(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.schedue_toast, null);
        //获取Dialog的监听

        InputView text = contentView.findViewById(R.id.tv_name);
        TextView confirm = (TextView) contentView.findViewById(R.id.tv_confirm);
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        if (!text.getInputText().equals("10")) {
            text.setInputText((String) binding.tvCurrenceTime.getText());
        } else {
            text.setInputText("10");
        }
        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
                }
            }
        });

        confirm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (text.getInputText().length() > 0) {
                    binding.tvCurrenceTime.setText(text.getInputText());
                    viewModel.scheduleConfigEntity.setEndCount(Integer.parseInt(text.getInputText()));
                    if (bottomDialog.isShowing()) {
                        bottomDialog.dismiss();
                    }
                }
            }
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗
    }

    public SetLessonConfigEntity getConfig() {
        LessonScheduleConfigEntity lessonScheduleConfigEntity = CloneObjectUtils.cloneObject(viewModel.scheduleConfigEntity);
        lessonScheduleConfigEntity.setStartDateTime((int) startTimeFromWebView);
        int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(startTimeFromWebView * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : lessonScheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        lessonScheduleConfigEntity.setRepeatTypeWeekDay(weekDays);
        SetLessonConfigEntity entity = new SetLessonConfigEntity();
        entity.setLessonType(lessonScheduleConfigEntity.getLessonType());
        entity.setLessonScheduleConfig(lessonScheduleConfigEntity);

        return entity;
    }
}
