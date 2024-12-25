package com.spelist.tunekey.ui.student.sAchievement.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Observer;

import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentAchievementBinding;
import com.spelist.tunekey.ui.toolsView.base.BaseFragmentPagerAdapter;
import com.spelist.tunekey.ui.teacher.insights.dialog.DialogSelectPeriod;
import com.spelist.tunekey.ui.teacher.insights.dialog.DialogSelectRangeType;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;

public class StudentAchievementFragment extends BaseFragment<FragmentStudentAchievementBinding, StudentAchievementViewModel> {

    private BaseTitleViewModel baseTitleViewModel;


    private PracticeInsightFragment practiceInsightFragment = new PracticeInsightFragment();
    private MilestonesInsightFragment milestonesInsightFragment = new MilestonesInsightFragment();

    public DialogSelectPeriod dialogSelectPeriod;
    public FragmentManager fragmentManager;
    public DialogSelectRangeType dialogSelectRangeType;

    private List<Fragment> fragments = new ArrayList<>();
    private List<String> titleList = new ArrayList<>();
    public BaseFragmentPagerAdapter pagerAdapter;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_achievement;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        fragments.add(practiceInsightFragment);
        fragments.add(milestonesInsightFragment);

        titleList.add("Practice");
        titleList.add("Milestones");
        baseTitleViewModel = new BaseTitleViewModel(getActivity().getApplication());
        binding.setVariable(BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set("Insight");
        baseTitleViewModel.rightFirstImgVisibility.set(View.VISIBLE);
        binding.titleLayout.titleRightFirstImg.setImageResource(R.mipmap.ic_calendar);
        viewModel.emptyLayoutVisibility.set(View.GONE);

        pagerAdapter = new BaseFragmentPagerAdapter(getChildFragmentManager(), fragments, titleList);
        binding.viewPager.setAdapter(pagerAdapter);
        binding.viewPager.setOffscreenPageLimit(2);
        binding.secondTitleTabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.setScroll(false);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.secondTitleTabs));
        binding.secondTitleTabs.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                baseTitleViewModel.rightFirstImgVisibility.set(tab.getPosition() == 0 ? View.VISIBLE : View.INVISIBLE);
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {

            }
        });
    }

    @Override
    public void initViewObservable() {
        baseTitleViewModel.uc.clickRightFirstImgButton.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                initSelectInsightRangeTypeDialog();

            }
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

                dialogSelectRangeType.dismissDialog();
                refTime();
            }
        });

    }

    private void refTime() {
        if (getActivity()==null){
            return;
        }
        getActivity().runOnUiThread(() -> {
            practiceInsightFragment.update(viewModel.rangeStartTime,viewModel.rangeEndTime);
        });


    }

//    public void initPeriodDialog() {
//        if (dialogSelectPeriod == null) {
//            dialogSelectPeriod = new DialogSelectPeriod();
//            fragmentManager = Objects.requireNonNull(getActivity()).getSupportFragmentManager();
//        }
//
//        assert dialogSelectPeriod != null;
//
//
//        if (!dialogSelectPeriod.isAdded()) {
//            dialogSelectPeriod.show(fragmentManager, "DialogFragment");
//        }
//
//        dialogSelectPeriod.setDialogCallback(period -> Objects.requireNonNull(getActivity()).runOnUiThread(() -> {
//
//            dialogSelectPeriod.dismissDialog();
//        }));
//    }
}
