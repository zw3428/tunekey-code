package com.spelist.tunekey.ui.teacher.insights.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentInsightsBinding;
import com.spelist.tunekey.ui.toolsView.base.BaseFragmentPagerAdapter;
import com.spelist.tunekey.ui.teacher.insights.dialog.DialogSelectPeriod;
import com.spelist.tunekey.ui.teacher.insights.dialog.DialogSelectRangeType;
import com.spelist.tunekey.ui.teacher.insights.vm.InsightsViewModel;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * Author WHT
 * Description:
 * Date :2019-10-07
 */
public class InsightsFragment extends BaseFragment<FragmentInsightsBinding, InsightsViewModel> {


    private TeachingFragment teachingFragment = new TeachingFragment();
    private EarningsFragment earningsFragment = new EarningsFragment();
    private LearningFragment learningFragment = new LearningFragment();

    public DialogSelectPeriod dialogSelectPeriod;
    public FragmentManager fragmentManager;
    public DialogSelectRangeType dialogSelectRangeType;

    private List<Fragment> fragments = new ArrayList<>();
    private List<String> titleList = new ArrayList<>();
    public BaseFragmentPagerAdapter pagerAdapter;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_insights;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initData() {


    }

    @Override
    public void initView() {
        super.initView();
        fragments.add(teachingFragment);
        fragments.add(earningsFragment);
        fragments.add(learningFragment);
        titleList.add("Teaching");
        titleList.add("Earnings");
        titleList.add("Learning");
        pagerAdapter = new BaseFragmentPagerAdapter(getChildFragmentManager(), fragments, titleList);
        binding.viewPager.setAdapter(pagerAdapter);
        binding.viewPager.setOffscreenPageLimit(3);
        binding.secondTitleTabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.setScroll(false);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.secondTitleTabs));
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.clickCal.observe(this, aVoid -> {
            initSelectInsightRangeTypeDialog();
        });
        viewModel.uc.refIsShowUploadPro.observe(this,aBoolean -> {
            teachingFragment.refIsShowData(!aBoolean);
            earningsFragment.refIsShowData(!aBoolean);
            learningFragment.refIsShowData(!aBoolean);
        });
    }

    /**
     * 初始化弹窗
     */
    private void initSelectInsightRangeTypeDialog() {

        dialogSelectRangeType = new DialogSelectRangeType(this, viewModel, viewModel.rangeStartTime, viewModel.rangeEndTime);
        fragmentManager = getActivity().getSupportFragmentManager();
        dialogSelectRangeType.show(fragmentManager, "DialogFragments");

        Calendar thisMonth = TimeUtils.getCurrentMonthStart();
        dialogSelectRangeType.setDialogCallback(new DialogSelectRangeType.DialogCallback() {
            @Override
            public void nextMonth() {
                viewModel.rangeStartTime = TimeUtils.addMonth(thisMonth.getTimeInMillis(), 1);
                viewModel.rangeEndTime = TimeUtils.addDay(TimeUtils.addMonth(viewModel.rangeStartTime, 1), -1);
                refTime();
            }

            @Override
            public void thisMonth() {
                viewModel.rangeStartTime = thisMonth.getTimeInMillis();
                viewModel.rangeEndTime =  TimeUtils.addDay(TimeUtils.addMonth(viewModel.rangeStartTime, 1), -1);
                refTime();
            }

            @Override
            public void lastMonth() {
                viewModel.rangeStartTime = TimeUtils.addMonth(thisMonth.getTimeInMillis(), -1);
                viewModel.rangeEndTime = TimeUtils.addDay(thisMonth.getTimeInMillis(), -1);
                refTime();
            }

            @Override
            public void last2Month() {
                viewModel.rangeStartTime = TimeUtils.addMonth(thisMonth.getTimeInMillis(), -1);
                viewModel.rangeEndTime = TimeUtils.addDay(TimeUtils.addMonth(thisMonth.getTimeInMillis(), 1), -1);
                refTime();
            }

            @Override
            public void last3Month() {
                viewModel.rangeStartTime = TimeUtils.addMonth(thisMonth.getTimeInMillis(), -2);
                viewModel.rangeEndTime = TimeUtils.addDay(TimeUtils.addMonth(thisMonth.getTimeInMillis(), 1), -1);
                refTime();
            }

            @Override
            public void confirmDateRange() {
                if (getActivity()==null){
                    return;
                }
                getActivity().runOnUiThread(() -> {
                    refTime();
                });

            }
        });

    }

    private void refTime() {
        teachingFragment.refData(viewModel.rangeStartTime,viewModel.rangeEndTime);
        earningsFragment.refData(viewModel.rangeStartTime,viewModel.rangeEndTime);
        learningFragment.refData(viewModel.rangeStartTime,viewModel.rangeEndTime);
    }

    public void initPeriodDialog() {
        if (getActivity() == null){
            return;
        }
        if (dialogSelectPeriod == null) {
            dialogSelectPeriod = new DialogSelectPeriod();
            fragmentManager = getActivity().getSupportFragmentManager();
        }

        assert dialogSelectPeriod != null;

        Logger.e("======= init target hour =======");

        if (!dialogSelectPeriod.isAdded()) {
            dialogSelectPeriod.show(fragmentManager, "DialogFragment");
        }

        dialogSelectPeriod.setDialogCallback(period -> getActivity().runOnUiThread(() -> {
//            viewPagerBindingAdapter.resetPeriod(period);

            dialogSelectPeriod.dismissDialog();
        }));
    }
}
