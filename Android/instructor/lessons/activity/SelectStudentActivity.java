package com.spelist.tunekey.ui.teacher.lessons.activity;

import androidx.recyclerview.widget.LinearLayoutManager;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;

import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivitySelectStudent2Binding;
import com.spelist.tunekey.ui.teacher.lessons.vm.SelectStudentViewModel;

import me.goldze.mvvmhabit.base.BaseActivity;

public class SelectStudentActivity extends BaseActivity<ActivitySelectStudent2Binding, SelectStudentViewModel> {


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_select_student2;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initData() {
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this.getApplication());
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvSelectStudent.setLayoutManager(linearLayoutManager);
        viewModel.getStudentList();
    }

    @Override
    public void initViewObservable() {

        viewModel.addStudent.observe(this, value -> {
            Intent intent = new Intent(this, AddLessonStepActivity.class);
            intent.putExtra("list", value);
            startActivity(intent);
            finish();
        });
    }

    @Override
    public void initView() {
        super.initView();
        binding.rvSelectStudent.setItemAnimator(null);
        binding.search.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                viewModel.search(s.toString());
            }
        });
        binding.close.setOnClickListener(view -> {
            binding.search.setText("");
        });
    }
}
