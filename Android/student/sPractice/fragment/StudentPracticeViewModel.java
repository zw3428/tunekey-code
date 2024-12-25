package com.spelist.tunekey.ui.student.sPractice.fragment;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableInt;
import androidx.databinding.ObservableList;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

public class StudentPracticeViewModel extends BaseViewModel {

//    private Button button;

    public ObservableInt emptyLayoutVisibility = new ObservableInt();

    public UIEventObservable uc = new UIEventObservable();

    public class UIEventObservable {
        /**
         * 点击 log
         */
        public SingleLiveEvent<String> clickLog = new SingleLiveEvent<>();
        /**
         * 点击 practice
         */
        public SingleLiveEvent<String> clickPractice = new SingleLiveEvent<>();

        /**
         * Practice log data
         */
        public SingleLiveEvent<ObservableList<ItemViewModel>> practiceLogObserverData = new SingleLiveEvent<>();
    }

    public ObservableList<StudentPracticeItemViewModel> items = new ObservableArrayList<>();

    public ItemBinding<StudentPracticeItemViewModel> itemViewPagerBinding =
            ItemBinding.of((itemBinding, position, item) -> {
                switch (position) {
                    case 0:
                        itemBinding.set(BR.itemPracticeViewModel,
                                R.layout.fragment_student_practice_item1);
                        break;
                    case 1:
                        itemBinding.set(BR.itemPracticeViewModel,
                                R.layout.fragment_student_practice_item2);
                        break;
                }
            });

    public StudentPracticeViewModel(@NonNull Application application) {
        super(application);
        //ViewPager页面
        for (int i = 0; i < 2; i++) {
            StudentPracticeItemViewModel itemViewModel =
                    new StudentPracticeItemViewModel(this, i);
            items.add(itemViewModel);
        }
    }

    //给ViewPager添加PageTitle
    public final BindingViewPagerAdapter.PageTitles<StudentPracticeItemViewModel> pageTitles = (position, item) -> {
        String title = "";
        if (position == 0) {
            title = "Log";
        } else if (position == 1) {
            title = "Metronome";
        }
        return title;
    };

    //ViewPager切换监听
    public BindingCommand<Integer> onPageSelectedCommand =
            new BindingCommand<>(index -> {
                if (index == 0) {
                    // log
                } else if (index == 1) {
                    // metronome
                }
            });
}
