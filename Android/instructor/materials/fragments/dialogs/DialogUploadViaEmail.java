package com.spelist.tunekey.ui.teacher.materials.fragments.dialogs;

import android.annotation.SuppressLint;
import android.content.Context;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.lxj.xpopup.animator.PopupAnimator;
import com.lxj.xpopup.core.CenterPopupView;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.network.UserService;

/**
 * @author zw, Created on 2020/11/27
 */
public class DialogUploadViaEmail extends CenterPopupView {

    private Context context;
    private TextView title;
    private TextView prompt;
    private TextView leftBtn;
    private TextView rightBtn;
    private String userId = UserService.getInstance().getCurrentUserId();

    public DialogUploadViaEmail(@NonNull Context context) {
        super(context);
        this.context = context;
    }

    // 返回自定义弹窗的布局
    @Override
    protected int getImplLayoutId() {
        return R.layout.dialog_upload_from_computer;
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate() {
        super.onCreate();
        title = findViewById(R.id.dialog_title);
        prompt = findViewById(R.id.dialog_prompt);
        leftBtn = findViewById(R.id.dialog_left_btn);
        rightBtn = findViewById(R.id.dialog_right_btn);

        title.setText("Upload from computer");
        prompt.setText("Send your files to support@tunekey.app or upload your files via the link " +
                "( https://tunekey.app/d/upload/" + userId + " ).\n" +
                "We will organize files for you in-app.");

        leftBtn.setOnClickListener(v -> {
            dismiss(); // 关闭弹窗
        });

        rightBtn.setOnClickListener(v -> {
            CloudFunctions
                    .uploadViaEmail()
                    .addOnCompleteListener(task -> {
                        dismiss();
                    });
//            dismiss();
        });
    }

    // 设置最大宽度，看需要而定
    @Override
    protected int getMaxWidth() {
        return super.getMaxWidth();
    }

    // 设置最大高度，看需要而定
    @Override
    protected int getMaxHeight() {
        return super.getMaxHeight();
    }

    // 设置自定义动画器，看需要而定
    @Override
    protected PopupAnimator getPopupAnimator() {
        return super.getPopupAnimator();
    }

    /**
     * 弹窗的宽度，用来动态设定当前弹窗的宽度，受getMaxWidth()限制
     *
     * @return
     */
    protected int getPopupWidth() {
        return 0;
    }

    /**
     * 弹窗的高度，用来动态设定当前弹窗的高度，受getMaxHeight()限制
     *
     * @return
     */
    protected int getPopupHeight() {
        return 0;
    }
}
