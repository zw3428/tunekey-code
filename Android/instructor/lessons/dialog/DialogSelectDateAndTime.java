package com.spelist.tunekey.ui.teacher.lessons.dialog;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddBlockActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddEventActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddBlockActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddEventActivity;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.Objects;


/**
 * @author zw, Created on 2020-02-03
 */
public class DialogSelectDateAndTime extends DialogFragment {

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击
    private int type;

//    @BindView(R.id.calendar)
//    WebView calendar;
//    @BindView(R.id.next_button_disable)
//    TextView nextBtnDisable;
//    @BindView(R.id.next_button_clickable)
//    TextView nextBtnClickable;
//    @BindView(R.id.calendar_container)
//    LinearLayout calendarContainer;

    private AddBlockActivity addBlockActivity;
    private AddEventActivity addEventActivity;
    private Activity activity;
    private TextView nextBtnDisable;
    private TextView nextBtnClickable;
    private LinearLayout calendarContainer;
    private  WebView calendar;
    public DialogSelectDateAndTime(){}
    public DialogSelectDateAndTime(AddEventActivity activity, int type) {
        this.addEventActivity = activity;

        this.type = type;
    }

    private void initView() {
        nextBtnDisable = (TextView) view.findViewById(R.id.next_button_disable);
        nextBtnClickable = (TextView) view.findViewById(R.id.next_button_clickable);
        calendarContainer = view.findViewById(R.id.calendar_container);
        calendar =  view.findViewById(R.id.calendar);
    }

    public interface DialogCallback {
        void getDateAndTime();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_select_date, container, false);
        initView();
        mDecorView = FuncUtils.initBottomDialogView(Objects.requireNonNull(getDialog()), getResources());
        initCalendarWebView();
        return view;
    }

    public void initCalendarWebView() {

        String date = TimeUtils.getNowDate("yyyy/M/d");
        FuncUtils.initWebViewSetting(calendar, "file:///android_asset/web/cal.month.for.popup.html");
        WebHost webHost = new WebHost(this.getContext(), true, this);
        calendar.addJavascriptInterface(webHost, "js");

        calendar.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return true;
            }

            @Override
            public void onReceivedError(WebView view, int errorCode, String description,
                                        String failingUrl) {
                super.onReceivedError(view, errorCode, description, failingUrl);
            }

            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                super.onReceivedSslError(view, handler, error);
            }

            @Override
            public void onLoadResource(WebView view, String url) {
                super.onLoadResource(view, url);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return super.shouldOverrideUrlLoading(view, request);
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                Logger.e("=====date" + date);
                calendar.evaluateJavascript("getCalendarStartYMD('" + date + "')", s -> {
                });
            }
        });
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

    private void getFocus() {
        getView().setFocusableInTouchMode(true);
        getView().requestFocus();
        getView().setOnKeyListener((v, keyCode, event) -> {
            // 监听到back键(悬浮手势)返回按钮点击事件
            if (event.getAction() == KeyEvent.ACTION_UP && keyCode == KeyEvent.KEYCODE_BACK) {
                //判断弹窗是否显示
                if (DialogSelectDateAndTime.this.getDialog().isShowing()) {
                    //关闭弹窗
                    dismissDialog();
                    return true;
                }
            }
            return false;
        });
    }

    @SuppressLint("ClickableViewAccessibility")
    private void touchOutShowDialog() {
        mDecorView.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                dismissDialog();
            }
            return true;
        });
    }

    private void initListener() {
        calendar.setOnClickListener(v -> {
            dismissDialog();
        });
        calendarContainer.setOnClickListener(v -> {
        });
        nextBtnDisable.setOnClickListener(v -> {
            dismissDialog();
        });
        nextBtnClickable.setOnClickListener(v -> {
            addEventActivity.initMetronomeDialog(0);
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
                DialogSelectDateAndTime.this.dismiss();
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
    }

    public void getTime(String startTime) {
        Logger.e("######" + startTime);
        addEventActivity.getWebViewEndTime(startTime, true);
    }

}
