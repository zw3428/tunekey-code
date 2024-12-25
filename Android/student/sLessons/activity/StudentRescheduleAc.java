package com.spelist.tunekey.ui.student.sLessons.activity;

import android.app.Dialog;
import android.os.Bundle;
import android.os.Handler;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.recyclerview.widget.GridLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.StudentLessonService;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.databinding.ActivityStudentRescheduleBinding;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.StudentRescheduleHost;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentRescheduleVM;
import com.spelist.tunekey.utils.FuncUtils;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class StudentRescheduleAc extends BaseActivity<ActivityStudentRescheduleBinding, StudentRescheduleVM> {


    private GridLayoutManager gridLayoutManager;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_reschedule;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        viewModel.beforeData = (LessonScheduleEntity) getIntent().getSerializableExtra("lessonData");
        viewModel.policyData = (PolicyEntity) getIntent().getSerializableExtra("policyData");
        viewModel.teacherData = (UserEntity) getIntent().getSerializableExtra("teacherData");
        viewModel.afterData = (LessonRescheduleEntity) getIntent().getSerializableExtra("rescheduleData");
        viewModel.isCredit = getIntent().getBooleanExtra("isCredit", false);
        viewModel.creditId = getIntent().getStringExtra("creditId");

        viewModel.initData();
    }

    @Override
    public void initView() {
        super.initView();
        gridLayoutManager = new GridLayoutManager(this, 3);
        binding.bottomButton.setEnabled(false);

        binding.recyclerView.setLayoutManager(gridLayoutManager);
        binding.recyclerView.setItemAnimator(null);
        StudentRescheduleHost webHost = new StudentRescheduleHost(this, viewModel);
        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/cal.month.reschedule.date.html");
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
//                    binding.webView.evaluateJavascript("getAgenda(" + json + "," + oldTime + "," + lessonMinuteLength + ")", s -> {
//                    });
            }
        });
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickCancel.observe(this, aVoid -> {
            StudentLessonService.getInstance().cancelLesson(viewModel.policyData, viewModel.studentData, viewModel.beforeData, this);
        });
        viewModel.uc.refreshCalendar.observe(this, strings -> {
            //这里面 显示的出错啦
            //cal.month.reschedule.date.html 126行 item = date 为啥不这么写
            //yyyy-MM-dd 和 yyyy-M-d 时间差了一天
//            new Handler().postDelayed(() -> binding.webView.evaluateJavascript("getCalendarAvailableYMD('" + SLJsonUtils.toJsonString(strings) + "')", s -> {
//            }), 1000);
            Logger.e("????==>%s","????");
            binding.webView.evaluateJavascript("getCalendarAvailableYMD('" + SLJsonUtils.toJsonString(strings) + "')", s -> {
            });

        });
        viewModel.uc.refreshAvailableTime.observe(this, data ->{
                    gridLayoutManager.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                        @Override
                        public int getSpanSize(int position) {
                            //这个占几分,不是一排显示几个  注意 注意 注意
                            if (data.get(position).getData().getType() == 0) {
                                return 1;
                            } else {
                                return 3;
                            }
                        }

                    });
                    try {
                        new Handler().postDelayed(() -> {
                            int targetViewPosition = binding.recyclerView.getTop();
                            binding.scrollView.smoothScrollTo(0, targetViewPosition);
                        }, 200);
                    }catch (Exception e){

                    }


                }
              );
        viewModel.uc.clickAvailableTip.observe(this, aVoid -> {
            SLDialogUtils.showOneButton(this, "", "Tunekey's scheduling system tries to group lessons together to greatly increase efficiency and convenience for your instructor", "Ok");
        });
        viewModel.uc.clickAvailableTime.observe(this, aVoid -> {

            binding.bottomButton.setEnabled(true);
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

}