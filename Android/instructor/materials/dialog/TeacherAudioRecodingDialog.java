package com.spelist.tunekey.ui.teacher.materials.dialog;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.util.Log;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;

import com.lxj.xpopup.core.BottomPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.databinding.DialogRecordPracticeBinding;
import com.spelist.tunekey.ui.teacher.materials.host.TeacherRecordHost;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.RecorderUtils;
import com.spelist.tunekey.utils.SLTools;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import me.jessyan.autosize.utils.AutoSizeUtils;


/**
 * com.spelist.tunekey.ui.sPractice.dialogs
 * 2021/4/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
@SuppressLint("ViewConstructor")
public class TeacherAudioRecodingDialog extends BottomPopupView {
    private DialogRecordPracticeBinding binding;
    private RecorderUtils recorderUtils = new RecorderUtils();
    // 开始录音 但是没有声音的 1秒钟10个 结束录音后自动剪裁
    private List<Double> beforeRecordingVolumeList = new ArrayList<>();
    private List<Double> volumeList = new ArrayList<>();

    private List<RecordPracticeDialog.TKAudioModule> audios = new ArrayList<>();
    private boolean isFirstRecording = true;
    private boolean isNeedStartRecoding = false;
    public RecordPracticeDialog.TKAudioModule cutAudio;
    public RecordPracticeDialog.TKAudioModule cutBeforeAudio;
    public RecordPracticeDialog.TKAudioModule margeAudio;
    public RecordPracticeDialog.TKAudioModule margeBeforeAudio;
    public RecordPracticeDialog.TKAudioModule margeAfterAudio;
    public int nameDef = 1;

    // 0正常,1剪裁,2合并
    public int status = 0;

    private RecordListener mRecordListener;


    public interface RecordListener {
        //0添加log,1更新log
        void onRecordDone(RecordPracticeDialog.TKAudioModule uploadData,String name);
    }

    public void setOnRecordListener(RecordListener recordListener) {
        this.mRecordListener = recordListener;

    }

    public TeacherAudioRecodingDialog(@NonNull Context context,int nameDef) {
        super(context);
        this.nameDef = nameDef;

    }


    protected int getImplLayoutId() {
        return R.layout.dialog_record_practice;
    }

    @Override
    protected void onCreate() {
        super.onCreate();

        binding = DataBindingUtil.bind(getPopupImplView());

        if (binding == null) {
            return;
        }
        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/record.audio.html");
        FuncUtils.closeHardwareAccelerated(binding.webView);
        TeacherRecordHost webHost = new TeacherRecordHost(this);
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                binding.webView.evaluateJavascript("adaptIOS12()", s -> {
                });

                binding.webView.evaluateJavascript("setDefaultTitle('Audio " + nameDef + "')", s -> {
                });
            }
        });


        recorderUtils.setOnMicStatusListener(db -> {


            if (db <= 45 && db > 13) {
                db = 12 + Math.random() * 13 % (13 - 12 + 1);
                ;
            }
            if (db >= 75) {
                db = 90 + Math.random() * 92 % (92 - 90 + 1);
                ;
            }
            double a = db;
            db = db * 0.01 * 0.6;
            Log.e("TAG", "处理前:" + a + "==处理后:" + db);
            if (isNeedStartRecoding) {
                binding.webView.evaluateJavascript("updateDB('" + db + "')", s -> {
                });
                if (volumeList.size() > 49) {
                    volumeList.remove(0);
                }
                volumeList.add(db);
                if (volumeList.size() >= 50) {
                    if (volumeList.stream().filter(aDouble -> aDouble > 0.1).count() > 0) {
                    } else {
                        Logger.e("======%s", "5秒钟内声音都小于0.1");
                        stop(true);
                    }
                }
            } else {
                beforeRecordingVolumeList.add(db);
                if (db >= 0.14 || !isFirstRecording) {
                    isNeedStartRecoding = true;
                    Logger.e("======%s", "开始录音");

                    binding.webView.evaluateJavascript("listenStartRecord()", s -> {
                    });
                }
            }
        });

    }

    public void stop(boolean isAutoPlay) {
        recorderUtils.stopRecord();
        isFirstRecording = false;
        isNeedStartRecoding = false;
        Logger.e("======没有声音的个数:%s, 总时长:%s", beforeRecordingVolumeList.size(), recorderUtils.totalTime);

        if (beforeRecordingVolumeList.size() > 15) {
            String recordId = IDUtils.getId();
            File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
            File localFile = new File(storagePath, recordId + ".aac");
            try {
                RecorderUtils.clip(recorderUtils.getPath(), localFile.getPath(), beforeRecordingVolumeList.size() * 100, recorderUtils.totalTime);
                String base64 = FuncUtils.fileToBase64(localFile);
                base64 = "data:audio/" + "aac" + ";base64," + base64;
                audios.get(audios.size() - 1).setId(recordId);
                audios.get(audios.size() - 1).setBase64(base64);
                audios.get(audios.size() - 1).setAudioPath(localFile.getPath());
                binding.webView.evaluateJavascript("listenStopRecord('" + SLJsonUtils.toJsonString(base64) + "','" + audios.get(audios.size() - 1).getId() + "','" + isAutoPlay + "')", s -> {
                });
                volumeList.clear();
            } catch (IOException e) {
                Logger.e("=====clip失败=%s", e.getMessage());
                e.printStackTrace();
            }


        } else {
            initStopRecording(isAutoPlay);
        }
    }

    private void initStopRecording(boolean isAutoPlay) {
        volumeList.clear();
        File file = new File(recorderUtils.getPath());
        String base64 = FuncUtils.fileToBase64(file);
        base64 = "data:audio/" + "aac" + ";base64," + base64;
        String id = audios.get(audios.size() - 1).getId();
        audios.get(audios.size() - 1).setBase64(base64);
        if (audios.size() == 2) {
            continueToMergeAudio();
            return;
        }
        binding.webView.evaluateJavascript("listenStopRecord('" + SLJsonUtils.toJsonString(base64) + "','" + id + "','" + isAutoPlay + "')", s -> {
        });
//        File storagePath = new File(Environment.getExternalStorageDirectory(), "tunekeyPractice");
//        File localFile = new File(storagePath, "hh.aac");
//        File bbb = new File(storagePath, "jnj.aac");
//        List<String> a = new ArrayList<>();
//        a.add(recorderUtils.getPath());
//        a.add(recorderUtils.getPath());
//        try {
//            RecorderUtils.heBingMP3(a,localFile.getPath(),true);
//            boolean clip = RecorderUtils.clip(recorderUtils.getPath(), bbb.getPath(), 0, 15);
//            Logger.e("======%s",clip );
//        } catch (IOException e) {
//            Logger.e("剪裁失败:%s",e.getMessage() );
//            e.printStackTrace();
//        }

    }

    // 继续后合并音频
    private void continueToMergeAudio() {
        String id = IDUtils.getId();
        String beforePath = audios.get(0).getAudioPath();
        String afterPath = audios.get(1).getAudioPath();
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, id + ".aac");
        List<String> a = new ArrayList<>();
        a.add(beforePath);
        a.add(afterPath);
        try {
            RecorderUtils.heBingMP3(a, localFile.getPath(), true);
            String base64 = FuncUtils.fileToBase64(localFile);
            base64 = "data:audio/" + "aac" + ";base64," + base64;

            audios.clear();
            audios.add(new RecordPracticeDialog.TKAudioModule(id, localFile.getPath(), 0, "", base64, true));
            Logger.e("======%s", id);
            binding.webView.evaluateJavascript("listenStopRecord('" + SLJsonUtils.toJsonString(base64) + "','" + id + "','" + true + "')", s -> {
            });
            status = 2;
        } catch (IOException e) {
            Logger.e("=====合并失败=%s", e.getMessage());
            e.printStackTrace();
        }

    }

    /**
     * 剪裁录音
     */
    public void cutInLocal(RecordPracticeDialog.TKAudioOperating.StepBean data, double duration) {
        int index = 0;
        for (int i = 0; i < audios.size(); i++) {
            if (data.getId().equals(audios.get(i).getId())) {
                index = i;
            }
        }
        audios.get(index)
                .setDuration(data.getTotal() + "")
                .setIndex(data.getIndex())
                .setUpload(data.isUpload);
        cutBeforeAudio = audios.get(index);
        String id = IDUtils.getId();
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, id + ".aac");
        try {
            boolean clip = RecorderUtils.clip(audios.get(index).getAudioPath(), localFile.getPath(), data.start * 1000, data.end * 1000);
            String base64 = FuncUtils.fileToBase64(localFile);
            base64 = "data:audio/" + "aac" + ";base64," + base64;
            Logger.e("======%s", id);
            cutAudio = new RecordPracticeDialog.TKAudioModule(id, localFile.getPath(), data.getIndex(), duration + "", base64, data.isUpload);
            binding.webView.evaluateJavascript("updatePieces('" + data.getIndex() + "','" + id + "','" + SLJsonUtils.toJsonString(base64) + "','" + duration + "')", s -> {
            });
            status = 1;

        } catch (IOException e) {
            Logger.e("=====clip失败=%s", e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 合并
     *
     * @param data
     * @param duration
     */
    public void mergeInLocal(RecordPracticeDialog.TKAudioOperating.StepBean data, double duration) {
        String id = IDUtils.getId();
        int beforeIndex = 0;
        int afterIndex = 0;
        String beforePath = "";
        String afterPath = "";
        for (int i = 0; i < audios.size(); i++) {
            if (data.getBeforeId().equals(audios.get(i).getId())) {
                beforeIndex = i;
                beforePath = audios.get(i).getAudioPath();
            }
            if (data.getAfterId().equals(audios.get(i).getId())) {
                afterIndex = i;
                afterPath = audios.get(i).getAudioPath();
            }
        }
        audios.get(beforeIndex).setDuration(data.getBeforeDuration());
        audios.get(beforeIndex).setIndex(data.getBeforeIndex());
        audios.get(beforeIndex).setUpload(data.isBeforeIsUpload());
        margeBeforeAudio = audios.get(beforeIndex);

        audios.get(afterIndex).setDuration(data.getAfterDuration());
        audios.get(afterIndex).setIndex(data.getAfterIndex());
        audios.get(afterIndex).setUpload(data.isAfterIsUpload());
        margeAfterAudio = audios.get(afterIndex);

        List<String> a = new ArrayList<>();
        a.add(beforePath);
        a.add(afterPath);
        File storagePath = SLTools.getFile(TApplication.getInstance().getApplicationContext(), "tunekeyPractice");
        File localFile = new File(storagePath, id + ".aac");
        try {
            RecorderUtils.heBingMP3(a, localFile.getPath(), true);
            String base64 = FuncUtils.fileToBase64(localFile);
            base64 = "data:audio/" + "aac" + ";base64," + base64;
            margeAudio = new RecordPracticeDialog.TKAudioModule(id, localFile.getPath(), data.getBeforeIndex(), duration + "", base64, data.isUpload);
            binding.webView.evaluateJavascript("updatePieces('" + data.getIndex() + "','" + id + "','" + SLJsonUtils.toJsonString(base64) + "','" + duration + "')", s -> {
            });
            status = 2;
        } catch (IOException e) {
            Logger.e("=====合并失败=%s", e.getMessage());
            e.printStackTrace();
        }

    }


    /**
     * 保存裁剪或合并
     */
    public void saveCutOrMerge() {
        if (status == 1) {
            Logger.e("点击保存剪裁==>");
            audios.clear();
            audios.add(cutAudio);
            cutAudio = null;
            cutBeforeAudio = null;
        } else if (status == 2) {
            RecordPracticeDialog.TKAudioModule element = CloneObjectUtils.cloneObject(margeAudio);
            audios.add(margeBeforeAudio.getIndex(), margeAudio);


            for (int i = audios.size() - 1; i >= 0; i--) {

                if (audios.get(i).getId().equals(margeAfterAudio.getId())) {
                    audios.remove(i);
                    continue;
                }
                if (audios.get(i).getId().equals(margeBeforeAudio.getId())) {
                    audios.remove(i);
                    continue;
                }
            }
            margeAudio = null;
            margeAfterAudio = null;
            margeBeforeAudio = null;

        }
        status = 0;
    }

    /**
     * 取消裁剪或合并
     */
    public void cancelCutOrMerge() {
        RecordPracticeDialog.TKCutOrMergeModule param = new RecordPracticeDialog.TKCutOrMergeModule();
        Logger.e("======%s", status);
        if (status == 1) {
            Logger.e("点击取消剪裁==>" + cutBeforeAudio.getId());
            param.setType(0)
                    .setId(cutBeforeAudio.getId())
                    .setDuration(cutBeforeAudio.getDuration());

            binding.webView.evaluateJavascript("cancelCutOrMerge('" + SLJsonUtils.toJsonString(param) + "','" + SLJsonUtils.toJsonString(cutBeforeAudio.getBase64()) + "','" + "')", s -> {
            });
            cutAudio = null;
            cutBeforeAudio = null;

        } else if (status == 2) {
            param.setType(1)
                    .setBeforeIndex(margeBeforeAudio.getIndex() + "")
                    .setBeforeId(margeBeforeAudio.getId())
                    .setBeforeDuration(margeBeforeAudio.duration)
                    .setBeforeIsUpload(margeBeforeAudio.isUpload())
                    .setAfterIndex(margeAfterAudio.getIndex() + "")
                    .setAfterId(margeAfterAudio.getId())
                    .setAfterDuration(margeAfterAudio.getDuration())
                    .setAfterIsUpload(margeAfterAudio.isUpload());
            binding.webView.evaluateJavascript("cancelCutOrMerge('" + SLJsonUtils.toJsonString(param) + "','" + SLJsonUtils.toJsonString(margeBeforeAudio.getBase64()) + "','" + SLJsonUtils.toJsonString(margeAfterAudio.getBase64()) + "')", s -> {
            });
            margeAudio = null;
            margeAfterAudio = null;
            margeBeforeAudio = null;
        }
        status = 0;
    }


    /**
     * 显示取消上传弹窗
     */
    public void showUnUploadPop() {
        SLDialogUtils.showOneButton(getContext(), "Uploaded", "This upload has been removed", "OK");

    }

    /**
     * 显示上传弹窗
     */
    public void showUploadPop() {
        SLDialogUtils.showOneButton(getContext(), "Uploaded", "Your recording has been uploaded and shared with your instructor.\nTap again to remove upload. Uploaded recordings can be found under \"Practice\" > \"Log\".", "OK");

    }

    /**
     * 结束录音
     *
     * @param data
     * @param logId
     */
    public void recordDone(List<RecordPracticeDialog.TKAudioModule> data, String logId) {
        //关闭播放

        double totalTime = 0;
        List<RecordPracticeDialog.UploadRecode> uploadRecodes = new ArrayList<>();
        for (RecordPracticeDialog.TKAudioModule item : data) {
            double duration = 0;
            try {
                duration = Double.parseDouble(item.getDuration());
            } catch (Throwable e) {

            }
            if (item.isUpload) {
                RecordPracticeDialog.UploadRecode uploadRecode = new RecordPracticeDialog.UploadRecode();
                for (RecordPracticeDialog.TKAudioModule audio : audios) {
                    if (audio.getId().equals(item.getId())) {
                        uploadRecode.setPath(audio.getAudioPath());
                    }
                }
                uploadRecode.setId(item.getId());

                Logger.e("======%s", item.getDuration());
                uploadRecode.setDuration(duration);
                uploadRecodes.add(uploadRecode);

            }
            totalTime += duration;
        }

        String time = String.format("%.1f", totalTime / 60d);
        String message = "You have completed " + time + " minutes of practice.\nContinue recording?";
        Dialog aContinue = SLDialogUtils.showTwoButton(getContext(), "Good work!", message, "Continue", "I'm done");
        aContinue.findViewById(R.id.left_button).setOnClickListener(v -> {
            aContinue.dismiss();
            binding.webView.evaluateJavascript("continueRecordFromNative()", s -> {
            });

        });
        double finalTotalTime = totalTime;
        aContinue.findViewById(R.id.right_button).setOnClickListener(v -> {
            aContinue.dismiss();
            binding.webView.evaluateJavascript("pauseRecordFromNative()", s -> {
            });

            dismiss();
        });
    }

    //结束录音
    public void stopRecordAudio() {
        ViewGroup.LayoutParams lp;
        lp = binding.mainLayout.getLayoutParams();
        lp.height = AutoSizeUtils.pt2px(getContext(), 360);
        binding.mainLayout.setLayoutParams(lp);

    }

    public void goBack() {
        ViewGroup.LayoutParams lp;
        lp = binding.mainLayout.getLayoutParams();
        lp.height = AutoSizeUtils.pt2px(getContext(), 300);
        binding.mainLayout.setLayoutParams(lp);
    }

    public void closePractice() {
        if (recorderUtils != null) {
            recorderUtils.stopRecord();
        }
        dismiss();
    }

    public void uploadAudio(String title) {

        RecordPracticeDialog.TKAudioModule tkAudioModule = audios.get(0);
        String audioPath = tkAudioModule.getAudioPath();
        if (mRecordListener != null) {
            mRecordListener.onRecordDone(tkAudioModule, title);
        }

        dismiss();
    }

    public void recording() {
        String id = IDUtils.getId();
        recorderUtils.startRecord(id,false);
        beforeRecordingVolumeList.clear();
        audios.add(new RecordPracticeDialog.TKAudioModule(id, recorderUtils.getPath(), audios.size(), "", "", false));
    }


}
