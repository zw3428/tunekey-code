package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.ToastUtils;
import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

public class UpgradPromptViewModel extends BaseViewModel {
    public SingleLiveEvent<String> itemClickEvent = new SingleLiveEvent<>();
    public UpgradPromptViewModel(@NonNull Application application) {
        super(application);

        for (int i = 1; i <= 3; i++) {
            UpgradPromptItemViewModel itemViewModel = new UpgradPromptItemViewModel(this, "第" + i + "个页面");
            items.add(itemViewModel);
        }
    }

    public ObservableList items = new ObservableArrayList<>();
    public ItemBinding<UpgradPromptViewModel> itemBinding = ItemBinding.of(BR.viewModel, R.layout.address_book_layout);
    public final BindingViewPagerAdapter.PageTitles<UpgradPromptViewModel> pageTitles = new BindingViewPagerAdapter.PageTitles<UpgradPromptViewModel>() {
        @Override
        public CharSequence getPageTitle(int position, UpgradPromptViewModel item) {
            return "条目" + position;
        }
    };

    //ViewPager切换监听
    public BindingCommand<Integer> onPageSelectedCommand = new BindingCommand<>(new BindingConsumer<Integer>() {
        @Override
        public void call(Integer index) {
            ToastUtils.showShort("ViewPager切换：" + index);
        }
    });

}
