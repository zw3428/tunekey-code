package com.spelist.tunekey.ui.teacher.materials.dialog;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.content.Context;
import android.os.Handler;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;
import androidx.fragment.app.FragmentActivity;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.lxj.xpopup.core.BottomPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.widget.OnRangeChangedListener;
import com.spelist.tools.custom.widget.RangeSeekBar;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.databinding.DialogPlayPracticeBinding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.teacher.materials.host.PlayAudioHost;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLTools;

import java.io.File;
import java.io.Serializable;
import java.util.List;

/**
 * com.spelist.tunekey.ui.sPractice.dialogs
 * 2021/4/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PlayAudioDialog extends BottomPopupView {
    private DialogPlayPracticeBinding binding;
    private ClickListener mClickListener;
    private MaterialEntity data;
    private FragmentActivity activity;
    private float speed = 1.0f;

    public void showSpeed() {
        // 主线程把 binding.speedLayout设置显示
        Logger.e("==>%s","准备显示");
        activity.runOnUiThread(() -> {
            if (binding.speedLayout.getVisibility() == View.VISIBLE) {
                goneSpeedLayout();
                return;
            }
            // 获取视图的高度
            final int height = binding.speedLayout.getHeight();

            // 设置视图的位置在底部
            binding.speedLayout.setTranslationY(height);

            // 移除全局布局监听器
//            binding.speedLayout.getViewTreeObserver().removeOnGlobalLayoutListener(this);

            // 设置视图为可见
            binding.speedLayout.setVisibility(View.VISIBLE);

            // 创建一个属性动画，将 translationY 属性从 height 改变到 0
            ObjectAnimator animator = ObjectAnimator.ofFloat(binding.speedLayout, "translationY", height, 0f);

            // 设置动画时长
            animator.setDuration(300);

            // 开始动画
            animator.start();
        });
    }

    public interface ClickListener {
        //0添加log,1更新log
        void onCloseClick(List<String> deleteId);
    }

    public void setOnClickCloseListener(ClickListener clickListener) {
        this.mClickListener = clickListener;

    }

    public PlayAudioDialog(@NonNull Context context, FragmentActivity activity, MaterialEntity data) {
        super(context);
        this.activity = activity;
        this.data = data;
        initData();
    }

    private void initData() {

    }

    protected int getImplLayoutId() {
        return R.layout.dialog_play_practice;
    }

    @Override
    protected void onCreate() {
        super.onCreate();
        binding = DataBindingUtil.bind(getPopupImplView());
        if (binding == null) {
            return;
        }
        binding.rangeSeekBar.setIndicatorTextDecimalFormat("0%");
        binding.rangeSeekBar.setOnRangeChangedListener(new OnRangeChangedListener() {
            @Override
            public void onRangeChanged(RangeSeekBar view, float leftValue, float rightValue, boolean isFromUser) {
                float roundedNum = Math.round(leftValue * 100) / 100f;
                Logger.e("fff==>%s>%s", leftValue, roundedNum);
                binding.webView.evaluateJavascript("setSpeed(" + roundedNum + ")", s -> {
                    Logger.e("======%s", s);
                });
            }

            @Override
            public void onStartTrackingTouch(RangeSeekBar view, boolean isLeft) {

            }

            @Override
            public void onStopTrackingTouch(RangeSeekBar view, boolean isLeft) {
                new Handler().postDelayed(() -> {
                    goneSpeedLayout();
                }, 1000);
            }

        });
        binding.rangeSeekBar.setProgress(1);


        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/teacher.play.audio.html");
        FuncUtils.closeHardwareAccelerated(binding.webView);
        PlayAudioHost webHost = new PlayAudioHost(this);
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
//                Logger.e("======%s", isDelete);
//                binding.webView.evaluateJavascript("initPlayList('" + SLJsonUtils.toJsonString(audioDatas) + "','" + practice.getName() + "'," + isDelete + ")", s -> {
//                });

                download();

            }
        });
    }
    private void goneSpeedLayout() {
        // 获取视图的高度
        int height = binding.speedLayout.getHeight();

        // 创建一个属性动画，将 translationY 属性从 0 改变到 height
        ObjectAnimator animator = ObjectAnimator.ofFloat(binding.speedLayout, "translationY", 0f, height);

        // 设置动画时长
        animator.setDuration(300);

        // 开始动画
        animator.start();

        // 设置动画结束的监听
        animator.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                super.onAnimationEnd(animation);
                // 动画结束后，隐藏视图
                binding.speedLayout.setVisibility(View.GONE);
            }
        });
    }


    public void close() {

        binding.webView.evaluateJavascript("pausePlay()", s -> {
            Logger.e("======%s", s);
        });
        dismiss();
    }

    /**
     * 点击播放
     */
    public void download() {


        Logger.e("======%s", data.getStoragePatch());
        if (data.getStoragePatch().equals("")) {
            return;
        }
        StorageReference ref = FirebaseStorage.getInstance().getReference().child(data.getStoragePatch());
        boolean isHaveCache = false;
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, data.getId() + "." + data.getSuffixName());
        if (storagePath.exists()) {
            if (localFile.exists()) {
                isHaveCache = true;
            }
        }
        Logger.e("======%s", localFile.getPath());
        if (isHaveCache) {
            Logger.e("===文件存在");

            binding.webView.evaluateJavascript("percentFromLocal('" + 100 + "')", s -> {
            });
            String base64 = FuncUtils.fileToBase64(localFile);
            String format = "x-m4a";
            if (data.getSuffixName().equals(".aac") || data.getSuffixName().equals("aac")) {
                format = "aac";
            }
            base64 = "data:audio/" + format + ";base64," + base64;
            Logger.e("======成功%s", localFile.getPath());
            binding.webView.evaluateJavascript("playBase64Audio('" + SLJsonUtils.toJsonString(base64) + "','" + SLJsonUtils.toJsonString(data.getName().replaceAll("\\\\", "\\\\\\\\").replaceAll("\"", "”").replaceAll("'", "”")) + "')", s -> {
                Logger.e("======%s", s);
            });

        } else {

            if (!storagePath.exists()) {
                storagePath.mkdirs();
            }
            Logger.e("===文件不存在开始下载===%s", "===");
            ref.getFile(localFile).addOnProgressListener(snapshot -> {
                long totalByteCount = snapshot.getTotalByteCount();
                long bytesTransferred = snapshot.getBytesTransferred();
                if (totalByteCount > 0) {
                    double progress = (100.0 * bytesTransferred) / totalByteCount;
                    binding.webView.evaluateJavascript("percentFromLocal('" + (int) progress + "')", s -> {
                    });
                }
            }).addOnSuccessListener(taskSnapshot -> {
                // Local temp file has been created

                String base64 = FuncUtils.fileToBase64(localFile);
                String format = "x-m4a";
                if (data.getSuffixName().equals(".aac") || data.getSuffixName().equals("aac")) {
                    format = "aac";
                }
                base64 = "data:audio/" + format + ";base64," + base64;
//                Logger.e("======成功%s", base64);
                binding.webView.evaluateJavascript("playBase64Audio('" + SLJsonUtils.toJsonString(base64) + "','" + SLJsonUtils.toJsonString(data.getName()) + "')", s -> {
                    Logger.e("======%s", s);
                });
            }).addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception exception) {
                    // Handle any errors
                    Logger.e("======失败" + exception.getMessage());
                }
            });

        }
    }


    public static class AudioModel implements Serializable {
        private double duration;
        private long time;
        private boolean isDelete;
        private String id = "";

        public double getDuration() {
            return duration;
        }

        public AudioModel setDuration(double duration) {
            this.duration = duration;
            return this;
        }

        public long getTime() {
            return time;
        }

        public AudioModel setTime(long time) {
            this.time = time;
            return this;
        }

        public boolean isDelete() {
            return isDelete;
        }

        public AudioModel setDelete(boolean delete) {
            isDelete = delete;
            return this;
        }

        public String getId() {
            return id;
        }

        public AudioModel setId(String id) {
            this.id = id;
            return this;
        }
    }
}
