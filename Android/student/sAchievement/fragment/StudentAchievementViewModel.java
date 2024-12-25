package com.spelist.tunekey.ui.student.sAchievement.fragment;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableInt;
import androidx.databinding.ObservableList;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

public class StudentAchievementViewModel extends BaseViewModel {

    public ObservableInt emptyLayoutVisibility = new ObservableInt();
    public long rangeStartTime = TimeUtils.addDay(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis(), -7);
    public long rangeEndTime = TimeUtils.getTwelveTimeOfDay(System.currentTimeMillis());
    public StudentAchievementViewModel(@NonNull Application application) {
        super(application);
        for (int i = 0;i < 2;i++) {
            StudentAchievementItemViewModel itemViewModel = new StudentAchievementItemViewModel(this, i);
            items.add(itemViewModel);
        }
    }

    public UIEventObservable uc = new UIEventObservable();

    public class UIEventObservable {

    }

    public ObservableList<StudentAchievementItemViewModel> items = new ObservableArrayList<>();

    public ItemBinding<StudentAchievementItemViewModel> itemBinding = ItemBinding.of((itemBinding
            , position, item) -> {
                switch (position) {
                    case 0:
                        itemBinding.set(BR.itemAchievementViewModel, R.layout.fragment_student_achievement_item1);
                        break;
                    case 1:
                        itemBinding.set(BR.itemAchievementViewModel, R.layout.fragment_student_achievement_item2);
                        break;
                }
            });

    //给ViewPager添加PageTitle
    public final BindingViewPagerAdapter.PageTitles<StudentAchievementItemViewModel> pageTitles = (position, item) -> {
        String title = "";
        if (position == 0) {
            title = "Practice";
        } else if (position == 1) {
            title = "Milestones";
        }
        return title;
    };

    public BindingCommand<Integer> onPageSelectedCommand =
            new BindingCommand<>(index -> {
                if (index == 0) {
                    // log
                } else if (index == 1) {
                    // metronome
                }
            });

}
