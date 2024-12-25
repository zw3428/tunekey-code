package com.spelist.tunekey.ui.student.sAchievement.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentAchievementItem2Binding;
import com.spelist.tunekey.ui.student.sAchievement.vm.MilestonesInsightVM;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * com.spelist.tunekey.ui.sAchievement.fragment
 * 2021/6/2
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MilestonesInsightFragment extends BaseFragment<FragmentStudentAchievementItem2Binding, MilestonesInsightVM> {
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
        return R.layout.fragment_student_achievement_item2;
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



    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.card1.setBackgroundResource(R.drawable.background_gradient_purple_blue);
        binding.card2.setBackgroundResource(R.drawable.background_gradient_orange_yellow);
    }
}
