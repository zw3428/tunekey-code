package com.spelist.tunekey.ui.teacher.students.activity;

import android.os.Bundle;

import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityNotesBinding;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.ui.teacher.students.vm.NotesViewModel;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;

public class NotesActivity extends BaseActivity<ActivityNotesBinding, NotesViewModel> {
    private BaseTitleViewModel baseTitleViewModel;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_notes;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initData() {
        Bundle bundle = getIntent().getExtras();
        assert bundle != null;
        if ( bundle.getSerializable("data") !=null){
            viewModel.data = (List<LessonScheduleEntity>) bundle.getSerializable("data");

            viewModel.initData();
        }else {
            viewModel.studentId =  bundle.getString("studentId");
            viewModel.getData();
        }

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvNotes.setLayoutManager(linearLayoutManager);
    }
}
