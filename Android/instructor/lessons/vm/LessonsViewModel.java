package com.spelist.tunekey.ui.teacher.lessons.vm;

import static com.spelist.tunekey.api.ListenerService.handleSnapshot;

import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.utils.MemoryManager;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.MetadataChanges;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.StudioService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.studioEvent.StudioEventListAc;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.BlockEntity;
import com.spelist.tunekey.entity.GoogleCalendarEventForShow;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.NotificationEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKFollowUp;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.entity.UserNotificationEntity;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.StudioCalendarHomeEX;
import com.spelist.tunekey.ui.studio.calendar.followUp.StudioFollowUpAc;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTimeUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class LessonsViewModel extends ToolbarViewModel {
    public ObservableField<String> unconfirmedCountString = new ObservableField("0");
    public ObservableField<String> cancelledCountString = new ObservableField("0");
    public ObservableField<String> rescheduledCountString = new ObservableField("0");
    public ObservableField<String> noShowsCountString = new ObservableField("0");
    public ObservableField<Integer> emptyLayoutVisibility = new ObservableField(View.GONE);
    public ObservableField<Integer> lessonLayoutVisibility = new ObservableField();
    public ObservableField<Integer> lessonDaysVisibility = new ObservableField();
    public ObservableField<Integer> lessonMonthVisibility = new ObservableField();
    public ObservableField<Integer> viewBtnVisibility = new ObservableField();
    public ObservableField<String> month = new ObservableField();
    public ObservableField<Boolean> isShowCountDownView = new ObservableField(false);
    public List<StudentListEntity> studentList = new ArrayList<>();
    public int viewDisplayType = 0; // 0: close, 1: open

    //正在上课的Lesson
    public LessonScheduleEntity nowLesson;

    //    // data connection
////    public LessonsFragment lessonsFragment;
    public List<LessonScheduleConfigEntity> scheduleConfigs = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypes = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleList = new ArrayList<>();
    public Map<String, LessonScheduleEntity> lessonScheduleMap = new HashMap<>();
    //    public List<EventConfigEntity> eventConfigList = new ArrayList<>();
//    public List<EventEntity> eventList = new ArrayList<>();
    public List<BlockEntity> blockList = new ArrayList<>();
    //    public List<LessonScheduleEntity> lessonScheduleListCache = new ArrayList<>();
//    public List<LessonScheduleEntity> lessonScheduleListCalculation = new ArrayList<>();
//    public List<LessonScheduleEntity> lessonScheduleList = new ArrayList<>();
//    public List<LessonScheduleEntity> lessonScheduleListDisplay = new ArrayList<>();
//    public List<LessonRescheduleEntity> lessonRescheduleList = new ArrayList<>();
//    public List<LessonCancellationEntity> lessonCancellationList = new ArrayList<>();
//    public JSONObject promptData = new JSONObject();
    //日期范围
    public long startTime = 0;
    public long endTime;
    //日历显示的月份的起始时间
    public Calendar currentMonthDate;
    //当前选择的天
    public long currentSelectTimestamp = TimeUtils.getCurrentTime() * 1000L;
    private ListenerRegistration lessonScheduleListener;
    public List<LessonRescheduleEntity> undoneRescheduleData = new ArrayList<>();

    private Map<String, StudentListEntity> studentMap = new HashMap<>();
    private Map<String, LessonTypeEntity> lessonTypeMap = new HashMap<>();
    private Map<String, LessonScheduleConfigEntity> configMap = new HashMap<>();
    private boolean isCheckingNotifications = false;
    public boolean haveLesson = false;
    public HashMap<String, LessonScheduleEntity> onlineLessonData = new HashMap<>();
    public HashMap<String, LessonScheduleEntity> locationLessonData = new HashMap<>();
    public List<TKFollowUp> followUpData = new ArrayList<>();

    public LessonsViewModel(@NonNull Application application) {
        super(application);
        initView();
        initData();
        initMessage();
    }

    public void initMessage() {
        Messenger.getDefault().register(this, MessengerUtils.STUDIO_FOLLOW_UP_CHANGE, () -> {
            followUpData = TKFollowUp.getTeacherData(SLCacheUtil.getCurrentUserId(), CloneObjectUtils.cloneObject(ListenerService.shared.teacherData.getFollowUps()));
            initFollowUpData();
        });

        Messenger.getDefault().register(this, MessengerUtils.REFRESH_LESSON, LessonScheduleConfigEntity.class, new BindingConsumer<LessonScheduleConfigEntity>() {
            @Override
            public void call(LessonScheduleConfigEntity lessonScheduleConfigEntity) {
//                initData(lessonScheduleConfigEntity.getStartDateTime());
            }
        });
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_STUDENT_LIST_CHANGED, () -> {
            SLCacheUtil.setStudentList(UserService.getInstance().getCurrentUserId(), ListenerService.shared.teacherData.getStudentList());
            getStudentList();
            reloadData();
        });
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_TYPE_CHANGED, this::reloadData);

        Messenger.getDefault().register(this, MessengerUtils.TEACHER_LESSON_SCHEDULE_CONFIG_CHANGED, this::reloadData);

        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, this::reloadData);

        Messenger.getDefault().register(this, MessengerUtils.REFRESH_REMINDER, this::initNotification);
        Messenger.getDefault().register(this, MessengerUtils.SHOW_COUNT_DOWN_VIEW, this::checkClassNow);

        Messenger.getDefault().register(this, MessengerUtils.TEACHER_GOOGLE_CALENDAR_EVENTS_CHANGED, new BindingAction() {
            @Override
            public void call() {

//                Logger.e("Google Event 数据更新: %s", SLJsonUtils.toJsonString(ListenerService.shared.teacherData.getGoogleCalendarEventsForShow()));
//                Logger.e("Google Event 数据更新个数为: %s", ListenerService.shared.teacherData.getGoogleCalendarEventsForShow().size());

                if (ListenerService.shared.teacherData.getGoogleCalendarEventsForShow().size() > 0) {
                    initGoogleEvent();

                } else {
                    for (LessonScheduleEntity lessonScheduleEntity : lessonScheduleList) {
                        if (lessonScheduleEntity.getType() == 4) {
                            lessonScheduleMap.remove(lessonScheduleEntity.getId());
                        }
                    }
                    lessonScheduleList.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getType() == 4);
                    uc.refreshData.call();
                }


            }
        });
    }

    private void initFollowUpData() {
        int unconfirmedCount = 0;
        int cancelledCount = 0;
        int rescheduledCount = 0;
        int noShowsCount = 0;
        for (TKFollowUp data : followUpData) {
            switch (data.getColumn()) {
                case TKFollowUp.Column.unconfirmed:
                    if (data.getDataType().equals(TKFollowUp.DataType.noshows)) {
                        if (!data.getStatus().equals(TKFollowUp.Status.archived)) {
                            noShowsCount++;
                        }
                    } else {
                        unconfirmedCount++;
                    }
                    break;
                case TKFollowUp.Column.cancelled:
                    if (!data.getStatus().equals(TKFollowUp.Status.archived)) {
                        cancelledCount++;
                    }
                    break;
                case TKFollowUp.Column.rescheduled:
                    if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                        //是老师 并且 不是studio的管理员
                        if (!data.getRescheduleData().isTeacherRead()) {
                            rescheduledCount++;
                        }
                    } else {
                        if (!data.getRescheduleData().isStudioManagerRead()) {
                            rescheduledCount++;
                        }
                    }
                    break;
                case TKFollowUp.Column.noshows:
                    if (!data.getStatus().equals(TKFollowUp.Status.archived)) {
                        noShowsCount++;
                    }
                    break;
            }
        }
        unconfirmedCountString.set("" + unconfirmedCount);
        cancelledCountString.set("" + cancelledCount);
        rescheduledCountString.set("" + rescheduledCount);
        noShowsCountString.set("" + noShowsCount);
    }


    private void initNotificationData() {
        List<UserNotificationEntity> userNotifications = ListenerService.shared.userNotifications;
        String uId = UserService.getInstance().getCurrentUserId();
        List<LessonRescheduleEntity> data = new ArrayList<>();
        if (uId.equals("")) {
            return;
        }
        boolean newMsg = false;
        for (UserNotificationEntity notification : userNotifications) {
            if (!newMsg) {
                if (!notification.getSenderId().equals(uId) && !notification.getSenderId().equals("")) {
                    newMsg = true;
                }
            }
            switch (notification.getCategory()) {
                case 1:
                case 11:
                case 3:
                    LessonRescheduleEntity entity = SLJsonUtils.toBean(notification.getData(), LessonRescheduleEntity.class);
                    entity.setStudentData(studentMap.get(entity.getStudentId()));
                    data.add(entity);
                    break;
                case 2:
                case 21:
                    LessonCancellationEntity cancellation = SLJsonUtils.toBean(notification.getData(), LessonCancellationEntity.class);
                    LessonRescheduleEntity e = cancellation.convertToReschedule();
                    e.setStudentData(studentMap.get(cancellation.getStudentId()));
                    data.add(e);

                    break;
            }
        }
        undoneRescheduleData = data;
        //TODO:设置应用未读数
//        Logger.e("undoneRescheduleData的个数: %s", SLJsonUtils.toJsonString(undoneRescheduleData));
    }

    public void initData() {
//        agendaListOnWebview.clear();
//        // 初始化数据日期范围
//        initDataStartToEnd(startTimestamp);
//        // 获取 event config
//        getTeacherEventConfigList(false);
//        // 获取 reschedule
//        getTeacherLessonRescheduleList(false);
//        // 获取 block
//        getTeacherBlockList(false, start, end);
        // 初始化数据日期范围


        haveLesson = SLCacheUtil.getHaveLesson();
        initHaveData();
        followUpData = TKFollowUp.getTeacherData(SLCacheUtil.getCurrentUserId(), CloneObjectUtils.cloneObject(ListenerService.shared.teacherData.getFollowUps()));
        initFollowUpData();

        currentMonthDate = SLTimeUtils.getCurrentMonthStart();
        startTime = SLTimeUtils.calendarAddMonth(currentMonthDate, -2).getTime().getTime();
        endTime = SLTimeUtils.calendarAddMonth(currentMonthDate, 5).getTime().getTime();

        // 获取学生列表
        getStudentList();
        //初始化日程数据
        reloadData();


    }

    public void initHaveData() {
        if (haveLesson) {
            if (emptyLayoutVisibility.get() != View.GONE) {
                emptyLayoutVisibility.set(View.GONE);
                lessonLayoutVisibility.set(View.VISIBLE);
                viewBtnVisibility.set(View.VISIBLE);
                setLeftImgButtonVisibility(View.VISIBLE);
            }

        } else {
            if (emptyLayoutVisibility.get() != View.VISIBLE) {
                emptyLayoutVisibility.set(View.VISIBLE);
                viewBtnVisibility.set(View.GONE);
                lessonLayoutVisibility.set(View.GONE);
                setLeftImgButtonVisibility(View.GONE);
            }
        }
    }

    private void reloadData() {
        ListenerService.TeacherDataEntity teacherData = ListenerService.shared.teacherData;
        lessonTypes = teacherData.getLessonTypes();
        scheduleConfigs = teacherData.getScheduleConfigs();
        configMap.clear();

        for (LessonTypeEntity lessonType : lessonTypes) {
            lessonTypeMap.put(lessonType.getId(), lessonType);
        }
        for (LessonScheduleConfigEntity scheduleConfig : scheduleConfigs) {
            configMap.put(scheduleConfig.getId(), scheduleConfig);
        }


        blockList = teacherData.getBlockEntities();
        lessonScheduleList.clear();
        lessonScheduleMap.clear();
        initNotificationData();
        initBlockData();
        initLessonSchedule();
        initGoogleEvent();

    }

    private void initGoogleEvent() {
        lessonScheduleList.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getType() == 4);
        for (GoogleCalendarEventForShow item : ListenerService.shared.teacherData.getGoogleCalendarEventsForShow()) {
            LessonScheduleEntity agendaEntity = new LessonScheduleEntity();
            agendaEntity.setId(item.getId());
            agendaEntity.setUrl("");
            agendaEntity.setOverDay(false);
            agendaEntity.setName(item.getSummary());
            agendaEntity.setShouldDateTime(item.getStartDateTime());
            agendaEntity.setShouldTimeLength((int) (item.getEndDateTime() - item.getStartDateTime()) / 60);
            agendaEntity.setType(4);
            lessonScheduleMap.put(item.getId(), agendaEntity);
            lessonScheduleList.add(agendaEntity);
        }
        uc.refreshData.call();
    }

    private void initBlockData() {
        lessonScheduleList.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getType() == 3);
        for (BlockEntity blockEntity : blockList) {
            LessonScheduleEntity agendaEntity = new LessonScheduleEntity();
            agendaEntity.setId(blockEntity.getId());
            agendaEntity.setUrl("");
            agendaEntity.setOverDay(false);
            agendaEntity.setName("Off");
            agendaEntity.setShouldDateTime(blockEntity.getStartDateTime());
            agendaEntity.setShouldTimeLength(24 * 60);
            agendaEntity.setType(3);
            lessonScheduleMap.put(blockEntity.getId(), agendaEntity);
            lessonScheduleList.add(agendaEntity);

        }

    }

    public void changeCalendarPage(long time) {
        time = time * 1000L;
        boolean reset = false;
        if (time - currentMonthDate.getTimeInMillis() > 0) {
            if (SLTimeUtils.getDifferMonth(time, endTime) < 4) {
                endTime = SLTimeUtils.calendarAddMonth(endTime, 5).getTimeInMillis();
                reset = true;
            } else {
                Logger.e("======%s", "当前日期与结束日期之间大于3个月,不获取");
            }
        } else {
            if (SLTimeUtils.getDifferMonth(time, startTime) < 2) {
                startTime = SLTimeUtils.calendarAddMonth(startTime, -2).getTimeInMillis();
                reset = true;
            } else {
                Logger.e("======%s", "当前日期与开始日期之间小于2个月,不获取");
            }
        }

        currentMonthDate.setTimeInMillis(SLTimeUtils.getMonthStart(time).getTimeInMillis());
        Logger.e("是否需要重新加载数据:%s, 当前日期:%s, 开始时间:%s, 结束时间:%s", reset, TimeUtils.getTimestampFormatYMD(currentMonthDate.getTimeInMillis()), TimeUtils.getTimestampFormatYMD(startTime), TimeUtils.getTimestampFormatYMD(endTime));
        if (reset) {
            if (SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
                addSubscribe(
                        LessonService
                                .getInstance()
                                .teacherRefreshLessonSchedule(scheduleConfigs, lessonTypes, startTime, endTime)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread(), true)
                                .subscribe(data -> {
                                    Logger.e("刷新课程 成功==>");
                                }, throwable -> {
                                    Logger.e("刷新课程失败,失败原因" + throwable.getMessage());
                                })
                );
            }

            initLessonSchedule();
        }
        uc.refreshData.call();
    }

    private void initLessonSchedule() {
        String tId = UserService.getInstance().getCurrentUserId();
        if (tId.equals("")) {
            return;
        }
        studentList = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
        Logger.e("[准备监听LessonSchedule]开始时间:%s,结束时间:%s", TimeUtils.getTimestampFormatYMD(startTime), TimeUtils.getTimestampFormatYMD(endTime));
        if (lessonScheduleListener != null) {
            lessonScheduleListener.remove();
            lessonScheduleListener = null;
        }
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            Logger.e("课程个数 开始前==>%s==>%s", lessonScheduleList.size(), lessonScheduleMap.size());
            String jsFile = FuncUtils.getJsFuncStr(TApplication.mApplication, "rrule2");
            V8 v8 = V8.createV8Runtime();
            MemoryManager scope = new MemoryManager(v8);
            v8.executeVoidScript(jsFile);
            configMap.forEach((key, value) -> {
                List<LessonScheduleEntity> data = StudioService.getInstance().getLessonTimeByRRuleAndStartTimeAndEndTime(value, (int) (startTime / 1000L), (int) (endTime / 1000L),v8);
                for (LessonScheduleEntity item : data) {
                    SLCacheUtil.setLessonData(item);
                    if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                        lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                    } else {
                        if (studentMap.get(item.getStudentId()) == null) {
                            if (lessonScheduleMap.get(item.getId()) != null) {
                                lessonScheduleMap.remove(item.getId());
                                lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                                onlineLessonData.remove(item.getId());
                            }
                            continue;
                        }
                        item.setStudentData(studentMap.get(item.getStudentId()));
                        item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
                        if (configMap.get(item.getLessonScheduleConfigId()) != null) {
                            item.setConfigEntity(configMap.get(item.getLessonScheduleConfigId()));
                        }
                        item.setWebData();
                        locationLessonData.put(item.getId(), item);
                        if (lessonScheduleMap.get(item.getId()) != null) {
                            for (int i = 0; i < lessonScheduleList.size(); i++) {
                                if (lessonScheduleList.get(i).getId().equals(item.getId())) {
                                    lessonScheduleList.set(i, item);
                                    break;
                                }
                            }
                        } else {
                            lessonScheduleMap.put(item.getId(), item);
                            lessonScheduleList.add(item);
                        }
                    }
                }
            });
            scope.release();
            v8.release();
            uc.refreshData.call();
            checkClassNow();
            Logger.e("课程个数 计算后==>%s==>%s", lessonScheduleList.size(), lessonScheduleMap.size());

        }

        lessonScheduleListener = DatabaseService.Collections.lessonSchedule()
                .whereEqualTo("teacherId", tId)
                .whereLessThanOrEqualTo("shouldDateTime", (endTime / 1000))
                .whereGreaterThanOrEqualTo("shouldDateTime", (startTime / 1000))
                .addSnapshotListener(MetadataChanges.INCLUDE, (snapshots, e) -> {
                    Logger.e("======%s", "开始监听课程");
                    if (e != null) {
                        Logger.e("[监听LessonSchedule数据失败]%s", e.getMessage());
                    } else {
                        ListenerService.SnapshotData<LessonScheduleEntity> data = handleSnapshot(snapshots, LessonScheduleEntity.class);
                        Logger.e("课程个数==监听=%s=%s", data.getAdded().size(), data.getModified().size());

                        if (data.getAdded().size() > 0 || data.getModified().size() > 0) {
                            for (LessonScheduleEntity item : data.getAdded()) {
                                SLCacheUtil.setLessonData(item);
                                if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                                    lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                                } else {
                                    if (studentMap.get(item.getStudentId()) == null) {
                                        if (lessonScheduleMap.get(item.getId()) != null) {
                                            lessonScheduleMap.remove(item.getId());
                                            lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                                            onlineLessonData.remove(item.getId());
                                        }
                                        continue;
                                    }
                                    item.setStudentData(studentMap.get(item.getStudentId()));
                                    item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
                                    if (configMap.get(item.getLessonScheduleConfigId()) != null) {
                                        item.setConfigEntity(configMap.get(item.getLessonScheduleConfigId()));
                                    }
                                    item.setWebData();
                                    onlineLessonData.put(item.getId(), item);
                                    if (lessonScheduleMap.get(item.getId()) != null) {
                                        for (int i = 0; i < lessonScheduleList.size(); i++) {
                                            if (lessonScheduleList.get(i).getId().equals(item.getId())) {
                                                lessonScheduleList.set(i, item);
                                                break;
                                            }
                                        }
                                    } else {
                                        lessonScheduleMap.put(item.getId(), item);
                                        lessonScheduleList.add(item);
                                    }
                                }
                            }

                            for (LessonScheduleEntity item : data.getModified()) {
                                SLCacheUtil.setLessonData(item);
                                if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                                    lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                                } else {
                                    if (studentMap.get(item.getStudentId()) == null) {
                                        if (lessonScheduleMap.get(item.getId()) != null) {
                                            lessonScheduleMap.remove(item.getId());
                                            lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(item.getId()));
                                        }
                                        continue;
                                    }
                                    item.setStudentData(studentMap.get(item.getStudentId()));
                                    item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
                                    if (configMap.get(item.getLessonScheduleConfigId()) != null) {
                                        item.setConfigEntity(configMap.get(item.getLessonScheduleConfigId()));
                                    }
                                    item.setWebData();
                                    if (lessonScheduleMap.get(item.getId()) != null) {
                                        for (int i = 0; i < lessonScheduleList.size(); i++) {
                                            if (lessonScheduleList.get(i).getId().equals(item.getId())) {
                                                lessonScheduleList.set(i, item);
                                                break;
                                            }
                                        }
                                    } else {
                                        lessonScheduleMap.put(item.getId(), item);
                                        lessonScheduleList.add(item);
                                    }
                                }
                            }
                        }
                        //删除被删除的课程
                        for (LessonScheduleEntity lessonScheduleEntity : data.getRemoved()) {
                            lessonScheduleList.removeIf(thisLesson -> thisLesson.getId().equals(lessonScheduleEntity.getId()));
                            lessonScheduleMap.remove(lessonScheduleEntity.getId());
                        }

                        uc.refreshData.call();
                        new Thread(() -> {
                            //更新数据库课程数据
                            AppDataBase.getInstance().lessonDao().insertAll(lessonScheduleList);
                        }).start();
                        //去除无用数据
                        if (SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
                            LessonService.getInstance().teacherCheckLessonsIfIsValid(lessonScheduleList);
                        } else {
                            StudioCalendarHomeEX.updateLessonData(locationLessonData, onlineLessonData);
                        }
                        checkClassNow();
                        initNotification();
                    }
                });
    }

    private void getStudentList() {
        studentList = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
        studentMap.clear();
        for (StudentListEntity studentListEntity : studentList) {
            studentMap.put(studentListEntity.getStudentId(), studentListEntity);
        }
    }

    private void initNotification() {
        if (isCheckingNotifications) {
            return;
        }

        addSubscribe(UserService
                .getInstance()
                .getNotification(false)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(this::checkNotificationData, throwable -> Logger.e("getNotification,失败原因" + throwable.getMessage())));
    }

    private void checkNotificationData(NotificationEntity notificationConfig) {
        if (isCheckingNotifications) {
            return;
        }
        if (!notificationConfig.isReminderOpened()) {
            Logger.e("开始设置NotificationReminder, Reminder为关闭状态清空通知");
            TKNotificationUtils.closeLessonNotification(TApplication.getInstance().getBaseContext());
            return;
        }
        Logger.e("开始设置NotificationReminder数据");
        isCheckingNotifications = true;
        List<LessonScheduleEntity> data = new ArrayList<>();
        int currentTime = TimeUtils.getCurrentTime();
        data = lessonScheduleList.stream().filter(item -> item.getTKShouldDateTime() > currentTime && (item.getType() == 0 || item.getType() == 1)).collect(Collectors.toList());
        data = data.stream().sorted(Comparator.comparing(LessonScheduleEntity::getTKShouldDateTime)).collect(Collectors.toList());
        // 获取要提醒的提前时间
        List<Integer> times = notificationConfig.getReminderTimes().stream().filter(item -> item < 1440).collect(Collectors.toList());
        boolean hasNextDayLesson = notificationConfig.getReminderTimes().contains(1440);
        Calendar today = TimeUtils.getStartDay(currentTime);
        long nextWeek = TimeUtils.addDay(today.getTimeInMillis(), 8) / 1000L;
        //排除天的通知
        List<LessonScheduleEntity> dataList = data.stream().filter(item -> item.getTKShouldDateTime() <= nextWeek).collect(Collectors.toList());
//        List<String> timeForReminder = new ArrayList<>();
        TKNotificationUtils.closeLessonNotification(TApplication.getInstance().getBaseContext());
        List<Integer> reminderIds = new ArrayList<>();
        for (LessonScheduleEntity item : dataList) {
            for (Integer time : times) {
                long reminderTime = TimeUtils.addMinute(item.getTKShouldDateTime() * 1000L, -time) / 1000L;
                if (reminderTime > currentTime) {
                    if (studentMap.get(item.getStudentId()) != null) {
//                        timeForReminder.add(TimeUtils.timeFormat(reminderTime, "yyyy-MM-dd hh:mm:ss a"));
                        reminderIds.add(reminderIds.size() + 1);

                        String timeString = "";
                        if (time > 60) {
                            timeString = (time / 60) + " hour" + ((time / 60) > 1 ? "s" : "");
                            if (time % 60 > 0) {
                                timeString += (time % 60) + " minute" + ((time % 60) > 1 ? "s" : "");
                            }
                        } else {
                            timeString = time + " minute" + (time > 1 ? "s" : "");
                        }
                        String content = "You're scheduled to teach a lesson in " + timeString + " with " + studentMap.get(item.getStudentId()).getName();
                        TKNotificationUtils.scheduleNotification(TApplication.getInstance().getBaseContext(), "Reminder for today's lesson", content, reminderTime * 1000L, reminderIds.size());
//                        Logger.e("即时提醒: 上课的时间:%s, 提醒的时间:%s, 通知内容%s", TimeUtils.timeFormat(item.getShouldDateTime() , "yyyy-MM-dd hh:mm:ss a"),TimeUtils.timeFormat(reminderTime , "yyyy-MM-dd hh:mm:ss a"),content);
                    }
//
                }
            }
        }
        Map<Long, List<LessonScheduleEntity>> oneDayReminder = new HashMap<>();
//        List<LessonScheduleEntity> tomorrowLesson = new ArrayList<>();
        //明天的通知
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
                StringBuilder content = new StringBuilder("You're scheduled to teach ");
                content.append(value.size()).append(" lesson").append(value.size() > 1 ? "s" : "").append(" tomorrow with ");
                for (int i = 0; i < value.size(); i++) {
                    LessonScheduleEntity item = value.get(i);
                    if (studentMap.get(item.getStudentId()) != null) {
                        if (i == value.size() - 1) {
                            content.append("and ");
                        }
                        content.append(studentMap.get(item.getStudentId()).getName()).append(" at ").append(TimeUtils.timeFormat(item.getTKShouldDateTime(), "hh:mm a"));
                        if (i == value.size() - 1) {
                            content.append(".");
                        } else {
                            content.append(", ");
                        }
                    }

                }
//                Logger.e("提前一天提醒%s: 通知内容%s", TimeUtils.timeFormat(time / 1000L, "yyyy-MM-dd hh:mm:ss a"), content.toString());
                reminderIds.add(reminderIds.size() + 1);
                TKNotificationUtils.scheduleNotification(TApplication.getInstance().getBaseContext(), "Reminder for tomorrow's lesson", content.toString(), time, reminderIds.size());
            }
        });

//        Logger.e("timeForReminder: %s", timeForReminder);
        //把reminderId 存入到缓存中
        SLCacheUtil.setLessonNotificationIds(reminderIds);

        isCheckingNotifications = false;

    }


    /***************************开始-- Reschedule box data --开始*********************/
    //close用
    private void clickCloseCancelation(LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .confirmCancelation(data)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
//                    SLToast.success("Successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("clickCloseCancelation失败,失败原因" + throwable.getMessage());

                }));
    }

    //close用
    private void teacherReadRetractedReschedule(LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .teacherReadRetractedReschedule(data)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
//                    SLToast.success("Successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("ReadRetractedReschedule失败,失败原因" + throwable.getMessage());

                }));
    }

    //close用
    private void teacherReadReschedule(LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .teacherReadReschedule(data)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
//                    SLToast.success("Successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("teacherReadReschedule失败,失败原因" + throwable.getMessage());
                }));
    }

    //retract
    public void retractReschedule(LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .retractReschedule(data)
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

    public void declinedReschedule(String message, LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .teacherDeclinedReschedule(data)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
                    SLToast.success("Declined successfully!");
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("teacherReadReschedule失败,失败原因" + throwable.getMessage());
                }));

    }

    /***************************结束-- Reschedule box data --结束*********************/


    private void initView() {
//        Logger.e("-*-*-*-*-*-*-*- hasLesson: " + hasLesson);
//        if (hasLesson) {
//            emptyLayoutVisibility.set(View.GONE);
//            lessonLayoutVisibility.set(View.VISIBLE);
////            if (lessonsFragment != null && lessonsFragment.viewDisplayType == 0) {
//                viewBtnVisibility.set(View.VISIBLE);
////            }
//            lessonDaysVisibility.set(View.VISIBLE);
//            lessonMonthVisibility.set(View.GONE);
////            if(lessonsFragment.lessonDisplayType < 4) {
////                lessonDaysVisibility.set(View.VISIBLE);
////                lessonMonthVisibility.set(View.GONE);
////            }else {
////                lessonDaysVisibility.set(View.GONE);
////                lessonMonthVisibility.set(View.VISIBLE);
////            }
//        } else {
//            emptyLayoutVisibility.set(View.VISIBLE);
//            viewBtnVisibility.set(View.GONE);
//            lessonLayoutVisibility.set(View.GONE);
//        }
        lessonMonthVisibility.set(View.VISIBLE);
        lessonDaysVisibility.set(View.GONE);
        month.set(TimeUtils.getMonthStr(Calendar.getInstance().get(Calendar.MONTH)));
    }

    @Override
    public void initToolbar() {

        setTitleString("Lessons");
        setLeftButtonVisibility(View.VISIBLE);
        setLeftButtonText(TimeUtils.getMonthStr(Calendar.getInstance().get(Calendar.MONTH)));

    }


    public class UIEventObservable {
        /**
         * 点击添加 lesson/event
         */
        public SingleLiveEvent<Void> clickAddLesson = new SingleLiveEvent<>();

        /**
         * 点击 filter
         */
        public SingleLiveEvent<Void> clickFilter = new SingleLiveEvent<>();

        /**
         * 点击 搜索 icon
         */
        public SingleLiveEvent<Void> clickSearch = new SingleLiveEvent<>();

        /**
         * 点击 view
         */
        public SingleLiveEvent<View> clickView = new SingleLiveEvent<>();

        /**
         * day
         */
        public SingleLiveEvent<Void> clickDay = new SingleLiveEvent<>();

        /**
         * 3 day
         */
        public SingleLiveEvent<Void> click3Day = new SingleLiveEvent<>();

        /**
         * week
         */
        public SingleLiveEvent<Void> clickWeek = new SingleLiveEvent<>();

        /**
         * month
         */
        public SingleLiveEvent<Void> clickMonth = new SingleLiveEvent<>();

        /**
         * 刷新日历数据
         */
        public SingleLiveEvent<Void> refreshData = new SingleLiveEvent<>();

        /**
         * 点击消息盒子中的Retract
         */
        public SingleLiveEvent<LessonRescheduleEntity> clickRetract = new SingleLiveEvent<>();

        /**
         * 点击消息盒子中的Retract
         */
        public SingleLiveEvent<LessonRescheduleEntity> clickDeclined = new SingleLiveEvent<>();


        public SingleLiveEvent<Map<String, String>> showErrorDialog = new SingleLiveEvent<>();

        public SingleLiveEvent<LessonScheduleEntity> nowLesson = new SingleLiveEvent<>();

    }

    public UIEventObservable uc = new UIEventObservable();

    public BindingCommand clickAddLesson = new BindingCommand(() -> uc.clickAddLesson.call());
    public TKButton.ClickListener clickAddLessonByTK = tkButton -> uc.clickAddLesson.call();

    public BindingCommand clickSearch = new BindingCommand(() -> uc.clickSearch.call());

    public BindingCommand clickView = new BindingCommand(() -> uc.clickView.call());

    public BindingCommand clickDay = new BindingCommand(() -> uc.clickDay.call());
    public BindingCommand click3Day = new BindingCommand(() -> uc.click3Day.call());
    public BindingCommand clickWeek = new BindingCommand(() -> uc.clickWeek.call());
    public BindingCommand clickMonth = new BindingCommand(() -> uc.clickMonth.call());

    /***************************开始-- RescheduleBoxClick --开始*********************/

    /**
     * 点击box close
     *
     * @param data
     */
    public void clickBoxClose(LessonRescheduleEntity data) {
        if (data.isCancelLesson()) {
            clickCloseCancelation(data);
        } else if (data.getRetracted()) {
            teacherReadRetractedReschedule(data);
        } else {
            teacherReadReschedule(data);
        }
    }

    /**
     * 点击box Confirm 两种情况 一种学生发过来 一种老师发过去然后学生重新选择时间
     *
     * @param data
     */
    public void clickBoxConfirm(LessonRescheduleEntity data) {
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .confirmReschedule(data)
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
    }

    /**
     * 老师取消reschedule
     *
     * @param data
     */
    public void clickRetract(LessonRescheduleEntity data) {
        uc.clickRetract.setValue(data);
    }


    /**
     * 点击Declined
     *
     * @param data
     */
    public void clickBoxDeclined(LessonRescheduleEntity data) {
        uc.clickDeclined.setValue(data);
    }


    /**
     * 点击Reschedule
     *
     * @param data
     * @param selectTime
     */
    public void clickBoxReschedule(LessonRescheduleEntity data, int selectTime) {
        Logger.e("======%s", selectTime);
        showDialog();
        addSubscribe(LessonService
                .getInstance()
                .updateReschedule(data, selectTime + "", true, false)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(d -> {
                    dismissDialog();
//                    SLToast.success("Successfully!");
                    CloudFunctions.sendEmailNotificationForRescheduleNewTime(data.getId(), 2, "");

                }, throwable -> {


                    if (throwable instanceof FirebaseFirestoreException) {
                        FirebaseFirestoreException error = (FirebaseFirestoreException) throwable;
                        Logger.e("走到了错误%s", error.getCode().value());
                        if (error.getCode() == FirebaseFirestoreException.Code.CANCELLED) {
                            String userId = "";
                            if (data.getTeacherId().equals(UserService.getInstance().getCurrentUserId())) {
                                userId = data.getStudentId();
                            } else {
                                userId = data.getTeacherId();
                            }
                            AtomicBoolean isSuccess = new AtomicBoolean(false);
                            addSubscribe(
                                    UserService
                                            .getInstance()
                                            .getUserById(userId)
                                            .subscribeOn(Schedulers.io())
                                            .observeOn(AndroidSchedulers.mainThread(), true)
                                            .subscribe(user -> {

                                                if (!isSuccess.get()) {
                                                    dismissDialog();
//                                                    Dialog dialog = SLDialogUtils.showOneButton(TApplication.getInstance().getBaseContext(),
//                                                            "Something wrong",
//                                                            "This lesson has been updated by" + user.getName() + "recently.",
//                                                            "SEE UPDATE");
//                                                    TextView button = dialog.findViewById(R.id.button);
//                                                    button.setOnClickListener(v -> {
//                                                        dialog.dismiss();
//                                                        uc.clickRescheduleBox.call();
//                                                    });
                                                    Map<String, String> d = new HashMap<>();
                                                    d.put("title", "Something wrong");
                                                    d.put("content", "This lesson has been updated by " + user.getName() + " recently.");
                                                    uc.showErrorDialog.setValue(d);
                                                    isSuccess.set(true);
                                                }
                                            }, e -> {
                                                Logger.e("走到了获取user数据");
                                                dismissDialog();
                                                SLToast.showError();
                                            })

                            );

                        } else if (error.getCode() == FirebaseFirestoreException.Code.UNKNOWN) {
//                            Dialog dialog = SLDialogUtils.showOneButton(TApplication.getInstance().getBaseContext(),
//                                    "Too late",
//                                    "Someone just took your spot, the time you attempted to confirm is no longer available. Please reconsider.",
//                                    "SEE UPDATE");
//                            TextView button = dialog.findViewById(R.id.button);
//                            button.setOnClickListener(v -> {
//                                dialog.dismiss();
//                                uc.clickRescheduleBox.call();
//                            });
                            Map<String, String> d = new HashMap<>();
                            d.put("title", "Too late");
                            d.put("content", "Someone just took your spot, the time you attempted to confirm is no longer available. Please reconsider.");
                            uc.showErrorDialog.setValue(d);
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
                    Logger.e("teacherUpdateReschedule失败,失败原因" + throwable.getMessage());
                }));


    }

    /***************************结束-- RescheduleBoxClick --结束*********************/


    private Handler nextLessonHandler;
//    private Timer timer;

    public void checkClassNow() {
        long nowTime = TimeUtils.getCurrentTime();
        LessonScheduleEntity lesson = null;
        List<LessonScheduleEntity> nextLessons = new ArrayList<>();
        for (LessonScheduleEntity item : lessonScheduleList) {
            if (item.getType() == 1 || item.getType() == 0) {
                long endTime = item.getTKShouldDateTime() + (item.getShouldTimeLength() * 60);
                if (nowTime >= item.getTKShouldDateTime() && nowTime < endTime && item.getLessonStatus() != 2) {
                    lesson = item;
                }
                if (nowTime < item.getTKShouldDateTime()) {
                    nextLessons.add(item);
                }
            }
        }
        nowLesson = lesson;
        if (lesson != null) {
            isShowCountDownView.set(true);
            uc.nowLesson.setValue(lesson);
            Messenger.getDefault().send(lesson, MessengerUtils.REFRESH_NOW_LESSON);

        } else {
            isShowCountDownView.set(false);
            Messenger.getDefault().send(new LessonScheduleEntity().setId("-999"), MessengerUtils.REFRESH_NOW_LESSON);

        }


        nextLessons.sort((o1, o2) -> (int) (o1.getTKShouldDateTime() - o2.getTKShouldDateTime()));

        if (nextLessons.size() > 0) {
            long difference = (nextLessons.get(0).getTKShouldDateTime() - nowTime) * 1000;
            if (nextLessonHandler != null) {
                nextLessonHandler.removeCallbacksAndMessages(null);
                nextLessonHandler = null;
            }

//            if (timer !=null){
//                timer.cancel();
//                timer = null;
//            }
//            timer = new Timer();
//            timer.schedule(new TimerTask() {
//                @Override
//                public void run() {
//                    nowLesson = nextLessons.get(0);
//                    isShowCountDownView.set(true);
//                    uc.nowLesson.setValue(nextLessons.get(0));
//                    Logger.e("1======%s","倒计时结束开始显" );
//                    checkClassNow();
//                }
//            },difference);
            nextLessonHandler = new Handler();
            nextLessonHandler.postDelayed(() -> {
                nowLesson = nextLessons.get(0);
                isShowCountDownView.set(true);
                uc.nowLesson.setValue(nextLessons.get(0));
                checkClassNow();
            }, difference);
        }
    }


    public void updateBlock(int time, String blockId) {
        showDialog();
        addSubscribe(
                LessonService
                        .getInstance()
                        .editBlock(time, blockId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            SLToast.success("Edit Successfully!");
                        }, throwable -> {
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public void deleteBlock(String blockId) {
        showDialog();
        addSubscribe(
                LessonService
                        .getInstance()
                        .deleteBlock(blockId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            SLToast.success("Delete Successfully!");
                        }, throwable -> {
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public void setupBlock(int time) {
        BlockEntity blockEntity = new BlockEntity()
                .setId(IDUtils.getId())
                .setTeacherId(UserService.getInstance().getCurrentUserId())
                .setCreateTime(TimeUtils.getCurrentTimeString())
                .setUpdateTime(TimeUtils.getCurrentTimeString())
                .setStartDateTime(time)
                .setEndDateTime((int) (TimeUtils.getEndDay(time).getTimeInMillis() / 1000L));
        showDialog();
        addSubscribe(
                LessonService
                        .getInstance()
                        .addNewBlock(blockEntity)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            SLToast.success("Set successfully!");
                        }, throwable -> {
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    public BindingCommand<View> clickFollowUpLayout = new BindingCommand<View>(view -> {
        int selectPos = 0;
        switch (view.getId()) {
            case R.id.unconfirmedLayout:
                selectPos = 0;
                break;
            case R.id.cancelledLayout:
                selectPos = 1;
                break;
            case R.id.rescheduleLayout:
                selectPos = 2;
                break;
            case R.id.noShowLayout:
                selectPos = 3;
                break;
        }
        Bundle bundle = new Bundle();
        bundle.putInt("pos", selectPos);
        startActivity(StudioFollowUpAc.class, bundle);
    });


    // data connection

//    /**
//     * 获取教师的学生列表(cache)
//     */
//    private void getStudentList() {
//        addSubscribe(
//                UserService
//                        .getInstance()
//                        .getStudentListForTeacher(true)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(students -> {
//                            if (students.size() > 0) {
//                                studentList = students;
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的学生列表(cache), size: " + studentList.size());
//                            }
//                            // 获取 lesson type
//                            getTeacherLessonTypeList(false);
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 获取教师的 lessonScheduleConfig 列表
//     */
//    private void getTeacherLessonScheduleConfigList(boolean isOnlyCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonScheduleConfigList(isOnlyCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(lessonScheduleConfigs -> {
//                            if (lessonScheduleConfigs != null && lessonScheduleConfigs.size() > 0) {
//                                lessonScheduleConfigList = lessonScheduleConfigs;
////                                Gson gson = new Gson();
////                                Logger.json(gson.toJson(lessonScheduleConfigs));
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 config 列表, size: " + lessonScheduleConfigList.size());
//
//                                // 计算 schedule
//                                calculateLessonScheduleList(isOnlyCache);
//                            }
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*-  throwable: " + throwable);
////                            lessonScheduleConfigList = new ArrayList<>();
////                            calculateLessonScheduleList(isOnlyCache);
//                        })
//        );
//    }
//
//    /**
//     * js 计算出教师在时间段内所有的 lessonSchedule
//     *
//     * @param isOnlyCache
//     */
//    private void calculateLessonScheduleList(boolean isOnlyCache) {
//        Logger.e("-*-*-*-*-*-*-*- js 计算 ");
//        lessonScheduleListCalculation.clear();
//        if (lessonScheduleConfigList.size() > 0) {
//            Logger.e("-*-*-*-*-*-*-*- js 计算出教师在时间段内所有的 lessonSchedule");
//            int currentTime = (int) (System.currentTimeMillis() / 1000L);
//            String jsFile = FuncUtils.getJsFuncStr(getApplication(), "calculate.lesson.event");
//            V8 v8 = V8.createV8Runtime();
//            MemoryManager scope = new MemoryManager(v8);
//            v8.executeVoidScript(jsFile);
//
//            for (int i = 0; i < lessonScheduleConfigList.size(); i++) {
//                boolean validConfig = false;
//                LessonScheduleConfigEntity entity = lessonScheduleConfigList.get(i);
//                String studentId = entity.getStudentId();
//
//                for (int j = 0; j < studentList.size(); j++) {
//                    if (studentList.get(j).getStudentId().equals(studentId)) {
//                        validConfig = true;
//                        break;
//                    }
//                }
//
//                if (!validConfig) {
//                    continue;
//                }
//
//                int repeatType = entity.getRepeatType() == 1 ? 2 : entity.getRepeatType();
//                int startTimestamp = entity.getStartDateTime();
//                int endTimestamp = entity.getEndDate();
//                long lessonStartTime = startTimestamp * 1000L;
//                long lessonEndTime = endTimestamp * 1000L;
//                String[] dateArr;
//                int dateArrLength;
//                Logger.e("-=-=-=-=-=-=-=- endDate: " + entity.getEndDate());
//                String lessonStartYMD = TimeUtils.getTimestampFormatYMD(lessonStartTime);
//                String lessonEndYMD = TimeUtils.getTimestampFormatYMD(lessonEndTime);
//
//                if (repeatType != 0) {
//                    V8Array configWeekDay = new V8Array(v8);
//                    List<Integer> configWeekDayFromEntity = entity.getRepeatTypeWeekDay();
//                    if (configWeekDayFromEntity.size() > 0) {
//                        for (int w = 0; w < configWeekDayFromEntity.size(); w++) {
//                            configWeekDay.push(configWeekDayFromEntity.get(w));
//                        }
//                    }
////                    Logger.e("-*-*-*-*-*-*-*- lessonStart: " + lessonStartYMD);
////                    Logger.e("-*-*-*-*-*-*-*- lessonEnd: " + lessonEndYMD);
////                    Logger.e("-*-*-*-*-*-*-*- startTimestamp: " + lessonStartTime);
//                    // 组装计算数据
//                    V8Object configFromJava = new V8Object(v8)
//                            .add("startYYMMDD", startYMD)
//                            .add("endYYMMDD", endYMD)
//                            .add("lessonStartYYMMDD", lessonStartYMD)
//                            .add("lessonEndYYMMDD", lessonEndYMD)
//                            .add("configWeekDay", configWeekDay)
//                            .add("endType", entity.getEndType())
//                            .add("endCount", entity.getEndCount())
//                            .add("repeatType", repeatType)
//                            .add("monthRepeat", entity.getRepeatTypeMonthDayType())
//                            .add("nthWeekIndex", entity.getRepeatTypeMonthDay())
//                            .add("nthDay", entity.getRepeatTypeMonthDay())
//                            .add("lastDay", 1)
//                            .add("weekRepeat", repeatType)
//                            .add("lessonStartTimestamp", lessonStartTime)
//                            .add("currentBasedTime", System.currentTimeMillis());
//
//                    V8Array param = new V8Array(v8).push(configFromJava);
//                    String dateStr = v8.executeStringFunction("calcDate", param);
//                    Logger.e("-*-*-*-*-*-*-*- dateStr: " + dateStr);
//                    dateArr = dateStr.split(",");
//                    Logger.e("-*-*-*-*-*-*-*- dateArr: " + Arrays.toString(dateArr));
//                    dateArrLength = dateArr.length;
//                } else {
//                    dateArr = new String[]{lessonStartYMD};
//                    dateArrLength = dateArr.length;
//                    Logger.e("no repeat lesson: " + dateArrLength);
//                }
//
//                // 组装计算结果
//                if (dateArrLength > 0) {
//                    Logger.e("组装lesson");
//                    LessonTypeEntity ltEntity = new LessonTypeEntity();
//                    for (int s = 0; s < lessonTypeList.size(); s++) {
//                        if (entity.getLessonTypeId().equals(lessonTypeList.get(s).getId())) {
//                            ltEntity = lessonTypeList.get(s);
//                        }
//                    }
//
//                    for (int j = 0; j < dateArrLength; j++) {
//                        LessonScheduleEntity calculationEntity = new LessonScheduleEntity();
//                        String hour = TimeUtils.getFormatHour(entity.getStartDateTime() * 1000L);
//                        String minute = TimeUtils.getFormatMinute(entity.getStartDateTime() * 1000L);
//                        Logger.e("-*-*-*-*-*-*-*- yy/mm/dd hh:mm -> " + dateArr[j] + " " + hour + ":" + minute);
//                        int shouldDateTime = (int) (TimeUtils.getTimestampBasedOnFormat(dateArr[j] + " " + hour + ":" + minute) / 1000L);
//                        String id = entity.getTeacherId() + ":" + studentId + ":" + shouldDateTime;
//                        calculationEntity.setId(id);
//                        calculationEntity.setInstrumentId(ltEntity.getInstrumentId());
//                        calculationEntity.setLessonTypeId(ltEntity.getId());
//                        calculationEntity.setLessonScheduleConfigId(entity.getId());
//                        calculationEntity.setTeacherId(entity.getTeacherId());
//                        calculationEntity.setStudentId(studentId);
//                        calculationEntity.setShouldDateTime(shouldDateTime);
//                        calculationEntity.setShouldTimeLength(ltEntity.getTimeLength());
//                        calculationEntity.setRealityDateTime(0);
//                        calculationEntity.setRealityTimeLength(0);
//                        calculationEntity.setTeacherNote("");
//                        calculationEntity.setStudentNote("");
//                        calculationEntity.setLessonStatus(0);
//                        calculationEntity.setCancelled(false);
//                        calculationEntity.setRescheduled(false);
//                        calculationEntity.setRescheduleId("");
//                        calculationEntity.setCreateTime(String.valueOf(currentTime));
//                        calculationEntity.setUpdateTime(String.valueOf(currentTime));
//                        lessonScheduleListCalculation.add(0, calculationEntity);
//                    }
//                }
//            }
//
//            Logger.e("-*-*-*-*-*-*-*- 计算结果组装完成: " + lessonScheduleListCalculation.size());
//            scope.release();
//        }
//        // 获取 schedule cache / online
//        getTeacherLessonScheduleList(isOnlyCache);
//    }
//
//    /**
//     * js 计算出教师在时间段内所有的 event
//     */
//    private void calculateEventList() {
//        Logger.e("-*-*-*-*-*-*-*- js 计算");
//        eventList.clear();
//        if (eventConfigList != null && eventConfigList.size() > 0) {
//            Logger.e("-*-*-*-*-*-*-*- js 计算出教师在时间段内所有的 event");
//            int currentTime = (int) (System.currentTimeMillis() / 1000L);
//            String jsFile = FuncUtils.getJsFuncStr(getApplication(), "calculate.lesson.event");
//            V8 v8 = V8.createV8Runtime();
//            MemoryManager scope = new MemoryManager(v8);
//            v8.executeVoidScript(jsFile);
//
//            config:
//            for (int i = 0; i < eventConfigList.size(); i++) {
//                EventConfigEntity entity = eventConfigList.get(i);
//                int repeatType = entity.getRepeatType() == 1 ? 2 : entity.getRepeatType();
//                int startTimestamp = entity.getStartDateTime();
//                int endTimestamp = entity.getEndDate();
//                long lessonStartTime = startTimestamp * 1000L;
//                long lessonEndTime = endTimestamp * 1000L;
//                String lessonStartYMD = TimeUtils.getTimestampFormatYMD(lessonStartTime);
//                String lessonEndYMD = TimeUtils.getTimestampFormatYMD(lessonEndTime);
//                V8Array configWeekDay = new V8Array(v8);
//                List<Integer> configWeekDayFromEntity = entity.getRepeatTypeWeekDay();
//                if (configWeekDayFromEntity.size() > 0) {
//                    for (int w = 0; w < configWeekDayFromEntity.size(); w++) {
//                        configWeekDay.push(configWeekDayFromEntity.get(w));
//                    }
//                }
//                // 组装计算数据
//                V8Object configFromJava = new V8Object(v8)
//                        .add("startYYMMDD", startYMD)
//                        .add("endYYMMDD", endYMD)
//                        .add("lessonStartYYMMDD", lessonStartYMD)
//                        .add("lessonEndYYMMDD", lessonEndYMD)
//                        .add("configWeekDay", configWeekDay)
//                        .add("endType", entity.getEndType())
//                        .add("endCount", entity.getEndCount())
//                        .add("repeatType", repeatType)
//                        .add("monthRepeat", entity.getRepeatTypeMonthDayType())
//                        .add("nthWeekIndex", entity.getRepeatTypeMonthDay())
//                        .add("nthDay", entity.getRepeatTypeMonthDay())
//                        .add("lastDay", 1)
//                        .add("weekRepeat", repeatType)
//                        .add("lessonStartTimestamp", lessonStartTime)
//                        .add("currentBasedTime", System.currentTimeMillis());
//
//                V8Array param = new V8Array(v8).push(configFromJava);
//                String dateStr = v8.executeStringFunction("calcDate", param);
//                Logger.e("-*-*-*-*-*-*-*-event dateStr: " + dateStr);
//                String[] dateArr = dateStr.split(",");
//                Logger.e("-*-*-*-*-*-*-*-event dateArr: " + Arrays.toString(dateArr));
//                int dateArrLength = dateArr.length;
//
//                // 组装计算结果
//                if (dateArrLength > 1) {
//                    Logger.e("组装event");
//
//                    for (int j = 0; j < dateArrLength; j++) {
//                        EventEntity eEntity = new EventEntity();
//                        String hour = TimeUtils.getFormatHour(entity.getStartDateTime() * 1000L);
//                        String minute = TimeUtils.getFormatMinute(entity.getStartDateTime());
//                        int shouldDateTime = (int) (TimeUtils.getTimestampBasedOnFormat(dateArr[j] + " " + hour + ":" + minute) / 1000L);
//                        eEntity.setEventConfigId(entity.getId());
//                        eEntity.setTeacherId(entity.getTeacherId());
//                        eEntity.setStartDateTime(shouldDateTime);
//                        eEntity.setTimeLength((entity.getEndDateTime() - entity.getStartDateTime()) / 60);
//                        eEntity.setTitle(entity.getTitle());
//                        eventList.add(0, eEntity);
//                    }
//                }
//            }
//
//            Logger.e("-*-*-*-*-*-*-*- event 计算结果组装完成: " + eventList.size());
//            scope.release();
//        }
//    }
//
//    /**
//     * 获取教师的 lessonType 列表
//     */
//    private void getTeacherLessonTypeList(boolean isOnlyCache) {
//        addSubscribe(
//                UserService
//                        .getStudioInstance()
//                        .getLessonTypeList(isOnlyCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(lessonTypes -> {
//                            if (lessonTypes != null && lessonTypes.size() > 0) {
//                                lessonTypeList = lessonTypes;
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonType 列表, size: " + lessonTypeList.size());
//                                getTeacherLessonScheduleConfigList(true);
//                            }
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 获取教师的 eventConfig 列表
//     */
//    public void getTeacherEventConfigList(boolean isOnlyCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherEventConfigList(isOnlyCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(eventConfigs -> {
//                            Logger.e("======= 获取 event config, size: " + eventConfigs.size());
//                            if (eventConfigs.size() > 0) {
//                                eventConfigList = eventConfigs;
//                                calculateEventList();
//                            }
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 获取教师的 block 列表
//     */
//    private void getTeacherBlockList(boolean isOnlyCache, int startDateTime, int endDateTime) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherBlockList(isOnlyCache, startDateTime, endDateTime)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(blocks -> {
//                            Logger.e("======== 获取 block, size: " + blocks.size());
//                            if (blocks.size() > 0) {
//                                blockList = blocks;
//                            }
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 获取教师的 lessonSchedule 列表
//     */
//    private void getTeacherLessonScheduleList(boolean isOnlyCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonScheduleList(isOnlyCache, start, end)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(lessonSchedules -> {
//                            Logger.e("-*-*-*-*-*-*-*- lessonSchedule start: " + start);
//                            lessonScheduleListCache = lessonSchedules;
//                            if (isOnlyCache) {
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (cache): " + lessonSchedules.size());
//                            } else {
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (online): " + lessonSchedules.size());
//                                lessonScheduleList = lessonSchedules;
//                            }
//                            // 比对 config
//                            compareScheduleCacheConfig(isOnlyCache);
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * schedule(cache / online) config 和 缓存config 比对
//     *
//     * @param isOnlyCache
//     */
//    private void compareScheduleCacheConfig(boolean isOnlyCache) {
//        Logger.e("-*-*-*-*-*-*-*- 缓存config 和 schedule(cache) config 比对, schedule before size: " + lessonScheduleListCache.size());
//        List<LessonScheduleEntity> cache = new ArrayList<>();
//        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
//            for (int j = 0; j < lessonScheduleConfigList.size(); j++) {
//                if (lessonScheduleListCache.get(i).getLessonScheduleConfigId().equals(lessonScheduleConfigList.get(j).getId())) {
//                    cache.add(lessonScheduleListCache.get(i));
//                    break;
//                }
//            }
//        }
//        lessonScheduleListCache = cache;
//        Logger.e("-*-*-*-*-*-*-*- 缓存config 和 schedule(cache) config 比对, schedule after size: " + lessonScheduleListCache.size());
//
//        // 比对 calculation 和 cache
//        compareScheduleCalculationAndCache(isOnlyCache);
//    }
//
//    /**
//     * 比对 calculation 和 cache
//     *
//     * @param isOnlyCache
//     */
//    private void compareScheduleCalculationAndCache(boolean isOnlyCache) {
//        Logger.e("-*-*-*-*-*-*-*- 比对 计算结果 和 缓存数据");
//        Logger.e("-*-*-*-*-*-*-*- 缓存数据数: " + lessonScheduleListCache.size());
//        Logger.e("-*-*-*-*-*-*-*- 计算结果数: " + lessonScheduleListCalculation.size());
//        lessonScheduleListDisplay.clear();
//        agendaListOnWebview.clear();
//
//        List<LessonScheduleEntity> cache = new ArrayList<>();
//
//        // 计算结果没有，缓存有，删除缓存
//        for (int j = 0; j < lessonScheduleListCache.size(); j++) {
//            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(j);
//            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
//                LessonScheduleEntity calculationEntity = lessonScheduleListCalculation.get(i);
//                if (cacheEntity.getId().equals(calculationEntity.getId())) {
//                    cache.add(cacheEntity);
//                    break;
//                }
//            }
//        }
//        lessonScheduleListCache = cache;
//        Logger.e("-*-*-*-*-*-*-*- 比对 config 后 cache 数据数: " + lessonScheduleListCache.size());
//
//        // 缓存判断是否 cancel, reschedule, 否则加入 agenda 中
//        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
//            if (!lessonScheduleListCache.get(i).isCancelled() && (!lessonScheduleListCache.get(i).isRescheduled() && lessonScheduleListCache.get(i).getRescheduleId().equals(""))) {
//                lessonScheduleListDisplay.add(lessonScheduleListCache.get(i));
//            }
//        }
//        Logger.e("-*-*-*-*-*-*-*- display 数据数 before: " + lessonScheduleListDisplay.size());
//
//        // 比对 calculation 和 cache，并将 calculation 去重后加入 agenda 中
//        for (int j = 0; j < lessonScheduleListCache.size(); j++) {
//            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(j);
//            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
//                LessonScheduleEntity calculationEntity = lessonScheduleListCalculation.get(i);
//                if (cacheEntity.getId().equals(calculationEntity.getId())) {
////                    Logger.e("-=-=--=- 计算结果重复 -=-=-=-=-=" + calculationEntity.getId());
//                    lessonScheduleListCalculation.remove(i);
//                    i--;
//                }
//            }
//        }
//        Logger.e("-*-*-*-*-*-*-*- 去重后 calculation 数据数: " + lessonScheduleListCalculation.size());
//
//        // 去重后 calculation 加入到 agenda 中
//        if (lessonScheduleListCalculation.size() > 0) {
//            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
//                lessonScheduleListDisplay.add(lessonScheduleListCalculation.get(i));
//            }
//        }
//        Logger.e("-*-*-*-*-*-*-*- display 数据数 after: " + lessonScheduleListDisplay.size());
//
//        for (int i = 0; i < lessonScheduleListDisplay.size(); i++) {
//            formatWebviewAgenda(lessonScheduleListDisplay.get(i));
//        }
//
//        for (int i = 0; i < eventList.size(); i++) {
//            formatWebviewAgenda(eventList.get(i));
//        }
//
//        for (int i = 0; i < blockList.size(); i++) {
//            formatWebviewAgenda(blockList.get(i));
//        }
//
//        if (isOnlyCache) {
//            Logger.e("-=-=-=-=-=-=- 缓存 + 计算");
//            // 将数据传入 webview 显示
//            if (agendaListOnWebview.size() > 0) {
//                Logger.e("-*-*-*-*-*-*-*- 显示 缓存 + 计算");
//                hasLesson = true;
//                initView();
////                lessonsFragment.updateDataToWebview(agendaListOnWebview, promptData);
////                lessonsFragment.initLessonFilter();
//            }
//            // 获取 online config
//            getTeacherLessonScheduleConfigList(false);
//        } else {
//            Logger.e("-=-=-=-=-=-=- 云上 + 计算");
//
//            addCalculationToOnline();
//        }
//    }
//
//    /**
//     * 计算添加到云上
//     */
//    private void addCalculationToOnline() {
//        Logger.e("=-=-=-=-=-=-=-=-=-=- calculation add to online: " + lessonScheduleListCalculation.size());
//        Logger.e("-*-*-*-*-*-*-*- 显示 云上 + 计算");
//        if (lessonScheduleListCalculation.size() > 0) {
//            for (int i = 0;i < lessonScheduleListCalculation.size();i++) {
//                addNewLessonScheduleFromCalculation(lessonScheduleListCalculation.get(i));
//            }
//        }
//        if (agendaListOnWebview.size() > 0) {
//            Logger.e("-=-=-=-=-=-=-=-= 最终刷新: " + agendaListOnWebview.size() + "--" + TimeUtils.getTimestampFormat(agendaListOnWebview.get(agendaListOnWebview.size() - 1).getShouldDateTime()));
//            hasLesson = true;
//            initView();
////            lessonsFragment.updateDataToWebview(agendaListOnWebview, promptData);
////                lessonsFragment.initLessonFilter();
//        }
//    }
//
//    /**
//     * 将缓存中未上传的 lessonSchedule 上传到云上
//     *
//     * @param lessonScheduleEntity
//     */
//    public void addNewLessonScheduleFromCalculation(LessonScheduleEntity lessonScheduleEntity) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .addNewLessonSchedule(lessonScheduleEntity)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(code -> {
////                            Logger.e("-*-*-*-*-*-*-*- 添加新的 schedule code: " + code);
//                            if (code == SLStaticString.DATA_ADDED) {
//                                Logger.e("-*-*-*-*-*-*-*- 添加新的 schedule 成功, id: " + lessonScheduleEntity.getId());
//                            }
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }


//    private void formatWebviewAgenda(EventEntity eventEntity) {
//        AgendaOnWebviewEntity agendaEntity = new AgendaOnWebviewEntity();
//        agendaEntity.setId(eventEntity.getEventConfigId());
//        agendaEntity.setAvatarUrl("");
//        agendaEntity.setOverDay(false);
//        agendaEntity.setName(eventEntity.getTitle());
//        agendaEntity.setShouldDateTime(eventEntity.getStartDateTime() * 1000L);
//        agendaEntity.setShouldTimeLength(eventEntity.getTimeLength());
//        agendaEntity.setType(2);
//        agendaListOnWebview.add(0, agendaEntity);
//    }
//
//    private void formatWebviewAgenda(BlockEntity blockEntity) {
//        AgendaOnWebviewEntity agendaEntity = new AgendaOnWebviewEntity();
//        agendaEntity.setId(blockEntity.getId());
//        agendaEntity.setAvatarUrl("");
//        agendaEntity.setOverDay(false);
//        agendaEntity.setName("OFF");
//        agendaEntity.setShouldDateTime(TimeUtils.getZeroTimeOfDay(blockEntity.getStartDateTime() * 1000L));
//        agendaEntity.setShouldTimeLength(24 * 60);
//        agendaEntity.setType(3);
//        agendaListOnWebview.add(0, agendaEntity);
//    }
//
//    /**
//     * 获取 reschedule lesson
//     *
//     * @param isOnlyCache
//     */
//    private void getTeacherLessonRescheduleList(boolean isOnlyCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonRescheduleList(isOnlyCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(rescheduleList -> {
//                            Logger.e("========= 获取 reschedule, size: " + rescheduleList.size());
//                            if (rescheduleList.size() > 0) {
//                                for (int i = 0; i < rescheduleList.size(); i++) {
//                                    if (rescheduleList.get(i).getConfirmType() == 0) {
//                                        lessonRescheduleList.add(rescheduleList.get(i));
//                                    }
//                                }
//                            }
//                            getTeacherLessonCancellationList(false);
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 获取 cancel lesson
//     *
//     * @param isOnlyCache
//     */
//    private void getTeacherLessonCancellationList(boolean isOnlyCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonCancellationList(isOnlyCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(cancellationList -> {
//                            Logger.e("======= 获取 cancellation: " + cancellationList.size());
//                            if (cancellationList.size() > 0) {
//                                lessonCancellationList = cancellationList;
//                            }
//                            formatWeviewPromptData();
//                        }, throwable -> {
//                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
//                        })
//        );
//    }
//
//    /**
//     * 格式化 webview reschedule prompt数据
//     */
//    private void formatWeviewPromptData() {
//        promptData = new JSONObject();
//        int rescheduleCount = 0, cancellationCount = 0;
//        for (int i = 0; i < lessonRescheduleList.size(); i++) {
//            if (lessonRescheduleList.get(i).getConfirmType() == 0) {
//                rescheduleCount++;
//            }
//        }
//
//        for (int i = 0; i < lessonCancellationList.size(); i++) {
//            if (!lessonRescheduleList.get(i).getTeacherRevisedReschedule()) {
//                cancellationCount++;
//            }
//        }
//
////        prompt: "Reschedule request",
////                count: 3
//
//        try {
//            promptData.put("prompt", rescheduleCount > 0 ? "Reschedule request" : (cancellationCount > 0 ? "Cancelation" : ""));
//            promptData.put("count", rescheduleCount + cancellationCount);
//        } catch (JSONException e) {}
//    }
}
