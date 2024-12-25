package com.spelist.tunekey.ui.teacher.lessons;

import android.annotation.SuppressLint;
import android.content.Context;
import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.ui.teacher.lessons.fragments.LessonsFragment;

/**
 * com.spelist.tunekey.ui.lessons
 * 2021/1/13
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LessonWebHost extends Object {
    public Context context;
    public LessonsFragment lessonsFragment;

    public LessonWebHost(Context context, LessonsFragment lessonsFragment) {
        this.context = context;
        this.lessonsFragment = lessonsFragment;
    }

    @SuppressLint("Assert")
    @JavascriptInterface
    public void updateCalendarFirstDay(long timestamp) {
        lessonsFragment.getActivity().runOnUiThread(() -> {
            if (timestamp == 0) {
                return;
            }

            Logger.e("==翻页====%s", timestamp);
            lessonsFragment.changeCalendarPage(timestamp);
        });

    }

    @JavascriptInterface
    public void updatePickedDay(long timestamp) {
        lessonsFragment.getActivity().runOnUiThread(() -> {
            Logger.e("===选中的===%s", timestamp);
//        lessonsFragment.selectTimestamp = timestamp;
            lessonsFragment.changeSelectTime(timestamp * 1000L);
        });


    }
    @JavascriptInterface
    public void test() {



    }

    /**
     * 点击 某一天中的某一节课程
     *
     * @param selectedLesson     选的json
     * @param selectedIndexOfDay 选中的是第几个
     * @param allLessonOfDay     选中当天的json
     */
    @JavascriptInterface
    public void getLessonDetail(String selectedLesson, String selectedIndexOfDay, String allLessonOfDay) {
        lessonsFragment.getActivity().runOnUiThread(() -> {
            int index = 0;
            if (!selectedIndexOfDay.equals("")) {
                index = Integer.parseInt(selectedIndexOfDay);
            }
            lessonsFragment.toLessonDetail(selectedLesson, index, allLessonOfDay);
        });


    }


    @JavascriptInterface
    public void consoleLog(String value) {
        Logger.e("-*-*-*-*-*-*-*- Log from webView: " + value);
    }

    /**
     * 无用的方法
     *
     * @param yymmd
     */
    @JavascriptInterface
    public void onDatePick(String yymmd) {

    }


    /**
     * 点击消息盒子
     *
     * @param rescheduleData
     */
    @JavascriptInterface
    public void showReschedule(String rescheduleData) {
        lessonsFragment.getActivity().runOnUiThread(() -> {

            Logger.e("点击了 消息盒子%s", rescheduleData);
            lessonsFragment.clickRescheduleBox();
        });

    }
}
