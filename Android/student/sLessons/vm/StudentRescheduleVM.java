package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.text.Spannable;
import android.text.SpannableString;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.utils.MemoryManager;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.StudentLessonService;
import com.spelist.tunekey.api.network.StudioService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.CenterAlignImageSpan;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.AvailableTimesEntity;
import com.spelist.tunekey.entity.BlockEntity;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.ShouldTimeEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKFollowUp;
import com.spelist.tunekey.entity.TKRescheduleMakeupRefundHistory;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.activity.SignPoliciesAc;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.StudioCalendarHomeEX;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTimeUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/26
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleVM extends ToolbarViewModel {
    public LessonScheduleEntity beforeData;
    public LessonRescheduleEntity afterData;
    public PolicyEntity policyData;
    public StudentListEntity studentData;
    public UserEntity teacherData;
    private Disposable scheduleDisposable;


    public ObservableField<String> beforeTime = new ObservableField<>("");
    public ObservableField<String> beforeMonth = new ObservableField<>("");
    public ObservableField<String> beforeDay = new ObservableField<>("");

    public ObservableField<Integer> afterColor = new ObservableField<>(ContextCompat.getColor(getApplication(), R.color.fourth));
    public ObservableField<String> afterTime = new ObservableField<>("Time");
    public ObservableField<String> afterMonth = new ObservableField<>("Date");
    public ObservableField<String> afterDay = new ObservableField<>("");
    public ObservableField<Boolean> isShowAfterDay = new ObservableField<>(false);

    public ObservableField<SpannableString> tip = new ObservableField<>();
    public ObservableField<Boolean> isShowCancelButton = new ObservableField<>(false);
    public ObservableField<String> calendarMonth = new ObservableField<>("");
    public ObservableField<String> buttonString = new ObservableField<>("");

    public Map<String, LessonScheduleEntity> lessonScheduleIdMap = new HashMap<>();
    public List<LessonScheduleEntity> lessonSchedule = new ArrayList<>();
    public List<LessonRescheduleEntity> doneReschedule = new ArrayList<>();
    public List<LessonRescheduleEntity> unDoneReschedule = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypes = new ArrayList<>();
    public List<LessonScheduleConfigEntity> scheduleConfigs = new ArrayList<>();
    public Map<String, LessonTypeEntity> lessonTypeMap = new HashMap<>();
    public Map<String, LessonScheduleConfigEntity> lessonConfigMap = new HashMap<>();
    public int startTimestamp = 0;
    public int endTimestamp = 0;
    public Calendar currentMonthDate;
    public Map<Integer, List<AvailableTimesEntity>> availableData = new HashMap<>();
    public String selectTime = "";
    public AvailableTimesEntity selectData;
    private boolean isEdit;
    public boolean isCredit = false;
    public String creditId = "";

    public StudentRescheduleVM(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Reschedule");
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_CANCEL_LESSON, this::finish);

    }

    public void initData() {
        studentData = ListenerService.shared.studentData.getStudentData();
        calendarMonth.set(TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "MMMM yyyy"));
        showDialog();
        initTime();
        initCalendarTip();
        initLessonData();
    }

    private void initLessonData() {
        startTimestamp = TimeUtils.getCurrentTime();
        currentMonthDate = SLTimeUtils.getCurrentMonthStart();

        endTimestamp = (int) (TimeUtils.addMonth(currentMonthDate.getTimeInMillis(), 4) / 1000L);
        getTeacherBlock();
        getTeacherUnConfirmReschedule();
        getLessonTypes(true);
        getLessonTypes(false);
    }

    private void getLessonTypes(boolean isCache) {
        if (studentData==null){
            return;
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .getLessonTypeByStudioId(studentData.getStudioId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            lessonTypes = data;
                            for (LessonTypeEntity datum : data) {
                                lessonTypeMap.put(datum.getId(), datum);
                            }
                            getScheduleConfig(isCache);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getLessonTypeByTeacherId(studentData.getTeacherId(), isCache)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            lessonTypes = data;
//                            for (LessonTypeEntity datum : data) {
//                                lessonTypeMap.put(datum.getId(), datum);
//                            }
//                            getScheduleConfig(isCache);
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
    }

    private void getScheduleConfig(boolean isCache) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getLessonConfigByTeacherId(beforeData.getTeacherId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            scheduleConfigs = data;
                            for (LessonScheduleConfigEntity scheduleConfig : scheduleConfigs) {
                                lessonConfigMap.put(scheduleConfig.getId(), scheduleConfig);
                            }
                            Logger.e("lessonConfigMap==>%s", data.size());
                            StudioCalendarHomeEX.refreshLessonSchedules(scheduleConfigs, startTimestamp, endTimestamp);
                            initScheduleData(isCache);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void initScheduleData(boolean isCache) {
//        getLessonData(isCache);
//        if (isCache) {
//            return;
//        }
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .studentRefreshLessonSchedule(scheduleConfigs, lessonTypes, startTimestamp, endTimestamp)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            getLessonData(true);
//
//                        }, throwable -> {
//                            Logger.e("刷新课程失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
        getLessDataV2(isCache);
    }

    private void getLessDataV2(boolean isCache) {
        if (scheduleDisposable != null) {
            scheduleDisposable.dispose();
        }
        List<String> configIds = new ArrayList<>();
        for (Map.Entry<String, LessonScheduleConfigEntity> entry : lessonConfigMap.entrySet()) {
            configIds.add(entry.getKey());
        }
        scheduleDisposable = AppDataBase.getInstance().lessonDao().getByStudentIdWithStartTimeAndEndTime(SLCacheUtil.getCurrentUserId(), startTimestamp, endTimestamp, configIds)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(data -> {
                    Logger.e("本地获取出来的课程==>%s", data.size());
                    for (LessonScheduleEntity d : data) {
                        if (lessonConfigMap.get(d.getLessonScheduleConfigId()) != null) {
                            d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                        }
                    }
                    data.removeIf(item -> {
                        boolean isRemove = false;
                        LessonScheduleConfigEntity config = lessonConfigMap.get(item.getLessonScheduleConfigId());
                        if (config == null) {
                            isRemove = true;
                        } else {
                            if (config.getEndType() == 1 && item.getShouldDateTime() > config.getEndDate()) {
                                isRemove = true;
                            }
                            String configHM = TimeUtils.timeFormat(config.startDateTime, "hh:mm");
                            String lessonHM = TimeUtils.timeFormat(item.getTKShouldDateTime(), "hh:mm");
                            if (!configHM.equals(lessonHM) && AppDataBase.getInstance().lessonDao().getByRescheduleId(item.getId()) == null) {
                                isRemove = true;
                            }
                        }
                        return isRemove;
                    });
                    data.sort((o1, o2) -> (int) (o2.getShouldDateTime() - o1.getShouldDateTime()));
                    for (LessonScheduleEntity item : data) {
                        if (lessonConfigMap.get(item.getLessonScheduleConfigId()) == null) {
                            continue;
                        }
                        item.setConfigEntity(lessonConfigMap.get(item.getLessonScheduleConfigId()));
                        item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
                        if (lessonScheduleIdMap.get(item.getId()) != null) {
                            if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                                lessonScheduleIdMap.remove(item.getId());
                            } else {
                                for (int i = 0; i < lessonSchedule.size(); i++) {
                                    if (lessonSchedule.get(i).getId().equals(item.getId())) {
                                        lessonSchedule.set(i, item);
                                        break;
                                    }
                                }
                                lessonScheduleIdMap.put(item.getId(), item);
                            }
                        } else {
                            if (!item.isCancelled() && !item.isRescheduled()) {
                                lessonSchedule.add(item);
                                lessonScheduleIdMap.put(item.getId(), item);
                            }
                        }
                    }


                    if (beforeData != null) {
                        lessonSchedule.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getId().equals(beforeData.getId()));
                    }

                    Logger.e("sdsdsdsdsd==>%s==>%s==>%s", lessonSchedule.size(), startTimestamp, endTimestamp);

                    initCalendarData();
                }, throwable -> {
                    Logger.e("失败,失败原因" + throwable.getMessage());
                });
        addSubscribe(scheduleDisposable);

        String jsFile = FuncUtils.getJsFuncStr(TApplication.mApplication, "rrule2");
        V8 v8 = V8.createV8Runtime();
        MemoryManager scope = new MemoryManager(v8);
        v8.executeVoidScript(jsFile);
        lessonConfigMap.forEach((key, value) -> {
            List<LessonScheduleEntity> data = StudioService.getInstance().getLessonTimeByRRuleAndStartTimeAndEndTime(value, startTimestamp, endTimestamp, v8);
            int nowTime = TimeUtils.getCurrentTime();
            Logger.e("data==>%s", data.size());

            data.sort((o1, o2) -> (int) (o2.getShouldDateTime() - o1.getShouldDateTime()));
            for (LessonScheduleEntity item : data) {
                if (lessonConfigMap.get(item.getLessonScheduleConfigId()) == null) {
                    continue;
                }
                item.setConfigEntity(lessonConfigMap.get(item.getLessonScheduleConfigId()));
                item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
                if (lessonScheduleIdMap.get(item.getId()) != null) {
                    if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                        lessonScheduleIdMap.remove(item.getId());
                    } else {
                        for (int i = 0; i < lessonSchedule.size(); i++) {
                            if (lessonSchedule.get(i).getId().equals(item.getId())) {
                                lessonSchedule.set(i, item);
                                break;
                            }
                        }
                        lessonScheduleIdMap.put(item.getId(), item);
                    }
                } else {
                    if (!item.isCancelled() && !item.isRescheduled()) {
                        lessonSchedule.add(item);
                        lessonScheduleIdMap.put(item.getId(), item);
                    }
                }
            }
            if (beforeData != null) {
                lessonSchedule.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getId().equals(beforeData.getId()));
            }


        });
        Logger.e("sdsdsdsdsd==>%s==>%s==>%s", lessonSchedule.size(), startTimestamp, endTimestamp);

        initCalendarData();
        scope.release();
        v8.release();

    }
//    private void getLessonData(boolean isCache) {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonScheduleList(isCache, teacherData.getUserId(), startTimestamp, endTimestamp)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            data.sort((o1, o2) -> (int) (o2.getShouldDateTime() - o1.getShouldDateTime()));
//
//                            for (LessonScheduleEntity item : data) {
//                                if (lessonConfigMap.get(item.getLessonScheduleConfigId()) == null) {
//                                    continue;
//                                }
//                                item.setConfigEntity(lessonConfigMap.get(item.getLessonScheduleConfigId()));
//                                item.setLessonType(lessonTypeMap.get(item.getLessonTypeId()));
//
//                                if (lessonScheduleIdMap.get(item.getId()) != null) {
//                                    if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
//                                        lessonScheduleIdMap.remove(item.getId());
//                                    } else {
//                                        for (int i = 0; i < lessonSchedule.size(); i++) {
//                                            if (lessonSchedule.get(i).getId().equals(item.getId())) {
//                                                lessonSchedule.set(i, item);
//                                                break;
//                                            }
//                                        }
//                                        lessonScheduleIdMap.put(item.getId(), item);
//
//                                    }
//
//                                } else {
//                                    if (!item.isCancelled() && !item.isRescheduled()) {
//                                        lessonSchedule.add(item);
//                                        lessonScheduleIdMap.put(item.getId(), item);
//                                    }
//
//
//                                }
//                            }
//                            if (beforeData != null) {
//                                lessonSchedule.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getId().equals(beforeData.getId()));
//                            }
//                            initCalendarData();
//
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//
//                        })
//
//        );
//    }

    private void getTeacherUnConfirmReschedule() {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getTeacherLessonRescheduleList(beforeData.getTeacherId())
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            Logger.e("======getTeacherUnConfirmReschedule%s", data.size());
//                            unDoneReschedule.clear();
//                            doneReschedule.clear();
//                            for (LessonRescheduleEntity item : data) {
//                                if ((item.getConfirmType() == 0) && (Integer.parseInt(item.getTimeBefore()) > TimeUtils.getCurrentTime())) {
//                                    unDoneReschedule.add(item);
//                                }
//                                if (item.getConfirmType() == 1) {
//                                    doneReschedule.add(item);
//                                }
//                            }
//                            initCalendarData();
//
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//                        })
//        );
        unDoneReschedule.clear();
        doneReschedule.clear();
        List<TKFollowUp> followUps = ListenerService.shared.studentData.getFollowUps();
        if (followUps != null && followUps.size() > 0) {
            for (TKFollowUp followUp : followUps) {
                if (followUp.getColumn().equals(TKFollowUp.Column.rescheduled)) {
                    LessonRescheduleEntity r = CloneObjectUtils.cloneObject(followUp.getRescheduleData());
                    doneReschedule.add(r);
                } else if (followUp.getColumn().equals(TKFollowUp.Column.unconfirmed) && followUp.getDataType().equals(TKFollowUp.DataType.reschedule)) {
                    LessonRescheduleEntity r = CloneObjectUtils.cloneObject(followUp.getRescheduleData());
                    unDoneReschedule.add(r);
                }
            }
        }
        initCalendarData();
    }

    private void initCalendarData() {
        Logger.e("未完成的reschedule个数: %s, lessonSchedule的个数: %s", unDoneReschedule.size(), lessonSchedule.size());
        if (unDoneReschedule.size() > 0) {
            List<String> ids = new ArrayList<>();
            for (LessonRescheduleEntity rescheduleEntity : unDoneReschedule) {
                ids.add(rescheduleEntity.getScheduleId());
            }
            addSubscribe(
                    LessonService
                            .getInstance()
                            .getLessonScheduleByIds(ids)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                Logger.e("根据未出完成的reschedule获取出来的Schedule个数: %s", data.size());
                                if (data.size() > 0) {

                                    Map<String, LessonScheduleEntity> map = new HashMap<>();
                                    for (LessonScheduleEntity item : data) {
                                        map.put(item.getId(), item);
                                    }
                                    Map<String, Integer> timeMap = new HashMap<>();
                                    for (LessonRescheduleEntity item : unDoneReschedule) {
                                        if (map.get(item.getScheduleId()) != null && lessonConfigMap.get(map.get(item.getScheduleId()).getLessonScheduleConfigId()) != null) {
                                            int diff = TimeUtils.getStartTimeDiffWithLocalTime(
                                                    lessonConfigMap.get(map.get(item.getScheduleId()).getLessonScheduleConfigId()).getStartDateTime()
                                                    , Integer.parseInt(item.getTimeAfter()));
                                            timeMap.put(item.getId(), diff);
                                        }
                                    }
                                    for (LessonRescheduleEntity item : unDoneReschedule) {
                                        if (!item.getTimeAfter().equals("")) {
                                            LessonScheduleEntity scheduleEntity = new LessonScheduleEntity();
                                            scheduleEntity.setTeacherId(item.getTeacherId());
                                            scheduleEntity.setStudentId(item.getStudentId());
                                            int diff = 0;
                                            if (timeMap.get(item.getId()) != null) {
                                                diff = timeMap.get(item.getId()) * 3600;
                                            }
                                            scheduleEntity.setShouldDateTime(Long.parseLong(item.getTimeAfter()) + diff);
                                            scheduleEntity.setShouldTimeLength(item.getShouldTimeLength());
                                            scheduleEntity.setType(2);
                                            if (afterData == null || !item.getId().equals(afterData.getId())) {
                                                lessonSchedule.add(scheduleEntity);
                                            }
                                        }
                                    }
                                }
                                if (beforeData != null) {
                                    lessonSchedule.removeIf(lessonScheduleEntity -> lessonScheduleEntity.getId().equals(beforeData.getId()));
                                }
                                getAvailableTimeData(false);

                            }, throwable -> {
                                dismissDialog();
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })

            );
        } else {
            getAvailableTimeData(false);
        }

    }

    private void getAvailableTimeData(boolean isBlock) {
        if (lessonSchedule.size() <= 0) {
            return;
        }
        List<ShouldTimeEntity> shouldTime = new ArrayList<>();
        lessonSchedule.sort((o1, o2) -> (int) (o1.getShouldDateTime() - o2.getShouldDateTime()));
        List<Integer> dayOffTimes = new ArrayList<>();
        Map<Integer, List<ShouldTimeEntity>> shouldMap = new HashMap<>();
        for (int i = 0; i < lessonSchedule.size(); i++) {
            LessonScheduleEntity item = lessonSchedule.get(i);
            ShouldTimeEntity data = new ShouldTimeEntity();
            data.setShouldDateTime((int) item.getTKShouldDateTime());
            data.setTimeLength(item.getShouldTimeLength());
            data.setIndex(i);
            shouldTime.add(data);
            int startTime = (int) (TimeUtils.getStartDay((int) item.getShouldDateTime()).getTimeInMillis() / 1000L);
            if (shouldMap.get(startTime) != null) {
                shouldMap.get(startTime).add(data);
            } else {
                List<ShouldTimeEntity> datas = new ArrayList<>();
                datas.add(data);
                shouldMap.put(startTime, datas);
            }
            if (data.getTimeLength() == 1439) {
                dayOffTimes.add(startTime);
            }
        }
        if (dayOffTimes.size() > 0) {
            //去重
            dayOffTimes = dayOffTimes.stream().distinct().collect(Collectors.toList());
            List<Integer> needDeleteIndex = new ArrayList<>();
            for (Integer item : dayOffTimes) {
                if (shouldMap.get(item) != null) {
                    for (ShouldTimeEntity shouldTimeEntity : shouldMap.get(item)) {
                        if (shouldTimeEntity.getTimeLength() != 1439) {
                            needDeleteIndex.add(shouldTimeEntity.getIndex());
                        }
                    }
                }

            }
            for (Integer deleteIndex : needDeleteIndex) {
                shouldTime.removeIf(shouldTimeEntity -> shouldTimeEntity.getIndex() == deleteIndex);
            }

        }
        int sTime = (int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L);
        int eTime = (int) (TimeUtils.getEndDay(endTimestamp).getTimeInMillis() / 1000L);
        if (policyData.getLimitDays() != 0 && policyData.getLimitDays() != -1) {
            long l = TimeUtils.addDay(TimeUtils.getCurrentTime() * 1000L, policyData.getLimitDays()) / 1000L;
            int policyTime = (int) (TimeUtils.getEndDay((int) l).getTimeInMillis() / 1000L);
            if (eTime > policyTime) {
                eTime = policyTime;
            }
        }
//        Logger.e("eTime==>%s==>%s===>%s=%s=",sTime,eTime,beforeData.getShouldTimeLength(),shouldTime);
        availableData.clear();
        addSubscribe(
                StudentLessonService
                        .getInstance()
                        .getTeacherAvailableTime(sTime, eTime, beforeData.getShouldTimeLength(), shouldTime, policyData)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("data==>%s", data.size());

                            int nowTime = TimeUtils.getCurrentTime();
                            if (policyData.getRescheduleNoticeRequired() != 0) {
                                if (afterData != null && !afterData.getSenderId().equals(afterData.getStudentId())) {

                                } else {
                                    nowTime = nowTime + policyData.getRescheduleNoticeRequired() * 60 * 60;
                                }
                            }

                            for (LessonRescheduleEntity item : doneReschedule) {
                                if (Integer.parseInt(item.getTimeBefore()) > nowTime) {
                                    int timestamp = Integer.parseInt(item.getTimeBefore());
                                    if (timestamp < beforeData.getShouldDateTime() || timestamp > (beforeData.getShouldDateTime() + beforeData.getShouldTimeLength() * 60)) {

                                        int startOfDay = (int) (TimeUtils.getStartDay(timestamp).getTimeInMillis() / 1000L);
                                        AvailableTimesEntity d = new AvailableTimesEntity();
                                        d.setTimestamp(timestamp);
                                        d.setTop(true);
                                        d.setEndTimestamp(timestamp + beforeData.getShouldTimeLength());
                                        if (availableData.get(startOfDay) == null) {
                                            availableData.put(startOfDay, new ArrayList<>());
                                            availableData.get(startOfDay).add(d);
                                        } else {
                                            boolean isHave = false;
                                            for (AvailableTimesEntity timesEntity : availableData.get(startOfDay)) {
                                                if (timesEntity.getTimestamp() == timestamp) {
                                                    isHave = true;
                                                }
                                            }
                                            if (!isHave) {
                                                availableData.get(startOfDay).add(d);
                                            }
                                        }

                                    }
                                }
                            }
                            for (AvailableTimesEntity item : data) {
                                if (item.getTimestamp() > nowTime) {
                                    int startOfDay = (int) (TimeUtils.getStartDay(item.getTimestamp()).getTimeInMillis() / 1000L);
                                    if (availableData.get(startOfDay) == null) {
                                        availableData.put(startOfDay, new ArrayList<>());
                                        availableData.get(startOfDay).add(item);
                                    } else {
                                        boolean isHave = false;
                                        for (AvailableTimesEntity timesEntity : availableData.get(startOfDay)) {
                                            if (timesEntity.getTimestamp() == item.getTimestamp()) {
                                                isHave = true;
                                            }
                                        }
                                        if (!isHave) {
                                            availableData.get(startOfDay).add(item);
                                        }
                                    }

                                }
                            }
                            List<Integer> removeTimes = new ArrayList<>();
                            if (policyData.getLessonHours().size() > 0) {
                                for (Map.Entry<Integer, List<ShouldTimeEntity>> entry : shouldMap.entrySet()) {
                                    int weekDay = TimeUtils.getDayOfWeek(entry.getKey() * 1000L) - 1;
                                    int totalHours = 0;
                                    for (ShouldTimeEntity timeItem : entry.getValue()) {
                                        totalHours += timeItem.getTimeLength();
                                    }
                                    totalHours += beforeData.getShouldTimeLength();
                                    totalHours = totalHours / 60;
                                    if (totalHours > policyData.getLessonHours().get(weekDay)) {
                                        removeTimes.add((int) (TimeUtils.getStartDay(entry.getKey()).getTimeInMillis() / 1000L));
                                    }
                                }
                            }

                            for (Map.Entry<Integer, List<AvailableTimesEntity>> entry : availableData.entrySet()) {
                                boolean isHave = false;
                                for (Integer removeTime : removeTimes) {
                                    int key = entry.getKey();
                                    int removeTime1 = removeTime;
                                    if (removeTime1 == key) {
                                        isHave = true;
                                    }
                                }

                                if (isHave) {
                                    availableData.put(entry.getKey(), null);
                                } else {

                                    if (policyData.getLessonHours().size() > 0) {
                                        int weekDay = TimeUtils.getDayOfWeek(entry.getKey() * 1000L) - 1;
                                        long time = beforeData.getShouldTimeLength() / 60;
                                        if (time > policyData.getLessonHours().get(weekDay)) {
                                            availableData.put(entry.getKey(), null);
                                        }
                                    }
                                }
                            }


                            availableData = filterAvailableData(availableData, policyData.getRescheduleStartTime());


                            List<String> calendarList = new ArrayList<>();
                            for (Map.Entry<Integer, List<AvailableTimesEntity>> entry : availableData.entrySet()) {
                                if (entry.getValue() != null) {
                                    calendarList.add(TimeUtils.timeFormat(entry.getKey(), "yyyy-M-d"));
                                }
                            }
                            if (!isBlock) {
                                dismissDialog();
                            }

                            uc.refreshCalendar.setValue(calendarList);


                        }, throwable -> {
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public static Map<Integer, List<AvailableTimesEntity>> filterAvailableData(
            Map<Integer, List<AvailableTimesEntity>> availableData, String type) {
        return availableData.entrySet().stream()
                .map(entry -> new HashMap.SimpleEntry<>(
                        entry.getKey(),
                        filterListByType(entry.getValue(), type)))
                .filter(entry -> !entry.getValue().isEmpty()) // Remove entries with empty lists
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    private static List<AvailableTimesEntity> filterListByType(List<AvailableTimesEntity> list, String type) {
        switch (type) {
            case PolicyEntity.RescheduleStartTime.hour:
                return list.stream().filter(AvailableTimesEntity::isOnTheHour).collect(Collectors.toList());
            case PolicyEntity.RescheduleStartTime.halfHour:
                return list.stream().filter(AvailableTimesEntity::isOnTheHalfHour).collect(Collectors.toList());
            case PolicyEntity.RescheduleStartTime.quarterHour:
                return list; // No filtering needed
            default:
                return list;
        }
    }

    public void initAvailableTime(String time, boolean isClickOtherTime) {
        selectTime = time;

        itemDataList.clear();
        int l = (int) (TimeUtils.timeToStamp(time, "yyyy-MM-dd HH:mm:ss") / 1000L);
        List<AvailableTimesEntity> preferred = new ArrayList<>();
        List<AvailableTimesEntity> morning = new ArrayList<>();
        List<AvailableTimesEntity> afternoon = new ArrayList<>();
        List<AvailableTimesEntity> night = new ArrayList<>();
        if (availableData.get(l) == null) {
            return;
        }
        for (AvailableTimesEntity timesEntity : availableData.get(l)) {
            if (timesEntity.isTop()) {
                preferred.add(timesEntity);
            } else {
                int hour = Integer.parseInt(TimeUtils.timeFormat(timesEntity.getTimestamp(), "HH"));
                if (hour >= 6 && hour < 12) {
                    morning.add(timesEntity);
                } else if (hour >= 12 && hour < 18) {
                    afternoon.add(timesEntity);
                } else {
                    night.add(timesEntity);
                }
            }
        }
        List<AvailableTimesEntity> dataList = new ArrayList<>();
        if (preferred.size() > 0) {
            AvailableTimesEntity e = new AvailableTimesEntity();
            //Convenient time
            e.setType(2);
            dataList.add(e);
            dataList.addAll(preferred);
            AvailableTimesEntity e1 = new AvailableTimesEntity();

            //Other time
            if (isClickOtherTime) {
                e1.setType(5);
            } else {
                e1.setType(3);
            }

            dataList.add(e1);
        } else {
            AvailableTimesEntity e = new AvailableTimesEntity();
            //4AvailableTime
            e.setType(4);
            dataList.add(e);
        }
        if (isClickOtherTime || preferred.size() == 0) {
            if (morning.size() > 0) {
                dataList.addAll(morning);
                AvailableTimesEntity e = new AvailableTimesEntity();
                //4AvailableTime
                e.setType(1);
                dataList.add(e);
            }
            if (afternoon.size() > 0) {
                dataList.addAll(afternoon);
                AvailableTimesEntity e = new AvailableTimesEntity();
                //4AvailableTime
                e.setType(1);
                dataList.add(e);
            }
            if (night.size() > 0) {
                dataList.addAll(night);
            }
        }


        for (AvailableTimesEntity timesEntity : dataList) {
            if (timesEntity.getType() == 0) {
                StudentRescheduleAvailableItemVM itemVM = new StudentRescheduleAvailableItemVM(this, timesEntity);
                itemDataList.add(itemVM);
                if (selectData != null) {
                    if (itemVM.getData().getTimestamp() == selectData.getTimestamp()) {
                        itemVM.isSelectData = true;
                        itemVM.changeIsSelectData(true);
                    }
                }
            } else {
                StudentRescheduleAvailableTipItemVM itemVM = new StudentRescheduleAvailableTipItemVM(this, timesEntity);
                itemDataList.add(itemVM);
            }
        }
        uc.refreshAvailableTime.setValue(itemDataList);
    }


    private void getTeacherBlock() {
        if (studentData==null){
            return;
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .getBlockListByTeacherId(studentData.getTeacherId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            for (BlockEntity item : data) {
                                if (lessonScheduleIdMap.get(item.getId()) == null) {
                                    LessonScheduleEntity lessonScheduleEntity = new LessonScheduleEntity();
                                    lessonScheduleEntity.setId(item.getId());
                                    lessonScheduleEntity.setTeacherId(lessonScheduleEntity.getTeacherId());
                                    lessonScheduleEntity.setShouldDateTime(item.getStartDateTime());
                                    lessonScheduleEntity.setShouldTimeLength((item.getEndDateTime() - item.getStartDateTime()) / 60);
                                    lessonScheduleEntity.setType(3);
                                    lessonScheduleIdMap.put(item.getId(), lessonScheduleEntity);
                                    lessonSchedule.add(lessonScheduleEntity);
                                }
                            }
                            getAvailableTimeData(true);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void initCalendarTip() {
        StringBuilder info = new StringBuilder();
        if (afterData != null && afterData.getSenderId().equals(afterData.getTeacherId())) {
            if (policyData != null && policyData.getRescheduleNoticeRequired() != 0) {
                info.append("Reschedule up until ").append(policyData.getRescheduleNoticeRequired()).append("  hours before class. You can also cancel a lesson. See policies ");
            } else {
                info.append("Reschedule your lesson up until before class. You can also cancel this class. See policies ");
            }
            isShowCancelButton.set(true);

        } else {

            if (policyData != null && policyData.getRescheduleNoticeRequired() != 0) {
                info.append("Reschedule up until ").append(policyData.getRescheduleNoticeRequired()).append(" hours before class. See policies ");
            } else {
                info.append("Reschedule your lesson up until before class. See policies ");
            }
        }
        if (afterData == null || afterData.getSenderId().equals(afterData.getTeacherId())) {
            buttonString.set("SEND REQUEST");
        } else {
            buttonString.set("UPDATE");
        }

//        info.append("Reschedule up until");

        SpannableString spannable = new SpannableString(info + "[info]");//用于可变字符串
        Drawable drawable = ContextCompat.getDrawable(getApplication(), R.mipmap.icinfo3x);
        drawable.setBounds(0, 0, drawable.getMinimumWidth() - 19, drawable.getMinimumHeight() - 19);
        CenterAlignImageSpan span = new CenterAlignImageSpan(drawable, CenterAlignImageSpan.CENTRE);

        spannable.setSpan(span, info.length(), info.length() + "[info]".length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);

        tip.set(spannable);
    }

    private void initTime() {
        if (afterData != null && !afterData.getTKAfter().equals("") && !afterData.getTKAfter().equals("0")) {
            isShowAfterDay.set(true);
            afterDay.set(TimeUtils.timeFormat(Long.parseLong(afterData.getTKAfter()), "d"));
            afterMonth.set(TimeUtils.timeFormat(Long.parseLong(afterData.getTKAfter()), "MMM"));
            afterTime.set(TimeUtils.timeFormat(Long.parseLong(afterData.getTKAfter()), "hh:mm a"));
            afterColor.set(ContextCompat.getColor(getApplication(), R.color.main));
        }
        isEdit = (afterData != null);
        beforeDay.set(TimeUtils.timeFormat(beforeData.getTKShouldDateTime(), "d"));
        beforeMonth.set(TimeUtils.timeFormat(beforeData.getTKShouldDateTime(), "MMM"));
        beforeTime.set(TimeUtils.timeFormat(beforeData.getTKShouldDateTime(), "hh:mm a"));
    }

    //日历翻页
    public void changeMonth(long time) {
        time = time * 1000L;
        if (time - currentMonthDate.getTimeInMillis() > 0) {
            //往未来翻页
            if (SLTimeUtils.getDifferMonth(time, endTimestamp * 1000L) < 3) {
                endTimestamp = (int) (SLTimeUtils.calendarAddMonth(endTimestamp * 1000L, 3).getTimeInMillis() / 1000L);
//                initScheduleData(true);
                initScheduleData(false);
            } else {
                Logger.e("======%s", "当前日期与结束日期之间大于2个月,不获取");
            }

        }
        currentMonthDate.setTimeInMillis(SLTimeUtils.getMonthStart(time).getTimeInMillis());

    }

    //日历选择
    public void changeSelect(String time) {

        initAvailableTime(time, false);
    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> clickCancel = new SingleLiveEvent<>();
        public SingleLiveEvent<List<String>> refreshCalendar = new SingleLiveEvent<>();
        public SingleLiveEvent<List<StudentRescheduleAvailableMultiItemVM>> refreshAvailableTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAvailableTip = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAvailableTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Map<String, String>> showErrorDialog = new SingleLiveEvent<>();

    }

    public ObservableList<StudentRescheduleAvailableMultiItemVM> itemDataList = new ObservableArrayList<>();

    public ItemBinding<StudentRescheduleAvailableMultiItemVM> itemBinding =
            ItemBinding.of((itemBinding, position, item) -> {
                //通过item的类型, 动态设置Item加载的布局
                int itemType = item.getData().getType();
                if (itemType == 0) {
                    itemBinding.set(BR.itemViewModel, R.layout.item_student_reschedule_available);
                } else {
                    itemBinding.set(BR.itemViewTipModel, R.layout.item_student_reschedule_available_tip);
                }
            });


    /**
     * 点击可用时间
     *
     * @param data
     */
    public void clickAvailableItem(AvailableTimesEntity data) {
        selectData = data;
        uc.clickAvailableTime.call();
        for (StudentRescheduleAvailableMultiItemVM item : itemDataList) {
            if (item instanceof StudentRescheduleAvailableItemVM) {
                StudentRescheduleAvailableItemVM itemVM = (StudentRescheduleAvailableItemVM) item;
                if (itemVM.isSelectData) {
                    itemVM.isSelectData = false;
                    itemVM.changeIsSelectData(false);
                }
            }
            if (!data.isTop()) {
                if (item.getData().getType() == 4 || item.getData().getType() == 5) {
                    if (item instanceof StudentRescheduleAvailableTipItemVM) {
                        StudentRescheduleAvailableTipItemVM itemVM = (StudentRescheduleAvailableTipItemVM) item;
                        item.getData().setType(6);
                        itemVM.showTip();
                    }
                }
            }
        }

        isShowAfterDay.set(true);
        afterDay.set(TimeUtils.timeFormat(data.getTimestamp(), "d"));
        afterMonth.set(TimeUtils.timeFormat(data.getTimestamp(), "MMM"));
        afterTime.set(TimeUtils.timeFormat(data.getTimestamp(), "hh:mm a"));
        afterColor.set(ContextCompat.getColor(getApplication(), R.color.main));


    }

    public BindingCommand clickCancel = new BindingCommand(() -> {
        uc.clickCancel.call();

    });

    public BindingCommand clickSeePolicies = new BindingCommand(() -> {
        Bundle bundle = new Bundle();
        bundle.putSerializable("policiesData", policyData);
        bundle.putSerializable("studentData", studentData);
        startActivity(SignPoliciesAc.class, bundle);
    });
    public TKButton.ClickListener clickBottomButton = new TKButton.ClickListener() {
        @Override
        public void onClick(TKButton tkButton) {
            if (isCredit) {
                creditReschedule();
            } else {
                if (isEdit) {
                    editRescheduleV2();
                } else {
                    rescheduleV2();
                }
            }

        }


    };

    private void creditReschedule() {
        showDialog();
        int diff = 0;
        if (beforeData.getLessonScheduleData() != null) {
            diff = TimeUtils.getRescheduleDiff(beforeData.getLessonScheduleData().getStartDateTime(), selectData.getTimestamp());
        } else {
            List<LessonScheduleConfigEntity> collect = new ArrayList<>();
            if (ListenerService.shared.user.getRoleIds().contains("1")) {
                collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            } else {
                collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            }
            if (collect.size() > 0) {
                diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectData.getTimestamp());
            }
        }
        Map<String, Object> map = new HashMap<>();
        map.put("creditId", creditId);
        map.put("time", (selectData.getTimestamp() + (diff * 3600L)));
        Logger.e("map==>%s", SLJsonUtils.toJsonString(map));
        addSubscribe(
                TKApi.INSTANCE.requestNewLessonFromCredit(map)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            Logger.e("====reschedule成功==");
//                            SLToast.success("Rescheduled successfully!");
                            finish();
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public void editRescheduleV2() {
        showDialog();
        int diff = 0;
        if (beforeData.getLessonScheduleData() != null) {
            diff = TimeUtils.getRescheduleDiff(beforeData.getLessonScheduleData().getStartDateTime(), selectData.getTimestamp());
        } else {
            List<LessonScheduleConfigEntity> collect = new ArrayList<>();
            if (ListenerService.shared.user.getRoleIds().contains("1")) {
                collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            } else {
                collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            }
            if (collect.size() > 0) {
                diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectData.getTimestamp());
            }
        }
        Map<String, Object> map = new HashMap<>();
        map.put("id", afterData.getFollowData().getId());
        map.put("newTime", (selectData.getTimestamp() + (diff * 3600L)));
        addSubscribe(
                TKApi.INSTANCE.updateReschedule(map)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            Logger.e("====reschedule成功==");
                            SLToast.success("Saved successfully!");
                            finish();
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public void editReschedule() {
        showDialog();
        int diff = 0;
        if (beforeData.getLessonScheduleData() != null) {
            diff = TimeUtils.getRescheduleDiff(beforeData.getLessonScheduleData().getStartDateTime(), selectData.getTimestamp());
        } else {
            List<LessonScheduleConfigEntity> collect = new ArrayList<>();
            if (ListenerService.shared.user.getRoleIds().contains("1")) {
                collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            } else {
                collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            }
            if (collect.size() > 0) {
                diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectData.getTimestamp());
            }
        }

        int finalDiff = diff;
        addSubscribe(
                LessonService
                        .getInstance()
                        .getRescheduleById(afterData.getId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            boolean studentResvisedReschedule = false;
                            if (!afterData.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                                studentResvisedReschedule = true;
                            }

                            addSubscribe(LessonService
                                    .getInstance()
                                    .updateReschedule(data, (selectData.getTimestamp() + (finalDiff * 3600)) + "", false, studentResvisedReschedule)
                                    .subscribeOn(Schedulers.io())
                                    .observeOn(AndroidSchedulers.mainThread(), true)
                                    .subscribe(d -> {
                                        dismissDialog();
                                        SLToast.success("Saved successfully!");
                                        CloudFunctions.sendEmailNotificationForRescheduleNewTime(data.getId(), 2, "");
                                        finish();
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
                                                                        dismissDialog();
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
                                                dismissDialog();
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

                        }, throwable -> {
                            dismissDialog();

                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );


    }

    public void rescheduleV2() {
        showDialog();
        int diff = 0;
        if (beforeData.getLessonScheduleData() != null) {
            diff = TimeUtils.getRescheduleDiff(beforeData.getLessonScheduleData().getStartDateTime(), selectData.getTimestamp());
        } else {
            List<LessonScheduleConfigEntity> collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            if (collect.size() > 0) {
                diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectData.getTimestamp());
            }
        }

        addSubscribe(
                TKApi.INSTANCE.reschedule(beforeData.getStudioId(), beforeData.getSubStudioId()
                                , (selectData.getTimestamp() + (diff * 3600L)), null, "", beforeData.id)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            Logger.e("====reschedule成功==");
                            SLToast.success("Rescheduled successfully!");
                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                            finish();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public void reschedule() {
        int diff = 0;
        if (beforeData.getLessonScheduleData() != null) {
            diff = TimeUtils.getRescheduleDiff(beforeData.getLessonScheduleData().getStartDateTime(), selectData.getTimestamp());
        } else {
            List<LessonScheduleConfigEntity> collect = new ArrayList<>();
            if (ListenerService.shared.user.getRoleIds().contains("1")) {
                collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            } else {
                collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(beforeData.getLessonScheduleConfigId())).collect(Collectors.toList());
            }
            if (collect.size() > 0) {
                diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectData.getTimestamp());
            }
        }

        String time = TimeUtils.getCurrentTimeString();
        List<LessonRescheduleEntity> rescheduleList = new ArrayList<>();
        LessonRescheduleEntity reschedule = new LessonRescheduleEntity()
                .setId(beforeData.getId())
                .setTeacherId(beforeData.getTeacherId())
                .setStudentId(beforeData.getStudentId())
                .setScheduleId(beforeData.getId())
                .setSenderId(beforeData.getStudentId())
                .setConfirmerId(beforeData.getTeacherId())
                .setConfirmType(0)
                .setShouldTimeLength(beforeData.getShouldTimeLength())
                .setTimeBefore(beforeData.getShouldDateTime() + "")
                .setTimeAfter((selectData.getTimestamp() + (diff * 3600)) + "")
                .setCreateTime(time)
                .setUpdateTime(time);
        rescheduleList.add(reschedule);
        showDialog();
        List<LessonScheduleEntity> lessonList = new ArrayList<>();
        lessonList.add(beforeData);
        addSubscribe(
                LessonService
                        .getInstance()
                        .reschedule(lessonList, rescheduleList, "")
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            Logger.e("====reschedule成功==");
                            SLToast.success("Rescheduled successfully!");
                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                            TKRescheduleMakeupRefundHistory tkRescheduleMakeupRefundHistory = new TKRescheduleMakeupRefundHistory();
                            tkRescheduleMakeupRefundHistory.setUpdateTime(time);
                            tkRescheduleMakeupRefundHistory.setCreateTime(time);
                            tkRescheduleMakeupRefundHistory.setId(IDUtils.getId());
                            tkRescheduleMakeupRefundHistory.setTeacherId(beforeData.getTeacherId());
                            tkRescheduleMakeupRefundHistory.setStudentId(beforeData.getStudentId());
                            tkRescheduleMakeupRefundHistory.setType(0);
                            LessonService.getInstance().setRescheduleMakeupRefundHistory(tkRescheduleMakeupRefundHistory);
                            finish();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            if (throwable instanceof FirebaseFirestoreException) {
                                FirebaseFirestoreException error = (FirebaseFirestoreException) throwable;
                                Logger.e("走到了错误%s", error.getCode().value());

                                if (error.getCode() == FirebaseFirestoreException.Code.CANCELLED) {
                                    String userId = "";
                                    if (rescheduleList.get(0).getTeacherId().equals(UserService.getInstance().getCurrentUserId())) {
                                        userId = rescheduleList.get(0).getStudentId();
                                    } else {
                                        userId = rescheduleList.get(0).getTeacherId();
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
                                                            dismissDialog();
                                                        }
                                                    }, e -> {
                                                        Logger.e("走到了获取user数据失败:%s,%s", e.getMessage(), finalUserId);
                                                        dismissDialog();
                                                        SLToast.showError();
                                                    })

                                    );

                                } else if (error.getCode() == FirebaseFirestoreException.Code.UNKNOWN) {
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
                                    dismissDialog();

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


}
