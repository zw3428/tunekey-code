package com.spelist.tunekey.ui.student.sPractice.dialogs;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.util.Log;
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
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.ui.student.sPractice.host.RecordPracticeHost;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.RecorderUtils;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.TimeUtils;

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
@SuppressLint("ViewConstructor")
public class RecordPracticeDialog extends BottomPopupView {
    private List<TKPractice> practice;
    private DialogRecordPracticeBinding binding;
    private List<TKWebPractice> practiceListData = new ArrayList<>();
    private RecorderUtils recorderUtils = new RecorderUtils();
    // 开始录音 但是没有声音的 1秒钟10个 结束录音后自动剪裁
    private List<Double> beforeRecordingVolumeList = new ArrayList<>();
    private List<Double> volumeList = new ArrayList<>();

    private List<TKAudioModule> audios = new ArrayList<>();
    private boolean isFirstRecording = true;
    private boolean isNeedStartRecoding = false;
    public TKAudioModule cutAudio;
    public TKAudioModule cutBeforeAudio;
    public TKAudioModule margeAudio;
    public TKAudioModule margeBeforeAudio;
    public TKAudioModule margeAfterAudio;

    // 0正常,1剪裁,2合并
    public int status = 0;

    private RecordListener mRecordListener;

    public interface RecordListener {
        //0添加log,1更新log
        void onRecordDone(List<UploadRecode> uploadData, double totalTime, String logId);
    }

    public void setOnRecordListener(RecordListener recordListener) {
        this.mRecordListener = recordListener;

    }

    public RecordPracticeDialog(@NonNull Context context, List<TKPractice> practice) {
        super(context);
        this.practice = practice;

        initData();
    }

    private void initData() {
        for (TKPractice tkPractice : practice) {
            TKWebPractice tkWebPractice = new TKWebPractice();
            tkWebPractice.setId(tkPractice.getId());
//            tkWebPractice.setName(tkPractice.getName());
            String name = tkPractice.getName();
            tkWebPractice.setName(name.replaceAll("\\\\","\\\\\\\\").replaceAll("\"", "”").replaceAll("'", "”"));
            tkWebPractice.setSelected(tkPractice.isSelect());
            practiceListData.add(tkWebPractice);
        }
        Logger.e("practiceListData%s", practiceListData.size());
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
        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/practice.record.v2.html");
        FuncUtils.closeHardwareAccelerated(binding.webView);
        RecordPracticeHost webHost = new RecordPracticeHost(this);
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
//                Logger.e("initLog%s", SLJsonUtils.toJsonString(practiceListData));
                binding.webView.evaluateJavascript("adaptIOS12()", s -> {
                });

                Logger.e("???==>%s",SLJsonUtils.toJsonString(practiceListData));
                binding.webView.evaluateJavascript("initLog('" + SLJsonUtils.toJsonString(practiceListData) + "')", s -> {
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
        File file = new File(recorderUtils.getPath());
        String base64 = FuncUtils.fileToBase64(file);
        base64 = "data:audio/" + "aac" + ";base64," + base64;
        String id = audios.get(audios.size() - 1).getId();
        audios.get(audios.size() - 1).setBase64(base64);
        binding.webView.evaluateJavascript("listenStopRecord('" + SLJsonUtils.toJsonString(base64) + "','" + id + "','" + isAutoPlay + "')", s -> {
        });
        volumeList.clear();
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

    /**
     * 剪裁录音
     */
    public void cutInLocal(TKAudioOperating.StepBean data, double duration) {
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
            boolean clip = RecorderUtils.clip(recorderUtils.getPath(), localFile.getPath(), data.start * 1000, data.end * 1000);
            Logger.e("????==>%s", localFile.getPath());
            String base64 = FuncUtils.fileToBase64(localFile);
            base64 = "data:audio/" + "aac" + ";base64," + base64;
            cutAudio = new TKAudioModule(id, localFile.getPath(), data.getIndex(), duration + "", base64, data.isUpload);
            binding.webView.evaluateJavascript("updatePieces('" + data.getIndex() + "','" + id + "','" + SLJsonUtils.toJsonString(base64) + "','" + duration + "')", s -> {
            });
            status = 1;
            Logger.e("???==>%s", cutAudio == null);
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
    public void mergeInLocal(TKAudioOperating.StepBean data, double duration) {
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
            Logger.e("????==>%s", localFile.getPath());
            String base64 = FuncUtils.fileToBase64(localFile);
            base64 = "data:audio/" + "aac" + ";base64," + base64;
            margeAudio = new TKAudioModule(id, localFile.getPath(), data.getBeforeIndex(), duration + "", base64, data.isUpload);
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
//            Logger.e("点击保存剪裁==>%s,%s", cutBeforeAudio.getIndex(), SLJsonUtils.toJsonString(cutAudio));
            audios.set(cutBeforeAudio.getIndex(), cutAudio);
            cutAudio = null;
            cutBeforeAudio = null;
//            Logger.e("点击保存结束==>%s", SLJsonUtils.toJsonString(audios));

        } else if (status == 2) {
            TKAudioModule element = margeAudio;
            audios.add(margeBeforeAudio.getIndex(), element);


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
        TKCutOrMergeModule param = new TKCutOrMergeModule();
        Logger.e("======%s", status);
        if (status == 1) {
            Logger.e("点击取消剪裁==>");
            param.setType(0)
                    .setBeforeIndex(cutBeforeAudio.getIndex() + "")
                    .setBeforeId(cutBeforeAudio.getId())
                    .setBeforeDuration(cutBeforeAudio.getDuration())
                    .setBeforeIsUpload(cutBeforeAudio.isUpload());

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
    public void recordDone(List<TKAudioModule> data, String logId) {
        //关闭播放

        double totalTime = 0;
        List<UploadRecode> uploadRecodes = new ArrayList<>();
        for (TKAudioModule item : data) {
            double duration = 0;
            try {
                duration = Double.parseDouble(item.getDuration());
            } catch (Throwable e) {

            }
//            if (item.isUpload) {
            UploadRecode uploadRecode = new UploadRecode();
            for (TKAudioModule audio : audios) {
                Logger.e("audioStartTime==>%s", audio.getStartTime());
                if (audio.getId().equals(item.getId())) {
                    uploadRecode.setPath(audio.getAudioPath());
                    uploadRecode.setTime(audio.getStartTime());
                }
            }
            uploadRecode.setId(item.getId());

            Logger.e("======%s", item.getDuration());
            uploadRecode.setDuration(duration);
            uploadRecodes.add(uploadRecode);

//            }
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
            if (mRecordListener != null) {
                mRecordListener.onRecordDone(uploadRecodes, finalTotalTime, logId);
            }
            dismiss();
        });
    }


    public void recording() {
        String id = IDUtils.getId();
        recorderUtils.startRecord(id, false);
        beforeRecordingVolumeList.clear();
        audios.add(new TKAudioModule(id, recorderUtils.getPath(), audios.size(), "", "", false));
    }

    public static class UploadRecode implements Serializable {
        private String id;
        private double duration;
        private String path = "";
        private int time = 0;

        public int getTime() {
            return time;
        }

        public UploadRecode setTime(int time) {
            this.time = time;
            return this;
        }

        public String getId() {
            return id;
        }

        public UploadRecode setId(String id) {
            this.id = id;
            return this;
        }

        public double getDuration() {
            return duration;
        }

        public UploadRecode setDuration(double duration) {
            this.duration = duration;
            return this;
        }

        public String getPath() {
            return path;
        }

        public UploadRecode setPath(String path) {
            this.path = path;
            return this;
        }
    }

    public static class TKWebPractice {
        public String name = "";
        public String id = "";
        public boolean isSelected;
        public int startTime;

        public int getStartTime() {
            return startTime;
        }

        public TKWebPractice setStartTime(int startTime) {
            this.startTime = startTime;
            return this;
        }

        public String getName() {
            return name;
        }

        public TKWebPractice setName(String name) {
            this.name = name;
            return this;
        }

        public String getId() {
            return id;
        }

        public TKWebPractice setId(String id) {
            this.id = id;
            return this;
        }

        public boolean isSelected() {
            return isSelected;
        }

        public TKWebPractice setSelected(boolean selected) {
            isSelected = selected;
            return this;
        }
    }

    public static class TKAudioRecord {
        private String logId = "";
        private String title = "";
        private List<TKAudioModule> data = new ArrayList<>();

        public String getTitle() {
            return title;
        }

        public TKAudioRecord setTitle(String title) {
            this.title = title;
            return this;
        }

        public String getLogId() {
            return logId;
        }

        public TKAudioRecord setLogId(String logId) {
            this.logId = logId;
            return this;
        }

        public List<TKAudioModule> getData() {
            return data;
        }

        public TKAudioRecord setData(List<TKAudioModule> data) {
            this.data = data;
            return this;
        }
    }

    public static class TKAudioModule implements Serializable{
        public String id = "";
        public String audioPath = "";
        public int index;
        public String duration = "";
        public String base64 = "";
        public boolean isUpload;
        public int startTime;

        public int getStartTime() {
            return startTime;
        }

        public TKAudioModule setStartTime(int startTime) {
            this.startTime = startTime;
            return this;
        }

        public TKAudioModule(String id, String audioPath, int index, String duration, String base64, boolean isUpload) {
            this.id = id;
            this.audioPath = audioPath;
            this.index = index;
            this.duration = duration;
            this.base64 = base64;
            this.isUpload = isUpload;
            this.startTime = TimeUtils.getCurrentTime();
        }

        public String getId() {
            return id;
        }

        public TKAudioModule setId(String id) {
            this.id = id;
            return this;
        }

        public String getAudioPath() {
            return audioPath;
        }

        public TKAudioModule setAudioPath(String audioPath) {
            this.audioPath = audioPath;
            return this;
        }

        public int getIndex() {
            return index;
        }

        public TKAudioModule setIndex(int index) {
            this.index = index;
            return this;
        }

        public String getDuration() {
            return duration;
        }

        public TKAudioModule setDuration(String duration) {
            this.duration = duration;
            return this;
        }

        public String getBase64() {
            return base64;
        }

        public TKAudioModule setBase64(String base64) {
            this.base64 = base64;
            return this;
        }

        public boolean isUpload() {
            return isUpload;
        }

        public TKAudioModule setUpload(boolean upload) {
            isUpload = upload;
            return this;
        }
    }

    public static class TKAudioOperating implements Serializable {


        private StepBean step;
        private double duration;

        public StepBean getStep() {
            return step;
        }

        public TKAudioOperating setStep(StepBean step) {
            this.step = step;
            return this;
        }

        public double getDuration() {
            return duration;
        }

        public TKAudioOperating setDuration(double duration) {
            this.duration = duration;
            return this;
        }

        public static class StepBean implements Serializable {

            public int type;
            public int start;
            public int end;
            public double total;
            public int index;
            public String id;
            public boolean isUpload;

            public String beforeDuration = "";
            public String beforeId = "";
            public int beforeIndex = 0;
            public boolean beforeIsUpload;

            public String afterDuration = "";
            public String afterId = "";
            public int afterIndex = 0;
            public boolean afterIsUpload;

            public String getBeforeDuration() {
                return beforeDuration;
            }

            public StepBean setBeforeDuration(String beforeDuration) {
                this.beforeDuration = beforeDuration;
                return this;
            }

            public String getBeforeId() {
                return beforeId;
            }

            public StepBean setBeforeId(String beforeId) {
                this.beforeId = beforeId;
                return this;
            }


            public int getBeforeIndex() {
                return beforeIndex;
            }

            public StepBean setBeforeIndex(int beforeIndex) {
                this.beforeIndex = beforeIndex;
                return this;
            }

            public int getAfterIndex() {
                return afterIndex;
            }

            public StepBean setAfterIndex(int afterIndex) {
                this.afterIndex = afterIndex;
                return this;
            }

            public boolean isBeforeIsUpload() {
                return beforeIsUpload;
            }

            public StepBean setBeforeIsUpload(boolean beforeIsUpload) {
                this.beforeIsUpload = beforeIsUpload;
                return this;
            }

            public String getAfterDuration() {
                return afterDuration;
            }

            public StepBean setAfterDuration(String afterDuration) {
                this.afterDuration = afterDuration;
                return this;
            }

            public String getAfterId() {
                return afterId;
            }

            public StepBean setAfterId(String afterId) {
                this.afterId = afterId;
                return this;
            }


            public boolean isAfterIsUpload() {
                return afterIsUpload;
            }

            public StepBean setAfterIsUpload(boolean afterIsUpload) {
                this.afterIsUpload = afterIsUpload;
                return this;
            }

            public int getType() {
                return type;
            }

            public StepBean setType(int type) {
                this.type = type;
                return this;
            }

            public int getStart() {
                return start;
            }

            public StepBean setStart(int start) {
                this.start = start;
                return this;
            }

            public int getEnd() {
                return end;
            }

            public StepBean setEnd(int end) {
                this.end = end;
                return this;
            }

            public double getTotal() {
                return total;
            }

            public StepBean setTotal(double total) {
                this.total = total;
                return this;
            }

            public int getIndex() {
                return index;
            }

            public StepBean setIndex(int index) {
                this.index = index;
                return this;
            }

            public String getId() {
                return id;
            }

            public StepBean setId(String id) {
                this.id = id;
                return this;
            }

            public boolean isUpload() {
                return isUpload;
            }

            public StepBean setUpload(boolean upload) {
                isUpload = upload;
                return this;
            }
        }
    }

    public static class TKCutOrMergeModule {
        private int type = 0;
        private String beforeIndex = "";
        private String beforeId = "";
        private String beforeBase64 = "";
        private String beforeDuration = "";
        private boolean beforeIsUpload;

        private String afterIndex = "";
        private String afterId = "";
        private String afterBase64 = "";
        private String afterDuration = "";
        private boolean afterIsUpload;

        private String id;
        private String duration;

        public String getId() {
            return id;
        }

        public TKCutOrMergeModule setId(String id) {
            this.id = id;
            return this;
        }

        public String getDuration() {
            return duration;
        }

        public TKCutOrMergeModule setDuration(String duration) {
            this.duration = duration;
            return this;
        }

        public int getType() {
            return type;
        }

        public TKCutOrMergeModule setType(int type) {
            this.type = type;
            return this;
        }

        public String getBeforeIndex() {
            return beforeIndex;
        }

        public TKCutOrMergeModule setBeforeIndex(String beforeIndex) {
            this.beforeIndex = beforeIndex;
            return this;
        }

        public String getBeforeId() {
            return beforeId;
        }

        public TKCutOrMergeModule setBeforeId(String beforeId) {
            this.beforeId = beforeId;
            return this;
        }

        public String getBeforeBase64() {
            return beforeBase64;
        }

        public TKCutOrMergeModule setBeforeBase64(String beforeBase64) {
            this.beforeBase64 = beforeBase64;
            return this;
        }

        public String getBeforeDuration() {
            return beforeDuration;
        }

        public TKCutOrMergeModule setBeforeDuration(String beforeDuration) {
            this.beforeDuration = beforeDuration;
            return this;
        }

        public boolean isBeforeIsUpload() {
            return beforeIsUpload;
        }

        public TKCutOrMergeModule setBeforeIsUpload(boolean beforeIsUpload) {
            this.beforeIsUpload = beforeIsUpload;
            return this;
        }

        public String getAfterIndex() {
            return afterIndex;
        }

        public TKCutOrMergeModule setAfterIndex(String afterIndex) {
            this.afterIndex = afterIndex;
            return this;
        }

        public String getAfterId() {
            return afterId;
        }

        public TKCutOrMergeModule setAfterId(String afterId) {
            this.afterId = afterId;
            return this;
        }

        public String getAfterBase64() {
            return afterBase64;
        }

        public TKCutOrMergeModule setAfterBase64(String afterBase64) {
            this.afterBase64 = afterBase64;
            return this;
        }

        public String getAfterDuration() {
            return afterDuration;
        }

        public TKCutOrMergeModule setAfterDuration(String afterDuration) {
            this.afterDuration = afterDuration;
            return this;
        }

        public boolean isAfterIsUpload() {
            return afterIsUpload;
        }

        public TKCutOrMergeModule setAfterIsUpload(boolean afterIsUpload) {
            this.afterIsUpload = afterIsUpload;
            return this;
        }
    }

}
