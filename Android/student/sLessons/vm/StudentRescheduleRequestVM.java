package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.TKFollowUp;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.UserNotificationEntity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentRescheduleAc;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/25
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleRequestVM extends ToolbarViewModel {
    public List<LessonRescheduleEntity> data = new ArrayList<>();
    public UserEntity teacherData;
    public PolicyEntity policyData;

    public StudentRescheduleRequestVM(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Reschedule");
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_FOLLOW_UP_CHANGE, () -> {
            List<TKFollowUp> followUps = ListenerService.shared.studentData.getFollowUps();
            List<LessonRescheduleEntity> data = new ArrayList<>();

            if (followUps != null && followUps.size() > 0) {
                for (TKFollowUp followUp : followUps) {
                    if (followUp.getDataType().equals(TKFollowUp.DataType.reschedule)) {
                        if (followUp.getColumn().equals(TKFollowUp.Column.rescheduled)) {
                            continue;
                        }
                        try {
                            LessonRescheduleEntity rescheduleData = CloneObjectUtils.cloneObject(followUp.getRescheduleData());
                            if ((rescheduleData.getConfirmType() == 1 || rescheduleData.getConfirmType() == -1) && (rescheduleData.isStudentRead() || !rescheduleData.getSenderId().equals(SLCacheUtil.getCurrentUserId()))) {
                                continue;
                            }
                            if (Integer.parseInt(rescheduleData.getTKBefore())<= TimeUtils.getCurrentTime()) {
                                continue;
                            }


                            rescheduleData.setFollowData(followUp);
                            data.add(rescheduleData);
                        } catch (Exception e) {

                        }
                    }
                    if (followUp.getDataType().equals(TKFollowUp.DataType.cancellation)) {
                        LessonCancellationEntity lessonCancellationEntity = CloneObjectUtils.cloneObject(followUp.getCancellationData());
                        if (lessonCancellationEntity.isStudentRead()) {
                            continue;
                        }
                        LessonRescheduleEntity e = lessonCancellationEntity.convertToReschedule();
                        e.setFollowData(followUp);
                        data.add(e);
                    }
                }
            }
            this.data = data;
            itemDataList.clear();
            for (LessonRescheduleEntity datum : data) {
                itemDataList.add(new StudentRescheduleRequestItemVM(this, datum));
            }
        });

//        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, () -> {
//            List<UserNotificationEntity> userNotifications = ListenerService.shared.userNotifications;
//            List<LessonRescheduleEntity> newData = new ArrayList<>();
//
//            for (UserNotificationEntity notification : userNotifications) {
//
//                switch (notification.getCategory()) {
//                    case 2:
//                        LessonCancellationEntity lessonCancellationEntity = SLJsonUtils.toBean(notification.getData(), LessonCancellationEntity.class);
//                        newData.add(lessonCancellationEntity.convertToReschedule());
//                        break;
//                    case 1:
//                    case 11:
//                    case 3:
//                        newData.add(SLJsonUtils.toBean(notification.getData(), LessonRescheduleEntity.class));
//                        break;
//                }
//            }
//            data = newData;
//            itemDataList.clear();
//            for (LessonRescheduleEntity datum : data) {
//                itemDataList.add(new StudentRescheduleRequestItemVM(this, datum));
//            }
//        });
    }

    public void initData(List<LessonRescheduleEntity> data, UserEntity teacherData) {
        this.data = data;
        this.teacherData = teacherData;
        Logger.e("data==>%s",SLJsonUtils.toJsonString(data));
        for (LessonRescheduleEntity datum : data) {
            if (Integer.parseInt(datum.getTKBefore())<= TimeUtils.getCurrentTime()) {
                continue;
            }
            itemDataList.add(new StudentRescheduleRequestItemVM(this, datum));
        }
    }

    //给RecyclerView添加ObservableList
    public ObservableList<StudentRescheduleRequestItemVM> itemDataList = new ObservableArrayList<>();

    public ItemBinding<StudentRescheduleRequestItemVM> itemBinding =
            ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_student_reschedule_request));

    public UIEventObservable uc = new UIEventObservable();


    public static class UIEventObservable {

        public SingleLiveEvent<LessonRescheduleEntity> clickRetract = new SingleLiveEvent<>();

    }

    public void retractReschedule(LessonRescheduleEntity reschedule) {
//        showDialog();
//        addSubscribe(LessonService
//                .getInstance()
//                .retractReschedule(reschedule)
//                .subscribeOn(Schedulers.io())
//                .observeOn(AndroidSchedulers.mainThread(), true)
//                .subscribe(d -> {
//                    dismissDialog();
//                    SLToast.success("Retract successfully!");
//                }, throwable -> {
//                    dismissDialog();
//                    SLToast.showError();
//                    Logger.e("teacherReadReschedule失败,失败原因" + throwable.getMessage());
//                }));
        showDialog();
        addSubscribe(
                TKApi.INSTANCE.retractReschedule(reschedule.getFollowData())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            SLToast.success("Retract successfully!");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("clickCloseConfirm失败,失败原因" + throwable.getMessage());
                        })
        );

    }


    public void clickReschedule(LessonRescheduleEntity reschedule) {
        if (reschedule.getRetracted() || reschedule.getConfirmType() != 0) {
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleById(reschedule.getScheduleId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (isSuccess.get()) {
                                return;
                            }
                            Bundle bundle = new Bundle();
                            bundle.putSerializable("policyData", policyData);
                            bundle.putSerializable("teacherData", teacherData);
                            bundle.putSerializable("lessonData", data);
                            bundle.putSerializable("rescheduleData", reschedule);
                            startActivity(StudentRescheduleAc.class, bundle);
                            isSuccess.set(true);

                        }, throwable -> {
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );


    }

    public void clickConfirm(LessonRescheduleEntity reschedule) {
//        showDialog();
//        addSubscribe(LessonService
//                .getInstance()
//                .confirmReschedule(reschedule)
//                .subscribeOn(Schedulers.io())
//                .observeOn(AndroidSchedulers.mainThread(), true)
//                .subscribe(d -> {
//                    dismissDialog();
//                    SLToast.success("Confirmed successfully!");
//                }, throwable -> {
//                    dismissDialog();
//                    SLToast.showError();
//                    Logger.e("clickCloseConfirm失败,失败原因" + throwable.getMessage());
//                }));
        showDialog();
        addSubscribe(
                TKApi.INSTANCE.confirmReschedule(reschedule.getFollowData())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            SLToast.success("Confirmed successfully!");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("clickConfirm失败,失败原因" + throwable.getMessage());
                        })
        );

    }

    public void clickRetract(LessonRescheduleEntity reschedule) {
        uc.clickRetract.setValue(reschedule);
    }

    public void clickClose(LessonRescheduleEntity reschedule) {
//        Logger.e("cancel==>%s", SLJsonUtils.toJsonString(reschedule));
//        showDialog();
//        Map<String, Object> map = new HashMap<>();
//        map.put("read", true);
//        DatabaseService.Collections.userNotifications()
//                .document(reschedule.getId() + ":" + UserService.getInstance().getCurrentUserId())
//                .update(map)
//                .addOnCompleteListener(command -> {
//                    dismissDialog();
//                    if (command.getException() != null) {
//                        SLToast.showError();
//                    } else {
//
//                    }
//                });
        showDialog();
        List<TKFollowUp> data = new ArrayList<>();
        data.add(reschedule.getFollowData());
        if (reschedule.isCancelLesson()) {
            addSubscribe(
                    TKApi.INSTANCE.readCancel(TKApi.ReadRescheduleType.STUDENT_READ, data)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(d -> {
                                dismissDialog();
                            }, throwable -> {
                                dismissDialog();
                                SLToast.showError();
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })
            );
        } else {
            addSubscribe(
                    TKApi.INSTANCE.readReschedule(TKApi.ReadRescheduleType.STUDENT_READ, data)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(d -> {
                                dismissDialog();
                            }, throwable -> {
                                dismissDialog();
                                SLToast.showError();
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })
            );
        }
    }

}
