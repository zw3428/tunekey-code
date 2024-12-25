package com.spelist.tunekey.ui.student.sLessons.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonDetailsVM;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class StudentLessonAchievementItemViewModel<VM extends BaseViewModel> extends ItemViewModel<VM> {
    public ObservableField<String> title = new ObservableField<>();
    public ObservableField<String> achievement = new ObservableField<>();
    public ObservableField<String> type = new ObservableField<>();
    public ObservableField<Integer> leftImgIcon = new ObservableField<Integer>();
    public AchievementEntity achievementEntity;

    public StudentLessonAchievementItemViewModel(@NonNull VM vm, AchievementEntity achievementEntity) {
        super(vm);
        this.achievementEntity = achievementEntity;
        setData();
    }
    private void setData(){
        title.set(achievementEntity.getName());
        achievement.set(achievementEntity.getDesc());
        type.set(achievementEntity.getTypeString() + ": ");
        leftImgIcon.set(achievementEntity.getImage());
    }



}
