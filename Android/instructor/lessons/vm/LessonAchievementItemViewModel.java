package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.view.View;

import androidx.annotation.DrawableRes;
import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.AchievementEntity;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class LessonAchievementItemViewModel extends ItemViewModel<LessonDetailsVM> {
    public ObservableField<String> title = new ObservableField<>();
    public ObservableField<String> achievement = new ObservableField<>();
    public ObservableField<String> type = new ObservableField<>();
    public ObservableField<Integer> leftImgIcon = new ObservableField<Integer>();
    public AchievementEntity achievementEntity;

    public LessonAchievementItemViewModel(@NonNull LessonDetailsVM viewModel, AchievementEntity achievementEntity) {
        super(viewModel);
        this.achievementEntity = achievementEntity;
        setData();
    }
    public void setData(){
        title.set(achievementEntity.getName());
        achievement.set(achievementEntity.getDesc());
        type.set(achievementEntity.getTypeString() + ": ");
        leftImgIcon.set(achievementEntity.getImage());
    }

    public BindingCommand<View> clickItem = new BindingCommand<>(view -> {

//        viewModel.achievementChecked(5, achievementEntity);

        viewModel.clickAchievementItem(achievementEntity);
    });


}
