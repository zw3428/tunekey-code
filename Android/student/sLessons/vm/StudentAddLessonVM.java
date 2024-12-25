package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.os.Build;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;
import androidx.recyclerview.widget.GridLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.entity.Instrument;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.ui.teacher.addLessonType.AddLessonItemViewModel;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/8
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentAddLessonVM extends ToolbarViewModel {
    public MutableLiveData<Integer> selectedInstrumentVisible = new MutableLiveData<>();
    public MutableLiveData<Integer> selectedImgVisibility = new MutableLiveData<>();
    public MutableLiveData<Instrument> selectedInstrument = new MutableLiveData<>();
    public MutableLiveData<String> selectedInstrumentName = new MutableLiveData<>();
    public MutableLiveData<Integer> iconOfLessonVisibility = new MutableLiveData<>();
    public MutableLiveData<Integer> selectAnIconVisibility = new MutableLiveData<>();
    public MutableLiveData<Integer> addLessonList = new MutableLiveData<>();
    public ObservableField<GridLayoutManager> gridLayoutManager = new ObservableField<>();
    public ObservableField<Integer> instrumentPlaceholder = new ObservableField<>(R.drawable.def_instrument);
    public MutableLiveData<Boolean> isShowSelectTime = new MutableLiveData<>(false);
    public LessonScheduleConfigEntity scheduleConfigEntity = new LessonScheduleConfigEntity();
    public int startTime1 = 0;
    public ObservableField<Boolean> wk0Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk1Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk2Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk3Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk4Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk5Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk6Clickable = new ObservableField<>(true);

    public ObservableField<Boolean> wk0checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk1checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk2checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk3checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk4checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk5checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk6checked = new ObservableField<>(false);
    private List<Integer> weekList = new ArrayList<>();

    public MutableLiveData<List<Instrument>> instrumentList = new MutableLiveData<>();

    public StudentAddLessonVM(@NonNull Application application) {
        super(application);

    }

    @Override
    public void onCreate() {
        super.onCreate();
        getInstrumentList();
        addLessonList.setValue(View.GONE);
        selectedImgVisibility.setValue(View.GONE);
        iconOfLessonVisibility.setValue(View.VISIBLE);
        selectAnIconVisibility.setValue(View.VISIBLE);
        selectedInstrumentName.setValue("Icon of lesson type");
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Add Lesson");
    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> imageClick = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> startTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recBiWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recMonthly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> rb1 = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> endTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> currenceTime = new SingleLiveEvent<>();
    }


    //lesson type 相关

    /**
     * 获取乐器列表
     */
    @RequiresApi(api = Build.VERSION_CODES.N)
    public void getInstrumentList() {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getInstrumentListByPublicAndOwn()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(instruments -> {
                            if (observableList.size() > 0) {
                                return;
                            }
                            dismissDialog();
                            instrumentList.setValue(instruments);
                            instrumentList.getValue().sort((o1, o2) -> o1.getName().charAt(0) - o2.getName().charAt(0));
                            instrumentList.getValue().sort((o1, o2) -> o1.getCategory() - o2.getCategory());
                            observableList.clear();
                            for (int i = 0; i < instrumentList.getValue().size(); i++) {
                                Instrument instrument = instrumentList.getValue().get(i);
                                AddLessonItemViewModel item = new AddLessonItemViewModel(StudentAddLessonVM.this, instrument, i);
                                observableList.add(item);
                            }
                        }, throwable -> dismissDialog()));
    }

    //给RecyclerView添加ObservableList
    public ObservableList<AddLessonItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<AddLessonItemViewModel> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.viewModel, R.layout.item_add_lesson_detail));

    public BindingCommand imageClick = new BindingCommand(() -> {
        addLessonList.setValue(View.VISIBLE);
        if (selectedImgVisibility.getValue() != View.VISIBLE) {
            selectedImgVisibility.setValue(View.GONE);
            iconOfLessonVisibility.postValue(View.VISIBLE);
        } else {
            selectedImgVisibility.setValue(View.VISIBLE);
            iconOfLessonVisibility.postValue(View.GONE);
        }
        selectAnIconVisibility.setValue(View.GONE);
        selectedInstrumentName.setValue("Icon of lesson type");
        uc.imageClick.call();
    });

    public void selectInstrument(int pos) {
        if (instrumentList != null) {
            selectedInstrument.postValue(instrumentList.getValue().get(pos));
//            selectedInstrumentName.setValue(instrumentList.getValue().get(pos).getName());
            selectedImgVisibility.postValue(View.VISIBLE);
            iconOfLessonVisibility.postValue(View.GONE);
            addLessonList.postValue(View.GONE);
            selectAnIconVisibility.setValue(View.VISIBLE);
            uc.imageClick.call();
            isShowSelectTime.setValue(true);
        }
    }

    // lesson 相关
    public BindingCommand startTime = new BindingCommand(() -> uc.startTime.call());
    public BindingCommand recWeekly = new BindingCommand(() -> uc.recWeekly.call());

    public BindingCommand weekly1 = new BindingCommand(() -> setRepeatTypeWeekDay(0));
    public BindingCommand weekly2 = new BindingCommand(() -> setRepeatTypeWeekDay(1));

    public BindingCommand weekly3 = new BindingCommand(() -> setRepeatTypeWeekDay(2));

    public BindingCommand weekly4 = new BindingCommand(() -> setRepeatTypeWeekDay(3));

    public BindingCommand weekly5 = new BindingCommand(() -> setRepeatTypeWeekDay(4));
    public BindingCommand weekly6 = new BindingCommand(() -> setRepeatTypeWeekDay(5));

    public BindingCommand weekly7 = new BindingCommand(() -> setRepeatTypeWeekDay(6));


    //从0开始 周日是0 以此类推
    public void setRepeatTypeWeekDay(int weekDay) {
        boolean isAdd = true;
        for (int i = 0; i < weekList.size(); i++) {
            if (weekList.get(i) == weekDay) {
                isAdd = false;
                weekList.remove(i);
            }
        }
        if (isAdd) {
            weekList.add(weekDay);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekList);
        setWeekIsChecked(weekDay);
        checkWeekIsClickable();
    }

    public void setRepeatType(int repeatType) {
        scheduleConfigEntity.setRepeatType(repeatType);
    }


    private void setWeekIsChecked(int index) {
        switch (index) {
            case 0:
                wk0checked.set(!wk0checked.get());
                break;
            case 1:
                wk1checked.set(!wk1checked.get());
                break;
            case 2:
                wk2checked.set(!wk2checked.get());
                break;
            case 3:
                wk3checked.set(!wk3checked.get());
                break;
            case 4:
                wk4checked.set(!wk4checked.get());
                break;
            case 5:
                wk5checked.set(!wk5checked.get());
                break;
            case 6:
                wk6checked.set(!wk6checked.get());
                break;
        }
    }


    private void checkWeekIsClickable() {
        Logger.e("======%s", scheduleConfigEntity.getRepeatTypeWeekDay());
        if (scheduleConfigEntity.getRepeatTypeWeekDay().size() == 1) {
            for (Integer index : scheduleConfigEntity.getRepeatTypeWeekDay()) {
                switch (index) {
                    case 0:
                        wk0Clickable.set(false);
                        break;
                    case 1:
                        wk1Clickable.set(false);
                        break;
                    case 2:
                        wk2Clickable.set(false);
                        break;
                    case 3:
                        wk3Clickable.set(false);
                        break;
                    case 4:
                        wk4Clickable.set(false);
                        break;
                    case 5:
                        wk5Clickable.set(false);
                        break;
                    case 6:
                        wk6Clickable.set(false);
                        break;
                }
            }

        } else {
            wk0Clickable.set(true);
            wk1Clickable.set(true);
            wk2Clickable.set(true);
            wk3Clickable.set(true);
            wk4Clickable.set(true);
            wk5Clickable.set(true);
            wk6Clickable.set(true);
        }
    }

    public void getRepeatTypeMonthDay(int type) {
        scheduleConfigEntity.setRepeatTypeMonthDayType(type);
    }

    public void setRepeatTypeMonthType(String day) {
        scheduleConfigEntity.setRepeatTypeMonthDay(day);
    }

    public BindingCommand recBiWeekly = new BindingCommand(() -> uc.recBiWeekly.call());
    public BindingCommand recMonthly = new BindingCommand(() -> uc.recMonthly.call());
    public BindingCommand<Boolean> rb1 = new BindingCommand<>(aBoolean -> uc.rb1.call());

    public BindingCommand<Boolean> rb3 = new BindingCommand<>(aBoolean -> {
        if (aBoolean) {
            scheduleConfigEntity.setEndType(1);
        }
    });
    public BindingCommand<Boolean> rb4 = new BindingCommand<>(aBoolean -> {
        if (aBoolean) {
            scheduleConfigEntity.setEndType(2);
            if (scheduleConfigEntity.getEndCount() == 0) {
                scheduleConfigEntity.setEndCount(10);
            }
        }
    });
    public BindingCommand endTime = new BindingCommand(() -> uc.endTime.call());
    public BindingCommand currenceTime = new BindingCommand(() -> uc.currenceTime.call());
    public TKButton.ClickListener clickConfirm = tkButton -> {
        showDialog();
        String time = TimeUtils.getCurrentTimeString();
        String lessonTypeId = IDUtils.getId();
        LessonTypeEntity lessonType = new LessonTypeEntity()
                .setId(lessonTypeId).setTeacherId("").setInstrumentId(selectedInstrument.getValue().getId() + "")
                .setTimeLength(60).setPrice("0").setType(1).setName("")
                .setDeleted(false).set_package(0).setCreateTime(time).setUpdateTime(time);
        scheduleConfigEntity.setId(IDUtils.getId());
        scheduleConfigEntity.setTeacherId("");
        scheduleConfigEntity.setStudentId(UserService.getInstance().getCurrentUserId());
        scheduleConfigEntity.setLessonTypeId(lessonTypeId);
        scheduleConfigEntity.setStartDateTime(startTime1);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setCreateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
        int diff = TimeUtils.getUTCWeekdayDiff(startTime1 * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : scheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);

        Logger.json(SLJsonUtils.toJsonString(scheduleConfigEntity));

        addSubscribe(
                CloudFunctions
                        .studentAddLessonScheduleConfig(lessonType, scheduleConfigEntity)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            SLToast.success("Add lessons successfully!");
                            finish();
                            Logger.e("studentAddLessonScheduleConfig成功");
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            dismissDialog();
                            SLToast.showError();
                        })
        );
    };


}
