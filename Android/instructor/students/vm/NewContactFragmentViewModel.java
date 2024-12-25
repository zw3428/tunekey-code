package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.utils.MemoryManager;
import com.google.firebase.auth.FirebaseAuth;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.AgendaOnWebViewEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLStaticString;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.SnowFlakeShortUrl;

public class NewContactFragmentViewModel extends BaseViewModel {
    public List<AgendaOnWebViewEntity> agendaListOnWebview = new ArrayList<>();


    private List<Integer> weekList = new ArrayList<>();
    private List<Integer> biWeekList = new ArrayList<>();

    public MutableLiveData<List<AgendaOnWebViewEntity>> lessonData = new MutableLiveData<>();
    public LessonScheduleConfigEntity scheduleConfigEntity = new LessonScheduleConfigEntity();

    private String lessonId;
    public String studentId = "";
    public List<StudentListEntity> studentList = new ArrayList<>();
    public List<LessonScheduleConfigEntity> lessonScheduleConfigList = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypeList = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleListCache = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleListCalculation = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleList = new ArrayList<>();
    public int start, end;
    public String startYMD, endYMD, startYMDHm, endYMDHm;
    public long previousStartTime, currentMonthTime, previousEndTime;


    public int startTime1 = 0;
    public MutableLiveData<LessonScheduleConfigEntity> liveData = new MutableLiveData<>();
    public MutableLiveData<LessonTypeEntity> lessonTypeEntityMutableLiveData = new MutableLiveData<>();
    public MutableLiveData<UserEntity> studentInfoEntity = new MutableLiveData<>();


    public ObservableField<Boolean> wk0Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk1Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk2Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk3Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk4Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk5Clickable = new ObservableField<>(true);
    public ObservableField<Boolean> wk6Clickable = new ObservableField<>(true);

    public ObservableField<Boolean> wk0checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk1checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk2checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk3checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk4checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk5checked = new ObservableField<>(false);
    public ObservableField<Boolean> wk6checked = new ObservableField<>(false);


    public NewContactFragmentViewModel(@NonNull Application application) {
        super(application);

    }

    public NewContactFragmentViewModel.UIClickObservable uc = new UIClickObservable();

    public static class UIClickObservable {
        public SingleLiveEvent<Void> currenceTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> startTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> endTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> selectLessonType = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recBiWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recMonthly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> rb1 = new SingleLiveEvent<>();
    }

    public void getStartTime(int startTime) {

        scheduleConfigEntity.setId(String.valueOf(SnowFlakeShortUrl.nextId()));
        scheduleConfigEntity.setTeacherId(FirebaseAuth.getInstance().getUid());
        scheduleConfigEntity.setStartDateTime(startTime);
        scheduleConfigEntity.setStudentId(studentId);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setLessonTypeId(lessonId);
        scheduleConfigEntity.setCreateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
//        Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
    }

    public void getLessonId(String id) {
        lessonId = id;
    }



    public void getRepeatType(int repeatType) {
        scheduleConfigEntity.setRepeatType(repeatType);
    }

    public void setRepeatType(int repeatType) {
        scheduleConfigEntity.setRepeatType(repeatType);
    }

    public void setRepeatTypeMonthType(String day) {
        scheduleConfigEntity.setRepeatTypeMonthDay(day);
    }

    public void initData1(int startTimestamp) {
        long baseTime = startTimestamp == 0 ? System.currentTimeMillis() : startTimestamp * 1000L;
        startYMD = TimeUtils.getLastMonthFirstDayYMDStr(baseTime);
        startYMDHm = startYMD + " 00:00";
        endYMD = TimeUtils.getNextMonthLastDayYMDStr(baseTime);
        endYMDHm = endYMD + " 23:59";

        start = (int) (TimeUtils.getTimestampBasedOnFormat(startYMDHm) / 1000L);
        end = (int) (TimeUtils.getTimestampBasedOnFormat(endYMDHm) / 1000L);

        getStudentList();
        getTeacherLessonTypeList(false);

    }

    public void changeCalendarTime(long time) {
        long baseTime = time == 0 ? System.currentTimeMillis() : time * 1000L;
        Logger.e("日历获取到的时间:%s", baseTime);
        Logger.e("previousStartTime:%s", previousStartTime);
        Logger.e("previousEndTime:%s", previousEndTime);

        if (baseTime >= previousStartTime && baseTime <= previousEndTime) {
            return;
        }
        if (currentMonthTime <= baseTime) {
            currentMonthTime = TimeUtils.getNextMonthStartTime(currentMonthTime);
        } else {
            currentMonthTime = TimeUtils.getLastMonthStartTime(currentMonthTime);
        }
        Logger.e("当前月的起始时间:%s", currentMonthTime);
        previousStartTime = TimeUtils.getMonthFirstDay(currentMonthTime);
        previousEndTime = TimeUtils.getMonthLastDay(currentMonthTime);
        startYMD = TimeUtils.getLastMonthFirstDayYMDStr(currentMonthTime);
        startYMDHm = startYMD + " 00:00";
        endYMD = TimeUtils.getNextMonthLastDayYMDStr(currentMonthTime);
        endYMDHm = endYMD + " 23:59";
        start = (int) (TimeUtils.getTimestampBasedOnFormat(startYMDHm) / 1000L);
        end = (int) (TimeUtils.getTimestampBasedOnFormat(endYMDHm) / 1000L);
//        Logger.e("startTime:%s===endTime:%s", start,end);
        calculateLessonScheduleList();

//        endYMD = TimeUtils.getNextMonthLastDayYMDStr(baseTime);
//        endYMDHm = endYMD + " 23:59";
//        Logger.e("-*-*-*-*-*-*-*- startYMDHm: " + startYMDHm);
//        Logger.e("-*-*-*-*-*-*-*- endYMDHm: " + endYMDHm);
//        end = (int) (TimeUtils.getTimestampBasedOnFormat(endYMDHm) / 1000L);
    }


    /**
     * 获取教师的学生列表(cache)
     */
    private void getStudentList() {
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListForTeacher(true)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(students -> {
                            if (students != null && students.size() > 0) {
                                studentList = students;
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的学生列表(cache): " + studentList);
                                for (int i = 0; i < studentList.size(); i++) {
                                    Logger.e("-*-*-*-*-*-*-*-teacherId: " + studentList.get(i).getTeacherId() + " studentId: " + studentList.get(i).getStudentId());
                                }
                            }
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
                        })
        );
    }

    /**
     * 获取教师的 lessonScheduleConfig 列表
     */
    private void getTeacherLessonScheduleConfigList(boolean isOnlyCache) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getTeacherLessonScheduleConfigList(isOnlyCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(lessonScheduleConfigs -> {
                            if (lessonScheduleConfigs != null && lessonScheduleConfigs.size() > 0) {
                                lessonScheduleConfigList = lessonScheduleConfigs;
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonScheduleConfig 列表 lessonScheduleConfigList: " + lessonScheduleConfigList);
                                // 计算 schedule
                                calculateLessonScheduleList();
                            } else {
                                lessonScheduleConfigList = new ArrayList<>();
                                calculateLessonScheduleList();
                            }
                        }, throwable -> {
                            lessonScheduleConfigList = new ArrayList<>();
                            calculateLessonScheduleList();
                            Logger.e("-*-*-*-*-*-*-*-  throwable: " + throwable);
                        })
        );
    }

    /**
     * js 计算出教师在时间段内所有的 lessonSchedule
     */
    private void calculateLessonScheduleList() {
        Logger.e("-*-*-*-*-*-*-*- js 计算");
        lessonScheduleListCalculation.clear();
        if (lessonScheduleConfigList != null && lessonScheduleConfigList.size() > 0) {
            Logger.e("-*-*-*-*-*-*-*- js 计算出教师在时间段内所有的 lessonSchedule");
            int currentTime = (int) (System.currentTimeMillis() / 1000L);
            String jsFile = FuncUtils.getJsFuncStr(getApplication(), "calculate.lesson.event");
//            Logger.e("-*-*-*-*-*-*-*- jsFile: " + jsFile);
            V8 v8 = V8.createV8Runtime();
            MemoryManager scope = new MemoryManager(v8);
            v8.executeVoidScript(jsFile);

            for (int i = 0; i < lessonScheduleConfigList.size(); i++) {
                LessonScheduleConfigEntity entity = lessonScheduleConfigList.get(i);
//                Logger.e("-*-*-*-*-*-*-*- id: " + entity.getId());
                int repeatType = entity.getRepeatType() == 1 ? 2 : entity.getRepeatType();
                int startTimestamp = entity.getStartDateTime();
                int endTimestamp = entity.getEndDate();
                long lessonStartTime = startTimestamp * 1000L;
                long lessonEndTime = endTimestamp * 1000L;
                String lessonStartYMD = TimeUtils.getTimestampFormatYMD(lessonStartTime);
                String lessonEndYMD = TimeUtils.getTimestampFormatYMD(lessonEndTime);
                V8Array configWeekDay = new V8Array(v8);
                List<Integer> configWeekDayFromEntity = entity.getRepeatTypeWeekDay();
                if (configWeekDayFromEntity.size() > 0) {
                    for (int w = 0; w < configWeekDayFromEntity.size(); w++) {
                        configWeekDay.push(configWeekDayFromEntity.get(w));
                    }
                }
                Logger.e("-*-*-*-*-*-*-*- lessonStart: " + lessonStartYMD + "-*-*-*-*-*-*-*- lessonEnd: " + lessonEndYMD + "=============== timestamp: " + lessonStartTime);

                // 组装计算数据
                V8Object configFromJava = new V8Object(v8)
                        .add("startYYMMDD", startYMD)
                        .add("endYYMMDD", endYMD)
                        .add("lessonStartYYMMDD", lessonStartYMD)
                        .add("lessonEndYYMMDD", lessonEndYMD)
                        .add("configWeekDay", configWeekDay)
                        .add("endType", entity.getEndType())
                        .add("endCount", entity.getEndCount())
                        .add("repeatType", repeatType)
                        .add("monthRepeat", entity.getRepeatTypeMonthDayType())
                        .add("nthWeekIndex", entity.getRepeatTypeMonthDay())
                        .add("nthDay", entity.getRepeatTypeMonthDay())
                        .add("lastDay", 1)
                        .add("weekRepeat", repeatType)
                        .add("lessonStartTimestamp", lessonStartTime)
                        .add("currentBasedTime", System.currentTimeMillis());

                V8Array param = new V8Array(v8).push(configFromJava);
                String dateStr = v8.executeStringFunction("calcDate", param);
                String[] dateArr = dateStr.split(",");
                int dateArrLength = dateArr.length;
//                Logger.e("-*-*-*-*-*-*-*- dateArr: " + Arrays.toString(dateArr) + "-*-*-*-*-*-*-*- length: " + dateArrLength);

                // 组装计算结果
                if (dateArrLength > 1) {
                    Logger.e("-*-*-*-*-*-*-*- dateArr: " + Arrays.toString(dateArr));
                    LessonTypeEntity ltEntity = new LessonTypeEntity();
                    for (int s = 0; s < lessonTypeList.size(); s++) {
                        if (entity.getLessonTypeId().equals(lessonTypeList.get(s).getId())) {
                            ltEntity = lessonTypeList.get(s);
                        }
                    }

                    for (int j = 0; j < dateArrLength; j++) {
                        LessonScheduleEntity calculationEntity = new LessonScheduleEntity();
                        String hour = TimeUtils.getFormatHour(entity.getStartDateTime() * 1000L);
                        String minute = TimeUtils.getFormatMinute(entity.getStartDateTime());
                        int shouldDateTime = (int) (TimeUtils.getTimestampBasedOnFormat(dateArr[j] +
                                " " + hour + ":" + minute) / 1000L);
                        long id = SnowFlakeShortUrl.nextId();
                        calculationEntity.setId(String.valueOf(id));
                        calculationEntity.setInstrumentId(ltEntity.getInstrumentId());
                        calculationEntity.setLessonTypeId(ltEntity.getId());
                        calculationEntity.setLessonScheduleConfigId(entity.getId());
                        calculationEntity.setTeacherId(entity.getTeacherId());
                        calculationEntity.setStudentId(entity.getStudentId());
                        calculationEntity.setShouldDateTime(shouldDateTime);
                        calculationEntity.setShouldTimeLength(ltEntity.getTimeLength());
                        calculationEntity.setRealityDateTime(0);
                        calculationEntity.setRealityTimeLength(0);
                        calculationEntity.setTeacherNote("");
                        calculationEntity.setStudentNote("");
                        calculationEntity.setLessonStatus(0);
                        calculationEntity.setCancelled(false);
                        calculationEntity.setRescheduled(false);
                        calculationEntity.setRescheduleId("");
                        calculationEntity.setCreateTime(String.valueOf(currentTime));
                        calculationEntity.setUpdateTime(String.valueOf(currentTime));
                        lessonScheduleListCalculation.add(0, calculationEntity);
                    }
                }
            }

            scope.release();
        }

        // 获取 schedule cache
        getTeacherLessonScheduleList(true);
    }

    /**
     * 获取教师的 lessonType 列表
     */
    private void getTeacherLessonTypeList(boolean isOnlyCache) {
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .getLessonTypeList(isOnlyCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(lessonTypes -> {
                            if (lessonTypes != null && lessonTypes.size() > 0) {
                                lessonTypeList = lessonTypes;
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonType 列表 lessonTypeList: " + lessonTypeList);
                                getTeacherLessonScheduleConfigList(false);
                            }
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
                        })
        );
    }

    /**
     * 获取教师的 lessonSchedule 列表
     */
    private void getTeacherLessonScheduleList(boolean isOnlyCache) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getTeacherLessonScheduleList(isOnlyCache,UserService.getInstance().getCurrentUserId(), start, end)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(lessonSchedules -> {
                            if (isOnlyCache) {
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (cache) ");
                                // schedule 缓存
                                if (lessonSchedules != null && lessonSchedules.size() > 0) {
                                    lessonScheduleListCache = lessonSchedules;
                                }

                                // 比对 calculation 和 cache, 并补足 cache
                                compareScheduleCalculationAndCache();

                            } else {
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (online) ");
                                // online schedule
                                if (lessonSchedules != null && lessonSchedules.size() > 0) {
                                    lessonScheduleList = lessonSchedules;
                                }

                                // 比对 cache 和 online, 并分别补足
                                compareScheduleCacheAndOnline();
                            }
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
                        })
        );
    }

    /**
     * 比对 calculation 和 cache, 并补足 cache
     */
    private void compareScheduleCalculationAndCache() {
        agendaListOnWebview.clear();
        Logger.e("-*-*-*-*-*-*-*- 比对计算结果和缓存数据");
        List<LessonScheduleEntity> calculation = lessonScheduleListCalculation;
        Logger.e("-*-*-*-*-*-*-*- 缓存数据数: " + lessonScheduleListCache.size());
        Logger.e("-*-*-*-*-*-*-*- 计算结果数: " + calculation.size());

        // 删除相同 schedule
        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(i);
            for (int j = 0; j < calculation.size(); j++) {
                LessonScheduleEntity calculationEntity = calculation.get(j);
                if (cacheEntity.getLessonScheduleConfigId().equals(calculationEntity.getLessonScheduleConfigId())) {
                    if (cacheEntity.getShouldDateTime() == calculationEntity.getShouldDateTime()) {
                        lessonScheduleListCalculation.remove(j);
                    }
                }
            }
        }
        Logger.e("-*-*-*-*-*-*-*- 去重后计算结果数: " + lessonScheduleListCalculation.size());

        // 添加新的 schedule
        for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
            lessonScheduleListCache.add(0, lessonScheduleListCalculation.get(i));
        }
        Logger.e("-*-*-*-*-*-*-*- 补足后缓存数据数: " + lessonScheduleListCache.size());

        // 组装 webview 数据
        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
            formatWebviewAgenda(lessonScheduleListCache.get(i));
        }

        // 将数据传入 webview 显示
        if (agendaListOnWebview.size() > 0) {
            lessonData.setValue(agendaListOnWebview);
        } else {
            lessonData.setValue(new ArrayList<>());
        }

        // 获取 online schedule
        getTeacherLessonScheduleList(false);
    }

    /**
     * 比对 cache 和 online, 并补足 online
     */
    private void compareScheduleCacheAndOnline() {
        Logger.e("-*-*-*-*-*-*-*- 比对云上和缓存数据");
        List<LessonScheduleEntity> online = lessonScheduleList;
        List<LessonScheduleEntity> cache = lessonScheduleListCache;
        Logger.e("-*-*-*-*-*-*-*- 缓存数据数: " + cache.size());
        Logger.e("-*-*-*-*-*-*-*- 云上数据数: " + online.size());

        // 删除相同 schedule
        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(i);
            for (int j = 0; j < lessonScheduleList.size(); j++) {
                LessonScheduleEntity onlineEntity = lessonScheduleList.get(j);
                if (cacheEntity.getId().equals(onlineEntity.getId())) {
                    lessonScheduleListCache.set(i, lessonScheduleList.get(j));
                    Logger.e("-*-*-*-*-*-*-*- 相同 schedule: i -> " + i + "， j -> " + j);
                    cache.remove(i);
                    online.remove(j);
                    break;
                }
            }
        }

        Logger.e("-*-*-*-*-*-*-*- 去重后缓存数据数: " + cache.size());
        Logger.e("-*-*-*-*-*-*-*- 去重后云上数据数: " + online.size());

        // online 和 cache 互相补足，并上传
//        if (online.size() > 0) {
//            for (int i = 0; i < online.size(); i++) {
//                lessonScheduleListCache.add(0, online.get(i));
//            }
//        }
//        if (cache.size() > 0) {
//            for (int i = 0; i < cache.size(); i++) {
//                addNewLessonScheduleFromCache(cache.get(i));
//            }
//        }

        // 组装 webview 数据
//        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
//            formatWebviewAgenda(lessonScheduleListCache.get(i));
//        }

        // 将数据传入 webview 显示
//        if (agendaListOnWebview.size() > 0) {
//            hasLesson = true;
//            initView();
//            lessonsFragment.addDataToWebview(agendaListOnWebview);
//        }
    }

    /**
     * 将缓存中未上传的 lessonSchedule 上传到云上
     *
     * @param lessonScheduleEntity
     */
    public void addNewLessonScheduleFromCache(LessonScheduleEntity lessonScheduleEntity) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .addNewLessonSchedule(lessonScheduleEntity)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(code -> {
                            if (code == SLStaticString.DATA_ADDED) {
                                Logger.e("-*-*-*-*-*-*-*- 添加新的 schedule 成功, id: " + lessonScheduleEntity.getId());
                            }
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
                        })
        );
    }

    /**
     * 格式化 webview 数据
     *
     * @param lessonEntity
     */
    private void formatWebviewAgenda(LessonScheduleEntity lessonEntity) {

        AgendaOnWebViewEntity agendaEntity = new AgendaOnWebViewEntity();
        agendaEntity.setId(lessonEntity.getId());
        agendaEntity.setInstrumentId(lessonEntity.getInstrumentId());
        agendaEntity.setLessonTypeId(lessonEntity.getLessonTypeId());
        agendaEntity.setLessonScheduleConfigId(lessonEntity.getLessonScheduleConfigId());
        agendaEntity.setTeacherId(lessonEntity.getTeacherId());
        agendaEntity.setStudentId(lessonEntity.getStudentId());
        agendaEntity.setShouldDateTime(lessonEntity.getTKShouldDateTime() * 1000L);
        agendaEntity.setShouldTimeLength(lessonEntity.getShouldTimeLength());
        agendaEntity.setRealityDateTime(lessonEntity.getRealityDateTime() * 1000L);
        agendaEntity.setRealityTimeLength(lessonEntity.getRealityTimeLength());
        agendaEntity.setTeacherNote(lessonEntity.getTeacherNote());
        agendaEntity.setStudentNote(lessonEntity.getStudentNote());
        agendaEntity.setLessonStatus(lessonEntity.getLessonStatus());
        agendaEntity.setCancelled(lessonEntity.isCancelled());
        agendaEntity.setRescheduled(lessonEntity.isRescheduled());
        agendaEntity.setRescheduleId(lessonEntity.getRescheduleId());
        agendaEntity.setOverDay(false);

        for (int j = 0; j < lessonTypeList.size(); j++) {
            if (lessonTypeList.get(j).getId().equals(lessonEntity.getLessonTypeId())) {
                agendaEntity.setLessonName(lessonTypeList.get(j).getName());
                agendaEntity.setType(lessonTypeList.get(j).getType());
                agendaEntity.setPrice(lessonTypeList.get(j).getPrice());
            }
        }

        for (int k = 0; k < studentList.size(); k++) {
            if (lessonEntity.getStudentId().equals(studentList.get(k).getStudentId())) {
                agendaEntity.setStudentName(studentList.get(k).getName());
                agendaEntity.setName(studentList.get(k).getName());
            }
        }
        agendaListOnWebview.add(0, agendaEntity);
    }

    //从0开始 周日是0 以此类推
    public void getRepeatTypeWeekDay(int weekDay) {
        Boolean isAdd = true;
        for (int i = 0; i < weekList.size(); i++) {
            if (weekList.get(i) == weekDay) {
                isAdd = false;
                weekList.remove(i);
            }
        }
        if (isAdd) {
            weekList.add(weekDay);
        }
        if (scheduleConfigEntity.getRepeatType() == 1) {
            scheduleConfigEntity.setRepeatTypeWeekDay(weekList);
//            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
        }
    }

    public void getRepeatTypeMonthDay(int type) {
        scheduleConfigEntity.setRepeatTypeMonthDayType(type);
//        Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
    }

    public void getRepeatTypeMonthType(String day) {
        scheduleConfigEntity.setRepeatTypeMonthDay(day);
//        Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
    }


    public BindingCommand<Boolean> rb1 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            uc.rb1.call();
        }
    });


    public BindingCommand<Boolean> rb3 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            if (aBoolean) {
                scheduleConfigEntity.setEndType(1);
            }

        }
    });
    public BindingCommand<Boolean> rb4 = new BindingCommand<Boolean>(new BindingConsumer<Boolean>() {
        @Override
        public void call(Boolean aBoolean) {
            if (aBoolean) {
                scheduleConfigEntity.setEndType(2);
                if (scheduleConfigEntity.getEndCount() == 0) {
                    scheduleConfigEntity.setEndCount(10);
                }
            }
        }
    });

    public BindingCommand currenceTime = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.currenceTime.call();
        }
    });

    public BindingCommand startTime = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.startTime.call();
        }
    });

    public BindingCommand endTime = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.endTime.call();
        }
    });

    public BindingCommand selectLessonType = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.selectLessonType.call();
        }
    });
    public BindingCommand selectLessonType1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.selectLessonType.call();
        }
    });

    public BindingCommand recWeekly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recWeekly.call();
        }
    });

    public BindingCommand recBiWeekly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recBiWeekly.call();
        }
    });

    public BindingCommand recMonthly = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.recMonthly.call();
        }
    });


    public BindingCommand weekly1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(0);
        }
    });
    public BindingCommand weekly2 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(1);
        }
    });

    public BindingCommand weekly3 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(2);
        }
    });

    public BindingCommand weekly4 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(3);
        }
    });

    public BindingCommand weekly5 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(4);
        }
    });
    public BindingCommand weekly6 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(5);
        }
    });

    public BindingCommand weekly7 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            setRepeatTypeWeekDay(6);
        }
    });

    //从0开始 周日是0 以此类推
    public void setRepeatTypeWeekDay(int weekDay) {
        boolean isAdd = true;
        for (int i = 0; i < weekList.size(); i++) {
            if (weekList.get(i) == weekDay) {
                isAdd = false;
                weekList.remove(i);
            }
        }
        if (isAdd) {
            weekList.add(weekDay);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekList);
//        if (scheduleConfigEntity.getRepeatType() == 1) {
//            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
//        }
        setWeekIsChecked(weekDay);
        checkWeekIsClickable();
    }

    //从0开始 周日是0 以此类推
    public void getRepeatTypeBiWeekDay(int weekDay) {
        boolean isAdd = true;
        for (int i = 0; i < biWeekList.size(); i++) {
            if (biWeekList.get(i) == weekDay) {
                isAdd = false;
                biWeekList.remove(i);
            }
        }
        if (isAdd) {
            biWeekList.add(weekDay);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(biWeekList);
//        if (scheduleConfigEntity.getRepeatType() == 2) {
//            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.START_TIME);
//        }
    }

    private void setWeekIsChecked(int index) {
        switch (index) {
            case 0:
                wk0checked.set(!wk0checked.get());
                break;
            case 1:
                wk1checked.set(!wk1checked.get());
                break;
            case 2:
                wk2checked.set(!wk2checked.get());
                break;
            case 3:
                wk3checked.set(!wk3checked.get());
                break;
            case 4:
                wk4checked.set(!wk4checked.get());
                break;
            case 5:
                wk5checked.set(!wk5checked.get());
                break;
            case 6:
                wk6checked.set(!wk6checked.get());
                break;
        }
    }

    private void checkWeekIsClickable() {
        Logger.e("======%s", scheduleConfigEntity.getRepeatTypeWeekDay());
        if (scheduleConfigEntity.getRepeatTypeWeekDay().size() == 1) {
            for (Integer index : scheduleConfigEntity.getRepeatTypeWeekDay()) {
                switch (index) {
                    case 0:
                        wk0Clickable.set(false);
                        break;
                    case 1:
                        wk1Clickable.set(false);
                        break;
                    case 2:
                        wk2Clickable.set(false);
                        break;
                    case 3:
                        wk3Clickable.set(false);
                        break;
                    case 4:
                        wk4Clickable.set(false);
                        break;
                    case 5:
                        wk5Clickable.set(false);
                        break;
                    case 6:
                        wk6Clickable.set(false);
                        break;
                }
            }

        } else {
            wk0Clickable.set(true);
            wk1Clickable.set(true);
            wk2Clickable.set(true);
            wk3Clickable.set(true);
            wk4Clickable.set(true);
            wk5Clickable.set(true);
            wk6Clickable.set(true);
        }
    }

}
