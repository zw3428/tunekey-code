package com.spelist.tunekey.ui.teacher.insights.adapter;

import android.annotation.SuppressLint;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.databinding.ObservableList;
import androidx.databinding.ViewDataBinding;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SLWebView;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentInsightsItemBinding;
import com.spelist.tunekey.ui.teacher.insights.fragments.InsightsFragment;
import com.spelist.tunekey.ui.teacher.insights.vm.InsightsItemViewModel;
import com.spelist.tunekey.ui.teacher.insights.vm.InsightsViewModel;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.TimeUtils;
import com.spelist.tunekey.utils.WebHost;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;
import java.util.List;

import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;

public class ViewPagerBindingAdapter extends BindingViewPagerAdapter<InsightsItemViewModel> {
    public InsightsFragment insightsFragment;
    public ObservableList<InsightsItemViewModel> itemViewModel;
    public InsightsViewModel viewModel;
    public FragmentInsightsItemBinding _bindingTeaching;
    public FragmentInsightsItemBinding _bindingEarning;
    public FragmentInsightsItemBinding _bindingLearning;
    public boolean isPro;
    public SLWebView chart1;
    public SLWebView chart2;
    public TextView chart1Title;
    public TextView chart2Title;
    public LinearLayout card1;
    public LinearLayout card2;
    public TextView card1Value1;
    public TextView card1Value2;
    public TextView card2Value1;
    public TextView card2Value2;
    public View promptLayout;
    public TextView promptText;
    public ImageView lock1;
    public ImageView lock2;
    public TextView front1;
    public TextView front2;
    public TextView backward1;
    public TextView backward2;
    public int year = 2020;
    public int month = 8;
    public int date = 21;
    public JSONObject chartDataJson1 = new JSONObject();
    public JSONObject chartDataJson2 = new JSONObject();

    // chartData 模拟数据
    public String[] charData1 = {"6","5","8","4","9"};
    public String[] charData2 = {"3","5","7","4","7"};

    public ViewPagerBindingAdapter(InsightsFragment insightsFragment, InsightsViewModel viewModel, ObservableList<InsightsItemViewModel> itemViewModels) {
        this.insightsFragment = insightsFragment;
        this.itemViewModel = itemViewModels;
        this.viewModel = viewModel;
    }

    @Override
    public void onBindBinding(ViewDataBinding binding, int variableId, int layoutRes,
                              int position, InsightsItemViewModel item) {
        super.onBindBinding(binding, variableId, layoutRes, position, item);
        FragmentInsightsItemBinding _binding = (FragmentInsightsItemBinding) binding;

        if (position == 0) {
            this._bindingTeaching = _binding;
        }else if (position == 1) {
            this._bindingEarning = _binding;
        }else if (position == 2) {
            this._bindingLearning = _binding;
        }

        bindingElements(_binding);

        isPro = item.isPro;
        initCard(position, isPro);

        // 根据 type 计算 chartData1、chartData2
        initChartData(position);
    }

    private void bindingElements(FragmentInsightsItemBinding _binding) {
        chart1 = _binding.chartWeb1;
        chart1.setTag(1);
        chart2 = _binding.chartWeb2;
        chart2.setTag(2);
        chart1Title = _binding.chart1Title;
        chart2Title = _binding.chart2Title;

        card1 = (LinearLayout) _binding.card1.card;
        card2 = (LinearLayout) _binding.card2.card;
        card1Value1 = card1.findViewById(R.id.value1);
        card1Value2 = card1.findViewById(R.id.value2);
        card2Value1 = card2.findViewById(R.id.value1);
        card2Value2 = card2.findViewById(R.id.value2);
        lock1 = card1.findViewById(R.id.ic_lock);
        lock2 = card2.findViewById(R.id.ic_lock);
        front1 = card1.findViewById(R.id.front);
        front2 = card2.findViewById(R.id.front);
        backward1 = card1.findViewById(R.id.backward);
        backward2 = card2.findViewById(R.id.backward);
        promptLayout = _binding.promptLayout;
        promptText = promptLayout.findViewById(R.id.prompt);
        promptText.setText(R.string.prompt_to_be_pro_insights);
    }

    public void initChartData(int position) {
        int type = 2 * position + (int)chart1.getTag();
        FuncUtils.closeHardwareAccelerated(chart1);
        FuncUtils.closeHardwareAccelerated(chart2);

        if (type == 1) {
            // insight - teaching
        }else if (type == 3) {
            // insight - earning
        }else if (type == 5) {
            // insight - learning
        }else if (type == 7) {
            // achievement - practice
        }

        initJsonData(year, month, date, type, Arrays.toString(charData1), chartDataJson1);
        initJsonData(year, month, date, type + 1, Arrays.toString(charData2), chartDataJson2);

        initChart();
    }

    @SuppressLint("JavascriptInterface")
    public void initJsonData(int year, int month, int date, int type, String charData, JSONObject data) {
        try {
            data.put("year", year);
            data.put("month", month);
            data.put("date", date);
            data.put("type", type);
            data.put("data", charData);
        } catch (JSONException e) {}
    }

    private void initCard(int position, boolean isPro) {
        if (isPro) {
            lock1.setVisibility(View.GONE);
            lock2.setVisibility(View.GONE);
            card1Value2.setVisibility(View.VISIBLE);
            card2Value2.setVisibility(View.VISIBLE);
        }else {
            lock1.setVisibility(View.VISIBLE);
            lock2.setVisibility(View.VISIBLE);
            card1Value2.setVisibility(View.GONE);
            card2Value2.setVisibility(View.GONE);
        }
        switch (position) {
            case 0:
                chart1Title.setText("Hours");
                chart2Title.setText("Capacity");
                card1.setBackgroundResource(R.drawable.background_gradient_pink_purple);
                card2.setBackgroundResource(R.drawable.background_gradient_orange_yellow);
                card1Value1.setText(itemViewModel.get(0).period);
                card1Value2.setText(itemViewModel.get(0).duration);
                backward1.setText("hrs");
                card2Value1.setText("Capacity");
                card2Value2.setText(itemViewModel.get(0).capacity);
                backward2.setText("%");

                if (isPro) {
                    clickToSelectPeriod(card1);
                }

                break;
            case 1:
                chart1Title.setText("Students");
                chart2Title.setText("Earnings");
                card1.setBackgroundResource(R.drawable.background_gradient_purple_blue);
                card2.setBackgroundResource(R.drawable.background_gradient_green_blue);
                card1Value1.setText("Students");
                card1Value2.setText(itemViewModel.get(1).studentsAvg);
                backward1.setText("avg.");
                card2Value1.setText("Earnings");
                card2Value2.setText(itemViewModel.get(1).earnings);
                if (isPro) {
                    front2.setVisibility(View.VISIBLE);
                    backward2.setVisibility(View.GONE);
                }else {
                    backward2.setText("$");
                }
                break;
            case 2:
                chart1Title.setText("Avg. Practice");
                chart2Title.setText("Awards");
                card1.setBackgroundResource(R.drawable.background_gradient_yellow_orange);
                card2.setBackgroundResource(R.drawable.background_gradient_light_deep_green);
                card1Value1.setText("Practice");
                card1Value2.setText(itemViewModel.get(2).practice);
                backward1.setText("hrs/wk");
                card2Value1.setText("Awards");
                card2Value2.setText(itemViewModel.get(2).achievements);
                backward2.setText("total.");
                break;
        }
    }

    private void clickToSelectPeriod(View card) {
        card.setOnClickListener(v -> {
            insightsFragment.initPeriodDialog();
        });
    }

    private void initChart() {
        FuncUtils.initWebViewSetting(chart1, "file:///android_asset/web/chart.html");
        FuncUtils.initWebViewSetting(chart2, "file:///android_asset/web/chart.html");
        WebHost webHost = new WebHost(insightsFragment.getContext());
        chart1.addJavascriptInterface(webHost, "js");
        chart2.addJavascriptInterface(webHost, "js");

        initWebViewClient(chart1, chartDataJson1.toString());
        initWebViewClient(chart2, chartDataJson2.toString());
    }
    private void initWebViewClient(SLWebView webView, String chartDataJsonStr){
        webView.setWebViewClient(new WebViewClient() {
            // 该方法可对前端界面url进行拦截,实现源生与前端H5界面的数据互换
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return true;
            }

            @Override
            public void onReceivedError(WebView view, int errorCode, String description,
                                        String failingUrl) {
                super.onReceivedError(view, errorCode, description, failingUrl);
            }

            @Override
            public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
                super.onReceivedSslError(view, handler, error);
            }

            @Override
            public void onLoadResource(WebView view, String url) {
                super.onLoadResource(view, url);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return super.shouldOverrideUrlLoading(view, request);
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                if (isPro) {

                //    view.evaluateJavascript("initChart(" + year + "," + month + "," + date + "," + (2 * position + (int)webView.getTag()) + ")", value -> {});
//                    Logger.e("-**-*-*-*-*-*-*-  json: " + chartDataJsonStr);
                    view.evaluateJavascript("initChart(" + chartDataJsonStr + ")", value -> {});
                }else {
                    view.evaluateJavascript("initChart()", value -> {});
                }
            }
        });
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        super.destroyItem(container, position, object);
    }

    public void resetPeriod(String period) {
        card1Value2.setText(period);
    }

    public void updateHourAndCapacityCardValue(String duration, String capacity,
                                               List<String> workHourChartData, List<String> capacityChartData) {

        bindingElements(_bindingTeaching);
        card1Value2.setText(duration);
        card2Value2.setText(capacity);

        year = Integer.parseInt(TimeUtils.getFormatYear(viewModel.rangeStartTime));
        month = Integer.parseInt(TimeUtils.getFormatMonth(viewModel.rangeStartTime));
        date = Integer.parseInt(TimeUtils.getFormatDate(viewModel.rangeStartTime));
        charData1 = new String[workHourChartData.size()];
        workHourChartData.toArray(charData1);
        charData2 = new String[capacityChartData.size()];
        capacityChartData.toArray(charData2);

        Logger.e("hour: " + duration + ", capacity: " + capacity);
        Logger.e("---- teaching range start: " + year + "/" + month + "/" + date);
        Logger.e("---- teaching hour: " + Arrays.toString(charData1) + ". size: " + charData1.length);
        Logger.e("---- teaching capacity: " + Arrays.toString(charData2) + ". size: " + charData2.length);

        initChartData(0);
    }

    public void updateStudentAndEarningCardValue(String averageStudentsCount, String totalEarning, List<String> studentsChartData, List<String> earningsChartData) {
        bindingElements(_bindingEarning);
        card1Value2.setText(averageStudentsCount);
        card2Value2.setText(totalEarning);

        year = Integer.parseInt(TimeUtils.getFormatYear(viewModel.rangeStartTime));
        month = Integer.parseInt(TimeUtils.getFormatMonth(viewModel.rangeStartTime));
        date = Integer.parseInt(TimeUtils.getFormatDate(viewModel.rangeStartTime));
        charData1 = new String[studentsChartData.size()];
        studentsChartData.toArray(charData1);
        charData2 = new String[earningsChartData.size()];
        earningsChartData.toArray(charData2);

        Logger.e("students: " + averageStudentsCount + ", earnings: " + totalEarning);
        Logger.e("---- earning range start: " + year + "/" + month + "/" + date);
        Logger.e("---- earning students: " + Arrays.toString(charData1) + ". size: " + charData1.length);
        Logger.e("---- earning earnings: " + Arrays.toString(charData2) + ". size: " + charData2.length);

        initChartData(3);
    }
}
