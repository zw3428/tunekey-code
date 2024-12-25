package com.spelist.tunekey.ui.student.sPractice.dialogs;

import android.content.Context;
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
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.databinding.DialogPlayPracticeBinding;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.ui.student.sPractice.host.PlayPracticeHost;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLTools;

import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

/**
 * com.spelist.tunekey.ui.sPractice.dialogs
 * 2021/4/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PlayPracticeDialog extends BottomPopupView {
    private TKPractice practice;
    private List<AudioModel> audioDatas;
    private boolean isDelete;
    private DialogPlayPracticeBinding binding;
    private ClickListener mClickListener;
    private FragmentActivity activity;


    public interface ClickListener {
        void onCloseClick(List<String> deleteId);
    }

    public void setOnClickCloseListener(ClickListener clickListener) {
        this.mClickListener = clickListener;

    }

    public PlayPracticeDialog(@NonNull Context context, TKPractice practice, boolean isDelete) {
        super(context);
        this.practice = practice;
        this.isDelete = isDelete;
        initData();
    }

    private void initData() {
        audioDatas = new ArrayList<>();
        for (TKPractice.PracticeRecord item : practice.getRecordData()) {
            AudioModel audioModel = new AudioModel();
            audioModel.setId(item.getId());
            audioModel.setDuration(item.getDuration());
            audioModel.setTime(item.getStartTime() * 1000L);
            if (audioModel.getTime() == 0) {
                audioModel.time = Long.parseLong(practice.getCreateTime()) * 1000L;
            }
            if (audioModel.getDuration() == 0) {
                audioModel.setDuration(90.0);
            }
            audioDatas.add(audioModel);
        }
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
        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/play.audio.html");
        FuncUtils.closeHardwareAccelerated(binding.webView);
        PlayPracticeHost webHost = new PlayPracticeHost(this);
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                Logger.e("======%s", isDelete);
                binding.webView.evaluateJavascript("initPlayList('" + SLJsonUtils.toJsonString(audioDatas) + "','" + practice.getName() + "'," + isDelete + ")", s -> {
                });
            }
        });
    }

    public void close(List<String> deleteIds) {
        Logger.e("======%s", deleteIds);
        if (mClickListener != null) {
            mClickListener.onCloseClick(deleteIds);
        }
        binding.webView.evaluateJavascript("pausePlay()", s -> {
            Logger.e("======%s", s);
        });
        dismiss();
    }

    /**
     * 点击播放
     *
     * @param id
     */
    public void download(String id) throws IOException {
        TKPractice.PracticeRecord data = null;
        for (TKPractice.PracticeRecord recordDatum : practice.getRecordData()) {
            if (recordDatum.getId().equals(id)) {
                data = recordDatum;
            }
        }
        if (data == null) {
            return;
        }
        StorageReference ref = FirebaseStorage.getInstance().getReference().child("/practice/" + data.getId() + data.getFormat());
        boolean isHaveCache = false;
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, data.getId()+data.getFormat());
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
            if (data.getFormat().equals(".aac")) {
                format = "aac";
            }
            base64 = "data:audio/" + format + ";base64," + base64;
            Logger.e("======成功%s", localFile.getPath());
            binding.webView.evaluateJavascript("playBase64Audio('" + SLJsonUtils.toJsonString(base64) + "')", s -> {
                Logger.e("======%s", s);
            });

        } else {
//            File storagePath = new File(Environment.getExternalStorageDirectory(), "tunekeyPractice");

            if (!storagePath.exists()) {
                storagePath.mkdirs();
            }
            Logger.e("===文件不存在开始下载===%s", "===");
            TKPractice.PracticeRecord finalData = data;
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
                if (finalData.getFormat().equals(".aac")) {
                    format = "aac";
                }
                base64 = "data:audio/" + format + ";base64," + base64;
                binding.webView.evaluateJavascript("playBase64Audio('" + SLJsonUtils.toJsonString(base64) + "')", s -> {
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
