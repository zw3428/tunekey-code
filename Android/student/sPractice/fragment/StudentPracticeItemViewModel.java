package com.spelist.tunekey.ui.student.sPractice.fragment;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class StudentPracticeItemViewModel extends ItemViewModel<StudentPracticeViewModel> {

    public MutableLiveData<String> date = new MutableLiveData<>();
    public MutableLiveData<String> timeLength = new MutableLiveData<>();

    public StudentPracticeItemViewModel(@NonNull StudentPracticeViewModel viewModel, int position) {
        super(viewModel);
        if (position == 1) {

        }
    }

    public StudentPracticeItemViewModel(@NonNull StudentPracticeViewModel viewModel, String date, String timeLength) {
        super(viewModel);
        this.date.setValue(date);
        this.timeLength.setValue(timeLength);
    }

    public BindingCommand clickLog = new BindingCommand(() -> {
//            viewModel.uc.clickLog.setValue(text);
        viewModel.uc.clickLog.call();
    });

    public BindingCommand clickPractice = new BindingCommand(() -> {
//            viewModel.uc.clickLog.setValue(text);
        viewModel.uc.clickPractice.call();
    });
}