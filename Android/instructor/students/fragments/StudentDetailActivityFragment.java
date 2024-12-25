package com.spelist.tunekey.ui.teacher.students.fragments;


import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.GridLayoutManager;

import android.view.LayoutInflater;
import android.view.ViewGroup;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentDetailActivityBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.students.activity.AchievementActivity;
import com.spelist.tunekey.ui.teacher.students.activity.NotesActivity;
import com.spelist.tunekey.ui.teacher.students.activity.PracticeActivity;
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailActivityFragmentViewModel;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * A simple {@link Fragment} subclass.
 */
public class StudentDetailActivityFragment extends BaseFragment<FragmentStudentDetailActivityBinding, StudentDetailActivityFragmentViewModel> {
    public StudentListEntity studentListEntity = new StudentListEntity();

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_detail_activity;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        viewModel.getStudentList();
        GridLayoutManager gridLayoutManager = new GridLayoutManager(getContext(), 3);
        viewModel.setDate(studentListEntity);
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();

        viewModel.uc.linPractice.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                startActivity(PracticeActivity.class);
            }
        });
        viewModel.uc.linAchievement.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                startActivity(AchievementActivity.class);
            }
        });
        viewModel.uc.linNotes.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                startActivity(NotesActivity.class);
            }
        });
        viewModel.uc.linMaterials.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                startActivity(PracticeActivity.class);
            }
        });
    }

}
