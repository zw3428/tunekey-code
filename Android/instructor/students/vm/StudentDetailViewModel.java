package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;

import com.spelist.tools.viewModel.ToolbarViewModel;

public class StudentDetailViewModel extends ToolbarViewModel {


    public StudentDetailViewModel(@NonNull Application application) {
        super(application);
    }

   // public StudentDetailViewModel.UIClickObservable uc = new StudentDetailViewModel.UIClickObservable();

    @Override
    public void initToolbar() {
        setNormalToolbar("Student details");
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }
}
