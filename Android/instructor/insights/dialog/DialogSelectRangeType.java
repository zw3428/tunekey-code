package com.spelist.tunekey.ui.teacher.insights.dialog;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.ui.teacher.insights.fragments.InsightsFragment;
import com.spelist.tunekey.ui.teacher.insights.vm.InsightsViewModel;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementFragment;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementViewModel;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.Objects;

/**
 * @author zw, Created on 2020-08-14
 */
public class DialogSelectRangeType extends DialogFragment {

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击

    private InsightsFragment insightsFragment;
    private InsightsViewModel insightsViewModel;
    private StudentAchievementFragment studentAchievementFragment;
    private StudentAchievementViewModel studentAchievementViewModel;
    private long rangeStartTime;
    private long rangeEndTime;
    private LinearLayout rangeType;
    private TextView nextMonth;
    private TextView thisMonth;
    private TextView lastMonth;
    private TextView last2Month;
    private TextView last3Month;
    private TextView dateRange;
    private TextView cancelBottomDialog;
    private LinearLayout dateRangeCalendar;
    private WebView dateRangeCalendarWebview;
    public DialogSelectRangeType(){

    }
    public DialogSelectRangeType(InsightsFragment insightsFragment, InsightsViewModel viewModel, long rangeStartTime,
                                 long rangeEndTime) {
        this.insightsFragment = insightsFragment;
        this.insightsViewModel = viewModel;
        this.rangeStartTime = rangeStartTime;
        this.rangeEndTime = rangeEndTime;
    }

    public DialogSelectRangeType(StudentAchievementFragment insightsFragment, StudentAchievementViewModel viewModel, long rangeStartTime,
                                 long rangeEndTime) {
        this.studentAchievementFragment = insightsFragment;
        this.studentAchievementViewModel = viewModel;
        this.rangeStartTime = rangeStartTime;
        this.rangeEndTime = rangeEndTime;
    }

    public void updateTime(long start, long end) {
        if (insightsViewModel != null) {
            insightsViewModel.rangeStartTime = start;
            insightsViewModel.rangeEndTime = end;
        }
        if (studentAchievementViewModel != null) {
            studentAchievementViewModel.rangeStartTime = start;
            studentAchievementViewModel.rangeEndTime = end;
        }

    }

    private void initView() {
        rangeType = (LinearLayout) view.findViewById(R.id.range_type);
        nextMonth = (TextView) view.findViewById(R.id.next_month);
        thisMonth = (TextView) view.findViewById(R.id.this_month);
        lastMonth = (TextView) view.findViewById(R.id.last_month);
        last2Month = (TextView) view.findViewById(R.id.last_2_month);
        last3Month = (TextView) view.findViewById(R.id.last_3_month);
        dateRange = (TextView) view.findViewById(R.id.date_range);
        cancelBottomDialog = (TextView) view.findViewById(R.id.cancel_bottom_dialog);
        dateRangeCalendar = (LinearLayout) view.findViewById(R.id.date_range_calendar);
        dateRangeCalendarWebview = (WebView) view.findViewById(R.id.date_range_calendar_webview);
    }

    /**
     * 回调
     */
    public interface DialogCallback {
        void nextMonth();

        void thisMonth();

        void lastMonth();

        void last2Month();

        void last3Month();

        void confirmDateRange();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_select_insight_range_type, container, false);
        initView();
        mDecorView = FuncUtils.initBottomDialogView(Objects.requireNonNull(getDialog()), getResources());
        return view;
    }

    public void setDialogCallback(DialogCallback dialogCallback) {
        this.dialogCallback = dialogCallback;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        FuncUtils.initBottomDialogAnimationIn(mIntoSlide, view);
        initListener();
        touchOutShowDialog();
        getFocus();
    }

    /**
     * 初始化监听
     */
    private void initListener() {
        dateRangeCalendar.setOnClickListener(v -> {
        });
        dateRangeCalendarWebview.setOnClickListener(v -> {
        });
        rangeType.setOnClickListener(v -> {
        });
        nextMonth.setOnClickListener(v -> {
            dialogCallback.nextMonth();
            dismissDialog();
        });
        thisMonth.setOnClickListener(v -> {
            dialogCallback.thisMonth();
            dismissDialog();
        });
        lastMonth.setOnClickListener(v -> {
            dialogCallback.lastMonth();
            dismissDialog();
        });
        last2Month.setOnClickListener(v -> {
            dialogCallback.last2Month();
            dismissDialog();
        });
        last3Month.setOnClickListener(v -> {
            dialogCallback.last3Month();
            dismissDialog();
        });
        dateRange.setOnClickListener(v -> {
            FuncUtils.initWebViewSetting(dateRangeCalendarWebview, "file:///android_asset/web/cal.month.for.popup.range.html");
            WebHost webHost = new WebHost(this.getContext(), this);
            dateRangeCalendarWebview.addJavascriptInterface(webHost, "js");
            dateRangeCalendarWebview.setWebViewClient(new WebViewClient() {
                @Override
                public void onPageFinished(WebView view, String url) {
                    super.onPageFinished(view, url);
                    Logger.e("======%s==%s", rangeStartTime, rangeEndTime);
                    dateRangeCalendarWebview.evaluateJavascript("getCalendarStartYMD(" + rangeStartTime + ", " + rangeEndTime + ")", s -> {
                    });
                }

            });
            rangeType.setVisibility(View.GONE);
            dateRangeCalendar.setVisibility(View.VISIBLE);
        });
        cancelBottomDialog.setOnClickListener(v -> {
            dismissDialog();
        });

    }

    public void dismissDialog() {
        if (isClick) {
            return;
        }
        isClick = true;
        initOutAnimation();
    }

    private void initOutAnimation() {
        mOutSlide = FuncUtils.initBottomDialogAnimationOut(mOutSlide, view);
        mOutSlide.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                isClick = false;
                DialogSelectRangeType.this.dismiss();
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
    }

    /**
     * 拦截手势(弹窗外区域)
     */
    @SuppressLint("ClickableViewAccessibility")
    private void touchOutShowDialog() {
        mDecorView.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                //弹框消失的动画执行相关代码
                dismissDialog();
            }
            return true;
        });
    }

    /**
     * 监听主界面back键
     * 当点击back键时，执行弹窗动画
     */
    private void getFocus() {
        getView().setFocusableInTouchMode(true);
        getView().requestFocus();
        getView().setOnKeyListener((v, keyCode, event) -> {
            // 监听到back键(悬浮手势)返回按钮点击事件
            if (event.getAction() == KeyEvent.ACTION_UP && keyCode == KeyEvent.KEYCODE_BACK) {
                //判断弹窗是否显示
                if (DialogSelectRangeType.this.getDialog().isShowing()) {
                    //关闭弹窗
                    dismissDialog();
                    return true;
                }
            }
            return false;
        });
    }
}
