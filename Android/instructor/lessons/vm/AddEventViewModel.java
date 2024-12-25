package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import com.google.firebase.auth.FirebaseAuth;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.EventConfigEntity;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogSelectDateAndTime;
import com.spelist.tunekey.utils.MessengerUtils;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.SnowFlakeShortUrl;

public class AddEventViewModel extends ToolbarViewModel {
    public MutableLiveData<String> startDateAndTime = new MutableLiveData<>();
    public MutableLiveData<String> endDateAndTime = new MutableLiveData<>();
    public DialogSelectDateAndTime dialogSelectDateAndTime;
    public EventConfigEntity eventConfigEntity = new EventConfigEntity();
    private String inputTitle;
    private List<Integer> weekList = new ArrayList<>();
    private List<Integer> biWeekList = new ArrayList<>();

    public AddEventViewModel(@NonNull Application application) {
        super(application);
        initDefaultDataAndTime();
    }

    private void initDefaultDataAndTime() {
        long timeStamp = System.currentTimeMillis();
        startDateAndTime.setValue(TimeUtils.getNowDayAndTime(timeStamp,"HH:mm，MMM d yyyy"));
        endDateAndTime.setValue(TimeUtils.getNowDayAndTime(timeStamp+60*60*1000,"HH:mm"));

    }

    @Override
    public void initToolbar() {
        setTitleString("Add Event");
        setLeftImgButtonVisibility(View.VISIBLE);
        setLeftButtonIcon(R.mipmap.ic_back_primary);
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public void getTitle(String titleText) {
        inputTitle = titleText;
    }


    public BindingCommand<SubmitButton> submitButton = new BindingCommand<SubmitButton>(new BindingConsumer<SubmitButton>() {
        @Override
        public void call(SubmitButton submitButton) {
            setEvent(submitButton);
        }
    });

    private void setEvent(SubmitButton submitButton) {

        eventConfigEntity.setId(String.valueOf(SnowFlakeShortUrl.nextId()));
        eventConfigEntity.setTeacherId(FirebaseAuth.getInstance().getUid());
        eventConfigEntity.setTitle(inputTitle);
        eventConfigEntity.setStartDateTime(1586458800);
        eventConfigEntity.setEndDateTime(1586458800);
        eventConfigEntity.setCreateTime(System.currentTimeMillis() / 1000 + "");
        eventConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");

        Logger.e("=======开始上传=====");
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .setEventConfig(eventConfigEntity)
                        .subscribe(status -> {
                            submitButton.reset();
                            SLToast.success("Saved successfully!");
                            Messenger.getDefault().send("true", MessengerUtils.STUDENT);
                            finish();
                        }, throwable -> {
                            Logger.e("=====上传失败=" + throwable.getMessage());
                            submitButton.reset();
                            SLToast.error("！！！！！!");
                        }));



    }

    public void getRepeatType(int repeatType) {
        eventConfigEntity.setRepeatType(repeatType);

    }

    //从0开始 周日是0 以此类推
    public void getRepeatTypeWeekDay(int weekDay) {
        Boolean isAdd = true;
        for (int i = 0; i < weekList.size(); i++) {
            if (weekList.get(i) == weekDay) {
                isAdd = false;
                weekList.remove(i);
            }
        }
        if (isAdd) {
            weekList.add(weekDay);
        }
        if (eventConfigEntity.getRepeatType() == 1) {
            eventConfigEntity.setRepeatTypeWeekDay(weekList);
        }
    }

    //从0开始 周日是0 以此类推
    public void getRepeatTypeBiWeekDay(int weekDay) {
        Boolean isAdd = true;
        for (int i = 0; i < biWeekList.size(); i++) {
            if (biWeekList.get(i) == weekDay) {
                isAdd = false;
                biWeekList.remove(i);
            }
        }
        if (isAdd) {
            biWeekList.add(weekDay);
        }
        if (eventConfigEntity.getRepeatType() == 2) {
            eventConfigEntity.setRepeatTypeWeekDay(biWeekList);

        }
    }

    public class UIEventObservable {
        public SingleLiveEvent<Void> selectStart = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> selectEnd = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> endTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recBiWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recMonthly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> currenceTime = new SingleLiveEvent<>();

    }

    public AddEventViewModel.UIEventObservable uc = new AddEventViewModel.UIEventObservable();

    public BindingCommand<Boolean> rb1 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {

        }
    });

    public BindingCommand<Boolean> rb2 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {

        }
    });

    public BindingCommand<Boolean> rb3 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {

        }
    });

    public BindingCommand<Boolean> rb4 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {

        }
    });

    public BindingCommand endTime = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.endTime.call();
        }
    });

    public BindingCommand selectStart = new BindingCommand(() -> uc.selectStart.call());
    public BindingCommand selectEnd = new BindingCommand(() -> uc.selectEnd.call());
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

    public BindingCommand weekly1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(1);
        }
    });
    public BindingCommand weekly2 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(2);
        }
    });

    public BindingCommand weekly3 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(3);
        }
    });

    public BindingCommand weekly4 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(4);
        }
    });

    public BindingCommand weekly5 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(5);
        }
    });
    public BindingCommand weekly6 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(6);
        }
    });

    public BindingCommand weekly7 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeWeekDay(0);
        }
    });

    public BindingCommand biWeekly7 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(0);
        }
    });
    public BindingCommand biWeekly6 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(6);
        }
    });
    public BindingCommand biWeekly5 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(5);
        }
    });
    public BindingCommand biWeekly4 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(4);
        }
    });
    public BindingCommand biWeekly3 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(3);
        }
    });
    public BindingCommand biWeekly2 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(2);
        }
    });
    public BindingCommand biWeekly1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(1);
        }
    });
    public BindingCommand currenceTime = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.currenceTime.call();
        }
    });


}
