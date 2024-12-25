package com.spelist.tunekey.ui.teacher.insights.dialog;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import com.spelist.tools.custom.PickerScrollView;
import com.spelist.tools.custom.Pickers;
import com.spelist.tools.custom.easylayout.EasyConstraintLayout;
import com.spelist.tunekey.R;
import com.spelist.tunekey.utils.FuncUtils;

import java.util.ArrayList;
import java.util.List;

public class DialogSelectPeriod extends DialogFragment {

    private View view;
    private View mDecorView;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    public DialogCallback dialogCallback;
    private boolean isClick = false;

//    @BindView(R.id.dialog_single_picker)
//    LinearLayout dialogSinglePicker;
//    @BindView(R.id.picker_container)
//    EasyConstraintLayout pickerContainer;
//    @BindView(R.id.picker_outer)®
//    LinearLayout pickerOuter;
//    @BindView(R.id.dialog_btn_container)
//    RelativeLayout dialogBtnContainer;
//    @BindView(R.id.picker_selected_bg)
//    View pickerSelectedBg;
//    @BindView(R.id.first_picker)
//    PickerScrollView picker;
//    @BindView(R.id.dialog_close_btn)
//    TextView dialogCloseBtn;
//    @BindView(R.id.dialog_confirm_btn)
//    TextView dialogConfirmBtn;
//    @BindView(R.id.title)
//    TextView title;

    private List<Pickers> pickerList;
    private int[] pickerId;
    private String pickerSelected;
    private LinearLayout pickerOuter;
    private TextView title;
    private EasyConstraintLayout pickerContainer;
    private View pickerSelectedBg;
    private PickerScrollView picker;
    private TextView dialogCloseBtn;
    private TextView dialogConfirmBtn;
    public  DialogSelectPeriod(){

    }

    private void initView() {
        pickerOuter = (LinearLayout) view.findViewById(R.id.picker_outer);
        title = (TextView) view.findViewById(R.id.title_tv);
        pickerContainer = (EasyConstraintLayout) view.findViewById(R.id.picker_container);
        pickerSelectedBg = (View) view.findViewById(R.id.picker_selected_bg);
        picker = (PickerScrollView) view.findViewById(R.id.first_picker);
        dialogCloseBtn = (TextView) view.findViewById(R.id.dialog_close_btn);
        dialogConfirmBtn = (TextView) view.findViewById(R.id.dialog_confirm_btn);
    }

    public interface DialogCallback {
        void confirm(String period);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        view = inflater.inflate(R.layout.dialog_select_period, container, false);
        initView();
        initDialogView();
        initPickerViewData();
        return view;
    }

    private void initPickerViewData() {
        title.setText("Set target lesson hours");
        title.setVisibility(View.VISIBLE);

        pickerList = new ArrayList<>();
        pickerId = new int[]{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
        for (int value : pickerId) {
            int v = value * 5;
            pickerList.add(new Pickers(v + " hrs", v + " hrs"));
        }
        picker.setData(pickerList);
        picker.setSelected(5);

        pickerSelected = "30";
    }

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
                if (DialogSelectPeriod.this.getDialog().isShowing()) {
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
                //弹框消失的动画执行相关代码
                dismissDialog();
            }
            return true;
        });
    }

    private void initListener() {
        picker.setOnSelectListener(pickerListener);
        dialogConfirmBtn.setOnClickListener(clickListener);
        dialogCloseBtn.setOnClickListener(clickListener);

        pickerContainer.setOnClickListener(clickListener);
        pickerOuter.setOnClickListener(clickListener);
        pickerSelectedBg.setOnClickListener(clickListener);
    }

    private PickerScrollView.onSelectListener pickerListener = pickers -> {
        pickerSelected = pickers.getShowConetnt();
    };

    private View.OnClickListener clickListener = v -> {
        if (v == dialogCloseBtn) {
            dismissDialog();
        } else if (v == dialogConfirmBtn) {
            dialogCallback.confirm(pickerSelected);
        } else if (v == pickerContainer || v == pickerOuter ) {
        }
    };

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
                //过滤重复点击的标记
                isClick = false;
                //销毁弹窗
                DialogSelectPeriod.this.dismiss();
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        });
    }
}
