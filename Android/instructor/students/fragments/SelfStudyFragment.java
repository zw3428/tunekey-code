package com.spelist.tunekey.ui.teacher.students.fragments;


import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentPracticeBinding;
import com.spelist.tunekey.ui.teacher.addLessonType.Lesson;
import com.spelist.tunekey.ui.teacher.students.adapter.SelfStudyFragmentAdapter;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.base.BaseViewModel;

/**
 * A simple {@link Fragment} subclass.
 */
public class SelfStudyFragment extends BaseFragment<FragmentPracticeBinding, BaseViewModel> {
    private List<Lesson> list = new ArrayList<>();

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_practice;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();

        for (int i = 0; i < 2; i++) {
            list.add(new Lesson("July 17 - 24", R.mipmap.calendar));

        }

        LinearLayoutManager layoutManager = new LinearLayoutManager(getActivity().getApplication());
        binding.rvSelfStudy.setLayoutManager(layoutManager);
        SelfStudyFragmentAdapter adapter = new SelfStudyFragmentAdapter(getActivity(), list);
        binding.rvSelfStudy.setAdapter(adapter);
    }


}
