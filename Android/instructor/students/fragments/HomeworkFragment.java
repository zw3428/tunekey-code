package com.spelist.tunekey.ui.teacher.students.fragments;


import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentHomeworkBinding;
import com.spelist.tunekey.entity.StudentHomeworkEntity;
import com.spelist.tunekey.ui.teacher.students.adapter.HomeworkFragmentAdapter;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.base.BaseViewModel;


/**
 * A simple {@link Fragment} subclass.
 */
public class HomeworkFragment extends BaseFragment<FragmentHomeworkBinding,BaseViewModel> {


    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_homework;
    }

    @Override
    public void initData() {
        super.initData();

    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }
    public void getDate(List<StudentHomeworkEntity> list){

        LinearLayoutManager layoutManager = new LinearLayoutManager(getActivity());
        binding.rvHomework.setLayoutManager(layoutManager);
        HomeworkFragmentAdapter adapter = new HomeworkFragmentAdapter(getActivity(),list);
        binding.rvHomework.setAdapter(adapter);
    }


}
