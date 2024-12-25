package com.spelist.tunekey.ui.student.sAchievement.fragment;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;

public class StudentAchievementMilestoneViewModel extends ItemViewModel {

    public ObservableField<String> date = new ObservableField<>("date");
    public ObservableField<String> typeName = new ObservableField<String>("");
    public MutableLiveData<Integer> typeIcon = new MutableLiveData<>();
//    public ObservableField<Integer> typeIcon = new ObservableField<>();
    public ObservableField<String> title = new ObservableField<>("title");
    public ObservableField<String> content = new ObservableField<>("content");

    public StudentAchievementMilestoneViewModel(@NonNull BaseViewModel viewModel, AchievementEntity achievementEntity) {
        super(viewModel);
        this.date.set(TimeUtils.timeFormat(achievementEntity.getShouldDateTime(),"MMM dd"));
        this.title.set(achievementEntity.getName());
        this.content.set(achievementEntity.getDesc());
        this.typeName.set(achievementEntity.getTypeString());
        this.typeIcon.setValue(achievementEntity.getImage());
    }

    public StudentAchievementMilestoneViewModel(@NonNull BaseViewModel viewModel, String date, int type, String title, String content) {
        super(viewModel);


    }
}
