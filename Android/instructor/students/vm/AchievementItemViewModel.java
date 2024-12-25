package com.spelist.tunekey.ui.teacher.students.vm;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tunekey.entity.AchievementEntity;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import me.goldze.mvvmhabit.base.ItemViewModel;

public class AchievementItemViewModel extends ItemViewModel<AchievementViewModel> {
    public AchievementEntity achievementEntity;
    public ObservableField<String> date = new ObservableField<>();
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> desc = new ObservableField<>();
    public ObservableField<String> type = new ObservableField<>();
    public MutableLiveData<Integer> imgIcon = new MutableLiveData<Integer>();
    public int achType;

    public AchievementItemViewModel(@NonNull AchievementViewModel viewModel, AchievementEntity achievementEntity) {
        super(viewModel);
        this.achievementEntity = achievementEntity;
        this.date.set(timeDate(achievementEntity.getDate()));
        this.name.set(achievementEntity.getName());
        this.desc.set(achievementEntity.getDesc());
        this.achType = achievementEntity.getType();
        this.type.set(achievementEntity.getTypeString()+": ");
        imgIcon.setValue(achievementEntity.getImage());
    }

    /**
     * 调用此方法输入所要转换的时间戳输入例如（1402733340）输出（"英文月份缩写 日期"）
     *
     * @param time
     * @return
     */
    public static String timeDate(String time) {
        SimpleDateFormat sdr = new SimpleDateFormat("MMM d", Locale.ENGLISH);
        @SuppressWarnings("unused")
        int i = Integer.parseInt(time);
        String times = sdr.format(new Date(i * 1000L));
        return times;


    }
}
