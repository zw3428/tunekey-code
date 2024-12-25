package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.AutoInvoicingSetting;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;

import java.text.Collator;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * com.spelist.tunekey.ui.students.vm
 * 2019-12-09
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LessonTypeVM extends ToolbarViewModel {
    public boolean isStudentLook = false;
    public String teacherId = "";
    public String studioId = "";

    public LessonTypeVM.UIEventObservable uc = new UIEventObservable();
    public MutableLiveData<List<LessonTypeEntity>> liveData = new MutableLiveData<>();
    public List<LessonTypeEntity> lessonTypeEntities = new ArrayList<>();
    //0: teacher/student 1:studio
    public int type = 0;
    public ObservableField<Boolean> isCanCreateLessonTypeObservable = new ObservableField<>(true);
    public boolean isCanEditLessonTypeAndDelete  = true;

    public LessonTypeVM(@NonNull Application application) {
        super(application);
        initMessenger();

    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Lesson Types");
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public static class UIEventObservable {
        public SingleLiveEvent<Void> addLessonType = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> refreshCurrency = new SingleLiveEvent<>();

    }

    public BindingCommand addLessonType = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.addLessonType.call();
        }
    });

    public void getLessonType() {
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            if (TKRoleAndAccess.getData()!=null){
                TKRoleAndAccess data = TKRoleAndAccess.getData();
                isCanCreateLessonTypeObservable.set(data.getAllowManageLessonType() && data.getAllowManageLessonType4Create());
                isCanEditLessonTypeAndDelete = data.getAllowManageLessonType() && data.getAllowManageLessonType4EditAndDelete();
            }
        }
        if (isStudentLook){
            isCanCreateLessonTypeObservable.set(false);
        }
        if (type == 0) {
            if (!isStudentLook) {
                if (SLCacheUtil.getCurrentStudioIsSingleTeacher()){
                    addSubscribe(UserService
                            .getStudioInstance()
                            .getLessonTypeList()
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(value -> {
                                lessonTypeEntities.clear();
                                for (int i = 0; i < value.size(); i++) {
                                    if (!value.get(i).isDeleted()) {
                                        lessonTypeEntities.add(value.get(i));
                                    }
                                }
                                lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
                                liveData.setValue(lessonTypeEntities);
                            }, throwable -> {
                                Logger.e("=====getLessonType=" + throwable.getMessage());
                            }));
                }else {
                    addSubscribe(UserService
                            .getStudioInstance()
                            .getLessonTypeListByStudioId(SLCacheUtil.getCurrentStudioId())
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(value -> {
                                lessonTypeEntities.clear();
                                for (int i = 0; i < value.size(); i++) {
                                    if (!value.get(i).isDeleted()) {
                                        lessonTypeEntities.add(value.get(i));
                                    }
                                }
                                lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                                liveData.setValue(lessonTypeEntities);
                            }, throwable -> {
                                Logger.e("=====getLessonType=" + throwable.getMessage());
                            }));
                }


            } else {
                if (teacherId ==null ||teacherId.equals("")) {
                    if (!studioId.equals("")){
                        addSubscribe(UserService
                                .getStudioInstance()
                                .getLessonTypeListByStudioId(studioId)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread(), true)
                                .subscribe(value -> {
                                    lessonTypeEntities.clear();
                                    for (int i = 0; i < value.size(); i++) {
                                        if (!value.get(i).isDeleted()) {
                                            lessonTypeEntities.add(value.get(i));
                                        }
                                    }
                                    lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                                    liveData.setValue(lessonTypeEntities);
                                }, throwable -> {
                                    Logger.e("=====getLessonType=" + throwable.getMessage());
                                }));
                    }

                } else {
                    addSubscribe(UserService
                            .getStudioInstance()
                            .getLessonTypeListByTeacherId(teacherId)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(value -> {
                                lessonTypeEntities.clear();
                                for (int i = 0; i < value.size(); i++) {
                                    if (!value.get(i).isDeleted()) {
                                        lessonTypeEntities.add(value.get(i));
                                    }
                                }
                                lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                                liveData.setValue(lessonTypeEntities);

                            }, throwable -> {
                                Logger.e("=====getLessonType=" + throwable.getMessage());
                            }));
                }

            }


        } else if (type == 1) {
             if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                 if (SLCacheUtil.getCurrentStudioIsSingleTeacher()){
                     addSubscribe(UserService
                             .getStudioInstance()
                             .getLessonTypeList()
                             .subscribeOn(Schedulers.io())
                             .observeOn(AndroidSchedulers.mainThread(), true)
                             .subscribe(value -> {
                                 lessonTypeEntities.clear();
                                 for (int i = 0; i < value.size(); i++) {
                                     if (!value.get(i).isDeleted()) {
                                         lessonTypeEntities.add(value.get(i));
                                     }
                                 }
                                 lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
                                 liveData.setValue(lessonTypeEntities);
                             }, throwable -> {
                                 Logger.e("=====getLessonType=" + throwable.getMessage());
                             }));
                 }else {
                     addSubscribe(UserService
                             .getStudioInstance()
                             .getLessonTypeListByStudioId(SLCacheUtil.getCurrentStudioId())
                             .subscribeOn(Schedulers.io())
                             .observeOn(AndroidSchedulers.mainThread(), true)
                             .subscribe(value -> {
                                 lessonTypeEntities.clear();
                                 for (int i = 0; i < value.size(); i++) {
                                     if (!value.get(i).isDeleted()) {
                                         lessonTypeEntities.add(value.get(i));
                                     }
                                 }
                                 lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                                 liveData.setValue(lessonTypeEntities);
                             }, throwable -> {
                                 Logger.e("=====getLessonType=" + throwable.getMessage());
                             }));
                 }
             } else {
                 if (ListenerService.shared.studioData == null) {
                     return;
                 }
                 lessonTypeEntities.clear();
                 for (int i = 0; i < CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).size(); i++) {
                     if (!CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).get(i).isDeleted()) {
                         lessonTypeEntities.add(CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).get(i));
                     }
                 }
                 lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

                 liveData.setValue(lessonTypeEntities);
              }


        }

    }

    public void deleteLessonType(String lessonId) {
        showDialog();
        addSubscribe(UserService
                .getStudioInstance()
                .deleteLessonType(lessonId)
                .subscribe(status -> {
                    dismissDialog();
                    SLToast.success("Delete successfully!");
                }, throwable -> {
                    Logger.e("=====删除失败=" + throwable.getMessage());
                    dismissDialog();
                    SLToast.error("Delete failed, please try again!");
                }));

    }

    private void initMessenger() {
        Messenger.getDefault().register(this,MessengerUtils.UPDATE_STUDIO_CURRENCY, AutoInvoicingSetting.TKCurrency.class, currency -> {
            uc.refreshCurrency.call();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDIO_LESSON_TYPE_CHANGED, () -> {
            lessonTypeEntities.clear();
            for (int i = 0; i < CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).size(); i++) {
                if (!CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).get(i).isDeleted()) {
                    lessonTypeEntities.add(CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getLessonTypesData()).get(i));
                }
            }
            lessonTypeEntities.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
            liveData.setValue(lessonTypeEntities);
        });


        //有新保存的LessonType的消息监听
        Messenger.getDefault().register(this, MessengerUtils.TOKEN_ADD_LESSON_TYPE_VIEW_MODEL_REFRESH, LessonTypeEntity.class, new BindingConsumer<LessonTypeEntity>() {
            @Override
            public void call(LessonTypeEntity lessonTypeEntity) {
                getLessonType();
            }
        });

        //修改原有的LessonType的消息监听
        Messenger.getDefault().register(this, MessengerUtils.TOKEN_EDIT_LESSON_TYPE_VIEW_MODEL_REFRESH, LessonTypeEntity.class, new BindingConsumer<LessonTypeEntity>() {
            @Override
            public void call(LessonTypeEntity lessonTypeEntity) {

                getLessonType();
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.TOKEN_LESSON_TYPE_REFRESH, this::getLessonType);
//        Messenger.getDefault().register(this,  MessengerUtils.TOKEN_LESSON_TYPE_REFRESH, String.class, new BindingConsumer<String>() {
//            @Override
//            public void call(String s) {
//                Logger.e("======%s", "获取到啦:"+s);
//                getLessonType();
//            }
//        });
    }
}
