package com.spelist.tunekey.ui.teacher.students.vm;

import android.annotation.SuppressLint;
import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.utils.SLCacheUtil;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class NotesViewModel extends ToolbarViewModel {

    public List<LessonScheduleEntity> data = new ArrayList<>();
    public String studentId = "";


    public NotesViewModel(@NonNull Application application) {
        super(application);

    }

    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setNormalToolbar("Notes");
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    //给RecyclerView添加ObservableList
    public ObservableList<NotesItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<NotesItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<NotesItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, NotesItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_student_notes);
        }
    });

    public void initData() {
        data.sort((t0, t1) -> (int) (t1.shouldDateTime- t0.shouldDateTime));
        observableList.clear();
        for (LessonScheduleEntity item : data) {
            NotesItemViewModel notesItemViewModel = new NotesItemViewModel(this,item);
            observableList.add(notesItemViewModel);
        }


    }

    public void getData() {
        addSubscribe(
                TKApi.INSTANCE.getTeacherNoteByStudioIdAndStudentId(SLCacheUtil.getCurrentStudioId(), studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (d.size() == 0) {
                                return;
                            }
                            try {
                                for (LessonScheduleEntity item : d.toObjects(LessonScheduleEntity.class)) {
                                    if (data.size()>0){
                                        if (data.stream().noneMatch(scheduleEntity -> scheduleEntity.getId().equals(item.getId()))) {
                                            data.add(item);
                                        }
                                    }else {
                                        data.add(item);
                                    }
                                }
                            }catch (Throwable e){
                                Logger.e("有问题==>%s",e.getMessage());
                            }
                            initData();

                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
        addSubscribe(
                TKApi.INSTANCE.getStudentNoteByStudioIdAndStudentId(SLCacheUtil.getCurrentStudioId(), studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (d.size() == 0) {
                                return;
                            }
                            try {
                                for (LessonScheduleEntity item : d.toObjects(LessonScheduleEntity.class)) {
                                    if (data.size()>0){
                                        if (data.stream().noneMatch(scheduleEntity -> scheduleEntity.getId().equals(item.getId()))) {
                                            data.add(item);
                                        }
                                    }else {
                                        data.add(item);
                                    }
                                }
                            }catch (Throwable e){
                                Logger.e("有问题==>%s",e.getMessage());
                            }
                            initData();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }
}
