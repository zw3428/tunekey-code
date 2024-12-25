package com.spelist.tunekey.ui.student.sAchievement.adapter;

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
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tools.custom.SLWebView;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentAchievementItem1Binding;
import com.spelist.tunekey.databinding.FragmentStudentAchievementItem2Binding;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementFragment;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementItemViewModel;
import com.spelist.tunekey.ui.student.sAchievement.fragment.StudentAchievementViewModel;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;

import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;

public class ViewPagerBindingAdapter extends BindingViewPagerAdapter<StudentAchievementItemViewModel> {
    public StudentAchievementFragment studentAchievementFragment;
    public ObservableList<StudentAchievementItemViewModel> itemViewModels;
    public StudentAchievementViewModel viewModel;
    public SLWebView chart1;
    public SLWebView chart2;
    public LinearLayout card1;
    public LinearLayout card2;
    public TextView card1Value1;
    public TextView card1Value2;
    public TextView card2Value1;
    public TextView card2Value2;
    public ImageView lock1;
    public ImageView lock2;
    public TextView front1;
    public TextView front2;
    public TextView backward1;
    public TextView backward2;
    public int year;
    public int month;
    public int date;
    public JSONObject chartDataJson1 = new JSONObject();
    public JSONObject chartDataJson2 = new JSONObject();

    // chartData 模拟数据
    public int[] charData1 = {6,5,8,4,9};
    public int[] charData2 = {3,5,7,4,7};

    public ViewPagerBindingAdapter(StudentAchievementFragment studentAchievementFragment,
                                   ObservableList<StudentAchievementItemViewModel> itemViewModels) {
        this.studentAchievementFragment = studentAchievementFragment;
        this.itemViewModels = itemViewModels;
    }

    @Override
    public void onBindBinding(final ViewDataBinding binding, int variableId, int layoutRes, final int position, StudentAchievementItemViewModel item) {
        super.onBindBinding(binding, variableId, layoutRes, position, item);

        if (position == 0) {
            FragmentStudentAchievementItem1Binding _binding = (FragmentStudentAchievementItem1Binding) binding;
            chart1 = _binding.chartWeb1;
            chart2 = _binding.chartWeb2;
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

            year = 2019;
            month = 12;
            date = 15;

            initChart();
            initPracticeCard();

        }else if(position == 1) {
            FragmentStudentAchievementItem2Binding _binding = (FragmentStudentAchievementItem2Binding) binding;
            card1 = (LinearLayout) _binding.card1;
            card2 = (LinearLayout) _binding.card2;
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

            initMileStoneCard();

            itemViewModels.get(1).linearLayoutManager.set(new LinearLayoutManager(studentAchievementFragment.getContext()));
        }

        lock1.setVisibility(View.GONE);
        lock2.setVisibility(View.GONE);
    }

    private void initPracticeCard() {
        card1.setBackgroundResource(R.drawable.background_gradient_pink_purple);
        card2.setBackgroundResource(R.drawable.background_gradient_green_blue);
        card1Value1.setText(itemViewModels.get(0).period);
        card1Value2.setText(itemViewModels.get(0).duration);
        backward1.setText("hrs");
        card2Value1.setText(R.string.sessions);
        card2Value2.setText(itemViewModels.get(0).session);
        backward2.setText("wk");
    }

    @SuppressLint("SetTextI18n")
    private void initMileStoneCard() {
        card1.setBackgroundResource(R.drawable.background_gradient_purple_blue);
        card2.setBackgroundResource(R.drawable.background_gradient_orange_yellow);
        card1Value1.setText(R.string.achievements);
        card1Value2.setText(itemViewModels.get(1).totalAchievements);
        backward1.setText("total");
        card2Value1.setText(R.string.top_rated);
        card2Value2.setText(R.string.technique);
        backward2.setText(" ");
    }

    private void initChart() {
        initJsonData(year, month, date, 7, Arrays.toString(charData1), chartDataJson1);
        initJsonData(year, month, date, 8, Arrays.toString(charData2), chartDataJson2);

        FuncUtils.initWebViewSetting(chart1, "file:///android_asset/web/chart.html");
        FuncUtils.initWebViewSetting(chart2, "file:///android_asset/web/chart.html");
        WebHost webHost = new WebHost(studentAchievementFragment.getContext());
        chart1.addJavascriptInterface(webHost, "js");
        chart2.addJavascriptInterface(webHost, "js");
        initWebviewClient(chart1, chartDataJson1.toString());
        initWebviewClient(chart2, chartDataJson2.toString());
    }

    @SuppressLint("JavascriptInterface")
    private void initJsonData(int year, int month, int date, int type, String charData, JSONObject data) {
        try {
            data.put("year", year);
            data.put("month", month);
            data.put("date", date);
            data.put("type", type);
            data.put("data", charData);
        } catch (JSONException e) {}
    }

    private void initWebviewClient(SLWebView chart, String chartDataJsonStr) {
        chart.setWebViewClient(new WebViewClient() {

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
                view.evaluateJavascript("initChart(" + chartDataJsonStr + ")", value -> {});
            }
        });
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        super.destroyItem(container, position, object);
    }
}
