package com.spelist.tunekey.ui.student.sProfile.fragment;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.gdata.data.photos.UserEntry;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.ListenerServiceEX;
import com.spelist.tunekey.api.network.ChatService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.CountriesCurrencies;
import com.spelist.tunekey.entity.DataChangeHistory;
import com.spelist.tunekey.entity.InvoiceCalculation;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.NotificationEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.StudioInfoEntity;
import com.spelist.tunekey.entity.TKFollowUs;
import com.spelist.tunekey.entity.TKInvoice;
import com.spelist.tunekey.entity.TKInvoiceStatus;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.chat.ChatDataChangeActionType;
import com.spelist.tunekey.entity.chat.ConversationType;
import com.spelist.tunekey.entity.chat.TKConversation;
import com.spelist.tunekey.entity.chat.TKConversationUser;
import com.spelist.tunekey.entity.chat.TKSupportAccount;
import com.spelist.tunekey.ui.balance.BalanceListAc;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.loginAndOnboard.confirmStorefront.ConfirmStorefrontActivity;
import com.spelist.tunekey.ui.loginAndOnboard.login.PasswordActivity;
import com.spelist.tunekey.ui.loginAndOnboard.login.vm.LoginHistoryItemVM;
import com.spelist.tunekey.ui.teacher.profileTeacher.AccountActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.ReportBugActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.TermsAndPrivacyActivity;
import com.spelist.tunekey.ui.teacher.profileTeacher.VerifyActivity;
import com.spelist.tunekey.ui.teacher.students.activity.StudentDetailV2Ac;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.SharePreferenceUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.DeviceInfoUtils;

public class StudentProfileViewModel extends ToolbarViewModel {
    public int selectIndex = 0;
    public UserEntity selectStudent;

    private StudentListEntity studentData;
    private StudioInfoEntity studioInfoData = new StudioInfoEntity();
    private UserEntity teacherData;
    private UserEntity studentUserData;

    public MutableLiveData<Boolean> isStudent = new MutableLiveData<>(true);

    public MutableLiveData<String> studioLogoPath = new MutableLiveData<>();
    public MutableLiveData<String> studioName = new MutableLiveData<>();
    public MutableLiveData<String> studioEmail = new MutableLiveData<>();

    public MutableLiveData<String> teacherId = new MutableLiveData<>();

    public MutableLiveData<String> teacherName = new MutableLiveData<>();
    public MutableLiveData<String> userName = new MutableLiveData<>();
    public MutableLiveData<String> userId = new MutableLiveData<>();
    public MutableLiveData<String> userEmail = new MutableLiveData<>();
    public PolicyEntity policyEntity = new PolicyEntity();
    public ObservableField<Boolean> visibilityMin15 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityMin30 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityHour1 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityHour2 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityHour3 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityHour4 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityDay1 = new ObservableField<>(false);
    public ObservableField<Boolean> visibilityHour5 = new ObservableField<>(false);

    public ObservableField<Boolean> isShowProgressBar = new ObservableField<>(true);
    public ObservableField<Boolean> isShowInvite = new ObservableField<>(false);
    public ObservableField<Boolean> isShowStudioInfo = new ObservableField<>(false);
    public ObservableField<Boolean> isShowPending = new ObservableField<>(false);

    public List<UserEntity> studentListData = new ArrayList<>();

    /**
     * 是否可以聊天
     */
    public ObservableField<Boolean> isCanMessage = new ObservableField<>(false);
    public ObservableField<Boolean> isShowMessage = new ObservableField<>(false);
    public ObservableField<Boolean> isAddStudent = new ObservableField<>(false);

    public ObservableField<String> unReadMessageCount = new ObservableField<>("");
    public ObservableField<Boolean> isShowUnReadMessageCount = new ObservableField<>(false);
    public ObservableField<String> lastMessage = new ObservableField<>("");
    public ObservableField<String> lastMessageTime = new ObservableField<>("");

    public ObservableField<Boolean> isShowUnpaid = new ObservableField<>(false);
    public ObservableField<String> unpaidString = new ObservableField<>("");
    public boolean isHaveLesson = false;

    public TKConversation conversation;

    private List<Integer> reminderList = new ArrayList<>();
    public MutableLiveData<Boolean> isReminderOpened = new MutableLiveData<>();
    private boolean isClickReminderButton = true;
    public MutableLiveData<NotificationEntity> notificationData = new MutableLiveData<>(new NotificationEntity());
    public MutableLiveData<String> versionNameAndCode = new MutableLiveData<>("");
    public boolean isLatestVersion = true;
    public MutableLiveData<Boolean> logout = new MutableLiveData<>();
    public String currentCurrenciesData = CountriesCurrencies.getLocationCurrencies().toInvoiceSettingData().getSymbol();


    public StudentProfileViewModel(@NonNull Application application) {
        super(application);
        initMessage();
        getStudentList();
        getUser();
        getNotification();
        initLessonConfig();
        getInvoiceData();
        getAppVersion();
        versionNameAndCode.setValue("Your current version is" + DeviceInfoUtils.getVersionNameAndCode(getApplication()) + "for Android.");
        currentCurrenciesData = CountriesCurrencies.getLocationCurrencies().toInvoiceSettingData().getSymbol();

        if (SLCacheUtil.getStudioInfo() != null && SLCacheUtil.getStudioInfo().getCurrency() != null && !SLCacheUtil.getStudioInfo().getCurrency().getSymbol().equals("")) {
            currentCurrenciesData = SLCacheUtil.getStudioInfo().getCurrency().getSymbol();
        }
    }


    private void initLessonConfig() {
        if (ListenerService.shared.studentData != null) {
            List<LessonScheduleConfigEntity> scheduleConfigs = ListenerService.shared.studentData.getScheduleConfigs();

            isHaveLesson = scheduleConfigs.size() > 0;
//            setRightButtonVisibility((isHaveLesson || isShowUnpaid.get()) ? View.VISIBLE : View.GONE);
        }
    }

    @Override
    protected void clickRightTextButton() {
        super.clickRightTextButton();
        List<LoginHistoryItemVM.TKLoginHistory> loginHistory = SLCacheUtil.getLoginHistory().stream().filter(it -> !it.getPassword().equals("")).collect(Collectors.toList());
        loginHistory.removeIf(it -> (it.getUserId().equals(UserService.getInstance().getCurrentUserId()) || it.getUserData() == null));
        if (loginHistory.size() > 0) {
            uc.clickSwitchAccount.call();
        } else {
            SharePreferenceUtils.clear(getApplication());
            FirebaseAuth.getInstance().signOut();
            logout.setValue(true);
        }

    }

    private void getInvoiceData() {
        if (studioInfoData == null || studentData == null) {
            return;
        }
        addSubscribe(
                AppDataBase.getInstance().invoiceDao().getByStudioIdAndStudentId(studentData.getStudioId(), studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            d = d.stream().filter(it -> (
                                    (it.isSendAutomatically || (!it.status.equals(TKInvoiceStatus.created) && it.isSendAutomatically == false))&& !it.status.equals(TKInvoiceStatus.delete) &&!it.markAsPay && !it.status.equals(TKInvoiceStatus._void) && it.totalAmount > (it.paidAmount + it.waivedAmount))).collect(Collectors.toList());
                            isShowUnpaid.set(d.size() > 0);
                            if (d.size() > 0) {
                                StringBuilder st = new StringBuilder("");
                                for (TKInvoice invoice : d) {
                                    double unpaid = InvoiceCalculation.INSTANCE.getUnpaid(invoice);
                                    st.append(currentCurrenciesData).append(SLTools.getRound(unpaid, 2)).append(" due ").append(InvoiceCalculation.INSTANCE.getDueToString(invoice)).append(", ");
                                }
                                unpaidString.set(st.substring(0, st.length() - 2));
                            } else {
                                unpaidString.set("");
                            }
//                            setRightButtonVisibility((isHaveLesson || isShowUnpaid.get()) ? View.VISIBLE : View.GONE);
                        }, throwable -> {
//                            setRightButtonVisibility((isHaveLesson || isShowUnpaid.get()) ? View.VISIBLE : View.GONE);
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );

    }


    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setTitleString("Profile");
        List<LoginHistoryItemVM.TKLoginHistory> loginHistory = SLCacheUtil.getLoginHistory().stream().filter(it -> !it.getPassword().equals("")).collect(Collectors.toList());

        loginHistory.removeIf(it -> (it.getUserId().equals(UserService.getInstance().getCurrentUserId()) || it.getUserData() == null));
        if (loginHistory.size() > 0) {
            setRightButtonText("Switch account");
        } else {
            setRightButtonText("Sign out");
            setRightButtonTextColor(ContextCompat.getColor(getApplication().getApplicationContext(), R.color.red));
        }
        setRightButtonVisibility(View.VISIBLE);

    }

    //从0开始 周日是0 以此类推
    public void getReminderTime(int time) {

        boolean isAdd = true;
        for (int i = 0; i < reminderList.size(); i++) {
            if (reminderList.get(i) == time) {
                isAdd = false;
                reminderList.remove(i);
            }
        }

        if (isAdd) {
            reminderList.add(time);
        }
        Map<String, Object> map = new HashMap<>();
        map.put("reminderTimes", reminderList);
        updateNotification(map);
    }

    public void initMessage() {
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_PROFILE, () -> getUser());
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_GET_STUDIO, () -> {
            studioInfoData = ListenerService.shared.studentData.getStudioData();
            studioName.setValue(studioInfoData.getName());
            studioEmail.setValue(studioInfoData.getEmail());
            getStudentList();
            getInvoiceData();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_INFO_CHANGE, () -> {
            //studentList 刷新
            getStudentList();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_TEACHER_CHANGED, () -> {
            //teacher 刷新
            getStudentList();
            getInvoiceData();
        });

        Messenger.getDefault().register(this, MessengerUtils.REFRESH_AVATAR, String.class, time -> uc.refreshAvatar.setValue(time));
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_CHANGE_LESSON_CONFIG, this::initLessonConfig);

    }

    public void getStudentList() {
        studioInfoData = ListenerService.shared.studentData.getStudioData();
        isShowPending.set(false);
        isShowProgressBar.set(false);
        if (studioInfoData != null) {
            studioName.setValue(studioInfoData.getName());
            studioEmail.setValue(studioInfoData.getEmail());
            isShowInvite.set(false);
            isShowStudioInfo.set(true);
        } else {
            isShowInvite.set(true);
            isShowStudioInfo.set(false);
        }
        studentData = ListenerService.shared.studentData.getStudentData();
        if (studentData != null) {
            teacherId.setValue(ListenerService.shared.studentData.getStudentData().getTeacherId());

            if (teacherId.getValue().equals("")) {
                isShowProgressBar.set(true);
                isShowStudioInfo.set(false);
                isShowInvite.set(false);
                isShowPending.set(false);
                getStudentData();
            } else {
                isShowPending.set(studentData.getStudentApplyStatus() == 1);
                getTeacherName(teacherId.getValue());
            }

        } else {
            isShowProgressBar.set(true);
            isShowStudioInfo.set(false);
            isShowInvite.set(false);
            isShowPending.set(false);
            getStudentData();
        }
    }

    private void getStudentData() {
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListByStudentId(UserService.getInstance().getCurrentUserId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (data.size() > 0) {
                                studentData = data.get(0);
                                isShowPending.set(studentData.getStudentApplyStatus() == 1);
                                ListenerService.shared.studentData.setStudentData(studentData);
                                getStudioInfo(studentData.getStudioId());
                            } else {
                                isShowProgressBar.set(false);
                                if (studioInfoData != null) {
                                    isShowInvite.set(false);
                                    isShowStudioInfo.set(true);
                                } else {
                                    isShowInvite.set(true);
                                    isShowStudioInfo.set(false);
                                }
                            }
                        }, throwable -> {
                            isShowProgressBar.set(false);
                            if (studioInfoData != null) {
                                isShowInvite.set(false);
                                isShowStudioInfo.set(true);
                            } else {
                                isShowInvite.set(true);
                                isShowStudioInfo.set(false);
                            }
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    private void getStudioInfo(String studioId) {
        if (!studioId.equals("")) {
            addSubscribe(
                    UserService.getStudioInstance()
                            .getStudioInfoByStudioId(studioId)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
//                                Logger.e("获取studioInfo%s", data);
                                ListenerService.shared.studentData.setStudioData(data);
                                SLCacheUtil.setStudioInfo(data);
                                isShowProgressBar.set(false);

                                if (studioInfoData != null) {
                                    studioName.setValue(data.getName());
                                    studioEmail.setValue(data.getEmail());
                                    isShowInvite.set(false);
                                    isShowStudioInfo.set(true);
                                } else {
                                    isShowInvite.set(true);
                                    isShowStudioInfo.set(false);
                                }
                                teacherId.setValue(studentData.getTeacherId());
                            }, throwable -> {
                                isShowProgressBar.set(false);
                                if (studioInfoData != null) {
                                    isShowInvite.set(false);
                                    isShowStudioInfo.set(true);
                                } else {
                                    isShowInvite.set(true);
                                    isShowStudioInfo.set(false);
                                }
                                Logger.e("获取studioInfo失败,失败原因:" + throwable.getMessage());
                            })

            );
        } else {
            addSubscribe(
                    UserService.getStudioInstance().
                            getStudioInfoByTeacherId(studentData.getTeacherId())
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                Logger.e("获取studioInfo%s", data);
                                ListenerService.shared.studentData.setStudioData(data);
                                SLCacheUtil.setStudioInfo(data);
                                Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_GET_STUDIO);
                                isShowProgressBar.set(false);

                                if (studioInfoData != null) {
                                    studioName.setValue(data.getName());
                                    studioEmail.setValue(data.getEmail());
                                    isShowInvite.set(false);
                                    isShowStudioInfo.set(true);
                                } else {
                                    isShowInvite.set(true);
                                    isShowStudioInfo.set(false);
                                }
                                teacherId.setValue(studentData.getTeacherId());
                            }, throwable -> {
                                isShowProgressBar.set(false);
                                if (studioInfoData != null) {
                                    isShowInvite.set(false);
                                    isShowStudioInfo.set(true);
                                } else {
                                    isShowInvite.set(true);
                                    isShowStudioInfo.set(false);
                                }
                                Logger.e("获取studioInfo失败,失败原因:" + throwable.getMessage());
                            })

            );
        }

    }

    public void getTeacherName(String teacherId) {
        addSubscribe(UserService
                .getInstance()
                .getUserEntityForActive(teacherId)
                .subscribe(userEntity -> {
                    teacherData = userEntity;
                    teacherName.setValue(userEntity.getName());
                }, throwable -> {
                    Logger.e("==获取列表失败" + throwable.getMessage());
                }));
    }

    /**
     *
     */


    public void getUser() {
        addSubscribe(UserService
                .getInstance()
                .getCurrentUserEntity()
                .subscribe(userEntity -> {
                    studentUserData = userEntity;
                    ListenerService.shared.studentData.setUser(studentUserData);
                    userId.setValue(userEntity.getUserId());
                    userName.setValue(userEntity.getName());
                    if (!userEntity.getEmail().contains("_fake@tunekey.app")) {
                        userEmail.setValue(userEntity.getEmail());
                    } else {
                        userEmail.setValue(userEntity.getPhone());
                    }
                    if (userEntity.getRoleIds().contains(UserEntity.UserRole.parents)) {
                        isStudent.setValue(false);
                        List<String> kids = userEntity.getKids();
                        getKidsData(kids);
                    } else {
                        isStudent.setValue(true);
                    }
                }, throwable -> {
                    Logger.e("==获取列表失败" + throwable.getMessage());
                }));
    }

    private void getKidsData(List<String> kids) {
        addSubscribe(
                UserService.getInstance().getUserIds(kids)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            studentListData.clear();
                            studentListData = d;
                            studentListData.add(new UserEntity().setUserId("ADD"));
                            selectStudent = d.get(0);
                            uc.refreshStudentList.call();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );

    }

    public void getNotification() {
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                UserService
                        .getInstance()
                        .getNotification()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
//                            if (!isSuccess.get()){

                            List<NotificationEntity.PracticeReminder> workData = data.getWorkdayPracticeReminder();
                            List<NotificationEntity.PracticeReminder> weekData = data.getWeekendPracticeReminder();
                            if (workData.size() < 3) {
                                NotificationEntity.PracticeReminder practiceReminder = new NotificationEntity.PracticeReminder();
                                practiceReminder.setTime(61200);
                                practiceReminder.setEnable(true);
                                workData.add(practiceReminder);
                                workData.add(new NotificationEntity.PracticeReminder()
                                        .setTime(-1)
                                        .setEnable(false));
                                workData.add(new NotificationEntity.PracticeReminder()
                                        .setTime(-1)
                                        .setEnable(false));
                                data.setWorkdayPracticeReminder(workData);
                            }
                            if (weekData.size() < 3) {
                                weekData.add(new NotificationEntity.PracticeReminder()
                                        .setTime(-1)
                                        .setEnable(false));
                                weekData.add(new NotificationEntity.PracticeReminder()
                                        .setTime(-1)
                                        .setEnable(false));
                                weekData.add(new NotificationEntity.PracticeReminder()
                                        .setTime(-1)
                                        .setEnable(false));
                                data.setWeekendPracticeReminder(weekData);
                            }


                            notificationData.setValue(data);
                            isSuccess.set(true);
                            reminderList = data.getReminderTimes();
                            isReminderOpened.setValue(data.isReminderOpened());
                            for (Integer integer : reminderList) {
                                switch (integer) {
                                    case 5:
                                        isClickReminderButton = false;
                                        visibilityMin15.set(true);
                                        break;
                                    case 10:
                                        isClickReminderButton = false;
                                        visibilityMin30.set(true);
                                        break;
                                    case 15:
                                        isClickReminderButton = false;
                                        visibilityHour1.set(true);
                                        break;
                                    case 30:
                                        isClickReminderButton = false;
                                        visibilityHour2.set(true);
                                        break;
                                    case 60:
                                        isClickReminderButton = false;
                                        visibilityHour3.set(true);
                                        break;
                                    case 120:
                                        isClickReminderButton = false;
                                        visibilityHour4.set(true);
                                        break;
                                    case 180:
                                        isClickReminderButton = false;
                                        visibilityHour5.set(true);
                                        break;
                                    case 1440:
                                        isClickReminderButton = false;
                                        visibilityDay1.set(true);
                                        break;
                                }
//                                }
                            }

                        }, throwable -> {
                            if (!isSuccess.get()) {
                                Logger.e("获取Notification失败,失败原因" + throwable.getMessage());
                            }
                        })

        );
    }


    public void updateNotification(Map<String, Object> map) {
        addSubscribe(
                UserService
                        .getInstance()
                        .updateNotification(map)
                        .subscribe(status -> {
                            Messenger.getDefault().sendNoMsg(MessengerUtils.REFRESH_REMINDER);
//                            SLToast.success("Update successfully!");
                            Logger.e("======%s", "更新成功");
                            //创建Intent对象
                        }, throwable -> {
                            Logger.e("=====更新失败=" + throwable.getMessage());
                        }));
    }

    public void getFollowUsData() {
        showDialog();
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                UserService
                        .getInstance()
                        .getFollowUsData()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            if (!isSuccess.get()) {
                                uc.showFollow.setValue(data);
                                isSuccess.set(true);
                            }
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

//    public void setNotification() {
//        List<Integer> list = new ArrayList<>();
//        notificationEntity
//                .setUserId(FirebaseAuth.getInstance().getUid())
//                .setNotesNotificationOpened(true)
//                .setNewAchievementNotificationOpened(true)
//                .setFileSharedNotificationOpened(true)
//                .setRescheduleConfirmedNotificationOpened(true)
//                .setCancelLessonNotificationOpened(true)
//                .setHomeworkReminderTime(-1)
//                .setReminderOpened(true)
//                .setReminderTimes(list)
//                .setRegistrationToken("")
//                .setCreateTime(System.currentTimeMillis() / 1000 + "")
//                .setUpdateTime(System.currentTimeMillis() / 1000 + "");
//        addSubscribe(
//                UserService
//                        .getStudioInstance()
//                        .setNotification(notificationEntity)
//                        .subscribe(status -> {
//                            SLToast.success("Saved successfully!");
//                            //创建Intent对象
//
//                        }, throwable -> {
//                            Logger.e("=====上传失败=" + throwable.getMessage());
//                            SLToast.error("！！！！！!");
//                        }));
//
//    }

    //封装一个点击事件观察者
    public UIClickObservable uc = new UIClickObservable();

    public static class UIClickObservable {
        public SingleLiveEvent<Void> clickAddLessonType = new SingleLiveEvent<>();
        public SingleLiveEvent<String> refreshAvatar = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickInviteInstructor = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickContact = new SingleLiveEvent<>();
        public SingleLiveEvent<TKFollowUs> showFollow = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickFAQ = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickSwitchAccount = new SingleLiveEvent<>();
        public SingleLiveEvent<Integer> toMainActivity = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> refreshStudentList = new SingleLiveEvent<>();

    }

    public BindingCommand clickStudioInfo = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            if (studioInfoData != null) {
                Bundle bundle = new Bundle();
                bundle.putInt("type", 3);
                boolean teacherIsApply = true;
                if (studentData.getStudentApplyStatus() == 1) {
                    teacherIsApply = false;
                }
                bundle.putBoolean("teacherIsApply", teacherIsApply);
                bundle.putString("studentName", studentData.getName());
                if (teacherData != null) {
                    bundle.putString("teacherId", teacherData.getUserId());
                } else {
                    bundle.putBoolean("isStudio", true);
                    bundle.putSerializable("studioData", studioInfoData);
                }
                bundle.putString("color", studioInfoData.getStorefrontColor());
                startActivity(ConfirmStorefrontActivity.class, bundle);
            }

        }
    });
    public BindingCommand clickContact = new BindingCommand(() -> {
        uc.clickContact.call();
    });
    public BindingCommand clickReportBug = new BindingCommand(() -> {
        startActivity(ReportBugActivity.class);
    });

    public BindingCommand clickFAQ = new BindingCommand(() -> {
        uc.clickFAQ.call();
    });
    public BindingCommand clickInviteInstructor = new BindingCommand(() -> uc.clickInviteInstructor.call());


    public BindingCommand linEditProfile = new BindingCommand(() -> {
        if (isHaveLesson || isShowUnpaid.get()) {
            Bundle bundle = new Bundle();
            bundle.putBoolean("isStudent", true);
            bundle.putSerializable("student", studentData);
            startActivity(StudentDetailV2Ac.class, bundle);
        } else {
            startActivity(StudentProfileEditActivity.class);
        }

    });

    public BindingCommand linPassword = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            startActivity(VerifyActivity.class);
        }
    });
    public BindingCommand linAccount = new BindingCommand(() -> startActivity(AccountActivity.class));
    public BindingCommand clickPayment = new BindingCommand(() -> {
        Logger.e("ssss==>%s","clickPayment");
        List<LessonScheduleConfigEntity> data= new ArrayList<>();
        for (LessonScheduleConfigEntity scheduleConfig : ListenerService.shared.studentData.getScheduleConfigs()) {
            if (scheduleConfig.getStudentId().equals(studentData.getStudentId())){
                data.add(scheduleConfig);
            }
        }
        Bundle bundle = new Bundle();
        bundle.putSerializable("lessonConfigs", (Serializable) data);
        bundle.putSerializable("studentData", studentData);
        bundle.putSerializable("role", Integer.parseInt(SLCacheUtil.getUserRole()));
        startActivity(BalanceListAc.class, bundle);
    });

    public BindingCommand linPrivate = new BindingCommand(() -> startActivity(TermsAndPrivacyActivity.class));
    public BindingCommand<Boolean> min15 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityMin15.set(aBoolean);
            getReminderTime(5);
        }
    });
    public BindingCommand<Boolean> min30 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityMin30.set(aBoolean);
            getReminderTime(10);
        }
    });
    public BindingCommand<Boolean> hour1 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityHour1.set(aBoolean);
            getReminderTime(15);
        }
    });
    public BindingCommand<Boolean> hour2 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityHour2.set(aBoolean);
            getReminderTime(30);
        }
    });
    public BindingCommand<Boolean> hour3 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityHour3.set(aBoolean);
            getReminderTime(60);
        }
    });

    public BindingCommand<Boolean> hour4 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityHour4.set(aBoolean);
            getReminderTime(120);
        }
    });

    public BindingCommand<Boolean> hour5 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityHour5.set(aBoolean);
            getReminderTime(180);
        }
    });
    public BindingCommand<Boolean> day1 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            visibilityDay1.set(aBoolean);
            getReminderTime(720);
        }
    });

    //------------------------------------------聊天相关-----------------------------------------
    public void initChatData() {
        isShowMessage.set(false);

//        addSubscribe(
//                AppDataBase.getInstance().conversationDao()
//                        .getByTIdAndSId(teacherId.getValue(), UserService.getInstance().getCurrentUserId())
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            if (studioName == null || studioName.getValue().equals("")) {
//                                isCanMessage.set(false);
//                                return;
//                            }
//                            if (data.size() > 0) {
//                                isCanMessage.set(false);
//                                isShowMessage.set(false);
//                                conversation = data.get(0);
//                                TKConversationUser user = null;
//                                for (TKConversationUser item : conversation.getUsers()) {
//                                    if (item.getUserId().equals(UserService.getInstance().getCurrentUserId())) {
//                                        user = item;
//                                    }
//                                }
//                                if (user != null) {
//                                    isShowUnReadMessageCount.set(user.getUnreadMessageCount() != 0);
//                                    if (user.getUnreadMessageCount() > 9) {
//                                        unReadMessageCount.set("9+");
//                                    } else {
//                                        unReadMessageCount.set(user.getUnreadMessageCount() + "");
//                                    }
//                                }
//                                if (conversation.getLatestMessage() != null) {
//                                    isShowMessage.set(true);
//
//                                    lastMessage.set(conversation.getLatestMessage().messageText(false));
//                                    lastMessageTime.set(TimeUtils.getStrOfTimeTillNow((long) conversation.getLatestMessage().getDatetime()));
//                                } else {
//                                    isCanMessage.set(true);
//                                }
//
//
//                            } else {
//                                if (!isShowPending.get()) {
//                                    isCanMessage.set(true);
//                                }
//                            }
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//                        })
//        );
    }

    public BindingCommand clickMessage = new BindingCommand(() -> {

        if (conversation == null) {
            if (teacherData == null) {
                return;
            }
            addSubscribe(ChatService.getConversationInstance()
                    .getFromLocal(ChatService.getConversationInstance().getPrivateConversationId(teacherData.getUserId()))
                    .flatMap(conversation -> {
                        if (conversation.getId().equals("-1")) {
                            showDialog();
                            return ChatService.getConversationInstance().getPrivateWithoutLocal(teacherData.getUserId());
                        } else {
                            return Observable.create(emitter -> {
                                emitter.onNext(conversation);
                                emitter.onComplete();
                            });
                        }
                    })
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread(), true)
                    .subscribe(data -> {
                        conversation = data;
                        dismissDialog();
                        toConversion();
                    }, throwable -> {
                        dismissDialog();
                        SLToast.showError();
                        Logger.e("失败,失败原因" + throwable.getMessage());
                    })

            );
        } else {
            toConversion();
        }
    });

    private void toConversion() {
        isShowUnReadMessageCount.set(false);
        Bundle bundle = new Bundle();
        bundle.putSerializable("conversation", conversation);
        startActivity(ChatActivity.class, bundle);
        TKConversationUser user = null;
        for (TKConversationUser item : conversation.getUsers()) {
            if (item.getUserId().equals(UserService.getInstance().getCurrentUserId())) {
                user = item;
            }
        }
        if (user != null) {
            user.setUnreadMessageCount(0);
            ListenerService.shared.studentData.setConversation(conversation);
            Messenger.getDefault().sendNoMsg(MessengerUtils.STUDENT_CHAT_CONVERSION_CHANGE);
        }
    }

    /**
     * 查询SupportChat
     */
    public void getSupportGroupConversation() {
        String currentUserId = UserService.getInstance().getCurrentUserId();
        addSubscribe(
                ChatService.getConversationInstance()
                        .getFromLocal(currentUserId)
                        .flatMap(conversation -> {
                            if (conversation.getId().equals("-1")) {
                                showDialog();
                                return ChatService.getConversationInstance().getConversationByIdFromCloud(currentUserId);
                            } else {
                                return Observable.create(emitter -> {
                                    emitter.onNext(conversation);
                                    emitter.onComplete();
                                });
                            }
                        })
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (data.getId().equals("-1")) {
                                createSupportChat(currentUserId);
                            } else {
                                toSupportGroupConversation(data);
                            }

                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败1,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })
        );
    }

    /**
     * 创建SupportChat
     *
     * @param userId
     */
    public void createSupportChat(String userId) {
        addSubscribe(
                ChatService.getConversationInstance()
                        .getSupportAccounts()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(supperAccount -> {
                            Logger.e("获取supperAccount成功%s", supperAccount.size());
                            if (supperAccount.size() <= 0) {
                                dismissDialog();
                                SLToast.showError();
                                return;
                            }
                            int now = TimeUtils.getCurrentTime();
                            Map<String, Boolean> userMap = new HashMap<>();
                            userMap.put(userId, true);
                            List<TKConversationUser> userList = new ArrayList<>();
                            UserEntity currentUserData = SLCacheUtil.getCurrentUserData(userId);
                            if (currentUserData != null) {
                                userList.add(new TKConversationUser(userId, userId, currentUserData.getName(), 0));
                            } else if (ListenerService.shared.user != null) {
                                userList.add(new TKConversationUser(userId, userId, ListenerService.shared.user.getName(), 0));
                            }
                            for (TKSupportAccount account : supperAccount) {
                                userMap.put(account.getUserId(), true);
                                userList.add(new TKConversationUser(userId, account.getUserId(), account.getName(), 0));
                            }
                            TKConversation conversation = new TKConversation()
                                    .setId(userId)
                                    .setTitle("Support Center")
                                    .setType(ConversationType.groupType)
                                    .setCreatorId(userId)
                                    .setUserMap(userMap)
                                    .setUsers(userList)
                                    .setFull(false)
                                    .setLatestMessageId("")
                                    .setLatestMessageTimestamp(0)
                                    .setPinTop(false)
                                    .setRemoved(false)
                                    .setCreateTime(now)
                                    .setUpdateTime(now);

                            FirebaseFirestore.getInstance().runTransaction(transaction -> {
                                DocumentSnapshot documentSnapshot = transaction.get(DatabaseService.Collections.conversation().document(conversation.getId()));
                                if (documentSnapshot.exists()) {
                                    throw new FirebaseFirestoreException("Conversation exists",
                                            FirebaseFirestoreException.Code.NOT_FOUND);
                                }
                                transaction.set(DatabaseService.Collections.conversation().document(conversation.getId()), conversation);
                                for (TKConversationUser user : conversation.getUsers()) {
                                    String cId = IDUtils.getId();
                                    transaction.set(DatabaseService.Collections.dataChangeHistory().document(cId),
                                            new DataChangeHistory()
                                                    .setId(cId)
                                                    .setUserId(user.getUserId())
                                                    .setCollection("conversation")
                                                    .setDocId(conversation.getId())
                                                    .setActionType(ChatDataChangeActionType.add)
                                                    .setContent(SLJsonUtils.toJsonString(conversation))
                                                    .setCreateTime(now));
                                }
                                return null;
                            }).addOnCompleteListener(task -> {
                                if (task.getException() == null) {
                                    new Thread(() ->
                                            AppDataBase.getInstance()
                                                    .conversationDao()
                                                    .insert(conversation)
                                    ).start();
                                    toSupportGroupConversation(conversation);
                                } else {
                                    dismissDialog();
                                    Logger.e("失败2,失败原因" + task.getException().getMessage());
                                    SLToast.showError();
                                }
                            });


                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败3,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })

        );
    }

    public void toSupportGroupConversation(TKConversation data) {
        dismissDialog();
        Bundle bundle = new Bundle();
        bundle.putSerializable("conversation", data);
        startActivity(ChatActivity.class, bundle);
    }

    public void switchAccount(LoginHistoryItemVM.TKLoginHistory data) {
        showDialog();
        FirebaseAuth.getInstance().signInWithEmailAndPassword(data.getEmail(), data.getPassword())
                .addOnCompleteListener(new OnCompleteListener<AuthResult>() {
                    @Override
                    public void onComplete(@NonNull Task<AuthResult> task) {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            SLCacheUtil.setUserPassword(data.getUserId(), data.getPassword());
                            if (data.getUserData().getRoleIds().contains("1")) {
                                SharePreferenceUtils.put(getApplication(), "isLogin", "teacher");
                                SLCacheUtil.setCurrentUserData(data.getUserData().getUserId(), data.getUserData());

                                uc.toMainActivity.setValue(1);


                            } else if (data.getUserData().getRoleIds().contains("2")) {
                                SharePreferenceUtils.put(getApplication(), "isLogin", "student");
                                SLCacheUtil.setCurrentUserData(data.getUserData().getUserId(), data.getUserData());
                                uc.toMainActivity.setValue(2);
                            }

                        } else {
                            SLToast.error("Login failed, please log in to the account you want to switch");
                            uc.toMainActivity.setValue(3);
                        }
                    }
                });
    }
    public void getAppVersion() {
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .getAppVersion()
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("获取成功1:%s", SLJsonUtils.toJsonString(data));
                            String versionInfo = "";
                            if (DeviceInfoUtils.getVersionCode(getApplication())<data){
                                versionInfo = "The latest version is available for update. UPDATE NOW";
                                isLatestVersion = false;
                            }else {
                                versionInfo = "Your Tunekey has been updated to the latest version.";
                            }
                            versionNameAndCode.setValue("Your current version is " + DeviceInfoUtils.getVersionNameAndCode(getApplication()) + " for Android.\n"+versionInfo);

                        }, err -> {
                            Logger.e("1失败,失败原因" + err.getMessage());
                        })
        );
    }

}
