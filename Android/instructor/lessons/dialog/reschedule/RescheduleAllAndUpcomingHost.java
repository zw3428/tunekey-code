package com.spelist.tunekey.ui.teacher.lessons.dialog.reschedule;

import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;

/**
 * com.spelist.tunekey.ui.teacher.lessons.dialog.reschedule
 * 2022/4/6
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleAllAndUpcomingHost extends Object{
    public RescheduleAllAndUpcomingDialog rescheduleAllAndUpcomingDialog;

    public RescheduleAllAndUpcomingHost(RescheduleAllAndUpcomingDialog rescheduleAllAndUpcomingDialog) {
        this.rescheduleAllAndUpcomingDialog = rescheduleAllAndUpcomingDialog;
    }
    /**
     * 日历选择的日期
     *
     * @param yymmd
     */
    @JavascriptInterface
    public void onDatePick(String yymmd) {
        if (rescheduleAllAndUpcomingDialog !=null){
            rescheduleAllAndUpcomingDialog.setEndTime(yymmd);
        }
    }
    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("-*-*-*-*-*-*-*- log from webview: " + value);
    }

}
