package com.spelist.tunekey.ui.teacher.students.activity;

import androidx.fragment.app.Fragment;

import android.content.Intent;
import android.os.Bundle;

import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityStudentDetailBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.toolsView.base.BaseFragmentPagerAdapter;
import com.spelist.tunekey.ui.teacher.students.fragments.StudentDetailActivityFragment;
import com.spelist.tunekey.ui.teacher.students.fragments.StudentDetailProfileFragment;
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailViewModel;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;

public class StudentDetailActivity extends BaseActivity<ActivityStudentDetailBinding, StudentDetailViewModel> {
    List<Fragment> fragments = new ArrayList<>();
    List<String> titleList = new ArrayList<>();
    private StudentDetailProfileFragment studentDetailProfileFragment = new StudentDetailProfileFragment();
    private StudentDetailActivityFragment studentDetailActivityFragment = new StudentDetailActivityFragment();
    public BaseFragmentPagerAdapter pagerAdapter;
    private StudentListEntity studentListEntity = new StudentListEntity();

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_detail;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {

        Intent intent = getIntent();
        studentListEntity = (StudentListEntity) intent.getSerializableExtra("student");

        fragments.add(studentDetailProfileFragment);
        fragments.add(studentDetailActivityFragment);
        titleList.add("Profile");
        titleList.add("Activities");
        pagerAdapter = new BaseFragmentPagerAdapter(getSupportFragmentManager(), fragments, titleList);
        binding.viewPager.setAdapter(pagerAdapter);
        binding.viewPager.setOffscreenPageLimit(2);
        binding.tabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.tabs));
        studentDetailProfileFragment.studentListEntity = studentListEntity;
        studentDetailActivityFragment.studentListEntity = studentListEntity;

    }


}
