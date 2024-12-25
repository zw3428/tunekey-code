package com.spelist.tunekey.ui.teacher.insights.fragments;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.Nullable;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.customView.dialog.TeachingHoursDialog;
import com.spelist.tunekey.databinding.FragmentTeachingBinding;
import com.spelist.tunekey.ui.teacher.insights.InsightsHost;
import com.spelist.tunekey.ui.teacher.insights.vm.TeachingVM;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.TimeUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * com.spelist.tunekey.ui.insights.fragments
 * 2021/5/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class TeachingFragment extends BaseFragment<FragmentTeachingBinding, TeachingVM> {
    public JSONObject chartDataJson1 = new JSONObject();
    public JSONObject chartDataJson2 = new JSONObject();
    public String[] charData1 = {"0", "0", "0", "0", "0", "0", "0", "0"};
    public String[] charData2 = {"0", "0", "0", "0", "0", "0", "0", "0"};
    public int year = 0;
    public int month = 0;
    public int date = 0;
    boolean isShowData = true;

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
        return R.layout.fragment_teaching;
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

    public void refData(long start, long end) {
        viewModel.rangeStartTime = start;
        viewModel.rangeEndTime = end;
        viewModel.initData();
    }

    public void refIsShowData(boolean isShow) {
        try {
            isShowData = isShow;
            if (viewModel != null) {
                viewModel.isShowValue.set(isShow);
            }

            initJsonData(year, month, date, isShowData ? 1 : 9, Arrays.toString(charData1), chartDataJson1);
            initJsonData(year, month, date, isShowData ? 2 : 9, Arrays.toString(charData2), chartDataJson2);
            binding.chartWeb1.evaluateJavascript("initChart(" + chartDataJson1 + ")", value -> {
            });
            binding.chartWeb2.evaluateJavascript("initChart(" + chartDataJson2 + ")", value -> {
            });
        } catch (Exception e) {

        }
    }

    @Override
    public void initData() {
        super.initData();
        year = Integer.parseInt(TimeUtils.getFormatYear(viewModel.rangeStartTime));
        month = Integer.parseInt(TimeUtils.getFormatMonth(viewModel.rangeStartTime));
        date = Integer.parseInt(TimeUtils.getFormatDate(viewModel.rangeStartTime));
        initJsonData(year, month, date, isShowData ? 1 : 9, Arrays.toString(charData1), chartDataJson1);
        initJsonData(year, month, date, isShowData ? 2 : 9, Arrays.toString(charData2), chartDataJson2);
        FuncUtils.initWebViewSetting(binding.chartWeb1, "file:///android_asset/web/chart.html");
        FuncUtils.initWebViewSetting(binding.chartWeb2, "file:///android_asset/web/chart.html");
    }

    @Override
    public void initView() {
        super.initView();
        binding.card1.setBackgroundResource(R.drawable.background_gradient_pink_purple);
        binding.card2.setBackgroundResource(R.drawable.background_gradient_orange_yellow);
        FuncUtils.closeHardwareAccelerated(binding.chartWeb1);
        FuncUtils.closeHardwareAccelerated(binding.chartWeb2);
        InsightsHost insightsHost = new InsightsHost(this);
        binding.chartWeb1.addJavascriptInterface(insightsHost, "js");
        binding.chartWeb2.addJavascriptInterface(insightsHost, "js");


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
        binding.card2.setOnClickListener(v -> {
            if (isShowData) {

                TeachingHoursDialog.Builder teachingHoursDialog = new TeachingHoursDialog.Builder(getContext())
                        .setData(viewModel.lessonHours);
                teachingHoursDialog.setDoneOnClickListener(d -> {
//                viewModel.lessonHours = teachingHoursDialog.getData();
//                viewModel.teacherHoursString.set(viewModel.policyEntity.getTeacherHoursString());
                    ListenerService.shared.teacherData.getPolicyEntity().setLessonHours(teachingHoursDialog.getData());
                    viewModel.initData();
                    viewModel.updatePolicies();
                    teachingHoursDialog.dismiss();

                });
                teachingHoursDialog.create();
                teachingHoursDialog.showDialog();
            }

        });
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
            charData1 = new String[viewModel.workHourChartData.size()];
            viewModel.workHourChartData.toArray(charData1);
            charData2 = new String[viewModel.capacityChartData.size()];
            viewModel.capacityChartData.toArray(charData2);
            initJsonData(year, month, date, isShowData ? 1 : 9, Arrays.toString(charData1), chartDataJson1);
            initJsonData(year, month, date, isShowData ? 2 : 9, Arrays.toString(charData2), chartDataJson2);
//            Logger.e("chartDataJson1:%s",chartDataJson1);
//            Logger.e("chartDataJson2:%s",chartDataJson2);
            binding.chartWeb1.evaluateJavascript("initChart(" + chartDataJson1 + ")", value -> {
            });
            binding.chartWeb2.evaluateJavascript("initChart(" + chartDataJson2 + ")", value -> {
            });
        });
    }
}
