package com.spelist.tunekey.ui.student.sAchievement.fragment;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.Nullable;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentPracticeInsightBinding;
import com.spelist.tunekey.ui.student.sAchievement.vm.PracticeInsightVM;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.TimeUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * com.spelist.tunekey.ui.insights.fragments
 * 2021/5/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeInsightFragment extends BaseFragment<FragmentPracticeInsightBinding, PracticeInsightVM> {
    public JSONObject chartDataJson1 = new JSONObject();
    public JSONObject chartDataJson2 = new JSONObject();
    public String[] charData1 = {"0", "0", "0", "0", "0", "0", "0", "0"};
    public String[] charData2 = {"0", "0", "0", "0", "0", "0", "0", "0"};
    public int year = 0;
    public int month = 0;
    public int date = 0;

    /**
     * 初始化根布局
     *
     * @param inflater
     * @param container
     * @param savedInstanceState
     * @return 布局layout的id
     */
    @Override
    public int initContentView(LayoutInflater inflater, @Nullable @org.jetbrains.annotations.Nullable ViewGroup container, @Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
        return R.layout.fragment_practice_insight;
    }

    /**
     * 初始化ViewModel的id
     *
     * @return BR的id
     */
    @Override
    public int initVariableId() {
        return BR.viewModel;
    }
    public void update(long startTime,long endTime){
        viewModel.rangeStartTime = startTime;
        viewModel.rangeEndTime = endTime;
        viewModel.initData();
    }



    @Override
    public void initData() {
        super.initData();
        year = Integer.parseInt(TimeUtils.getFormatYear(viewModel.rangeStartTime));
        month = Integer.parseInt(TimeUtils.getFormatMonth(viewModel.rangeStartTime));
        date = Integer.parseInt(TimeUtils.getFormatDate(viewModel.rangeStartTime));
        initJsonData(year, month, date, 7, Arrays.toString(charData1), chartDataJson1);
        initJsonData(year, month, date, 8, Arrays.toString(charData2), chartDataJson2);
        FuncUtils.initWebViewSetting(binding.chartWeb1, "file:///android_asset/web/chart.html");
        FuncUtils.initWebViewSetting(binding.chartWeb2, "file:///android_asset/web/chart.html");
    }

    @Override
    public void initView() {
        super.initView();
        binding.card1.setBackgroundResource(R.drawable.background_gradient_pink_purple);
        binding.card2.setBackgroundResource(R.drawable.background_gradient_green_blue);
        FuncUtils.closeHardwareAccelerated(binding.chartWeb1);
        FuncUtils.closeHardwareAccelerated(binding.chartWeb2);



        binding.chartWeb1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                view.evaluateJavascript("initChart(" + chartDataJson1 + ")", value -> {
                });
            }
        });
        binding.chartWeb2.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                view.evaluateJavascript("initChart(" + chartDataJson2 + ")", value -> {
                });
            }
        });
        binding.chartWeb1.requestDisallowInterceptTouchEvent(true);

    }

    @SuppressLint("JavascriptInterface")
    public void initJsonData(int year, int month, int date, int type, String charData, JSONObject data) {
        try {
            data.put("year", year);
            data.put("month", month);
            data.put("date", date);
            data.put("type", type);
            data.put("data", charData);
        } catch (JSONException e) {
        }
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.update.observe(this, unused -> {
            year = Integer.parseInt(TimeUtils.getFormatYear(viewModel.rangeStartTime));
            month = Integer.parseInt(TimeUtils.getFormatMonth(viewModel.rangeStartTime));
            date = Integer.parseInt(TimeUtils.getFormatDate(viewModel.rangeStartTime));
//            charData1 = new String[viewModel.timeChartData.size()];
//            viewModel.timeChartData.toArray(charData1);
            charData1 = new String[viewModel.timeChartData.size()];

            List<String> practiceData = new ArrayList<>();

            for (Double item : viewModel.timeChartData) {
                practiceData.add(item+"");
            }
            practiceData.toArray(charData1);

            charData2 = new String[viewModel.sessionsChartData.size()];
//            viewModel.achievementChartData.toArray(charData2);
            List<String> sessionsData = new ArrayList<>();

            for (Integer item : viewModel.sessionsChartData) {
                sessionsData.add(item+"");
            }
            sessionsData.toArray(charData2);
            initJsonData(year, month, date, 7, Arrays.toString(charData1), chartDataJson1);
            initJsonData(year, month, date, 8, Arrays.toString(charData2), chartDataJson2);

            binding.chartWeb1.evaluateJavascript("initChart(" + chartDataJson1 + ")", value -> {
            });
            binding.chartWeb2.evaluateJavascript("initChart(" + chartDataJson2 + ")", value -> {
            });
        });
    }
}
