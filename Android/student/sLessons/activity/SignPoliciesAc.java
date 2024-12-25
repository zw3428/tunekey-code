package com.spelist.tunekey.ui.student.sLessons.activity;

import android.os.Bundle;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.SignPoliciesDialog;
import com.spelist.tunekey.databinding.ActivitySignPoliciesBinding;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.student.sLessons.vm.SignPoliciesVM;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class SignPoliciesAc extends BaseActivity<ActivitySignPoliciesBinding, SignPoliciesVM> {


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_sign_policies;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        PolicyEntity policiesData = (PolicyEntity) getIntent().getSerializableExtra("policiesData");
        StudentListEntity studentData = (StudentListEntity) getIntent().getSerializableExtra("studentData");
        viewModel.initData(policiesData,studentData);

    }

    @Override
    public void initView() {
        super.initView();
        binding.signButton.setEnabled(false);
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.isCheck.observe(this,isCheck -> {
            binding.signButton.setEnabled(isCheck);
        });
        viewModel.uc.clickSignNow.observe(this,aVoid -> {
            SignPoliciesDialog dialog = new SignPoliciesDialog(SignPoliciesAc.this);
            BasePopupView popupView = new XPopup.Builder(this)
                    .isDestroyOnDismiss(true)
                    .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(false)
                    .asCustom(dialog)
                    .show();
            dialog.setClickListener((bitmap) -> {
                viewModel.uploadSign(bitmap);
                binding.signImg.setImageBitmap(bitmap);

            });
        });
    }
}