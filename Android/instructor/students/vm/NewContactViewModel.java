package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableInt;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.SetLessonConfigEntity;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class NewContactViewModel extends ToolbarViewModel {

    public List<AddressBookEntity> addressBookEntities = new ArrayList<>();
    public MutableLiveData<Integer> clickPager = new MutableLiveData<>();
    public List<SetLessonConfigEntity> scheduleEntityList = new ArrayList<>();
    int selectPosition;

    public ObservableInt observableInt = new ObservableInt(0);


    public NewContactViewModel(@NonNull Application application) {
        super(application);
        initMessenger();

    }

    public NewContactViewModel.UIClickObservable uc = new NewContactViewModel.UIClickObservable();



    public class UIClickObservable {
        public SingleLiveEvent<Void> nextButton = new SingleLiveEvent<>();
    }

    /**
     * 注册消息监听
     */
    private void initMessenger() {


//        Messenger.getDefault().register(this, MessengerUtils.START_TIME, LessonScheduleConfigEntity.class, new BindingConsumer<LessonScheduleConfigEntity>() {
//            @Override
//            public void call(LessonScheduleConfigEntity lessonScheduleConfigEntity) {
//                scheduleEntityList.get(selectPosition).setId(lessonScheduleConfigEntity.getId());
//                scheduleEntityList.get(selectPosition).setTeacherId(lessonScheduleConfigEntity.getTeacherId());
//                scheduleEntityList.get(selectPosition).setStudentId(studentId);
//                scheduleEntityList.get(selectPosition).setLessonTypeId(lessonScheduleConfigEntity.getLessonTypeId());
//                scheduleEntityList.get(selectPosition).setStartDateTime(1586458800);
//                scheduleEntityList.get(selectPosition).setRepeatType(lessonScheduleConfigEntity.getRepeatType());
//                scheduleEntityList.get(selectPosition).setRepeatTypeWeekDay(lessonScheduleConfigEntity.getRepeatTypeWeekDay());
//                scheduleEntityList.get(selectPosition).setRepeatTypeMonthDayType(lessonScheduleConfigEntity.getRepeatTypeMonthDayType());
//                scheduleEntityList.get(selectPosition).setRepeatTypeMonthDay(lessonScheduleConfigEntity.getRepeatTypeMonthDay());
//                scheduleEntityList.get(selectPosition).setLessonStatus(lessonScheduleConfigEntity.getLessonStatus());
//                scheduleEntityList.get(selectPosition).setUpdateTime(lessonScheduleConfigEntity.getUpdateTime());
//                scheduleEntityList.get(selectPosition).setCreateTime(lessonScheduleConfigEntity.getCreateTime());
//            }
//        });
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

    public void setComplete(int pos, boolean isComplete) {
        if (observableList.size() > pos){
            observableList.get(pos).isComplete.set(isComplete);
        }
    }

    //点击item的时候翻页
    public void changePage(int pos) {
        selectPosition = pos;
        for (int a = 0; a < observableList.size(); a++) {
            if (a == pos) {
                observableList.get(a).isSelected.set(true);
            } else {
                observableList.get(a).isSelected.set(false);
            }
        }
        clickPager.setValue(selectPosition);
    }

    //滑动的时候改变选中的item
    public void changeItem(int pos) {
        selectPosition = pos;
        for (int a = 0; a < observableList.size(); a++) {
            if (a == pos) {
                observableList.get(a).isSelected.set(true);
            } else {
                observableList.get(a).isSelected.set(false);
            }
        }
        clickPager.setValue(selectPosition);
    }

    public void getData() {
        for (int i = 0; i < addressBookEntities.size(); i++) {
            AddressBookEntity addressBookEntity = addressBookEntities.get(i);
            NewContactItemViewModel item = new NewContactItemViewModel(this, addressBookEntity, i);
            observableList.add(item);
        }
        observableList.get(0).isSelected.set(true);
    }


    public ObservableList<NewContactItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<NewContactItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<NewContactItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, NewContactItemViewModel item) {
            itemBinding.set(BR.itemViewModel, R.layout.new_content_layout);
        }
    });


    public BindingCommand nextButton = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.nextButton.call();
        }
    });
    public void createData() {
        showDialog();
        Logger.json(SLJsonUtils.toJsonString(scheduleEntityList));
        addSubscribe(
                LessonService
                        .getInstance()
                        .setLessonScheduleConfig(scheduleEntityList, true)
                        .subscribe(aBoolean -> {
                            Logger.e("====成功");
                            dismissDialog();
                            SLToast.success("Created successfully!");
                            finish();
                        }, throwable -> {
                            Logger.e("=====失败=%s", throwable);
                            dismissDialog();
//                            Messenger.getDefault().send(scheduleConfigEntity,MessengerUtils.REFRESH_LESSON);
//                            finish();
                            SLToast.showError();
                        })
        );
    }
}
