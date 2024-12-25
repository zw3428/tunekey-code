package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * @author zw, Created on 2020-01-23
 */
public class AddBlockViewModel extends ToolbarViewModel {

    public MutableLiveData<String> startDateAndTime = new MutableLiveData<>();
    public MutableLiveData<String> endDateAndTime = new MutableLiveData<>();
    public DialogSelectDateAndTime dialogSelectDateAndTime;

    public AddBlockViewModel(@NonNull Application application) {
        super(application);
        initDefaultDataAndTime();
    }

    private void initDefaultDataAndTime() {
        long timeStamp = System.currentTimeMillis() / 1000;
        startDateAndTime.setValue(TimeUtils.getDateMonthYearAndTime(timeStamp + ""));
        endDateAndTime.setValue(TimeUtils.getDateMonthYearAndTime(timeStamp + 60 * 60 + ""));
    }

    @Override
    public void initToolbar() {
        setTitleString("Add Block");
        setLeftImgButtonVisibility(View.VISIBLE);
        setLeftButtonIcon(R.mipmap.ic_back_primary);
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public class UIEventObservable {
        public SingleLiveEvent<Void> selectStart = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> selectEnd = new SingleLiveEvent<>();
    }

    public UIEventObservable uc = new UIEventObservable();

    public BindingCommand selectStart = new BindingCommand(() -> uc.selectStart.call());
    public BindingCommand selectEnd = new BindingCommand(() -> uc.selectEnd.call());
}
