package com.spelist.tunekey.ui.teacher.students.activity;

import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.inputmethod.InputMethodManager;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivitySearchBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.students.vm.SearchViewModel;

import java.util.Timer;
import java.util.TimerTask;

import me.goldze.mvvmhabit.base.BaseActivity;

public class SearchActivity extends BaseActivity<ActivitySearchBinding, SearchViewModel> {

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_search;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        binding.rvStudentList.setItemAnimator(null);
        binding.editText.setFocusable(true);
        binding.editText.setFocusableInTouchMode(true);
        binding.editText.requestFocus();
        Timer timer = new Timer();
        timer.schedule(new TimerTask() {
                           public void run() {
                               InputMethodManager inputManager =
                                       (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                               inputManager.showSoftInput(binding.editText, 0);
                           }
                       },
                200);

    }

    @Override
    public void initData() {
        super.initData();
        viewModel.getStudentList();
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvStudentList.setLayoutManager(linearLayoutManager);

        binding.editText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                viewModel.searching(String.valueOf(s));
            }
        });

    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();

        viewModel.uc.search.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {

            }
        });
        viewModel.uc.clearAll.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.editText.setText("");
            }
        });
        viewModel.studentListEntityMutableLiveData.observe(this, new Observer<StudentListEntity>() {
            @Override
            public void onChanged(StudentListEntity studentListEntity) {

                Logger.e("ooo" + studentListEntity);
                Intent intent = new Intent(getApplicationContext(), StudentDetailV2Ac.class);
                intent.putExtra("student", studentListEntity);
                startActivity(intent);
                finish();
            }
        });


    }
}
