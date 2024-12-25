package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsAc;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsAc;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/28
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class SearchStudentLessonDetailVM extends ToolbarViewModel {

    public ObservableField<String> name = new ObservableField<>("");
    public ObservableField<String> email = new ObservableField<>("");
    public ObservableField<String> userId = new ObservableField<>("");
    public StudentListEntity userData = new StudentListEntity();
    public List<LessonTypeEntity> lessonTypeDatas = new ArrayList<>();
    public List<LessonScheduleConfigEntity> configDatas = new ArrayList<>();
    public List<LessonScheduleEntity> lessonData = new ArrayList<>();
    public int startTime = 0;
    public int endTime = 0;

    public SearchStudentLessonDetailVM(@NonNull Application application) {
        super(application);
        initData();
    }

    private void initData() {
        startTime = TimeUtils.getCurrentTime();
        endTime = (int) (TimeUtils.addMonth(startTime * 1000L, 2) / 1000L);
        lessonTypeDatas = SLCacheUtil.getTeacherLessonType(UserService.getInstance().getCurrentUserId());
        configDatas = ListenerService.shared.teacherData.getScheduleConfigs();

    }

    public UIEventObservable uc = new UIEventObservable();


    public static class UIEventObservable {
        public SingleLiveEvent<List<LessonScheduleEntity>> loadingComplete = new SingleLiveEvent<>();
    }
    public void clickItem(LessonScheduleEntity itemData) {
        Bundle bundle = new Bundle();
        List<LessonScheduleEntity> data = new ArrayList<>();
        data.add(itemData);
        bundle.putSerializable("data", (Serializable) data);
        bundle.putInt("selectIndex", 0);
        bundle.putLong("selectTime", itemData.getShouldDateTime());
        startActivity(LessonDetailsAc.class,bundle);
    }


    @Override
    public void initToolbar() {
    }


    public void getData() {

        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getLessonByTIdAndSIdAndTime(userData.getTeacherId(), userData.getStudentId(), startTime, endTime, false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            isSuccess.set(true);
                            for (LessonScheduleEntity item : data) {
                                for (LessonScheduleConfigEntity configData : configDatas) {
                                    if (configData.getId().equals(item.getLessonScheduleConfigId())) {
                                        item.setConfigEntity(configData);
                                        break;
                                    }
                                }
                                for (LessonTypeEntity lessonType : lessonTypeDatas) {
                                    if (lessonType.getId().equals(item.getLessonTypeId())) {
                                        item.setLessonType(lessonType);
                                        break;
                                    }
                                }
                                item.setStudentData(userData);
                            }
                            data.removeIf(scheduleEntity -> {
                                boolean isDelete = false;
                                for (LessonScheduleEntity lessonDatum : lessonData) {
                                    if (lessonDatum.getId().equals(scheduleEntity.getId())) {
                                        isDelete = true;
                                        break;
                                    }
                                }
                                if (scheduleEntity.isCancelled() || (scheduleEntity.isRescheduled() && !scheduleEntity.getRescheduleId().equals(""))) {
                                    isDelete = true;
                                }
                                if (scheduleEntity.getLessonType() == null || scheduleEntity.getConfigEntity() == null) {
                                    isDelete = true;
                                }
                                return isDelete;
                            });
                            lessonData.addAll(data);
                            uc.loadingComplete.setValue(data);
                            for (LessonScheduleEntity datum : data) {
                                observableList.add(new SearchStudentLessonDetailItemVM(this,datum));
                            }


                        }, throwable -> {
                            if (!isSuccess.get()) {
                            }
                            Logger.e("失败,失败原因" + throwable.getMessage());

                            uc.loadingComplete.call();

                        })

        );
    }


    //给RecyclerView添加ObservableList
    public ObservableList<SearchStudentLessonDetailItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<SearchStudentLessonDetailItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_search_student_lesson_detail));


}
