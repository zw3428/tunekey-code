package com.spelist.tunekey.ui.student.sLessons;

import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentRescheduleAc;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentRescheduleVM;
import com.spelist.tunekey.utils.TimeUtils;

/**
 * com.spelist.tunekey.ui.sLessons
 * 2021/4/1
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleHost extends Object{
    private StudentRescheduleAc studentRescheduleAc;
    private StudentRescheduleVM studentRescheduleVM;

    public StudentRescheduleHost(StudentRescheduleAc studentRescheduleAc, StudentRescheduleVM studentRescheduleVM) {
        this.studentRescheduleAc = studentRescheduleAc;
        this.studentRescheduleVM = studentRescheduleVM;
    }
    @JavascriptInterface
    public void updateCalendar(String YYmm) {

        if (studentRescheduleAc != null) {
            studentRescheduleAc.runOnUiThread(() -> {
                long l = TimeUtils.timeToStamp(YYmm, "yyyy-MM-dd") / 1000L;
                String format = "MMMM yyyy";
//                if (TimeUtils.getMonthOfYear(l*1000L)==0){
//                    format = "MMMM yyyy";
//                }
                studentRescheduleVM.changeMonth(l);
                studentRescheduleVM.calendarMonth.set(TimeUtils.timeFormat(l,format));

            });

        }
    }
    /**
     * 日历选择的日期
     *
     * @param yymmd
     */
    @JavascriptInterface
    public void onDatePick(String yymmd) {
        if (studentRescheduleAc != null) {
            studentRescheduleAc.runOnUiThread(() -> {
                studentRescheduleVM.changeSelect(yymmd + " 00:00:00");

            });
        }

    }
    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("Log from webView: " + value);
    }
}
