package com.spelist.tunekey.ui.teacher.lessons.activity;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;

import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityLessonSearchBinding;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonSearchVM;
import com.spelist.tunekey.utils.FuncUtils;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class LessonSearchAc extends BaseActivity<ActivityLessonSearchBinding, LessonSearchVM> {

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_lesson_search;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        binding.titleLayout.searchEditText.setFocusable(true);
        binding.titleLayout.searchEditText.setFocusableInTouchMode(true);
        binding.titleLayout.searchEditText.requestFocus();
        FuncUtils.toggleSoftInput(binding.titleLayout.searchEditText,true);
        binding.titleLayout.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                viewModel.search(String.valueOf(s));
            }
        });
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickCancelSearch.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.titleLayout.searchEditText.setText("");
            }
        });
    }
}