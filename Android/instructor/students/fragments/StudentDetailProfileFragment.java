package com.spelist.tunekey.ui.teacher.students.fragments;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentDetailProfileBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.addLessonType.AddLessonDetailActivity;
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailProfileFragmentViewModel;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * A simple {@link Fragment} subclass.
 */
public class StudentDetailProfileFragment extends BaseFragment<FragmentStudentDetailProfileBinding, StudentDetailProfileFragmentViewModel> {
    private boolean isEdit;
    public StudentListEntity studentListEntity = new StudentListEntity();

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_detail_profile;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getContext());
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
//        binding.rvLesson.setLayoutManager(linearLayoutManager);
        //添加Android自带的分割线
        binding.addLesson.setVisibility(View.GONE);
        isEdit = true;
        viewModel.setData(studentListEntity);

    }

    @Override
    public void initViewObservable() {
        viewModel.uc.edit.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                if (isEdit) {
                    binding.edit.setText("Done");
                    binding.addLesson.setVisibility(View.VISIBLE);
//                    viewModel.setImage(true);
                    isEdit = false;
                } else {
                    binding.edit.setText("Edit");
                    binding.addLesson.setVisibility(View.GONE);
//                    viewModel.setImage(false);
                    isEdit = true;
                }
            }
        });

        viewModel.uc.clickAddLessonType.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                Intent intent = new Intent(getActivity(), AddLessonDetailActivity.class);
                intent.putExtra("page", "3");
                startActivity(intent);
            }
        });
    }
}
