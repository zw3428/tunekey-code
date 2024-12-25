package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.StorageUtils;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.utils.MessengerUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class StudentDetailProfileFragmentViewModel extends ToolbarViewModel {
    public ObservableField<String> image = new ObservableField<>();
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> email = new ObservableField<>();
    private StudentListEntity studentListEntity = new StudentListEntity();
    private List<LessonScheduleConfigEntity> lessonScheduleConfigEntities = new ArrayList<>();
    public boolean isAdd;
    private List<String> lessonIdList = new ArrayList<>();


    public StudentDetailProfileFragmentViewModel.UIClickObservable uc = new StudentDetailProfileFragmentViewModel.UIClickObservable();

    public StudentDetailProfileFragmentViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {

    }

    public class UIClickObservable {
        public SingleLiveEvent<Void> edit = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddLessonType = new SingleLiveEvent<>();

    }

    public BindingCommand edit = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.edit.call();
        }
    });
    public BindingCommand clickAddLessonType = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.clickAddLessonType.call();
        }
    });

    @Override
    public void onCreate() {
        super.onCreate();
        initMessenger();

    }

    public void clickItem(int pos) {
        Bundle bundle = new Bundle();
        bundle.putSerializable("list", studentListEntity);
        startActivity(AddLessonStepActivity.class, bundle);
    }

//    public void setImage(Boolean isEdit) {
//        isAdd = isEdit;
//        for (int i = 0; i < observableList.size(); i++) {
//            observableList.get(i).setImage(isEdit);
//        }
//    }

//    //给RecyclerView添加ObservableList
//    public ObservableList<StudentDetailProfileFragmentItemViewModel> observableList = new ObservableArrayList<>();
//    //RecyclerView多布局添加ItemBinding
//    public ItemBinding<StudentDetailProfileFragmentItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<StudentDetailProfileFragmentItemViewModel>() {
//        @Override
//        public void onItemBind(ItemBinding itemBinding, int position, StudentDetailProfileFragmentItemViewModel item) {
//            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_lesson_during);
//        }
//    });


//    private void initLessonType(List<String> lessonTypeId) {
//        addSubscribe(UserService
//                .getStudioInstance()
//                .getLessonTypeList(false)
//                .subscribe(lessonTypeEntities -> {
//                    observableList.clear();
//                    for (int i = 0; i < lessonTypeId.size(); i++) {
//                        for (int j = 0; j < lessonTypeEntities.size(); j++) {
//                            if (lessonTypeId.get(i).equals(lessonTypeEntities.get(j).getId())) {
//                                StudentDetailProfileFragmentItemViewModel item = new StudentDetailProfileFragmentItemViewModel(StudentDetailProfileFragmentViewModel.this, lessonTypeEntities.get(j), i);
//                                observableList.add(item);
//                            }
//                        }
//                    }
//
//                }, throwable -> {
//                    //nextButtonStatus.setValue(1);
//                    Logger.e("==获取列表失败" + throwable.getMessage());
//                }));
//
//    }

    private void getLessonScheduleConfig() {
        String studentId = studentListEntity.getStudentId();
        addSubscribe(UserService
                .getStudioInstance()
                .getScheduleConfig(studentId)
                .subscribe(configEntities -> {
                    lessonScheduleConfigEntities = configEntities;
                    lessonIdList.clear();
                    for (int i = 0; i < configEntities.size(); i++) {
                        if (!lessonIdList.contains(configEntities.get(i).getLessonTypeId())) {
                            lessonIdList.add(configEntities.get(i).getLessonTypeId());
                        }
                    }
//                    initLessonType(lessonIdList);
                }, throwable -> {
                    //nextButtonStatus.setValue(1);
                    Logger.e("==获取列表失败" + throwable.getMessage());
                }));
    }


    /**
     * 注册消息监听
     */
    private void initMessenger() {

        //有新保存的LessonType的消息监听
        Messenger.getDefault().register(this, MessengerUtils.TOKEN_ADD_LESSON_TYPE_VIEW_MODEL_REFRESH, LessonTypeEntity.class, new BindingConsumer<LessonTypeEntity>() {
            @Override
            public void call(LessonTypeEntity lessonTypeEntity) {
//                StudentDetailProfileFragmentItemViewModel item = new StudentDetailProfileFragmentItemViewModel(StudentDetailProfileFragmentViewModel.this, lessonTypeEntity, observableList.size());
//                observableList.add(item);
                // nextButtonStatus.setValue(0);
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.TOKEN_LESSON_TYPE_REFRESH, () -> {
//            initLessonType(lessonIdList);
        });
    }

    public void setData(StudentListEntity studentListEntity) {
        this.studentListEntity = studentListEntity;
        getLessonScheduleConfig();
        image.set(StorageUtils.getInstrumentPath() + studentListEntity.getStudentId() + "_min.png");
        name.set(studentListEntity.getName());
        email.set(studentListEntity.getEmail());
    }

    public void deleteLesson(String lessonId) {
        int starTime = 0;
        String scheduleId = "";
        String studentId = "";
        String teacherId = "";
        for (int i = 0; i < lessonScheduleConfigEntities.size(); i++) {
            if (lessonScheduleConfigEntities.get(i).getLessonTypeId().equals(lessonId)) {
                starTime = lessonScheduleConfigEntities.get(i).getStartDateTime();
                scheduleId = lessonScheduleConfigEntities.get(i).getId();
            }
        }
        if (starTime > (System.currentTimeMillis() / 1000)) {

            addSubscribe(UserService
                    .getStudioInstance()
                    .deleteScheduleConfig(lessonId)
                    .subscribe(status -> {
                        Logger.e("delete successfully!" + status);
                        SLToast.success("delete successfully!");

                    }, throwable -> {
                        Logger.e("=====删除失败=" + throwable.getMessage());
                        SLToast.error("delete failed, please try again!");
                    }));
        } else {

            Map<String, Object> map = new HashMap<>();
            map.put("endType", 1);
            map.put("endDate", (System.currentTimeMillis() / 1000) + "");
            map.put("delete", true);

            addSubscribe(UserService
                    .getStudioInstance()
                    .updateScheduleConfig(scheduleId, map)
                    .subscribe(status -> {
                        Logger.e("delete successfully!" + status);
                        SLToast.success("delete successfully!");

                    }, throwable -> {
                        Logger.e("=====删除失败=" + throwable.getMessage());
                        SLToast.error("delete failed, please try again!");
                    }));

        }
        Map<String, Object> map1 = new HashMap<>();
        map1.put("time", (System.currentTimeMillis() / 1000) + "");
        map1.put("configId", scheduleId);
        map1.put("studentId", studentId);
        map1.put("teacherId", teacherId);
        CloudFunctions
                .deleteLessonScheduleConfig(map1)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult()) {
                            Logger.e("====== 删除 material 成功:" + task.getResult());

                            Messenger.getDefault().send("delete", MessengerUtils.REFRESH);
                        }
                    } else {
                        Logger.e("====== 删除 material 异常:" + task.getException().getMessage());

                    }
                });

    }
}
