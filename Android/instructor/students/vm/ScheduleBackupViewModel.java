package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;

import com.spelist.tools.viewModel.ToolbarViewModel;

import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class ScheduleBackupViewModel extends ToolbarViewModel {
    //封装一个点击事件观察者
    public ScheduleBackupViewModel.UIClickObservable uc = new ScheduleBackupViewModel.UIClickObservable();

    public ScheduleBackupViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Schedule");
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public class UIClickObservable {

        public SingleLiveEvent<Void> weekly1 = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> weekly2 = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recBiWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recMonthly = new SingleLiveEvent<>();
    }

    public BindingCommand weekly1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.weekly1.call();
        }
    });

    public BindingCommand weekly2 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.weekly2.call();
        }
    });

    public BindingCommand recWeekly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recWeekly.call();
        }
    });

    public BindingCommand recBiWeekly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recBiWeekly.call();
        }
    });

    public BindingCommand recMonthly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recMonthly.call();
        }
    });
}
