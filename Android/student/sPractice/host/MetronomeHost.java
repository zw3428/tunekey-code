package com.spelist.tunekey.ui.student.sPractice.host;

import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.ui.student.sPractice.fragment.StudentPracticeMetronomeFragment;
import com.spelist.tunekey.utils.SLCacheUtil;

/**
 * com.spelist.tunekey.ui.sPractice.host
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MetronomeHost extends Object{
    private StudentPracticeMetronomeFragment metronomeFragment;

    public MetronomeHost(StudentPracticeMetronomeFragment metronomeFragment) {
        this.metronomeFragment = metronomeFragment;
    }
    @JavascriptInterface
    public void showBeatPickerDialog() {
        metronomeFragment.showBeatPickerDialog();
    }
    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("Log from webView: " + value);
    }
    @JavascriptInterface
    public void saveMetronomeConfig(String value) {
        Logger.e("saveMetronomeConfig: " + value);
        SLCacheUtil.setStringData("metronomeData:"+ UserService.getInstance().getCurrentUserId(),value);
    }
//    @JavascriptInterface
//    public void set(String value) {
//        Logger.e("saveMetronomeConfig: " + value);
//    }


    @JavascriptInterface
    public void startMetronome() {
        Logger.e("startMetronome: ");
        metronomeFragment.startMetronome();
    }
    @JavascriptInterface
    public void stopMetronome() {
        Logger.e("stopMetronome: ");
        metronomeFragment.stopMetronome();
    }
}
