package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.entity.LessonScheduleAssignmentEntity;
import com.spelist.tunekey.entity.LessonSchedulePlanEntity;
import com.spelist.tunekey.entity.TKPractice;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class LessonHomeworkItemViewModel extends ItemViewModel<LessonDetailsVM> {
    public ObservableField<String> plan = new ObservableField<>();
    public ObservableField<Boolean> unChecked = new ObservableField<>();
    public ObservableField<Boolean> checked = new ObservableField<>();
    public TKPractice practice;

    public LessonHomeworkItemViewModel(@NonNull LessonDetailsVM viewModel, TKPractice practice) {
        super(viewModel);
        this.practice = practice;
        this.plan.set(practice.getName());
        if (practice.isDone()) {
            unChecked.set(false);
            checked.set(true);
        } else {
            unChecked.set(true);
            checked.set(false);
        }

    }

    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {

//        viewModel.homeworkChecked(type, lessonScheduleAssignmentEntity);
        viewModel.clickEditHomework(practice);
    });

    public BindingCommand<View> isDone = new BindingCommand<>(view -> {
        Logger.e("11111");

    });


}
