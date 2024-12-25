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

import com.spelist.tools.custom.PickerScrollView;
import com.spelist.tools.custom.Pickers;
import com.spelist.tools.custom.easylayout.EasyConstraintLayout;
import com.spelist.tunekey.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class DialogTime extends DialogFragment {

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;//过滤重复点击
    private InputHandler mInputHandler = new InputHandler();
    private boolean flags = false;//判断用户两次输入的时差是否大于500ms的标志 
    private long firstTime;//第一次的时间

//    @BindView(R.id.dialog_double_picker)
//    LinearLayout dialogDoublePicker;
//    @BindView(R.id.picker_container)
//    EasyConstraintLayout pickerContainer;
//    @BindView(R.id.picker_outer)
//    LinearLayout pickerOuter;
//    @BindView(R.id.dialog_btn_container)
//    RelativeLayout dialogBtnContainer;
//    @BindView(R.id.picker_selected_bg)
//    View pickerSelectedBg;
//    @BindView(R.id.first_picker)
//    PickerScrollView firstPicker;
//    @BindView(R.id.second_picker)
//    PickerScrollView secondPicker;
//    @BindView(R.id.dialog_close_btn)
//    TextView dialogCloseBtn;
//    @BindView(R.id.dialog_confirm_btn)
//    TextView dialogConfirmBtn;
//    @BindView(R.id.picker_divide)
//    View pickerDivide;
//
//    @BindView(R.id.time_am_tv)
//    TextView timeAmTv;
//    @BindView(R.id.time_am_border)
//    View timeAmBorder;
//    @BindView(R.id.time_pm_border)
//    View timePmBorder;
//    @BindView(R.id.time_pm_tv)
//    TextView timePmTv;

    private List<Pickers> firstPickerList;
    private String[] firstPickerId;
    private String firstSelected;


    private List<Pickers> secondPickerList;
    private List<String> secondPickerId;
    private String secondSelected;
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
    private PickerScrollView firstPicker;
    private TextView pickerDivide;
    private PickerScrollView secondPicker;
    private RelativeLayout dialogBtnContainer;
    private TextView dialogCloseBtn;
    private TextView dialogConfirmBtn;

    public DialogTime(){}

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
        firstPicker = (PickerScrollView) view.findViewById(R.id.first_picker);
        pickerDivide = (TextView) view.findViewById(R.id.picker_divide);
        secondPicker = (PickerScrollView) view.findViewById(R.id.second_picker);
        dialogBtnContainer = (RelativeLayout) view.findViewById(R.id.dialog_btn_container);
        dialogCloseBtn = (TextView) view.findViewById(R.id.dialog_close_btn);
        dialogConfirmBtn = (TextView) view.findViewById(R.id.dialog_confirm_btn);
    }


    /**
     * 通讯回调接口
     */
    public interface DialogCallback {
        void confirm(String count, String beat, boolean isAm);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_time, container, false);
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

        firstPickerId = new String[]{"1", "2", "3", "4", "5", "6", "7", "8",
                "9", "10", "11", "12", "1", "2", "3", "4", "5",
                "6", "7", "8", "9", "10", "11", "12"};

        firstPickerList = new ArrayList<Pickers>();

        for (int i = 0; i < firstPickerId.length; i++) {
            firstPickerList.add(new Pickers(String.valueOf(firstPickerId[i]), String.valueOf(i)));
        }

//        for (String value : firstPickerId) {
//            firstPickerList.add(new Pickers(String.valueOf(value), String.valueOf(value)));
//           // 如果是第二个1 是下午 选择PM
//        }

        // 设置数据，默认选择
        firstPicker.setData(firstPickerList);
        firstPicker.setSelected(0);
        firstSelected = firstPickerId[0];

        secondPickerList = new ArrayList<Pickers>();
        secondPickerId = new ArrayList<>();
        for (int i = 0; i < 60; i++) {
//            if (i<10){
//                secondPickerId.add("0"+i);
//            }else {
            secondPickerId.add(i + "");
//            }
        }

        for (String value : secondPickerId) {
            secondPickerList.add(new Pickers(value, value));
        }

        secondPicker.setData(secondPickerList);
        secondPicker.setSelected(0);
        secondSelected = secondPickerId.get(0);
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
        secondPicker.setOnSelectListener(secondPickerListener);
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
                DialogTime.this.dismiss();
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
                    if (DialogTime.this.getDialog().isShowing()) {
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
    private PickerScrollView.onSelectListener firstPickerListener = new PickerScrollView.onSelectListener() {

        @Override
        public void onSelect(Pickers pickers) {
            // Toast.makeText(getContext(),pickers.getShowId(),Toast.LENGTH_SHORT).show();

            if (Integer.parseInt(pickers.getShowId()) >= 12) {
                isAm = false;
                timeAmBorder.setVisibility(View.INVISIBLE);
                timePmBorder.setVisibility(View.VISIBLE);
                timeAmTv.setTextColor(Objects.requireNonNull(getContext()).getResources().getColor(R.color.primary));
                timePmTv.setTextColor(getContext().getResources().getColor(R.color.main));
            } else {
                isAm = true;
                timeAmBorder.setVisibility(View.VISIBLE);
                timePmBorder.setVisibility(View.INVISIBLE);
                timeAmTv.setTextColor(Objects.requireNonNull(getContext()).getResources().getColor(R.color.main));
                timePmTv.setTextColor(getContext().getResources().getColor(R.color.primary));
            }

            firstSelected = pickers.getShowConetnt();
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

    private PickerScrollView.onSelectListener secondPickerListener = new PickerScrollView.onSelectListener() {
        @Override
        public void onSelect(Pickers pickers) {
//            Toast.makeText(getContext(),pickers.getShowConetnt(),Toast.LENGTH_SHORT).show();
            secondSelected = pickers.getShowConetnt();
        }
    };

    /**
     * 点击事件
     */
    private View.OnClickListener clickListener = new View.OnClickListener() {

        @Override
        public void onClick(View v) {
            if (v == dialogCloseBtn) {
                dismissDialog();
            } else if (v == dialogConfirmBtn) {
                dialogCallback.confirm(firstSelected, secondSelected, isAm);
            } else if (v == pickerDivide  || v == dialogBtnContainer || v == pickerContainer || v == pickerOuter) {
            }
        }

    };
}
