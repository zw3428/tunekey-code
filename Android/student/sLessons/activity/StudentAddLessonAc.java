package com.spelist.tunekey.ui.student.sLessons.activity;

import static com.spelist.tools.tools.TimeUtils.getWeek;
import static com.spelist.tools.tools.TimeUtils.isLastDayOfMonth;

import android.app.Dialog;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.GridLayoutManager;

import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.databinding.ActivityStudentAddLessonBinding;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentAddLessonVM;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLUiUtils;
import com.spelist.tunekey.utils.WebHost;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class StudentAddLessonAc extends BaseActivity<ActivityStudentAddLessonBinding, StudentAddLessonVM> {

    public long oldStartTimeFromWebView = 0;
    public long startTimeFromWebView = 0;
    private Dialog bottomDialog;
    public long oldEndTimeFromWebView = 0;
    public long endTimeFromWebView = 0;

    private Dialog endDialog;
    private SubmitButton submitButton1;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_add_lesson;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
    }

    @Override
    public void initView() {
        super.initView();
        binding.confirmButton.setEnabled(false);
        viewModel.gridLayoutManager.set(new GridLayoutManager(this, 4));
        //设定初始化折叠，默认展开
        binding.swRec.setOnToggleChanged(on -> {
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
        });
        binding.swEnd.setOnToggleChanged(on -> {
            if (on) {
                binding.linEnd.setVisibility(View.VISIBLE);
                viewModel.scheduleConfigEntity.setEndType(1);
                binding.rb3.setChecked(true);
                binding.rb4.setChecked(false);

            } else {
                binding.linEnd.setVisibility(View.GONE);
                viewModel.scheduleConfigEntity.setEndType(0);
            }
        });
        binding.rcvAddlesson.setVisibility(View.GONE);
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.addLessonList.observe(this, integer -> {
            if ((integer == View.VISIBLE && binding.rcvAddlesson.getVisibility() == View.GONE || binding.rcvAddlesson.getVisibility() == View.INVISIBLE) ||
                    (integer == View.INVISIBLE || integer == View.GONE && binding.rcvAddlesson.getVisibility() == View.VISIBLE)) {
                SLUiUtils.expandAndCollapse(binding.rcvAddlesson, 500);
            }
        });
        viewModel.uc.imageClick.observe(this, isShowList -> {
            binding.lessonIconArrow.animate().rotation(viewModel.selectAnIconVisibility.getValue() == View.GONE ? -180 : 0);
        });

        //点击修改时间
        viewModel.uc.startTime.observe(this, aVoid -> {
            if (viewModel.scheduleConfigEntity.getRepeatTypeWeekDay() == null || viewModel.scheduleConfigEntity.getRepeatTypeWeekDay().size() == 0) {
                binding.weekly4.setChecked(true);
                binding.biweekly4.setChecked(true);
                viewModel.setRepeatType(0);
                viewModel.setRepeatTypeWeekDay(3);
            }
            showStartTime();
        });
        viewModel.uc.recWeekly.observe(this, aVoid -> {
            binding.imgWeekly.setVisibility(View.VISIBLE);
            binding.imgBi.setVisibility(View.GONE);
            binding.imgMonthly.setVisibility(View.GONE);
            binding.linWeekly.setVisibility(View.VISIBLE);
            binding.linBi.setVisibility(View.GONE);
            binding.linMonthly.setVisibility(View.GONE);
            viewModel.setRepeatType(1);
        });
        viewModel.uc.recBiWeekly.observe(this, aVoid -> {
            binding.imgWeekly.setVisibility(View.GONE);
            binding.imgBi.setVisibility(View.VISIBLE);
            binding.imgMonthly.setVisibility(View.GONE);
            binding.linWeekly.setVisibility(View.GONE);
            binding.linBi.setVisibility(View.VISIBLE);
            binding.linMonthly.setVisibility(View.GONE);
            viewModel.setRepeatType(2);
        });
        viewModel.uc.endTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                showEndDialog();
            }
        });
        viewModel.uc.currenceTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                showUpPop();
            }
        });

    }

    public void showUpPop() {
        bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.schedue_toast, null);
        //获取Dialog的监听

        InputView text = contentView.findViewById(R.id.tv_name);
        TextView confirm = contentView.findViewById(R.id.tv_confirm);
        TextView cancel = contentView.findViewById(R.id.tv_cancel);

        if (!text.getInputText().equals("10")) {
            text.setInputText((String) binding.tvCurrenceTime.getText());
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
                binding.tvCurrenceTime.setText(text.getInputText());
                viewModel.scheduleConfigEntity.setEndCount(Integer.parseInt(text.getInputText()));
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


    public void getWebViewEndTime(String endTime) {
        this.runOnUiThread(() -> {
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
//        if (endTimeFromWebView.equals("")) {
//            submitButton1.setButtonStatus(1);
//        } else {
//            submitButton1.setButtonStatus(0);
//        }
        });
    }

    private void showStartTime() {
        long t = 0;
        if (startTimeFromWebView > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
            t = startTimeFromWebView * 1000L;
        }
        SelectLessonDialog.Builder builder = new SelectLessonDialog.Builder(this)
                .create("",
                        t,
                        60);
        builder.clickConfirm(tkButton -> {
            startTimeFromWebView = builder.getSelectTime();
            binding.tvStartTime.setText(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
            viewModel.startTime1 = (int) startTimeFromWebView;
            binding.linRecurrence.setVisibility(View.VISIBLE);
            long time = startTimeFromWebView * 1000L;
            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
            endTimeFromWebView = endTim / 1000L;
            oldEndTimeFromWebView = endTim / 1000L;
            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
            binding.tvEndsDate.setText(TimeUtils.getDateForMMMTime(endTim));
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
            binding.confirmButton.setEnabled(true);
            if (isLastDayOfMonth(time)) {
                viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(time)));
            } else {
                viewModel.setRepeatTypeMonthType(getWeek(time).substring(0, 1) + ":" + TimeUtils.getDay(time));
            }
            refreshData(false);
            builder.dismiss();
        });
    }

    private void refreshData(boolean isLessonType) {
//        if (isLessonType) {
//            binding.tvStartTime.setText("Tap to select time");
//            oldStartTimeFromWebView = 0;
//            startTimeFromWebView = 0;
//            binding.linRecurrence.setVisibility(View.GONE);
//            binding.submitButton.setButtonStatus(1);
//        }


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
        viewModel.scheduleConfigEntity.setEndType(0);

    }

    public void showEndDialog() {
        endDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        WebView webView1 = contentView.findViewById(R.id.web_view);
        submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.html");
        WebHost webHost1 = new WebHost(this, this);
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
}