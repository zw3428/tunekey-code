package com.spelist.tunekey.ui.teacher.insights;

import android.webkit.JavascriptInterface;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.ui.teacher.insights.fragments.EarningsFragment;
import com.spelist.tunekey.ui.teacher.insights.fragments.LearningFragment;
import com.spelist.tunekey.ui.teacher.insights.fragments.TeachingFragment;
import com.spelist.tunekey.ui.teacher.insights.fragments.EarningsFragment;
import com.spelist.tunekey.ui.teacher.insights.fragments.LearningFragment;
import com.spelist.tunekey.ui.teacher.insights.fragments.TeachingFragment;

/**
 * com.spelist.tunekey.ui.insights
 * 2021/6/1
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class InsightsHost extends Object{
    private TeachingFragment teachingFragment;
    private EarningsFragment earningsFragment;
    private LearningFragment learningFragment;

    public InsightsHost(TeachingFragment teachingFragment) {
        this.teachingFragment = teachingFragment;
    }

    public InsightsHost(LearningFragment learningFragment) {
        this.learningFragment = learningFragment;
    }

    public InsightsHost(EarningsFragment earningsFragment) {
        this.earningsFragment = earningsFragment;
    }
    @JavascriptInterface
    public void mousemoveInsight() {
    }
    @JavascriptInterface
    public void mouseoutInsight() {

    }

    @JavascriptInterface
    public void consoleLog(String value) {

    }

}
