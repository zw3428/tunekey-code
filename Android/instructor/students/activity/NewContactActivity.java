package com.spelist.tunekey.ui.teacher.students.activity;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.viewpager.widget.ViewPager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityNewContactBinding;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.ui.teacher.students.adapter.NewContactAdapter;
import com.spelist.tunekey.ui.teacher.students.fragments.NewContactFragment;
import com.spelist.tunekey.ui.teacher.students.vm.NewContactViewModel;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BindingRecyclerViewAdapter;

public class NewContactActivity extends BaseActivity<ActivityNewContactBinding, NewContactViewModel> implements ViewPager.OnPageChangeListener {

    public List<AddressBookEntity> titleList = new ArrayList<>();
    public List<NewContactFragment> fragmentList = new ArrayList<>();
    public int pos = 0;
    BindingRecyclerViewAdapter adapter = new BindingRecyclerViewAdapter();
    public boolean isComplete = false;
    private LinearLayoutManager layoutManager;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_new_contact;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        Intent intent = getIntent();
        titleList = (List<AddressBookEntity>) intent.getSerializableExtra("data");
        viewModel.addressBookEntities = titleList;

        //把fragment add进一个list里
        for (int i = 0; i < titleList.size(); i++) {
            NewContactFragment newContactFragment = new NewContactFragment();
            newContactFragment.studentId = titleList.get(i).getuId();
            newContactFragment.position = i;
            newContactFragment.contactActivity = this;

            fragmentList.add(newContactFragment);
        }
        binding.newContactViewpager.setAdapter(new NewContactAdapter(getSupportFragmentManager(), fragmentList));
        binding.newContactViewpager.addOnPageChangeListener(NewContactActivity.this);
        binding.newContactViewpager.setCurrentItem(0);
        binding.newContactViewpager.setOffscreenPageLimit(titleList.size() - 1);
    }

    /**
     * 刷新底部button
     */
    public void changeData(int pos, boolean itemIsComplete) {
        viewModel.setComplete(pos, itemIsComplete);
        boolean isComplete = true;
        for (NewContactFragment newContactFragment : fragmentList) {
            if (!newContactFragment.isComplete) {
                isComplete = false;
            }
        }
        this.isComplete = isComplete;
        if (isComplete) {
            binding.nextButton.setText("CREATE");
        } else {
            binding.nextButton.setText("NEXT");
        }
    }

    @Override
    public void initData() {
        if (viewModel.addressBookEntities != null) {
            binding.setAdapter(adapter);
            layoutManager = new LinearLayoutManager(this);
            layoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
            binding.rvHeadimg.setLayoutManager(layoutManager);
            viewModel.getData();
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        //获取第几个fragment
        fragmentList.get(binding.newContactViewpager.getCurrentItem()).onActivityResult(requestCode, resultCode, data);
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {
            LessonTypeEntity lessonTypeEntity = new LessonTypeEntity();
            lessonTypeEntity = (LessonTypeEntity) data.getSerializableExtra("lessonType");
            // viewModel.lessonId(lessonTypeEntity.getId());
            fragmentList.get(binding.newContactViewpager.getCurrentItem()).selectLessonType(lessonTypeEntity);
        } else {
            Logger.e("lose");
        }
    }

    @Override
    public void initViewObservable() {


        viewModel.clickPager.observe(this, value -> {
            binding.newContactViewpager.setCurrentItem(value);
            adapter.notifyDataSetChanged();
        });

        viewModel.uc.nextButton.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                if (isComplete) {
                    Logger.e("======完成");
                    viewModel.scheduleEntityList.clear();
                    for (NewContactFragment item : fragmentList) {
                        viewModel.scheduleEntityList.add(item.getConfig());
                    }
                    viewModel.createData();
                } else {
                    int nextPos = -1;
                    for (NewContactFragment item : fragmentList) {
                        if (pos != item.position && !item.isComplete) {
                            nextPos = item.position;
                            break;
                        }
                    }
                    if (nextPos != -1) {
                        onPageSelected(nextPos);
                    }
                }


            }
        });


    }

    @Override
    public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

    }

    //此方法是页面跳转完后得到调用，position是你当前选中的页面的Position
    @Override
    public void onPageSelected(int position) {
        viewModel.changeItem(position);
        this.pos = position;
//        layoutManager.setStackFromEnd(false);
        layoutManager.scrollToPositionWithOffset(position, 0);

    }

    @Override
    public void onPageScrollStateChanged(int state) {

    }
}
