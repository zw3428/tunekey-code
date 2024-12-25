package com.spelist.tunekey.ui.teacher.materials.host;

import android.annotation.SuppressLint;
import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.ui.teacher.materials.dialog.PlayAudioDialog;

import java.io.Serializable;

/**
 * com.spelist.tunekey.ui.sPractice.host
 * 2021/4/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
@SuppressLint("JavascriptInterface")
public class PlayAudioHost extends Object{
    private PlayAudioDialog playPracticeDialog;

    public PlayAudioHost(PlayAudioDialog playPracticeDialog) {
        this.playPracticeDialog = playPracticeDialog;
    }
    @JavascriptInterface
    public void closeAudioPage() {

        playPracticeDialog.post(() -> {
            playPracticeDialog.close();

        });
    }
    @JavascriptInterface
    public void getAudioUrl(String value) {

    }
    @JavascriptInterface
    public void setSpeed (String value) {
        playPracticeDialog.showSpeed();
    }

    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("Log from webView:" + value);
    }

    public static class AudioModel implements Serializable {
        private String duration;
        private String time;
        private boolean isDelete;
        private String id = "";

        public String getDuration() {
            return duration;
        }

        public AudioModel setDuration(String duration) {
            this.duration = duration;
            return this;
        }

        public String getTime() {
            return time;
        }

        public AudioModel setTime(String time) {
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
