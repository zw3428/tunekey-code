package com.spelist.tunekey.ui.student.sLessons.activity;

import android.app.Dialog;
import android.os.Bundle;
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.databinding.ActivityStudentRescheduleRequestBinding;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentRescheduleRequestVM;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class StudentRescheduleRequestAc extends BaseActivity<ActivityStudentRescheduleRequestBinding, StudentRescheduleRequestVM> {


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_reschedule_request;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        viewModel.policyData = (PolicyEntity) getIntent().getSerializableExtra("policyData");
        viewModel.initData( ((List<LessonRescheduleEntity>) getIntent().getSerializableExtra("data")),(UserEntity)getIntent().getSerializableExtra("teacherData"));

    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setItemAnimator(null);
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this  ));
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickRetract.observe(this,lessonRescheduleEntity -> {
            Dialog dialog = SLDialogUtils.showTwoButton(StudentRescheduleRequestAc.this, "Retract request", "Are you sure you want to retract your reschedule request?", "Yes", "No");
            TextView leftButton = dialog.findViewById(R.id.left_button);
            leftButton.setTextColor(ContextCompat.getColor(StudentRescheduleRequestAc.this, R.color.red));

            leftButton.setOnClickListener(v -> {
                dialog.dismiss();
                viewModel.retractReschedule(lessonRescheduleEntity);
            });
        });
    }
}
