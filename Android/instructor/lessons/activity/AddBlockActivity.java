package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.os.Bundle;

import androidx.fragment.app.FragmentManager;

import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityAddBlockBinding;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.ui.teacher.lessons.vm.AddBlockViewModel;

import me.goldze.mvvmhabit.base.BaseActivity;

public class AddBlockActivity extends BaseActivity<ActivityAddBlockBinding, AddBlockViewModel> {

    private DialogSelectDateAndTime dialogSelectDateAndTime;
    private FragmentManager fragmentManager;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_add_block;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.selectStart.observe(this, aVoid -> {
           // initSelectDateAndTimeDialog(0);
        });

        viewModel.uc.selectEnd.observe(this, aVoid -> {
           // initSelectDateAndTimeDialog(1);
        });
    }

    @Override
    public void initData() {
        binding.createButton.setOnClickListener(v -> {
//            SLToast.info("create block");
        });
    }

//    public void initSelectDateAndTimeDialog(int type) {
//        if (dialogSelectDateAndTime == null && fragmentManager == null) {
//            dialogSelectDateAndTime = new DialogSelectDateAndTime(this, type);
//            fragmentManager = this.getSupportFragmentManager();
//        }
//        viewModel.dialogSelectDateAndTime = dialogSelectDateAndTime;
//
//        if (!dialogSelectDateAndTime.isAdded()) {
//            dialogSelectDateAndTime.show(fragmentManager, "DialogFragments");
//        }
//
//        dialogSelectDateAndTime.setDialogCallback(new DialogSelectDateAndTime.DialogCallback() {
//            @Override
//            public void getDateAndTime() {
//
//            }
//        });
//
//    }
}
