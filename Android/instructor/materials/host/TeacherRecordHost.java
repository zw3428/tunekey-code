package com.spelist.tunekey.ui.teacher.materials.host;

import android.annotation.SuppressLint;
import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.ui.teacher.materials.dialog.TeacherAudioRecodingDialog;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;

/**
 * com.spelist.tunekey.ui.sPractice.host
 * 2021/4/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
@SuppressLint("JavascriptInterface")
public class TeacherRecordHost extends Object{
    private TeacherAudioRecodingDialog recordPracticeDialog;

    public TeacherRecordHost(TeacherAudioRecodingDialog recordPracticeDialog) {
        this.recordPracticeDialog = recordPracticeDialog;
    }

    @JavascriptInterface
    public void stopLocalRecord(boolean value) {
        recordPracticeDialog.post(() -> {
            Logger.e("stopLocalRecord:" + value);
            recordPracticeDialog.stop(false);
        });

    }
    @JavascriptInterface
    public void startLocalRecord(boolean value) {
        recordPracticeDialog.post(() -> {
        Logger.e("startLocalRecord:" + value);
        recordPracticeDialog.recording();
        });
    }
    @JavascriptInterface
    public void cutInLocal(String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("cutInLocal:" + value);
            RecordPracticeDialog.TKAudioOperating data = SLJsonUtils.toBean(value, RecordPracticeDialog.TKAudioOperating.class);
            recordPracticeDialog.cutInLocal(data.getStep(),data.getDuration());
        });
    }


    @JavascriptInterface
    public void mergeInLocal(String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("mergeInLocal:" + value);
            RecordPracticeDialog.TKAudioOperating data = SLJsonUtils.toBean(value, RecordPracticeDialog.TKAudioOperating.class);
            recordPracticeDialog.mergeInLocal(data.getStep(),data.getDuration());

        });
    }
    @JavascriptInterface
    public void cancelCutOrMerge(String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("cancelCutOrMerge:" + value);
            recordPracticeDialog.cancelCutOrMerge();
        });
    }

    @JavascriptInterface
    public void stopRecordAudio() {
        recordPracticeDialog.post(() -> {
            Logger.e("stopRecordAudio:");
            recordPracticeDialog.stopRecordAudio();
        });
    }
    @JavascriptInterface
    public void goBack() {
        recordPracticeDialog.post(() -> {
            Logger.e("goBack:");
            recordPracticeDialog.goBack();
        });
    }
    @JavascriptInterface
    public void closeAudioRecord() {
        recordPracticeDialog.post(() -> {
            Logger.e("closeAudioRecord:" );
            recordPracticeDialog.closePractice();
        });
    }

    @JavascriptInterface
    public void uploadAudio(String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("uploadAudio:" + value);
//            RecordPracticeDialog.TKAudioRecord tkAudioRecord = SLJsonUtils.toBean(value, RecordPracticeDialog.TKAudioRecord.class);

            recordPracticeDialog.uploadAudio(value);
        });
    }

    @JavascriptInterface
    public void saveCutOrMerge(String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("saveCutOrMerge:" + value);
            recordPracticeDialog.saveCutOrMerge();
        });
    }



    @JavascriptInterface
    public void uploadRecordPiece(String id,String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("======%s", value);
            recordPracticeDialog.showUploadPop();
        });
    }
    @JavascriptInterface
    public void cancelUploadRecordPiece(String id,String value) {
        recordPracticeDialog.post(() -> {
            Logger.e("======%s", value);
            recordPracticeDialog.showUnUploadPop();

        });
    }
    @JavascriptInterface
    public void recordDone(String value) {
        recordPracticeDialog.post(() -> {
            RecordPracticeDialog.TKAudioRecord tkAudioRecord = SLJsonUtils.toBean(value, RecordPracticeDialog.TKAudioRecord.class);
            for (RecordPracticeDialog.TKAudioModule datum : tkAudioRecord.getData()) {
                Logger.e("======%s",datum.isUpload() );
            }

            recordPracticeDialog.recordDone(tkAudioRecord.getData(),tkAudioRecord.getLogId());
        });
    }

    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("Log from webView:" + value);
    }


}
