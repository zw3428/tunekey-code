package com.spelist.tunekey.ui.student.sLessons.vm;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.text.Html;
import android.text.Spanned;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.utils.MemoryManager;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.ChatService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.StudioService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleMaterialEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.NotificationEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKFollowUp;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.UserNotificationEntity;
import com.spelist.tunekey.entity.chat.TKConversation;
import com.spelist.tunekey.entity.chat.TKMessage;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentLessonDetailActivity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentRescheduleAc;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentRescheduleRequestAc;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.StudioCalendarHomeEX;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.GlobalFields;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import retrofit2.http.HEAD;

public class StudentLessonsViewModel extends BaseViewModel {
    public List<TKMessage> unReadMessage = new ArrayList<>();
    public boolean isShowedUnReadMessage = false;
    public ObservableField<Boolean> isHaveStudioAnnouncement = new ObservableField<>(false);
    public TKConversation studioAnnouncementConversation;
    public ObservableField<Integer> pendingCardLayoutVisibility = new ObservableField<>(View.GONE);

    public ObservableField<Boolean> emptyLayoutIsVisibility = new ObservableField<>(true);

    public MutableLiveData<String> emptyInfo = new MutableLiveData<>("Add your lessons in minutes.\nIt's easy, we promise!");

    public MutableLiveData<Boolean> isShowInviteButton = new MutableLiveData<>(false);
    public MutableLiveData<Boolean> isShowNextLesson = new MutableLiveData<>(false);
    public MutableLiveData<Boolean> isShowAddLessonButton = new MutableLiveData<>(false);
    public MutableLiveData<String> nLDay = new MutableLiveData<>("");
    public MutableLiveData<String> nLMonth = new MutableLiveData<>("");
    public MutableLiveData<String> nLInfo = new MutableLiveData<>("");
    public MutableLiveData<String> nLSelfStudy = new MutableLiveData<>(" 0 hrs");
    public MutableLiveData<String> nLAssignment = new MutableLiveData<>(" No assignment");
    public MutableLiveData<Integer> nLAssignmentColor = new MutableLiveData<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
    public MutableLiveData<Boolean> isShowNextLessonButton = new MutableLiveData<>(false);
    public ObservableField<Boolean> isShowRequest = new ObservableField<>(false);
    public ObservableField<Boolean> isShowRequestBox = new ObservableField<>(false);
    public ObservableField<String> requestCount = new ObservableField<>("0");


    public LessonScheduleEntity nextLessonData;
    public LessonScheduleEntity localNextLessonData;

    public StudentListEntity studentData;
    public UserEntity teacherData;
    public boolean isShowSignPolicy = false;
    public int startTimestamp = 0;
    public int endTimestamp = 0;

    public List<LessonScheduleConfigEntity> scheduleConfigs = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypes = new ArrayList<>();
    public Map<String, LessonScheduleEntity> lessonScheduleIdMap = new HashMap<>();
    public Map<String, LessonTypeEntity> lessonTypeMap = new HashMap<>();
    public Map<String, LessonScheduleConfigEntity> lessonConfigMap = new HashMap<>();
    public List<LessonCancellationEntity> cancelData = new ArrayList<>();
    public Map<String, LessonCancellationEntity> cancelDataMap = new HashMap<>();
    public List<LessonRescheduleEntity> rescheduleData = new ArrayList<>();
    public Map<String, LessonRescheduleEntity> rescheduleDataMap = new HashMap<>();
    public List<TKPractice> practiceData = new ArrayList<>();
    public List<AchievementEntity> achievementData = new ArrayList<>();
    public Map<String, List<AchievementEntity>> achievementDataMap = new HashMap<>();
    public Map<String, List<LessonScheduleMaterialEntity>> materialsDataMap = new HashMap<>();

    public ObservableField<String> requestStatus = new ObservableField<>("");
    public ObservableField<Spanned> requestInfo = new ObservableField<>(Html.fromHtml(""));
    public ObservableField<String> requestBeforeTime = new ObservableField<>("");
    public ObservableField<String> requestBeforeDay = new ObservableField<>("");
    public ObservableField<String> requestBeforeMonth = new ObservableField<>("");
    public ObservableField<String> requestAfterTime = new ObservableField<>("");
    public ObservableField<String> requestAfterDay = new ObservableField<>("");
    public ObservableField<String> requestAfterMonth = new ObservableField<>("");
    public ObservableField<Boolean> requestIsShowAfterQuestionImg = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowArrow = new ObservableField<>(true);

    public ObservableField<Boolean> requestIsShowConfirmButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowRescheduleButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowCenterRetractButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowRetractButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowDeclinedButton = new ObservableField<>(false);
    public ObservableField<Boolean> requestIsShowCloseButton = new ObservableField<>(false);

    public List<LessonRescheduleEntity> undoneRescheduleData = new ArrayList<>();
    private boolean isCheckingNotifications = false;

    public PolicyEntity policyData;

    public HashMap<String, LessonScheduleEntity> onlineLessonData = new HashMap<>();
    public HashMap<String, LessonScheduleEntity> locationLessonData = new HashMap<>();
    public HashMap<String, TeacherInfoEntity> teacherInfoDataMap = new HashMap<>();
    public String studentId;

    public StudentLessonsViewModel(@NonNull Application application) {
        super(application);
        studentId = ListenerService.shared.studentData.getUser().getUserId();
        initData();
    }

    public UserEntity getTeacherData(String id) {
        UserEntity u = new UserEntity();
        if (teacherData != null) {
            u = teacherData;
        } else {
            if (teacherInfoDataMap.get(id) != null && teacherInfoDataMap.get(id).getUserData() != null) {
                u = teacherInfoDataMap.get(id).getUserData();
            }
        }
        return u;
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.PARENT_SELECT_KIDS_DONE, () -> {
            studentId = ListenerService.shared.studentData.getUser().getUserId();
            materialsDataMap.clear();
            achievementDataMap.clear();
            achievementData.clear();
            practiceData.clear();
            rescheduleDataMap.clear();
            rescheduleData.clear();
            cancelDataMap.clear();
            lessonConfigMap.clear();
            lessonTypeMap.clear();
            lessonScheduleIdMap.clear();
            lessonTypes.clear();
            scheduleConfigs.clear();
            onlineLessonData.clear();
            locationLessonData.clear();
            undoneRescheduleData.clear();
            lessonDataList = new ObservableArrayList<>();
            lessonDataList.clear();

            initData();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_GET_STUDIO, () -> {
            for (TeacherInfoEntity teacherInfoEntity : AppDataBase.getInstance().teacherInfoDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
                teacherInfoDataMap.put(teacherInfoEntity.getUserId(), teacherInfoEntity);
            }
            initNotification();
            reloadData();
        });
        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, () -> {
            initNotification();
            reloadData();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_FOLLOW_UP_CHANGE, () -> {
            initFollowUp();
            reloadData();
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_PRACTICE_CHANGED, () -> {
            practiceData = ListenerService.shared.studentData.getPracticeData();
            new Handler().postDelayed(this::initShowData, 1000);

        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_ACHIEVEMENT_CHANGED, () -> {
            Logger.e("Achievement个数%s", ListenerService.shared.studentData.getAchievementData().size());
            achievementData = ListenerService.shared.studentData.getAchievementData();
            achievementDataMap.clear();
            for (AchievementEntity datum : achievementData) {
                if (achievementDataMap.get(datum.getScheduleId()) != null) {
                    achievementDataMap.get(datum.getScheduleId()).add(datum);
                } else {
                    List<AchievementEntity> list = new ArrayList<>();
                    list.add(datum);
                    achievementDataMap.put(datum.getScheduleId(), list);
                }
            }
            initShowData();
        });
        //materials 修改
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_MATERIALS_CHANGED, () -> getLessonScheduleMaterials());

        Messenger.getDefault().register(this, MessengerUtils.STUDENT_TEACHER_CHANGED, () -> {
            endTimestamp = TimeUtils.getCurrentTime();
            startTimestamp = (int) (TimeUtils.addMonth(endTimestamp * 1000L, -7) / 1000L);

            if (ListenerService.shared.studentData.isHaveTeacher()) {
                studentData = ListenerService.shared.studentData.getStudentData();
                getTeacherData(true);
                getTeacherData(false);
            } else {
                String time = TimeUtils.getCurrentTime() + "";
                studentData = new StudentListEntity()
                        .setTeacherId("")
                        .setStudioId("")
                        .setStudentId(studentId)
                        .setName("")
                        .setEmail("")
                        .setInvitedStatus("-1")
                        .setLessonTypeId("")
                        .setStatusHistory(new ArrayList<>())
                        .setStudentApplyStatus(0)
                        .setCreateTime(time)
                        .setUpdateTime(time);
                ListenerService.shared.studentData.setStudentData(studentData);
                getDatas(true);
                getDatas(false);
                getScheduleConfig();
                initReschedule();
            }
        });

        Messenger.getDefault().register(this, MessengerUtils.STUDENT_NOTE_CHANGED, LessonScheduleEntity.class, new BindingConsumer<LessonScheduleEntity>() {
            @Override
            public void call(LessonScheduleEntity data) {
                for (StudentLessonsItemViewModel itemViewModel : lessonDataList) {
                    if (itemViewModel.data.getId().equals(data.getId())) {
                        itemViewModel.initData(data);
                    }
                }
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_READ_MATERIAL, LessonScheduleEntity.class, new BindingConsumer<LessonScheduleEntity>() {
            @Override
            public void call(LessonScheduleEntity data) {
                for (StudentLessonsItemViewModel itemViewModel : lessonDataList) {
                    if (itemViewModel.data.getId().equals(data.getId())) {
                        itemViewModel.initData(data);
                    }
                }
                if (materialsDataMap.get(data.getId()) != null) {
                    materialsDataMap.put(data.getId(), data.getMaterialData());
                }
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_CHANGE_LESSON_CONFIG, this::reloadData);

        Messenger.getDefault().register(this, MessengerUtils.STUDENT_DELETE_ALL_LESSON, this::reloadData);
        Messenger.getDefault().register(this, MessengerUtils.REFRESH_REMINDER, this::initLessonNotification);
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_GET_STUDIO, () -> initStudioAnnouncement());

    }

    private void initFollowUp() {
        List<TKFollowUp> followUps = ListenerService.shared.studentData.getFollowUps();
        List<LessonRescheduleEntity> data = new ArrayList<>();

        if (followUps != null && followUps.size() > 0) {
            for (TKFollowUp followUp : followUps) {
                if (followUp.getDataType().equals(TKFollowUp.DataType.reschedule)) {
                    LessonRescheduleEntity rescheduleData = CloneObjectUtils.cloneObject(followUp.getRescheduleData());
                    rescheduleData.setFollowData(followUp);
                    data.add(rescheduleData);
                }
                if (followUp.getDataType().equals(TKFollowUp.DataType.cancellation)) {
                    LessonCancellationEntity lessonCancellationEntity = CloneObjectUtils.cloneObject(followUp.getCancellationData());
                    LessonRescheduleEntity e = lessonCancellationEntity.convertToReschedule();
                    e.setFollowData(followUp);
                    data.add(e);
                }
            }
        }

        Logger.e("undoneRescheduleData==>%s==>%s", undoneRescheduleData.size(), followUps.size());
        undoneRescheduleData = data;
        initReschedule();


    }


    private void initData() {
        if (studentId.equals("")){
            return;
        }
        if (!emptyLayoutIsVisibility.get()) {
            emptyLayoutIsVisibility.set(true);
        }

        for (TeacherInfoEntity teacherInfoEntity : AppDataBase.getInstance().teacherInfoDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
            teacherInfoDataMap.put(teacherInfoEntity.getUserId(), teacherInfoEntity);
        }

        endTimestamp = TimeUtils.getCurrentTime();

        startTimestamp = (int) (TimeUtils.addMonth(endTimestamp * 1000L, -7) / 1000L);

        getStudentData(true);
        getStudentData(false);
        getAchievement();
        getLessonScheduleMaterials();
        initFollowUp();
        initStudioAnnouncement();
    }

    public void reloadData() {
        getDatas(true);
        getDatas(false);
        getScheduleConfig();
        Logger.e("reloadData?%s", "reloadData");
    }

    private void initLessonNotification() {
        if (isCheckingNotifications) {
            return;
        }
        int startTime = TimeUtils.getCurrentTime();
        int endTime = (int) (TimeUtils.addMonth(startTime * 1000L, 1) / 1000L);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleByStudentIdAndTeacherIdAndTime(false, studentData.getStudentId(), startTime, endTime)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
//                            data.removeIf(scheduleEntity -> scheduleEntity.getShouldDateTime() < startTime || scheduleEntity.isCancelled() || (scheduleEntity.isRescheduled() && !scheduleEntity.getRescheduleId().equals("")));
                            getNotificationData(data);


                        }, throwable -> Logger.e("获取schedule失败,失败原因" + throwable.getMessage()))
        );


    }

    private void getNotificationData(List<LessonScheduleEntity> lessonScheduleList) {
        if (isCheckingNotifications) {
            return;
        }
        isCheckingNotifications = true;
        addSubscribe(
                UserService
                        .getInstance()
                        .getNotification(false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(notificationConfig -> {


                            TKNotificationUtils.closeLessonNotification(TApplication.getInstance().getBaseContext());

                            List<Integer> lessonNotificationIds = SLCacheUtil.getLessonNotificationIds();
                            if (notificationConfig.isPracticeReminderOpened()) {
                                //需要添加的
                                List<Integer> addTime = new ArrayList<>();
                                List<String> addTimeString = new ArrayList<>();
                                //30天的时间戳
                                List<Integer> time30 = new ArrayList<>();
                                Calendar startDay = TimeUtils.getStartDay(TimeUtils.getCurrentTime());
                                time30.add((int) (startDay.getTimeInMillis() / 1000L));
                                for (int i = 0; i < 60; i++) {
                                    startDay.add(Calendar.DATE, 1);
                                    time30.add((int) (startDay.getTimeInMillis() / 1000L));
                                }
                                int currentTime = TimeUtils.getCurrentTime();
                                for (Integer time : time30) {
                                    if (addTime.size() > 30) {
                                        break;
                                    }
                                    int dayOfWeek = TimeUtils.getDayOfWeek(time * 1000L);
                                    if (dayOfWeek == 1 || dayOfWeek == 7) {
                                        for (NotificationEntity.PracticeReminder item : notificationConfig.getWeekendPracticeReminder()) {
                                            if (item.isEnable()) {
                                                int e = time + item.getTime();
                                                if (e >= currentTime) {
                                                    addTime.add(e);
                                                    addTimeString.add(TimeUtils.timeFormat(time + item.getTime(), "yyyy-MM-dd HH:mm:ss"));
                                                }
                                            }
                                        }
                                    } else {
                                        for (NotificationEntity.PracticeReminder item : notificationConfig.getWorkdayPracticeReminder()) {
                                            if (item.isEnable()) {
                                                int e = time + item.getTime();
                                                if (e >= currentTime) {
                                                    addTime.add(time + item.getTime());
                                                    addTimeString.add(TimeUtils.timeFormat(time + item.getTime(), "yyyy-MM-dd HH:mm:ss"));
                                                }
                                            }
                                        }
                                    }
                                }
                                List<String> practiceReminderContent = GlobalFields.getPracticeReminderContent();
                                for (int i = 0; i < addTime.size(); i++) {
                                    int index = (int) (Math.random() * (practiceReminderContent.size()));
                                    lessonNotificationIds.add(i + 1);
                                    TKNotificationUtils.scheduleNotification(TApplication.getInstance().getBaseContext(), "Reminder for practice", practiceReminderContent.get(index), addTime.get(i) * 1000L, i + 1);
                                }
//                                Logger.e("practice reminder 时间==>%s", SLJsonUtils.toJsonString(addTimeString));


                            }

                            if (!notificationConfig.isReminderOpened()) {
                                Logger.e("开始设置NotificationReminder, Reminder为关闭状态清空通知");
                                SLCacheUtil.setLessonNotificationIds(lessonNotificationIds);
                                isCheckingNotifications = false;
                                return;
                            }
                            Logger.e("开始设置NotificationReminder数据");
                            List<LessonScheduleEntity> data = new ArrayList<>();
                            int currentTime = TimeUtils.getCurrentTime();
                            data = lessonScheduleList.stream().sorted(Comparator.comparing(LessonScheduleEntity::getTKShouldDateTime)).collect(Collectors.toList());
                            List<Integer> times = notificationConfig.getReminderTimes().stream().filter(item -> item < 1440).collect(Collectors.toList());
                            boolean hasNextDayLesson = notificationConfig.getReminderTimes().contains(1440);
                            Calendar today = TimeUtils.getStartDay(currentTime);
                            long nextWeek = TimeUtils.addDay(today.getTimeInMillis(), 8) / 1000L;
                            //排除天的通知
                            List<LessonScheduleEntity> dataList = data.stream().filter(item -> item.getTKShouldDateTime() <= nextWeek).collect(Collectors.toList());
//        List<String> timeForReminder = new ArrayList<>();
                            List<Integer> reminderIds = new ArrayList<>();
                            for (LessonScheduleEntity item : dataList) {
                                for (Integer time : times) {
                                    if (reminderIds.size() > 30) {
                                        break;
                                    }
                                    long reminderTime = TimeUtils.addMinute(item.getTKShouldDateTime() * 1000L, -time) / 1000L;
                                    if (reminderTime > currentTime) {

//                        timeForReminder.add(TimeUtils.timeFormat(reminderTime, "yyyy-MM-dd hh:mm:ss a"));
                                        reminderIds.add(reminderIds.size() + lessonNotificationIds.size() + 1);

                                        String timeString = "";
                                        if (time > 60) {
                                            timeString = (time / 60) + " hour" + ((time / 60) > 1 ? "s" : "");
                                            if (time % 60 > 0) {
                                                timeString += (time % 60) + " minute" + ((time % 60) > 1 ? "s" : "");
                                            }
                                        } else {
                                            timeString = time + " minute" + (time > 1 ? "s" : "");
                                        }
                                        String content = "You have a lesson in " + timeString + " with " + getTeacherData(item.getTeacherId());
                                        TKNotificationUtils.scheduleNotification(TApplication.getInstance().getBaseContext(), "Reminder for today's lesson", content, reminderTime * 1000L, reminderIds.size() + lessonNotificationIds.size() + 1);
//                        Logger.e("即时提醒: 上课的时间:%s, 提醒的时间:%s, 通知内容%s", TimeUtils.timeFormat(item.getShouldDateTime() , "yyyy-MM-dd hh:mm:ss a"),TimeUtils.timeFormat(reminderTime , "yyyy-MM-dd hh:mm:ss a"),content);
                                    }
                                }
                            }
                            Map<Long, List<LessonScheduleEntity>> oneDayReminder = new HashMap<>();
                            if (hasNextDayLesson) {
                                Calendar tomorrow = TimeUtils.getStartDay(currentTime);
                                for (LessonScheduleEntity item : dataList) {
                                    List<LessonScheduleEntity> tomorrowLesson = new ArrayList<>();
                                    Calendar lessonCalendar = Calendar.getInstance();
                                    lessonCalendar.setTimeInMillis(item.getTKShouldDateTime() * 1000L);
                                    if (lessonCalendar.get(Calendar.YEAR) != tomorrow.get(Calendar.YEAR) || lessonCalendar.get(Calendar.MONTH) != tomorrow.get(Calendar.MONTH) || lessonCalendar.get(Calendar.DATE) != tomorrow.get(Calendar.DATE)) {
                                        tomorrow = TimeUtils.getStartDay((int) item.getTKShouldDateTime());
                                    }
                                    if (oneDayReminder.get(tomorrow.getTimeInMillis() / 1000L + (3600 * 10)) != null) {
                                        oneDayReminder.get(tomorrow.getTimeInMillis() / 1000L + (3600 * 10)).add(item);
                                    } else {
                                        tomorrowLesson.add(item);
                                        oneDayReminder.put(tomorrow.getTimeInMillis() / 1000L + (3600 * 10), tomorrowLesson);
                                    }
                                }
                            }
//        Logger.e("tomorrowLesson数量: %s", tomorrowLesson.size());
                            oneDayReminder.forEach((key, value) -> {
                                long time = TimeUtils.addDay(key * 1000L, -1);
                                if (time / 1000L > currentTime) {
                                    StringBuilder content = new StringBuilder("You have a");
                                    content.append(value.size()).append(" lesson").append(value.size() > 1 ? "s" : "").append(" tomorrow with ");
                                    for (int i = 0; i < value.size(); i++) {
                                        LessonScheduleEntity item = value.get(i);

                                        if (i == value.size() - 1) {
                                            content.append("and ");
                                        }
                                        content.append(getTeacherData(item.getTeacherId())).append(" at ").append(TimeUtils.timeFormat(item.getTKShouldDateTime(), "hh:mm a"));
                                        if (i == value.size() - 1) {
                                            content.append(".");
                                        } else {
                                            content.append(", ");
                                        }
                                    }
//                Logger.e("提前一天提醒%s: 通知内容%s", TimeUtils.timeFormat(time / 1000L, "yyyy-MM-dd hh:mm:ss a"), content.toString());
                                    reminderIds.add(reminderIds.size() + lessonNotificationIds.size() + 1);
                                    TKNotificationUtils.scheduleNotification(TApplication.getInstance().getBaseContext(), "Reminder for tomorrow's lesson", content.toString(), time, reminderIds.size() + lessonNotificationIds.size() + 1);
                                }
                            });

                            reminderIds.addAll(lessonNotificationIds);
//        Logger.e("timeForReminder: %s", timeForReminder);
                            Logger.e("???==>%s", reminderIds);
                            //把reminderId 存入到缓存中
                            SLCacheUtil.setLessonNotificationIds(reminderIds);

                            isCheckingNotifications = false;


                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }


    private void initNotification() {
        List<UserNotificationEntity> userNotifications = ListenerService.shared.userNotifications;
        String uId = studentId;

        List<LessonRescheduleEntity> data = new ArrayList<>();
        List<LessonRescheduleEntity> oldData = undoneRescheduleData;

        if (uId.equals("")) {
            Logger.e("======%s", "uId为空");
            return;
        }

        boolean newMsg = false;
        for (UserNotificationEntity notification : userNotifications) {
            Logger.e("======notification.getCategory():%s", notification.getCategory());
            switch (notification.getCategory()) {
                case 2:
                    LessonCancellationEntity lessonCancellationEntity = SLJsonUtils.toBean(notification.getData(), LessonCancellationEntity.class);
                    data.add(lessonCancellationEntity.convertToReschedule());
                    break;
                case 1:
                case 11:
                case 3:
                    LessonRescheduleEntity reschedule = SLJsonUtils.toBean(notification.getData(), LessonRescheduleEntity.class);
                    data.add(reschedule);
                    if (!newMsg) {
                        for (LessonRescheduleEntity oldDatum : oldData) {
                            if (oldDatum.getId().equals(reschedule.getId())) {
                                if (!oldDatum.isEqual(reschedule)) {
                                    if (reschedule.getStudentId().equals(uId) && reschedule.getStudentRevisedReschedule()) {
                                        newMsg = true;
                                    }
                                }
                            } else {
                                newMsg = true;
                            }
                        }
                    }
                    break;
                case -2:
                    //note
                    LessonScheduleEntity lessonScheduleEntity = SLJsonUtils.toBean(notification.getData(), LessonScheduleEntity.class);
                    for (StudentLessonsItemViewModel itemViewModel : lessonDataList) {
                        if (itemViewModel.data.getId().equals(lessonScheduleEntity.getId())) {
                            itemViewModel.initData(lessonScheduleEntity);
                            break;
                        }
                    }
                    lessonScheduleIdMap.put(lessonScheduleEntity.getId(), lessonScheduleEntity);
                    break;
                case -4:
                    //materials分享
                    getLessonScheduleMaterials();
                    break;

            }
        }
        undoneRescheduleData = data;
        initReschedule();


    }


    public void getStudentData(boolean isCache) {
        Logger.e("时间-->开始获取学生数据%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListByStudentId(studentId, isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("data.size%s", data.size());

                            if (data.size() > 0) {
                                studentData = data.get(0);
                                ListenerService.shared.studentData.setStudentData(studentData);
                                if (!studentData.getStudioId().equals("")) {
                                    getDatas(isCache);
                                    getScheduleConfig();
                                    initReschedule();

                                } else {
                                    getTeacherData(isCache);
                                }
                            } else {
                                String time = TimeUtils.getCurrentTime() + "";
                                studentData = new StudentListEntity()
                                        .setTeacherId("")
                                        .setStudentId(studentId)
                                        .setName("")
                                        .setEmail("")
                                        .setInvitedStatus("-1")
                                        .setLessonTypeId("")
                                        .setStatusHistory(new ArrayList<>())
                                        .setStudentApplyStatus(0)
                                        .setCreateTime(time)
                                        .setUpdateTime(time);
                                ListenerService.shared.studentData.setStudentData(studentData);
                                getDatas(isCache);
                                getScheduleConfig();
                                initReschedule();
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    private void getTeacherData(boolean isCache) {
        Logger.e("时间-->开始获取老师数据%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));

        addSubscribe(
                UserService
                        .getInstance()
                        .getUserById(isCache, studentData.getTeacherId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            teacherData = data;
                            Logger.e("时间-->获取老师数据成功%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));

                            getDatas(isCache);
                            getScheduleConfig();
                            initReschedule();
                            if (!isCache) {
                                initLessonNotification();
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    private void getOnlyTeacherData() {
        addSubscribe(
                UserService
                        .getInstance()
                        .getUserById(false, studentData.getTeacherId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            uc.clickReAddTeacher.call();
                        }, throwable -> {
                            uc.clickAddTeacher.call();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    private void getDatas(boolean isCache) {
        getCancelLessonData(isCache);
        getReschedule(isCache);
//        getPracticeData(isCache);
        getNextLessonData(isCache);
        getPoliceData(isCache);
        //studio 新添加的
        if (!studentData.getStudioId().equals("")) {
            List<TKFollowUp> followUps = ListenerService.shared.studentData.getFollowUps();
            if (followUps != null && followUps.size() > 0) {
                for (TKFollowUp followUp : followUps) {
                    if (followUp.getDataType().equals(TKFollowUp.DataType.reschedule)) {
                        LessonRescheduleEntity rescheduleData = CloneObjectUtils.cloneObject(followUp.getRescheduleData());
                        rescheduleDataMap.put(rescheduleData.getScheduleId(), rescheduleData);
                    }
                    if (followUp.getDataType().equals(TKFollowUp.DataType.cancellation)) {
                        LessonCancellationEntity lessonCancellationEntity = CloneObjectUtils.cloneObject(followUp.getCancellationData());
                        cancelDataMap.put(lessonCancellationEntity.getOldScheduleId(), lessonCancellationEntity);
                    }
                }
                initShowData();
            }
        }
    }

    private void getCancelLessonData(boolean isCache) {
        if (studentData == null) {
            return;
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .studentGetCancellationListByStudentId(studentData.getStudentId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            cancelData = data;
                            for (LessonCancellationEntity datum : data) {
                                cancelDataMap.put(datum.getOldScheduleId(), datum);
                            }
                            Logger.e("获取cancel数据成功:%s", data.size());
                            initShowData();
                        }, throwable -> {
                            Logger.e("获取cancel数据失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    private void getAchievement() {
        if (studentData == null) {
            return;
        }

        addSubscribe(
                LessonService
                        .getInstance()
                        .getAchievementBySId(studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            achievementDataMap.clear();
                            achievementData = data;
                            for (AchievementEntity datum : data) {
                                if (achievementDataMap.get(datum.getScheduleId()) != null) {
                                    achievementDataMap.get(datum.getScheduleId()).add(datum);
                                } else {
                                    List<AchievementEntity> list = new ArrayList<>();
                                    list.add(datum);
                                    achievementDataMap.put(datum.getScheduleId(), list);
                                }
                            }
                            Logger.e("获取Reschedule数据成功:%s", data.size());
                            initShowData();
                        }, throwable -> {
                            Logger.e("获取Reschedule数据失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void getPoliceData(boolean isCache) {
        if (studentData == null || studentData.getTeacherId() == null || studentData.getTeacherId().equals("") || studentData.getStudentApplyStatus() == 1) {
            if (studentData != null && !studentData.getStudioId().equals("")) {
                AtomicBoolean isSuccess = new AtomicBoolean(false);
                addSubscribe(
                        UserService
                                .getInstance()
                                .getPolicyByStudioId(studentData.getStudioId(), isCache)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread(), true)
                                .subscribe(data -> {
                                    policyData = data;
                                    if (studentData.getSignPolicyTime() == 0 && !isShowSignPolicy && data.isSendRequest()) {
                                        isShowSignPolicy = true;
                                        uc.showSignPolicy.call();
                                    }
                                    isSuccess.set(true);
                                }, throwable -> {
                                    Logger.e("policyData失败,失败原因" + throwable.getMessage());
                                })

                );
            }
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                UserService
                        .getInstance()
                        .getPolicyByTeacherId(studentData.getTeacherId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            policyData = data;
                            if (studentData.getSignPolicyTime() == 0 && !isShowSignPolicy && data.isSendRequest()) {
                                isShowSignPolicy = true;
                                uc.showSignPolicy.call();
                            }
                            isSuccess.set(true);
                        }, throwable -> {
                            Logger.e("policyData失败,失败原因" + throwable.getMessage());
                        })

        );


    }

    private void getReschedule(boolean isCache) {
        if (studentData == null) {
            return;
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .studentGetRescheduleListByStudentId(studentData.getStudentId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            rescheduleData = data;
                            for (LessonRescheduleEntity datum : data) {
                                rescheduleDataMap.put(datum.getScheduleId(), datum);
                            }
                            Logger.e("获取Reschedule数据成功:%s", data.size());
                            initShowData();
                        }, throwable -> {
                            Logger.e("获取Reschedule数据失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    public void getScheduleConfig() {
        scheduleConfigs = ListenerService.shared.studentData.getScheduleConfigs();
//        Logger.e("或取出来的的confing==>%s==>%s",scheduleConfigs.size(),SLJsonUtils.toJsonString(scheduleConfigs));
        lessonConfigMap.clear();
        Logger.e("时间-->开始获取历史课程数据%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));
        List<String> lessonTypeIds = new ArrayList<>();
        for (LessonScheduleConfigEntity scheduleConfig : scheduleConfigs) {
            lessonTypeIds.add(scheduleConfig.getLessonTypeId());
            lessonConfigMap.put(scheduleConfig.getId(), scheduleConfig);
        }
        Logger.e("或取出来的的confing==>%s==>%s==>%s",lessonConfigMap.size(),scheduleConfigs.size(),SLJsonUtils.toJsonString(scheduleConfigs));

        if (lessonTypeIds.size() > 0) {
            getLessonType(lessonTypeIds);
        }
        initScheduleData();
    }

    private void getLessonType(List<String> ids) {
        Logger.e("======%s", "getLessonType");
        lessonTypes.clear();
        addSubscribe(
                LessonService
                        .getInstance()
                        .getLessonTypeByIds(ids)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("获取LessonType成功:%s", data.size());
                            lessonTypes.addAll(data);
                            for (LessonTypeEntity item : data) {
                                lessonTypeMap.put(item.getId(), item);
                            }
                            for (int i = 0; i < lessonDataList.size(); i++) {
                                String lessonTypeId = lessonDataList.get(i).data.getLessonTypeId();
                                if (lessonTypeMap.get(lessonTypeId) != null) {
                                    lessonDataList.get(i).data.setLessonType(lessonTypeMap.get(lessonTypeId));
                                    lessonDataList.get(i).initData(lessonDataList.get(i).data);
                                }
                            }
//                            initScheduleData();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }


    private void initScheduleData() {
        if (studentData == null) {
            Logger.e("studentData个数为空");
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        String teacherId = studentData.getTeacherId();
        if (studentData.getStudentApplyStatus() == 1) {
            teacherId = "";
        }
        Logger.e("startTimestamp==>%s>%s", startTimestamp, endTimestamp);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleByStudentIdAndTeacherIdAndTime(studentData.getStudentId(), startTimestamp, endTimestamp)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            data.sort((o1, o2) -> (int) (o2.getTKShouldDateTime() - o1.getTKShouldDateTime()));
                            int nowTime = TimeUtils.getCurrentTime();
                            data.removeIf(item -> item.getTKShouldDateTime() > nowTime);
                            data.removeIf(item -> lessonConfigMap.get(item.getLessonScheduleConfigId()) == null);

                            for (int i = 0; i < data.size(); i++) {
                                LessonScheduleEntity d = data.get(i);
                                SLCacheUtil.setLessonData(d);
//                                if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
//                                    continue;
//                                }
                                d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                                d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
                                onlineLessonData.put(d.getId(), d);
                                if (lessonScheduleIdMap.get(d.getId()) == null) {
//                                    lessonDataList.add(new StudentLessonsItemViewModel(this, i, d));
                                    lessonScheduleIdMap.put(d.getId(), d);
                                } else {
                                    for (StudentLessonsItemViewModel item : lessonDataList) {
                                        if (item.data.getId().equals(d.getId())) {
                                            item.initData(d);
                                        }
                                    }
                                }
                            }
                            emptyLayoutIsVisibility.set(lessonDataList.size() <= 0);
                            isSuccess.set(true);
                            uc.loadingComplete.setValue(data);
                            locationLessonData.forEach((s, lessonScheduleEntity) -> {
                                if (lessonScheduleEntity.getShouldDateTime() < startTimestamp || lessonScheduleEntity.getShouldDateTime() > endTimestamp) {
                                    locationLessonData.remove(s);
                                }
                            });
                            StudioCalendarHomeEX.updateLessonData(locationLessonData, onlineLessonData);
                            initShowData();
                        }, throwable -> Logger.e("获取schedule失败,失败原因" + throwable.getMessage()))

        );

        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            Logger.e("lessonConfigMap==>%s",lessonConfigMap.size());
            String jsFile = FuncUtils.getJsFuncStr(TApplication.mApplication, "rrule2");
            V8 v8 = V8.createV8Runtime();
            MemoryManager scope = new MemoryManager(v8);
            v8.executeVoidScript(jsFile);
            lessonConfigMap.forEach((key, value) -> {
                List<LessonScheduleEntity> data = StudioService.getInstance().getLessonTimeByRRuleAndStartTimeAndEndTime(value, startTimestamp, endTimestamp,v8);
                int nowTime = TimeUtils.getCurrentTime();
                data.removeIf(item -> item.getTKShouldDateTime() > nowTime);
                for (int i = 0; i < data.size(); i++) {
                    LessonScheduleEntity d = data.get(i);
                    SLCacheUtil.setLessonData(d);
                    if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
                        continue;
                    }
                    d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                    d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
                    locationLessonData.put(d.getId(), d);
                    if (lessonScheduleIdMap.get(d.getId()) == null) {
//                        lessonDataList.add(new StudentLessonsItemViewModel(this, i, d));
                        lessonScheduleIdMap.put(d.getId(), d);
                    } else {
                        for (StudentLessonsItemViewModel item : lessonDataList) {
                            if (item.data.getId().equals(d.getId())) {
                                item.initData(d);
                            }
                        }
                    }
                }
            });
            scope.release();
            v8.release();
            emptyLayoutIsVisibility.set(lessonDataList.size() <= 0);
            initShowData();
        }


    }

    /**
     * 获取课程的materials 数据
     */
    private void getLessonScheduleMaterials() {

        addSubscribe(
                LessonService
                        .getInstance()
                        .getStudentLessonMaterial(studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            materialsDataMap.clear();
                            for (LessonScheduleMaterialEntity datum : data) {
                                if (materialsDataMap.get(datum.getLessonScheduleId()) != null) {
                                    materialsDataMap.get(datum.getLessonScheduleId()).add(datum);
                                } else {
                                    List<LessonScheduleMaterialEntity> list = new ArrayList<>();
                                    list.add(datum);
                                    materialsDataMap.put(datum.getLessonScheduleId(), list);
                                }
                            }
                            initShowData();
                        }, throwable -> {
                            Logger.e("getLessonScheduleMaterials失败,失败原因" + throwable.getMessage());
                        })

        );


    }

    @SuppressLint("DefaultLocale")
    private void initShowData() {
        int nowTime = TimeUtils.getCurrentTime();
        for (int i = 0; i < lessonDataList.size(); i++) {
            //设置cancel数据
            String id = lessonDataList.get(i).data.getId();
            if (lessonDataList.get(i).data.isCancelled() && cancelDataMap.get(id) != null) {
                lessonDataList.get(i).data.setCancelLessonData(cancelDataMap.get(id));
            }
            //设置reschedule数据
            if (lessonDataList.get(i).data.isRescheduled() && !lessonDataList.get(i).data.getRescheduleId().equals("")
                    && rescheduleDataMap.get(id) != null) {
                lessonDataList.get(i).data.setRescheduleLessonData(rescheduleDataMap.get(id));
            }
            //设置achievement 数据
            lessonDataList.get(i).data.setAchievement(new ArrayList<>());
//            for (AchievementEntity achievementDatum : achievementData) {
//                if (achievementDatum.getScheduleId().equals(id)) {
//                    lessonDataList.get(i).data.getAchievement().add(achievementDatum);
//                }
//            }
            if (achievementDataMap.get(id) != null) {
                lessonDataList.get(i).data.setAchievement(achievementDataMap.get(id));
            }
            if (materialsDataMap.get(id) != null) {
                lessonDataList.get(i).data.setMaterialData(materialsDataMap.get(id));
            }

            //设置practice数据
            lessonDataList.get(i).data.setPracticeData(new ArrayList<>());
            long endTime = nowTime;
            if (i != 0) {
                endTime = lessonDataList.get(i - 1).data.getShouldDateTime();
            }
            long startTime = lessonDataList.get(i).data.getShouldDateTime();

            for (TKPractice practiceDatum : practiceData) {
                if (practiceDatum.getStartTime() >= startTime && practiceDatum.getStartTime() < endTime) {
                    lessonDataList.get(i).data.getPracticeData().add(practiceDatum);
                }
            }
            lessonDataList.get(i).initData(lessonDataList.get(i).data);
        }
        //设置NextLesson practice的数据
        if (lessonDataList.size() > 0 && lessonDataList.get(0).data.getPracticeData() != null && lessonDataList.get(0).data.getPracticeData().size() > 0) {
            List<TKPractice> assignmentData = new ArrayList<>();
            List<TKPractice> studyData = new ArrayList<>();
            for (TKPractice item : lessonDataList.get(0).data.getPracticeData()) {
                if (!item.isAssignment()) {
                    studyData.add(item);
                } else {
                    assignmentData.add(item);
                }
            }
            if (nextLessonData != null) {
                nextLessonData.setPracticeData(lessonDataList.get(0).data.getPracticeData());
            }
            double totalTime = 0;
            for (TKPractice item : studyData) {
                totalTime += item.getTotalTimeLength();
            }
            if (totalTime > 0) {
                totalTime = totalTime / 60 / 60;
                if (totalTime <= 0.1) {
                    nLSelfStudy.setValue(" 0.1 hrs");
                } else {
                    nLSelfStudy.setValue(" " + String.format("%.1f", totalTime) + " hrs");
                }
            } else {
                nLSelfStudy.setValue(" 0 hrs");
            }
            if (assignmentData.size() <= 0) {
                nLAssignment.setValue(" No assignment");
                nLAssignmentColor.setValue(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
                return;
            }
            boolean isComplete = false;

            for (TKPractice item : assignmentData) {
                if (item.isDone()) {
                    isComplete = true;
                    break;
                }
            }
            nLAssignment.setValue(isComplete ? " Completed" : " Incomplete");
            nLAssignmentColor.setValue(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), isComplete ? R.color.kermit_green : R.color.red));

        } else {
            nLSelfStudy.setValue(" 0 hrs");
            nLAssignment.setValue(" No assignment");
            nLAssignmentColor.setValue(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
        }

    }

    private void getNextLessonData(boolean isCache) {
        nextLessonData = null;
        if (studentData == null) {
            return;
        }
        String teacherId = studentData.getTeacherId();
        if (studentData.getStudentApplyStatus() == 1) {
            teacherId = "";
        }
        Logger.e("时间-->获取下一节课数据%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));

        Logger.e("teacherId:%s", teacherId);

        addSubscribe(
                LessonService
                        .getInstance()
                        .getNextLessonByTIdAndSIdAndTime(teacherId, studentData.getStudentId(), TimeUtils.getCurrentTime(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("时间-->获取下一节课数据成功%s", TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mm:ss"));
                            onlineLessonData.put(data.getId(), data);
                            nextLessonData = data;
                            locationLessonData.forEach((s, lessonScheduleEntity) -> {
                                if (lessonScheduleEntity.getShouldDateTime() < startTimestamp || lessonScheduleEntity.getShouldDateTime() > endTimestamp) {
                                    locationLessonData.remove(s);
                                }
                            });
                            StudioCalendarHomeEX.updateLessonData(locationLessonData, onlineLessonData);
                            refreshNextLesson();
                        }, throwable -> {
                            Logger.e("getNextLessonData失败,失败原因" + throwable.getMessage() + "===" + (localNextLessonData == null));
                            if (localNextLessonData == null) {
                                nextLessonData = null;
                                refreshNextLesson();
                            }
                        })
        );
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            List<LessonScheduleEntity> lesson = new ArrayList<>();
            String jsFile = FuncUtils.getJsFuncStr(TApplication.mApplication, "rrule2");
            V8 v8 = V8.createV8Runtime();
            MemoryManager scope = new MemoryManager(v8);
            v8.executeVoidScript(jsFile);
            lessonConfigMap.forEach((key, value) -> {
                List<LessonScheduleEntity> data = StudioService.getInstance().getLessonTimeByRRuleAndStartTimeAndEndTime(value, TimeUtils.getCurrentTime(), (int) (TimeUtils.addMonth((TimeUtils.getCurrentTime() * 1000L), 3) / 1000L),v8);
                Logger.e("生成的课程个数==>%s", data.size());

                for (int i = 0; i < data.size(); i++) {
                    LessonScheduleEntity d = data.get(i);
                    SLCacheUtil.setLessonData(d);
                    if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
                        continue;
                    }
                    locationLessonData.put(d.getId(), d);
                    d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                    d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
                    lesson.add(d);
                }

            });
            if (lesson.size() > 0) {
                Logger.e("获取到课程11111111111==>%s","获取到课程");
                lesson.sort((o1, o2) -> (int) (o1.getShouldDateTime() - o2.getShouldDateTime()));

                for (LessonScheduleEntity lessonScheduleEntity : lesson) {
                    if (lessonScheduleEntity.shouldDateTime>TimeUtils.getCurrentTime()){
                        localNextLessonData =lessonScheduleEntity;
                        nextLessonData = lessonScheduleEntity;
                        break;
                    }
                }

                refreshNextLesson();
            }
            scope.release();
            v8.release();
        }
    }

    private void refreshNextLesson() {

        if (nextLessonData != null) {
            isShowInviteButton.setValue(studentData.getTeacherId().equals("") && studentData.getStudioId().equals(""));

//            if (studentData.getStudentApplyStatus() == 1) {
//                uc.isShowAddButton.setValue(true);
//            }
            uc.isShowAddButton.setValue(studentData.getStudentApplyStatus() == 1);
            isShowAddLessonButton.setValue(false);
            isShowNextLesson.setValue(true);

            emptyInfo.setValue("Enjoy your lessons.");
            nLDay.setValue(TimeUtils.timeFormat(nextLessonData.getTKShouldDateTime(), "d"));
            nLMonth.setValue(TimeUtils.timeFormat(nextLessonData.getTKShouldDateTime(), "MMM"));
            nLInfo.setValue("Next lesson, " + TimeUtils.timeFormat(nextLessonData.getTKShouldDateTime(), "hh:mm a"));
        } else {
            isShowInviteButton.setValue(studentData.getTeacherId().equals("") && studentData.getStudioId().equals(""));
            uc.isShowAddButton.setValue(false);
            isShowNextLesson.setValue(false);
            if (studentData.getStudentApplyStatus() == 1) {
                emptyInfo.setValue("Add your lessons in minutes.\nIt's easy, we promise!");
                isShowAddLessonButton.setValue(true);
            } else if (studentData.getStudentApplyStatus() == 0) {
                emptyInfo.setValue("Enjoy your lessons.");
                isShowAddLessonButton.setValue(false);
            } else {
                emptyInfo.setValue("Your lesson will be ready once your instructor confirm your lesson.");
                isShowAddLessonButton.setValue(false);
            }

        }
    }

    /**
     * 初始化
     */
    private void initReschedule() {
        if (undoneRescheduleData != null && undoneRescheduleData.size() > 0) {

            requestIsShowAfterQuestionImg.set(false);
            requestIsShowConfirmButton.set(false);
            requestIsShowRescheduleButton.set(false);
            requestIsShowCenterRetractButton.set(false);
            requestIsShowRetractButton.set(false);
            requestIsShowDeclinedButton.set(false);
            requestIsShowCloseButton.set(false);
            requestIsShowArrow.set(true);

            isShowRequest.set(true);
            if (undoneRescheduleData.size() > 1) {
                requestCount.set(undoneRescheduleData.size() + "");
                isShowRequestBox.set(true);
            } else {
                isShowRequestBox.set(false);
                LessonRescheduleEntity reschedule = undoneRescheduleData.get(0);
                requestBeforeDay.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "d"));
                requestBeforeMonth.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "MMM"));
                requestBeforeTime.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKBefore()), "hh:mm a"));
                String timeAfter = reschedule.getTKAfter();
                String teacherName = "";
                String info = "";

                if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                    if (teacherData!=null){
                        teacherName = "<font color='#71d9c2'> " + teacherData.getName() + " </font>";
                    }
                }
                if (!reschedule.getTimeAfter().equals("") && Integer.parseInt(reschedule.getTKAfter()) < TimeUtils.getCurrentTime()) {
                    timeAfter = "";
                }
                if (!timeAfter.equals("")) {

                    requestAfterDay.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "d"));
                    requestAfterMonth.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "MMM"));
                    requestAfterTime.set(TimeUtils.timeFormat(Long.parseLong(reschedule.getTKAfter()), "hh:mm a"));
                    if (reschedule.getSenderId().equals(studentId)) {
                        requestStatus.set("Pending: ");
                        if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                            info = "Awaiting rescheduling confirmation " + teacherName;
                        } else {
                            info = "Awaiting rescheduling confirmation";
                        }
                        requestIsShowCenterRetractButton.set(true);
                        if (reschedule.getTeacherRevisedReschedule()) {
                            requestIsShowCenterRetractButton.set(false);
                            requestIsShowRetractButton.set(true);
                            requestStatus.set("");
                            requestIsShowRescheduleButton.set(true);
                            requestIsShowConfirmButton.set(true);
                            if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                                info = teacherName + " sent a reschedule request";
                            } else {
                                info = "Your instructor sent a reschedule request";
                            }

                        }
                    } else {
                        if (reschedule.getStudentRevisedReschedule()) {
                            if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                                info = "Awaiting rescheduling confirmation " + teacherName;
                            } else {
                                info = "Awaiting rescheduling confirmation";
                            }
                            requestStatus.set("Pending: ");

                        } else {
                            requestIsShowRescheduleButton.set(true);
                            requestIsShowConfirmButton.set(true);
                            requestStatus.set("");
                            if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                                info = teacherName + " sent a reschedule request";
                            } else {
                                info = "Your instructor sent a reschedule request";
                            }
                        }
                    }
                    if (reschedule.getRetracted()) {
                        if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                            info = teacherName + " retracted the reschedule request";
                        } else {
                            info = "Retracted the reschedule request";
                        }
                        requestStatus.set("");
                        requestIsShowCloseButton.set(true);
                        requestIsShowRetractButton.set(false);
                        requestIsShowConfirmButton.set(false);
                        requestIsShowCenterRetractButton.set(false);
                        requestIsShowRescheduleButton.set(false);
                    }
                    if (reschedule.isCancelLesson()) {
                        if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                            info = teacherName + " cancelled this lesson";
                        } else {
                            info = "Your instructor cancelled this lesson";
                        }
                        requestIsShowArrow.set(false);
                        requestIsShowCloseButton.set(true);
                        requestIsShowRetractButton.set(false);
                        requestIsShowConfirmButton.set(false);
                        requestIsShowCenterRetractButton.set(false);
                        requestIsShowRescheduleButton.set(false);
                        requestIsShowAfterQuestionImg.set(false);
                        requestAfterDay.set("");
                    }
                } else {
                    requestIsShowAfterQuestionImg.set(true);
                    if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                        info = teacherName + " sent a reschedule request";
                    } else {
                        info = "Your instructor sent a reschedule request";
                    }
                    if (reschedule.getSenderId().equals(studentId)) {
                        requestIsShowRetractButton.set(true);
                    }


                    if (reschedule.getRetracted()) {
                        if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                            info = teacherName + " retracted the reschedule request";
                        } else {
                            info = "Retracted the reschedule request";
                        }

                        requestIsShowCloseButton.set(true);
                        requestIsShowRetractButton.set(false);
                        requestIsShowConfirmButton.set(false);
                        requestIsShowCenterRetractButton.set(false);
                        requestIsShowRescheduleButton.set(false);
                    }
                    if (reschedule.isCancelLesson()) {
                        if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {
                            info = teacherName + " cancelled this lesson";
                        } else {
                            info = "Your instructor cancelled this lesson";
                        }
                        requestIsShowArrow.set(false);
                        requestIsShowCloseButton.set(true);
                        requestIsShowRetractButton.set(false);
                        requestIsShowConfirmButton.set(false);
                        requestIsShowCenterRetractButton.set(false);
                        requestIsShowRescheduleButton.set(false);
                        requestIsShowAfterQuestionImg.set(false);
                        requestAfterDay.set("");
                    }


                }
                if (reschedule.getConfirmType() != 0) {
                    if (getTeacherData(reschedule.getTeacherId()).getName().equals("")) {

                        info = teacherName + "declined the reschedule request";
                        if (reschedule.getConfirmType() == 1) {
                            info = teacherName + "confirmed the reschedule request";
                        }

                    } else {
                        info = "Declined the reschedule request";
                        if (reschedule.getConfirmType() == 1) {
                            info = "Confirmed the reschedule request";

                        }
                    }
                    requestStatus.set("");
                    requestIsShowCloseButton.set(true);
                    requestIsShowRetractButton.set(false);
                    requestIsShowConfirmButton.set(false);
                    requestIsShowCenterRetractButton.set(false);
                    requestIsShowRescheduleButton.set(false);
                }
                requestInfo.set(Html.fromHtml(info));


            }
        } else {
            isShowRequest.set(false);
        }
    }

    public void studentDeleteLessonWithoutTeacher(boolean deleteUpcoming) {

        if (nextLessonData != null) {
            showDialog();
            addSubscribe(
                    LessonService
                            .getInstance()
                            .studentDeleteLessonWithoutTeacher(nextLessonData, deleteUpcoming)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                dismissDialog();
                                SLToast.success("Removed this lesson successfully");
                                getNextLessonData(true);
                                getNextLessonData(false);

                            }, throwable -> {
                                SLToast.error("Remove failed, try again later");
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })

            );

        } else {
            SLToast.error("Remove failed, try again later");
        }
    }


    public UIEventObservable uc = new UIEventObservable();


    public static class UIEventObservable {
        public SingleLiveEvent<TreeMap<String, List<TKMessage>>> showAnnouncementDialog = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> showSignPolicy = new SingleLiveEvent<>();
        public SingleLiveEvent<Boolean> isShowAddButton = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickNextLeftView = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickDeleteLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickNextLessonCancel = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddTeacher = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickInviteTeacher = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonRescheduleEntity> clickRetract = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickReAddTeacher = new SingleLiveEvent<>();
        public SingleLiveEvent<List<LessonScheduleEntity>> loadingComplete = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickNextLessonReschedule = new SingleLiveEvent<>();

    }

    //给RecyclerView添加ObservableList
    public ObservableList<StudentLessonsItemViewModel> lessonDataList = new ObservableArrayList<>();

    public ItemBinding<StudentLessonsItemViewModel> itemLessonBinding =
            ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemLessonViewModel, R.layout.item_student_lessons));

    /**
     * 点击next lesson card
     */
    public BindingCommand clickAddLesson = new BindingCommand(() -> uc.clickAddLesson.call());
    public BindingCommand clickNextLessonLeft = new BindingCommand(() -> {
        uc.clickNextLeftView.call();
        isShowNextLessonButton.setValue(!isShowNextLessonButton.getValue());
    });
    public BindingCommand clickNextLessonRight = new BindingCommand(() -> {

        if (lessonDataList != null && lessonDataList.size() > 0 && lessonDataList.get(0) != null) {

            nextLessonData.setPracticeData(lessonDataList.get(0).data.getPracticeData());
        }
        clickLesson(nextLessonData, -1);
    });

    public BindingCommand clickNextLessonLeftButton = new BindingCommand(() -> {

        if (studentData.getTeacherId().equals("") || studentData.getStudentApplyStatus() == 1) {
            uc.clickDeleteLesson.call();
        } else {
            uc.clickNextLessonCancel.call();
        }
    });
    public BindingCommand clickNextLessonRightButton = new BindingCommand(() -> {
        if (SLCacheUtil.getCurrentStudioIsSingleTeacher() && (studentData.getTeacherId().equals("") || studentData.getStudentApplyStatus() == 1)) {
            if (studentData.getStudentApplyStatus() == 1) {
                showDialog();
                getOnlyTeacherData();
            } else {
                uc.clickAddTeacher.call();
            }
        } else {
//            Bundle bundle = new Bundle();
//            bundle.putSerializable("policyData", policyData);
//            bundle.putSerializable("teacherData", teacherData);
//            bundle.putSerializable("lessonData", nextLessonData);
//            startActivity(StudentRescheduleAc.class, bundle);
            uc.clickNextLessonReschedule.call();

        }
    });
    public BindingCommand clickInviteTeacher = new BindingCommand(() -> {
        uc.clickInviteTeacher.call();
    });
    public BindingCommand clickRescheduleRequest = new BindingCommand(() -> {
        Bundle bundle = new Bundle();
        bundle.putSerializable("data", (Serializable) undoneRescheduleData);
        bundle.putSerializable("teacherData", (Serializable) getTeacherData(undoneRescheduleData.get(0).getTeacherId()));
        bundle.putSerializable("policyData", policyData);
        startActivity(StudentRescheduleRequestAc.class, bundle);
    });

    /**
     * 点击历史课程
     */
    public void clickLesson(LessonScheduleEntity scheduleEntity, int pos) {
        if (scheduleEntity == null) {
            return;
        }
        int endTime = TimeUtils.getCurrentTime();
        int startTime = (int) scheduleEntity.getShouldDateTime();
        Logger.e("ddd==>%s=>%s", pos, SLJsonUtils.toJsonString(scheduleEntity));
        if (pos > 0) {
            List<StudentLessonsItemViewModel> newData = new ArrayList<>();
            int index = 0;
            for (StudentLessonsItemViewModel itemViewModel : lessonDataList) {
                if (!itemViewModel.data.isCancelled()
                        && (!itemViewModel.data.isRescheduled() && itemViewModel.data.getRescheduleId().equals(""))) {
                    if (itemViewModel.data.getId().equals(lessonDataList.get(pos).data.getId())) {
                        index = newData.size();
                    }
                    newData.add(itemViewModel);
                }
            }
            Logger.e("index==>%s", index);
            if (index != 0) {

                if (pos == 0) {
                    if (nextLessonData != null) {
                        endTime = (int) nextLessonData.getShouldDateTime();
                    }
                }
                endTime = (int) newData.get(index - 1).data.getShouldDateTime();

            }
        } else {
            if (lessonDataList != null) {
                for (StudentLessonsItemViewModel itemViewModel : lessonDataList) {
                    if (!itemViewModel.data.isCancelled()
                            && (!itemViewModel.data.isRescheduled() && itemViewModel.data.getRescheduleId().equals(""))) {
                        startTime = (int) itemViewModel.data.getShouldDateTime();
                        break;
                    }
                }
            }
            if (nextLessonData != null) {
                endTime = (int) nextLessonData.getShouldDateTime();
            }
        }
        if (teacherData != null) {
            scheduleEntity.setTeacherName(getTeacherData(scheduleEntity.getTeacherId()).getName());
        }

        Bundle bundle = new Bundle();
        bundle.putSerializable("data", scheduleEntity);
        bundle.putInt("endTime", endTime);
        bundle.putInt("startTime", startTime);

        startActivity(StudentLessonDetailActivity.class, bundle);
    }


    public void retractReschedule(LessonRescheduleEntity reschedule) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .retractReschedule(reschedule)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
                    SLToast.success("Retract successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("teacherReadReschedule失败,失败原因" + throwable.getMessage());
                }));
    }

    public void toReschedule() {
        if (policyData == null) {
            return;
        }
        showDialog();

    }


    public BindingCommand clickReschedule = new BindingCommand(() -> {
        if (undoneRescheduleData.get(0).getRetracted() || undoneRescheduleData.get(0).getConfirmType() != 0) {
            return;
        }
        LessonRescheduleEntity rescheduleEntity = undoneRescheduleData.get(0);
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleById(undoneRescheduleData.get(0).getScheduleId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            if (isSuccess.get()) {
                                return;
                            }
                            Bundle bundle = new Bundle();
                            bundle.putSerializable("policyData", policyData);
                            bundle.putSerializable("teacherData", getTeacherData(data.getTeacherId()));
                            bundle.putSerializable("lessonData", data);
                            bundle.putSerializable("rescheduleData", rescheduleEntity);
                            startActivity(StudentRescheduleAc.class, bundle);
                            isSuccess.set(true);

                        }, throwable -> {
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );


    });

    public BindingCommand clickConfirm = new BindingCommand(() -> {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .confirmReschedule(undoneRescheduleData.get(0))
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
                    SLToast.success("Confirmed successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("clickCloseConfirm失败,失败原因" + throwable.getMessage());
                }));
    });
    public BindingCommand clickRetract = new BindingCommand(() -> {
        uc.clickRetract.setValue(undoneRescheduleData.get(0));
    });

    public BindingCommand clickClose = new BindingCommand(() -> {
        showDialog();
        Map<String, Object> map = new HashMap<>();
        map.put("read", true);
        DatabaseService.Collections.userNotifications()
                .document(undoneRescheduleData.get(0).getId() + ":" + studentId)
                .update(map)
                .addOnCompleteListener(command -> {
                    dismissDialog();
                    if (command.getException() != null) {
                        SLToast.showError();
                    } else {

                    }
                });
    });

    public void initStudioAnnouncement() {
        if (ListenerService.shared.studentData == null || ListenerService.shared.studentData.getStudioData() == null) {
            return;
        }
        String studioId = ListenerService.shared.studentData.getStudioData().getId();
        if (studioId == null || studioId.equals("")) {

            return;
        }
        addSubscribe(
                ChatService.getConversationInstance()
                        .getFromLocal(studioId)
                        .flatMap(conversation -> {
                            if (conversation.getId().equals("-1")) {
                                return ChatService.getConversationInstance().getConversationByIdFromCloud(studioId);
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
                            if (data != null && !data.getId().equals("-1") && data.userMap.get(SLCacheUtil.getCurrentUserId()) != null && data.getLatestMessageTimestamp() > 0.0) {
                                studioAnnouncementConversation = data;
                                isHaveStudioAnnouncement.set(true);
                                getNoReadMessage(studioId);
                            } else {
                                isHaveStudioAnnouncement.set(false);
                            }

                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败1,失败原因" + throwable.getMessage());
                            SLToast.showError();
                        })
        );
    }

    private void getNoReadMessage(String studioId) {
        new Thread(() -> {
            List<TKMessage> noReadData = AppDataBase.getInstance().messageDao().getAllUnreadMessagesByConversationIdToList(studioId, SLCacheUtil.getCurrentUserId());
            noReadData.sort((tkMessage, t1) -> (int) (t1.getDatetime() - tkMessage.getDatetime()));
            Map<String,List<TKMessage>> messages = new HashMap<>();
            //获取
            for (TKMessage noReadDatum : noReadData) {
                String s = TimeUtils.timeFormat((long) noReadDatum.getDatetime(), "yyyy-MM-dd");
                Logger.e("s==>%s",s);
                if (messages.get(s) ==null){
                    if (messages.size()>3){
                        break;
                    }
                    ArrayList<TKMessage> v = new ArrayList<>();
                    v.add(noReadDatum);
                    messages.put(s, v);
                }else {
                    List<TKMessage> messages1 = messages.get(s);
                    messages1.add(noReadDatum);
                }
            }

        }).start();

        addSubscribe(
                AppDataBase.getInstance().messageDao().getAllUnreadMessagesByConversationId(studioId, SLCacheUtil.getCurrentUserId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(),true)
                        .subscribe(noReadData -> {
                            noReadData.sort((tkMessage, t1) -> (int) (t1.getDatetime() - tkMessage.getDatetime()));
                            TreeMap<String,List<TKMessage>> messages = new TreeMap<>();
                            //获取
                            unReadMessage = noReadData;
                            for (TKMessage noReadDatum : noReadData) {
                                String s = TimeUtils.timeFormat((long) noReadDatum.getDatetime(), "dd/MM/yyyy");
                                if (messages.get(s) ==null){
                                    if (messages.size()==3){
                                        break;
                                    }
                                    ArrayList<TKMessage> v = new ArrayList<>();
                                    v.add(noReadDatum);
                                    messages.put(s, v);
                                }else {
                                    List<TKMessage> messages1 = messages.get(s);
                                    messages1.add(noReadDatum);
                                }
                            }
                            if (messages.size()!=0&&!isShowedUnReadMessage){
                                uc.showAnnouncementDialog.postValue(messages);
                                isShowedUnReadMessage = true;
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public BindingCommand clickStudioAnnouncement = new BindingCommand(() -> {
        Bundle bundle = new Bundle();
        bundle.putSerializable("conversation", studioAnnouncementConversation);
        startActivity(ChatActivity.class, bundle);
    });
}
