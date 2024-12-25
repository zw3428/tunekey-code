package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Observer;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.custom.SwitchButton;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityAddEventBinding;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.ui.teacher.lessons.vm.AddEventViewModel;
import com.spelist.tunekey.ui.teacher.profile.fragments.DialogTime;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.Objects;

import me.goldze.mvvmhabit.base.BaseActivity;

public class AddEventActivity extends BaseActivity<ActivityAddEventBinding, AddEventViewModel> {
    private DialogSelectDateAndTime dialogSelectDateAndTime;
    private FragmentManager fragmentManager;
    public DialogTime dialogTime;
    private Dialog endDialog;
    private Dialog bottomDialog;
    public String endTimeFromWebview = "";
    private String startTimeFromWebview = "";
    private BaseTitleViewModel baseTitleViewModel;
    private SubmitButton submitButton1;
    private long startStamp;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_add_event;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        baseTitleViewModel = new BaseTitleViewModel(getApplication());
        binding.setVariable(BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set(getString(R.string.addevent));
        binding.titleLayout.titleLeftImg.setImageResource(R.mipmap.ic_back_primary);
        baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);

        //设定初始化折叠，默认展开
        binding.swRec.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                if (on) {
                    binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                    binding.layoutEnds.setVisibility(View.VISIBLE);
                } else {
                    binding.linRecurrenceDetail.setVisibility(View.GONE);
                    binding.layoutEnds.setVisibility(View.GONE);
                    viewModel.getRepeatType(0);
                }
            }
        });
        binding.swEnd.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                if (on) {
                    binding.linEnd.setVisibility(View.VISIBLE);
                    if (binding.rb3.isChecked()) {
                        viewModel.eventConfigEntity.setEndType(1);
                        // viewModel.scheduleConfigEntity.setEndDate(binding.tvEndsDate.getText());
                    } else if (binding.rb4.isChecked()) {
                        viewModel.eventConfigEntity.setEndType(2);
                    }

                } else {
                    binding.linEnd.setVisibility(View.GONE);
                    viewModel.eventConfigEntity.setEndType(0);
                    Logger.e("=====");
                }
            }
        });
    }

    @Override
    public void initViewObservable() {

        viewModel.uc.selectStart.observe(this, aVoid -> {
            initSelectDateAndTimeDialog(0);
        });

        viewModel.uc.selectEnd.observe(this, aVoid -> {
            initMetronomeDialog(1);
        });

        viewModel.uc.currenceTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                showUpPop();
            }
        });

        viewModel.uc.endTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                showEndDialog();
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
                viewModel.getRepeatType(1);
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
                viewModel.getRepeatType(2);
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
                viewModel.getRepeatType(3);
            }
        });

    }

    @Override
    public void initView() {
        super.initView();
        binding.inputTitle.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                viewModel.getTitle(binding.inputTitle.getInputText());
            }
        });
    }

    public void initSelectDateAndTimeDialog(int type) {
        if (dialogSelectDateAndTime == null && fragmentManager == null) {
            dialogSelectDateAndTime = new DialogSelectDateAndTime(AddEventActivity.this, type);
            fragmentManager = this.getSupportFragmentManager();
        }
        viewModel.dialogSelectDateAndTime = dialogSelectDateAndTime;

        if (!dialogSelectDateAndTime.isAdded()) {
            dialogSelectDateAndTime.show(fragmentManager, "DialogFragments");
        }

        dialogSelectDateAndTime.setDialogCallback(new DialogSelectDateAndTime.DialogCallback() {
            @Override
            public void getDateAndTime() {

            }
        });

    }

    public void initMetronomeDialog(int type) {

        if (dialogTime == null) {
            dialogTime = new DialogTime();
        }
        if (fragmentManager == null) {
            fragmentManager = Objects.requireNonNull(getSupportFragmentManager());
        }

        assert dialogTime != null;
        if (!dialogTime.isAdded()) {
            dialogTime.show(fragmentManager, "DialogFragment");
        }
        dialogTime.setDialogCallback(new DialogTime.DialogCallback() {
            @SuppressLint("ResourceAsColor")
            @Override
            public void confirm(String count, String beat, boolean isAm) {
                if (Integer.parseInt(beat) < 10) {
                    beat = "0" + beat;
                }
                String selectTimeAm = count + ":" + beat;
                String selectTimePm = Integer.parseInt(count) + 12 + ":" + beat;
                if (isAm) {
                    long a = Integer.parseInt(count) * 3600000;
                    long b = Integer.parseInt(beat) * 60000;
                    long c = a + b + startStamp;
                    if (type==0){
                        binding.startDateAndTime.setText(String.format("%s, %s", selectTimeAm, startTimeFromWebview));
                        viewModel.startDateAndTime.setValue(String.valueOf(c));
                    }else if (type == 1){
                        binding.endDateAndTime.setText(selectTimeAm);
                        viewModel.endDateAndTime.setValue(String.valueOf(c));
                    }

                } else {
                    binding.startDateAndTime.setText(String.format("%s, %s", selectTimePm, startTimeFromWebview));
                    long a = (Integer.parseInt(count) + 12) * 3600000;
                    long b = Integer.parseInt(beat) * 60000;
                    long c = a + b + startStamp;
                    viewModel.startDateAndTime.setValue(String.valueOf(c));
                }
                Logger.e("=======" + selectTimeAm + "=====" + selectTimePm);
                dialogTime.dismissDialog();
            }
        });
    }

    public void showUpPop() {
        bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.schedue_toast, null);
        //获取Dialog的监听

        InputView text = contentView.findViewById(R.id.tv_name);
        TextView confirm = (TextView) contentView.findViewById(R.id.tv_confirm);
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

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
                binding.tvCurrenceTime.setText(text.getInputText());
                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
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

    private void showEndDialog() {
        endDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        WebView webView1 = contentView.findViewById(R.id.web_view);
        submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.html");
        WebHost webHost1 = new WebHost(this, this);
        webView1.addJavascriptInterface(webHost1, "js");
        String date = TimeUtils.getNowDate("yyyy/M/d");

        webView1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView1.evaluateJavascript("getCalendarStartYMD('" + date + "')", s -> {
                });
            }

        });


        submitButton1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                binding.tvEndsDate.setText(endTimeFromWebview);
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

    public void getWebViewEndTime(String endTime, Boolean isStartTime) {
        Logger.e("=====end" + endTime);
        long timeStamp = TimeUtils.getStringToDate(endTime, "yyyy-M-dd");
        startStamp = timeStamp;
        if (isStartTime) {
            startTimeFromWebview = TimeUtils.getNowDayAndTime(timeStamp, "MMM d yyyy");
        } else {

            // viewModel.scheduleConfigEntity.setEndDate((int) timeStamp);
            endTimeFromWebview = TimeUtils.getDateForMMMTime(timeStamp);
            if (endTimeFromWebview.equals("")) {

            } else {

            }

        }

    }


}
