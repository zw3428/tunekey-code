package com.spelist.tunekey.ui.student.sPractice.host;

import android.annotation.SuppressLint;
import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.ui.student.sPractice.dialogs.PlayPracticeDialog;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

/**
 * com.spelist.tunekey.ui.sPractice.host
 * 2021/4/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
@SuppressLint("JavascriptInterface")
public class PlayPracticeHost extends Object{
    private PlayPracticeDialog playPracticeDialog;

    public PlayPracticeHost(PlayPracticeDialog playPracticeDialog) {
        this.playPracticeDialog = playPracticeDialog;
    }
    @JavascriptInterface
    public void closeAudioPage(String value) {
        Logger.e("closeAudioPage: " + value);
        List<String> deleteIds = new ArrayList<>();
        if (!value.equals("")) {
            List<AudioModel> audioModels = SLJsonUtils.toList(value, AudioModel.class);
            for (AudioModel audioModel : audioModels) {
                if (audioModel.isDelete()) {
                    deleteIds.add(audioModel.getId());
                }
            }
        }
        playPracticeDialog.post(() -> {
            playPracticeDialog.close(deleteIds);

        });
    }
    @JavascriptInterface
    public void getAudioUrl(String value) {
        playPracticeDialog.post(() -> {
            try {
                playPracticeDialog.download(value);
            } catch (IOException e) {
                e.printStackTrace();
                Logger.e("===getAudioUrl===%s", e.getMessage());
            }

        });
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
