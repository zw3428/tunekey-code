package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.functions.FirebaseFunctions;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.dialog.studioAddLesson.StudioAddLessonHost;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKLocation;
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
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/29
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleByTeacherVM extends ToolbarViewModel {

    public RescheduleByTeacherVM(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Reschedule");
    }

    public void initData(List<LessonScheduleEntity> data, int defSelect) {
        if (data == null) {
            return;
        }
        for (int i = 0; i < data.size(); i++) {
            RescheduleByTeacherItemVM e = new RescheduleByTeacherItemVM(this, data.get(i));
            if (i == defSelect) {
                e.isChecked.set(true);
            }
            observableList.add(e);
        }

    }

    public UIEventObservable uc = new UIEventObservable();

    public void sentRescheduleV2(String message, LessonScheduleEntity oldData, StudioAddLessonHost.SelectTimeLocationData newData) {
        showDialog();
        String newTeacherId = "";
        if (!oldData.teacherId.equals(newData.getTeacherId())) {
            newTeacherId = newData.getTeacherId();
        }
        TKLocation location = newData.toTKLocation();
        if (oldData.getLocation() != null) {
            if (oldData.getLocation().getId().equals(location.getId())) {
                location = null;
            }
        }

        Map<String, Object> newLocation = null;
        if (location != null&&!location.getId().equals("SetLater")) {
            newLocation = SLJsonUtils.toMaps(SLJsonUtils.toJsonString(location));
        }
        addSubscribe(
                TKApi.INSTANCE.reschedule(
                                oldData.getStudioId(),
                                oldData.getSubStudioId(),
                                newData.getSelectedTimestamp(),
                                newLocation,
                                newTeacherId,
                                oldData.getId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            SLToast.success("Rescheduled successfully!");
                            finish();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            dismissDialog();

                            SLToast.showError();
                        })
        );
    }

    public void confirmNowReschedule(LessonScheduleEntity data, String afterTime) {
        showDialog();
        try {
            Map<String, Object> d = new HashMap<>();
            d.put("lessonScheduleId", data.getId());
            d.put("timeAfter", Integer.parseInt(afterTime));
            FirebaseFunctions.getInstance().getHttpsCallable("scheduleService-confirmRescheduleDirectlly")
                    .call(d)
                    .addOnCompleteListener(task -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            dismissDialog();
                            Logger.e("====reschedule成功==");
                            SLToast.success("Rescheduled successfully!");
                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                            finish();
                        } else {
                            SLToast.showError();
                        }
                    });
        } catch (Throwable e) {
            dismissDialog();
            SLToast.showError();
        }

    }

    public void sendReschedule(String message, String afterTime, List<LessonScheduleEntity> selectLesson) {
        showDialog();
        List<LessonRescheduleEntity> reschedules = new ArrayList<>();
        String currentTime = TimeUtils.getCurrentTime() + "";
        for (LessonScheduleEntity item : selectLesson) {
            LessonRescheduleEntity reschedule = new LessonRescheduleEntity()
                    .setId(item.getId())
                    .setTeacherId(item.getTeacherId())
                    .setStudioId(SLCacheUtil.getCurrentStudioId())
                    .setStudentId(item.getStudentId())
                    .setScheduleId(item.getId())
                    .setShouldTimeLength(item.getShouldTimeLength())
                    .setSenderId(item.getTeacherId())
                    .setConfirmerId(item.getStudentId())
                    .setConfirmType(0)
                    .setTimeBefore("" + item.getShouldDateTime())
                    .setTimeAfter(afterTime)
                    .setCreateTime(currentTime)
                    .setUpdateTime(currentTime);
            reschedules.add(reschedule);
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .reschedule(selectLesson, reschedules, message)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            Logger.e("====reschedule成功==");
                            SLToast.success("Rescheduled successfully!");
                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                            finish();
                        }, throwable -> {
                            if (throwable instanceof FirebaseFirestoreException) {
                                FirebaseFirestoreException error = (FirebaseFirestoreException) throwable;
                                Logger.e("走到了错误%s", error.getCode().value());

                                if (error.getCode() == FirebaseFirestoreException.Code.CANCELLED) {
                                    String userId = "";
                                    if (reschedules.get(0).getTeacherId().equals(UserService.getInstance().getCurrentUserId())) {
                                        userId = reschedules.get(0).getStudentId();
                                    } else {
                                        userId = reschedules.get(0).getTeacherId();
                                    }
                                    AtomicBoolean isSuccess = new AtomicBoolean(false);
                                    String finalUserId = userId;
                                    addSubscribe(
                                            UserService
                                                    .getInstance()
                                                    .getUserById(userId)
                                                    .subscribeOn(Schedulers.io())
                                                    .observeOn(AndroidSchedulers.mainThread(), true)
                                                    .subscribe(user -> {
                                                        if (!isSuccess.get()) {
                                                            dismissDialog();
//                                                            Dialog dialog = SLDialogUtils.showOneButton(TApplication.getInstance().getBaseContext(),
//                                                                    "Something wrong",
//                                                                    "This lesson has been updated by" + user.getName() + "recently.",
//                                                                    "OK");
//                                                            TextView button = dialog.findViewById(R.id.button);
//                                                            button.setOnClickListener(v -> {
//                                                                dialog.dismiss();
//                                                            });

                                                            Map<String, String> d = new HashMap<>();
                                                            d.put("title", "Something wrong");
                                                            d.put("content", "This lesson has been updated by " + user.getName() + " recently.");
                                                            uc.showErrorDialog.setValue(d);
                                                            isSuccess.set(true);
                                                        }
                                                    }, e -> {
                                                        Logger.e("走到了获取user数据失败:%s,%s", e.getMessage(), finalUserId);
                                                        dismissDialog();
                                                        SLToast.showError();
                                                    })

                                    );

                                } else if (error.getCode() == FirebaseFirestoreException.Code.UNKNOWN) {
                                    dismissDialog();
                                    Map<String, String> d = new HashMap<>();
                                    d.put("title", "Too late");
                                    d.put("content", "Someone just took your spot, the time you attempted to confirm is no longer available. Please reconsider.");
                                    uc.showErrorDialog.setValue(d);
//                                    Dialog dialog = SLDialogUtils.showOneButton(TApplication.getInstance().getBaseContext(),
//                                            "Too late",
//                                            "Someone just took your spot, the time you attempted to confirm is no longer available. Please reconsider.",
//                                            "OK");
//                                    TextView button = dialog.findViewById(R.id.button);
//                                    button.setOnClickListener(v -> {
//                                        dialog.dismiss();
//
//                                    });

                                } else {
                                    Logger.e("走到了其他错误1");
                                    dismissDialog();
                                    SLToast.showError();
                                }

                            } else {
                                Logger.e("走到了其他错误2");
                                dismissDialog();

                                SLToast.showError();
                            }


                        })

        );


    }

    public static class UIEventObservable {
        public SingleLiveEvent<List<LessonScheduleEntity>> clickReschedule = new SingleLiveEvent<>();
        public SingleLiveEvent<Map<String, String>> showErrorDialog = new SingleLiveEvent<>();

    }


    //给RecyclerView添加ObservableList
    public ObservableList<RescheduleByTeacherItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<RescheduleByTeacherItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_reschedule_by_teacher));


    public TKButton.ClickListener clickReschedule = tkButton -> {
        List<LessonScheduleEntity> selectData = new ArrayList<>();
        Logger.e("????==>%s","sdsdsd");
        for (RescheduleByTeacherItemVM item : observableList) {
            if (item.isChecked.get()) {
                selectData.add(item.data);
            }
        }
        if (selectData.size() > 0) {
            uc.clickReschedule.setValue(selectData);
        }
    };


}
