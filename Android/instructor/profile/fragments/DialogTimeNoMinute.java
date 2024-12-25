package com.spelist.tunekey.ui.teacher.profile.fragments;

import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import com.spelist.tools.custom.DialogTimeNoMinutePickerData;
import com.spelist.tools.custom.NewPickerScrollView;
import com.spelist.tools.custom.easylayout.EasyConstraintLayout;
import com.spelist.tunekey.R;

import java.util.ArrayList;
import java.util.List;

public class DialogTimeNoMinute extends DialogFragment {

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击
    private InputHandler mInputHandler = new InputHandler();
    private boolean flags = false;//判断用户两次输入的时差是否大于500ms的标志 
    private long firstTime;//第一次的时间

    private int selectHr = 0;
    private DialogTimeNoMinutePickerData selectData = null;
    private List<DialogTimeNoMinutePickerData> data = new ArrayList<>();


    private boolean isAm = true;
    private LinearLayout pickerOuter;
    private LinearLayout timeAmLayout;
    private TextView timeAmTv;
    private View timeAmBorder;
    private LinearLayout timePmLayout;
    private TextView timePmTv;
    private View timePmBorder;
    private EasyConstraintLayout pickerContainer;
    private View pickerSelectedBg;
    private NewPickerScrollView firstPicker;
    private TextView pickerDivide;
    private RelativeLayout dialogBtnContainer;
    private TextView dialogCloseBtn;
    private TextView dialogConfirmBtn;
    private int minHour = -1;

    public DialogTimeNoMinute(){}

    public DialogTimeNoMinute(int minHour,int selectPos){
        this.minHour = minHour;
        this.selectHr = selectPos;
    }
    private void initView() {
        pickerOuter = (LinearLayout) view.findViewById(R.id.picker_outer);
        timeAmLayout = (LinearLayout) view.findViewById(R.id.time_am_layout);
        timeAmTv = (TextView) view.findViewById(R.id.time_am_tv);
        timeAmBorder = (View) view.findViewById(R.id.time_am_border);
        timePmLayout = (LinearLayout) view.findViewById(R.id.time_pm_layout);
        timePmTv = (TextView) view.findViewById(R.id.time_pm_tv);
        timePmBorder = (View) view.findViewById(R.id.time_pm_border);
        pickerContainer = (EasyConstraintLayout) view.findViewById(R.id.picker_container);
        pickerSelectedBg = (View) view.findViewById(R.id.picker_selected_bg);
        firstPicker = (NewPickerScrollView) view.findViewById(R.id.first_picker);
        pickerDivide = (TextView) view.findViewById(R.id.picker_divide);
        dialogBtnContainer = (RelativeLayout) view.findViewById(R.id.dialog_btn_container);
        dialogCloseBtn = (TextView) view.findViewById(R.id.dialog_close_btn);
        dialogConfirmBtn = (TextView) view.findViewById(R.id.dialog_confirm_btn);
    }


    /**
     * 通讯回调接口
     */
    public interface DialogCallback {
        void confirm(DialogTimeNoMinutePickerData data);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_time_no_minute, container, false);
        initView();

        //初始化Dialog
        initDialogView();
        //初始化监听器
        initListener();
        //初始化 pickerView 数据
        initPickerViewData();

        return view;
    }

    private void initPickerViewData() {
        data = DialogTimeNoMinutePickerData.getData();
        if (minHour != -1){
            //过滤小min hour的
            for (int i = 0; i < data.size(); i++) {
                if (data.get(i).getHr() <= minHour){
                    data.remove(i);
                    i--;
                }
            }
        }

        // 设置数据，默认选择
        firstPicker.setData(data);
        int selectPos = 0;
        for (int i = 0; i < data.size(); i++) {
            if (data.get(i).getHr() == selectHr){
                selectPos = i;
                selectData = data.get(i);
                break;
            }
        }
        firstPicker.setSelected(selectPos);

    }

    public void setDialogCallback(DialogCallback dialogCallback) {
        this.dialogCallback = dialogCallback;
    }

    /**
     * 根据业务需求，更改弹窗的一些样式
     */
    private void initDialogView() {
        mDecorView = getDialog().getWindow().getDecorView();
        //设置背景为透明
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            mDecorView.setBackground(new ColorDrawable(Color.TRANSPARENT));
        }

        Window window = getDialog().getWindow();
        WindowManager.LayoutParams layoutParams = window.getAttributes();
        //居屏幕底部
        layoutParams.gravity = Gravity.BOTTOM;
        //给window宽度设置成填充父窗体，解决窗体宽度过小问题
        layoutParams.width = WindowManager.LayoutParams.MATCH_PARENT;

        window.setAttributes(layoutParams);
        mDecorView.setPadding(0, 0, 0, 0);

        window.getDecorView().setMinimumWidth(getResources().getDisplayMetrics().widthPixels);

    }

    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        //弹窗弹入屏幕的动画
        initIntAnimation();
        //初始化监听
        initListener();
        //手指点击弹窗外处理
        touchOutShowDialog();
        //back键处理
        getFocus();
    }

    private void initListener() {
        firstPicker.setOnSelectListener(firstPickerListener);
        dialogConfirmBtn.setOnClickListener(clickListener);
        dialogCloseBtn.setOnClickListener(clickListener);


        pickerContainer.setOnClickListener(clickListener);
        pickerOuter.setOnClickListener(clickListener);
        dialogBtnContainer.setOnClickListener(clickListener);
        pickerSelectedBg.setOnClickListener(clickListener);
    }

    private class InputHandler extends Handler {
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case 1:
                    confirmButtonClickable();
                    break;
            }
        }
    }

    private void confirmButtonClickable() {
        flags = true;
        if (System.currentTimeMillis() - firstTime > 500) {
            flags = false;
        } else {
            mInputHandler.sendEmptyMessageDelayed(1, 300);
        }
    }


    /**
     * 弹窗弹入屏幕的动画
     */
    private void initIntAnimation() {
        if (mIntoSlide != null) {
            mIntoSlide.cancel();
        }
        mIntoSlide = new TranslateAnimation(
                Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 1.0f,
                Animation.RELATIVE_TO_SELF, 0.0f
        );
        mIntoSlide.setDuration(200);
        mIntoSlide.setFillAfter(true);
        mIntoSlide.setFillEnabled(true);
        view.startAnimation(mIntoSlide);
    }

    /**
     * 过滤重复点击
     */
    public void dismissDialog() {
        if (isClick) {
            return;
        }
        isClick = true;
        initOutAnimation();
    }

    /**
     * 弹窗弹出屏幕的动画
     */
    private void initOutAnimation() {
        if (mOutSlide != null) {
            mOutSlide.cancel();
        }
        mOutSlide = new TranslateAnimation(
                Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 0.0f,
                Animation.RELATIVE_TO_SELF, 1.0f);
        mOutSlide.setDuration(200);
        mOutSlide.setFillEnabled(true);
        mOutSlide.setFillAfter(true);
        view.startAnimation(mOutSlide);
        /**
         * 弹出屏幕动画的监听
         */
        mOutSlide.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                //过滤重复点击的标记
                isClick = false;
                //销毁弹窗
                DialogTimeNoMinute.this.dismiss();
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });

    }

    /**
     * 拦截手势(弹窗外区域)
     */
    private void touchOutShowDialog() {
        mDecorView.setOnTouchListener(new View.OnTouchListener() {
            public boolean onTouch(View v, MotionEvent event) {
                if (event.getAction() == MotionEvent.ACTION_UP) {
                    //弹框消失的动画执行相关代码
                    dismissDialog();
                }
                return true;
            }
        });
    }

    /**
     * 监听主界面back键
     * 当点击back键时，执行弹窗动画
     */
    private void getFocus() {
        getView().setFocusableInTouchMode(true);
        getView().requestFocus();
        getView().setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View v, int keyCode, KeyEvent event) {
                // 监听到back键(悬浮手势)返回按钮点击事件
                if (event.getAction() == KeyEvent.ACTION_UP && keyCode == KeyEvent.KEYCODE_BACK) {
                    //判断弹窗是否显示
                    if (DialogTimeNoMinute.this.getDialog().isShowing()) {
                        //关闭弹窗
                        dismissDialog();
                        return true;
                    }
                }
                return false;
            }
        });
    }

    /**
     * 选择器选中事件
     */
    private NewPickerScrollView.onSelectListener firstPickerListener = new NewPickerScrollView.onSelectListener() {

        @Override
        public void onSelect(DialogTimeNoMinutePickerData pickers) {
            // Toast.makeText(getContext(),pickers.getShowId(),Toast.LENGTH_SHORT).show();
            if (pickers.getHr() >= 12 && pickers.getHr() != 24 ) {
                isAm = false;
                timeAmBorder.setVisibility(View.INVISIBLE);
                timePmBorder.setVisibility(View.VISIBLE);
                timeAmTv.setTextColor(requireContext().getResources().getColor(R.color.primary));
                timePmTv.setTextColor(getContext().getResources().getColor(R.color.main));
            } else {
                isAm = true;
                timeAmBorder.setVisibility(View.VISIBLE);
                timePmBorder.setVisibility(View.INVISIBLE);
                timeAmTv.setTextColor(requireContext().getResources().getColor(R.color.main));
                timePmTv.setTextColor(getContext().getResources().getColor(R.color.primary));
            }
            selectHr = pickers.getHr();
            selectData = pickers;
        }
    };

//    @OnClick({R.id.time_am_layout, R.id.time_pm_layout})
//    public void clickPmAndAm(View view) {
//        initAmAndPm();
//    }

    private void initAmAndPm() {
        if (isAm) {
            isAm = false;
            timeAmBorder.setVisibility(View.INVISIBLE);
            timePmBorder.setVisibility(View.VISIBLE);
            timeAmTv.setTextColor(getContext().getResources().getColor(R.color.primary));
            timePmTv.setTextColor(getContext().getResources().getColor(R.color.main));


        } else {
            timeAmBorder.setVisibility(View.VISIBLE);
            timePmBorder.setVisibility(View.INVISIBLE);
            timeAmTv.setTextColor(getContext().getResources().getColor(R.color.main));
            timePmTv.setTextColor(getContext().getResources().getColor(R.color.primary));
            isAm = true;
        }
    }



    /**
     * 点击事件
     */
    private View.OnClickListener clickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            if (v == dialogCloseBtn) {
                dismissDialog();
            } else if (v == dialogConfirmBtn) {
                dialogCallback.confirm(selectData);
            } else if (v == pickerDivide  || v == dialogBtnContainer || v == pickerContainer || v == pickerOuter) {
            }
        }

    };
}
