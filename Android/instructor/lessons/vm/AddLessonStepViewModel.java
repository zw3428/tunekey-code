package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.utils.MemoryManager;
import com.google.firebase.functions.FirebaseFunctions;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.AgendaOnWebViewEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.SetLessonConfigEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLStaticString;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.SnowFlakeShortUrl;

public class AddLessonStepViewModel extends ToolbarViewModel {
    public boolean isEdit = false;

    public LessonScheduleConfigEntity oldConfig = new LessonScheduleConfigEntity();
    public LessonScheduleConfigEntity testOldConfig = new LessonScheduleConfigEntity();

    public List<Integer> weekList = new ArrayList<>();
    public List<Integer> biWeekList = new ArrayList<>();

    public MutableLiveData<List<AgendaOnWebViewEntity>> lessonData = new MutableLiveData<>();
    public LessonScheduleConfigEntity scheduleConfigEntity = new LessonScheduleConfigEntity();
    public List<LessonScheduleEntity> lessonScheduleListDisplay = new ArrayList<>();
    public StudentListEntity studentListEntity = new StudentListEntity();
    public ObservableField<String> startTimeString = new ObservableField<>("Tap to select time");
    public ObservableField<String> locationString = new ObservableField<>("");
    public ObservableField<String> groupStudentSizeString = new ObservableField<>("");
    public ObservableField<String> groupStudentSizeInfoString = new ObservableField<>("");
    public ObservableField<Boolean> isShowGroupStudent = new ObservableField<>(false);


    public TKLocation selectLocation;
    private String lessonId;
    private String studentId;
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> userId = new ObservableField<>();
    public ObservableField<String> teacherName = new ObservableField<>();
    public ObservableField<String> teacherUserId = new ObservableField<>();
    public List<StudentListEntity> studentList = new ArrayList<>();
    public List<LessonScheduleConfigEntity> lessonScheduleConfigList = new ArrayList<>();
    public List<LessonTypeEntity> lessonTypeList = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleListCache = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleListCalculation = new ArrayList<>();
    public List<LessonScheduleEntity> lessonScheduleList = new ArrayList<>();
    public List<AgendaOnWebViewEntity> agendaListOnWebView = new ArrayList<>();
    public int start, end;
    public String startYMD, endYMD, startYMDHm, endYMDHm;
    public long previousStartTime, currentMonthTime, previousEndTime;
    public double specialPrice = -1;

    public int startTime1 = 0;
    public MutableLiveData<LessonScheduleConfigEntity> liveData = new MutableLiveData<>();
    public MutableLiveData<LessonTypeEntity> lessonTypeEntityMutableLiveData = new MutableLiveData<>();
    public MutableLiveData<UserEntity> studentInfoEntity = new MutableLiveData<>();
    public String title = "";
    //封装一个点击事件观察者
    public AddLessonStepViewModel.UIClickObservable uc = new AddLessonStepViewModel.UIClickObservable();

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
    public ObservableField<String> memoString = new ObservableField<>("Optional");

    public boolean isTestUser = false;

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, "doneMessengerBySelectUserForLessonEdit", ArrayList.class, it -> {
            List<UserEntity> selectData = (List<UserEntity>) it;
            Map<String,LessonScheduleConfigEntity.GroupLessonStudent> data = new HashMap<>();
            for (UserEntity userEntity : selectData) {
                LessonScheduleConfigEntity.GroupLessonStudent groupLessonStudent = new LessonScheduleConfigEntity.GroupLessonStudent();
                groupLessonStudent.setStudentId(userEntity.getUserId());
                groupLessonStudent.setFrom(LessonScheduleConfigEntity.GroupLessonStudent.From.studioManagerAdded);
                groupLessonStudent.setStatus(LessonScheduleConfigEntity.GroupLessonStudent.Status.active);
                groupLessonStudent.setRegistrationTimestamp(TimeUtils.getCurrentTime());
                data.put(userEntity.getUserId(),groupLessonStudent);
            }
            scheduleConfigEntity.setGroupLessonStudents(data);
            groupStudentSizeString.set(selectData.size() + " students");
            if (scheduleConfigEntity.getLessonType().getMaxStudents() == -1) {
                groupStudentSizeInfoString.set("");
            } else {
                int pastSize = scheduleConfigEntity.getLessonType().getMaxStudents() - scheduleConfigEntity.getGroupLessonStudents().size();
                if (pastSize == 0) {
                    groupStudentSizeInfoString.set("Full");
                } else {
                    groupStudentSizeInfoString.set(pastSize + " spots available");
                }
            }

        });
    }

    public AddLessonStepViewModel(@NonNull Application application) {
        super(application);
        lessonData.setValue(new ArrayList<>());
    }

    @Override
    public void initToolbar() {
        setNormalToolbar(title);
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    public TKButton.ClickListener submitButton = new TKButton.ClickListener() {
        @Override
        public void onClick(TKButton tkButton) {
            tkButton.startLoading();
            if (isEdit) {
                rescheduleAllV2(tkButton);
            } else {
                setLessonSchedule(tkButton);
            }
        }
    };

    public void setRepeatType(int repeatType) {
        scheduleConfigEntity.setRepeatType(repeatType);
    }

    public void getLessonId(String id) {
        lessonId = id;
    }

    public void getStudentId(String id) {
        studentId = id;
    }


    public void initData1(int startTimestamp) {
        getStudentList();
        long baseTime = startTimestamp == 0 ? System.currentTimeMillis() : startTimestamp * 1000L;
        startYMD = TimeUtils.getLastMonthFirstDayYMDStr(baseTime);
        startYMDHm = startYMD + " 00:00";
        endYMD = TimeUtils.getNextMonthLastDayYMDStr(baseTime);
        endYMDHm = endYMD + " 23:59";


        previousStartTime = TimeUtils.getMonthFirstDay(baseTime);
        previousEndTime = TimeUtils.getMonthLastDay(baseTime);
        currentMonthTime = previousStartTime;
        start = (int) (TimeUtils.getTimestampBasedOnFormat(startYMDHm) / 1000L);
        end = (int) (TimeUtils.getTimestampBasedOnFormat(endYMDHm) / 1000L);
        getTeacherLessonTypeList();
//        getTeacherEventConfigList(false);
//        getTeacherBlockList(true, start, end);  // 暂无
//        getTeacherLessonScheduleList(true, start, end);
//        getTeacherLessonScheduleList(false, start, end);
//        getTeacherBlockList(false, start, end); // 暂无
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
        calculateLessonScheduleList(false);

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
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            studentList = ListenerService.shared.teacherData.getStudentList();
        } else {
            studentList = AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
        }
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
//                            if (lessonScheduleConfigs != null && lessonScheduleConfigs.size() > 0) {
//                                lessonScheduleConfigList = lessonScheduleConfigs;
//                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonScheduleConfig 列表 lessonScheduleConfigList: " + lessonScheduleConfigList);
//                                // 计算 schedule
//                                calculateLessonScheduleList();
//                            } else {
//                                lessonScheduleConfigList = new ArrayList<>();
//                                calculateLessonScheduleList();
//                            }
                            if (lessonScheduleConfigs != null && lessonScheduleConfigs.size() > 0) {
                                lessonScheduleConfigList = lessonScheduleConfigs;
//                                Gson gson = new Gson();
//                                Logger.json(gson.toJson(lessonScheduleConfigs));
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 config 列表, size: " + lessonScheduleConfigList.size());

                                // 计算 schedule
                                calculateLessonScheduleList(isOnlyCache);
                            }
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*-  throwable: " + throwable + "====" + isOnlyCache);
                            lessonScheduleConfigList = new ArrayList<>();
                            calculateLessonScheduleList(isOnlyCache);
                        })
        );
    }

    /**
     * js 计算出教师在时间段内所有的 lessonSchedule
     */
    private void calculateLessonScheduleList(boolean isOnlyCache) {
        Logger.e("-*-*-*-*-*-*-*- js 计算");
        if (true) {
            return;
        }
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
        getTeacherLessonScheduleList(isOnlyCache);
    }

    /**
     * 获取教师的 lessonType 列表
     */
    private void getTeacherLessonTypeList() {

        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            lessonTypeList = SLCacheUtil.getTeacherLessonType(UserService.getInstance().getCurrentUserId());
        } else {
            lessonTypeList = ListenerService.shared.studioData.lessonTypesData;
        }


//        getTeacherLessonScheduleConfigList(true);
    }

    /**
     * 获取教师的 lessonSchedule 列表
     */
    private void getTeacherLessonScheduleList(boolean isOnlyCache) {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getTeacherLessonScheduleList(isOnlyCache, UserService.getInstance().getCurrentUserId(), start, end)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(lessonSchedules -> {

                            lessonScheduleListCache = lessonSchedules;
                            if (isOnlyCache) {
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (cache): " + lessonSchedules.size());
                            } else {
                                Logger.e("-*-*-*-*-*-*-*- 获取教师的 lessonSchedule (online): " + lessonSchedules.size());
                                lessonScheduleList = lessonSchedules;
                            }
                            // 比对 config
                            compareScheduleCacheConfig(isOnlyCache);
                        }, throwable -> {
                            Logger.e("-*-*-*-*-*-*-*- throwable: " + throwable);
                        })
        );
    }

    /**
     * schedule(cache / online) config 和 缓存config 比对
     *
     * @param isOnlyCache
     */
    private void compareScheduleCacheConfig(boolean isOnlyCache) {
        Logger.e("-*-*-*-*-*-*-*- 缓存config 和 schedule(cache) config 比对, schedule before size: " + lessonScheduleListCache.size());
//        Logger.json(SLJsonUtils.toJsonString(lessonScheduleConfigList));
//        Logger.json(SLJsonUtils.toJsonString(lessonScheduleListCache));
        List<LessonScheduleEntity> cache = new ArrayList<>();
        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
            for (int j = 0; j < lessonScheduleConfigList.size(); j++) {
                if (lessonScheduleListCache.get(i).getLessonScheduleConfigId().equals(lessonScheduleConfigList.get(j).getId())) {
                    cache.add(lessonScheduleListCache.get(i));
                    break;
                }
            }
        }
        lessonScheduleListCache = cache;
        Logger.e("-*-*-*-*-*-*-*- 缓存config 和 schedule(cache) config 比对, schedule after size: " + lessonScheduleListCache.size());

        // 比对 calculation 和 cache
        compareScheduleCalculationAndCache(isOnlyCache);
    }


    /**
     * 比对 calculation 和 cache, 并补足 cache
     */
    private void compareScheduleCalculationAndCache(boolean isOnlyCache) {
        lessonScheduleListDisplay.clear();
        agendaListOnWebView.clear();

        List<LessonScheduleEntity> cache = new ArrayList<>();

        // 计算结果没有，缓存有，删除缓存
        for (int j = 0; j < lessonScheduleListCache.size(); j++) {
            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(j);
            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
                LessonScheduleEntity calculationEntity = lessonScheduleListCalculation.get(i);
                if (cacheEntity.getId().equals(calculationEntity.getId())) {
                    cache.add(cacheEntity);
                    break;
                }
            }
        }
        lessonScheduleListCache = cache;
        Logger.e("-*-*-*-*-*-*-*- 比对 config 后 cache 数据数: " + lessonScheduleListCache.size());

        // 缓存判断是否 cancel, reschedule, 否则加入 agenda 中
        for (int i = 0; i < lessonScheduleListCache.size(); i++) {
            if (!lessonScheduleListCache.get(i).isCancelled() && (!lessonScheduleListCache.get(i).isRescheduled() && lessonScheduleListCache.get(i).getRescheduleId().equals(""))) {
                lessonScheduleListDisplay.add(lessonScheduleListCache.get(i));
            }
        }
        Logger.e("-*-*-*-*-*-*-*- display 数据数 before: " + lessonScheduleListDisplay.size());

        // 比对 calculation 和 cache，并将 calculation 去重后加入 agenda 中
        for (int j = 0; j < lessonScheduleListCache.size(); j++) {
            LessonScheduleEntity cacheEntity = lessonScheduleListCache.get(j);
            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
                LessonScheduleEntity calculationEntity = lessonScheduleListCalculation.get(i);
                if (cacheEntity.getId().equals(calculationEntity.getId())) {
//                    Logger.e("-=-=--=- 计算结果重复 -=-=-=-=-=" + calculationEntity.getId());
                    lessonScheduleListCalculation.remove(i);
                    i--;
                }
            }
        }
        Logger.e("-*-*-*-*-*-*-*- 去重后 calculation 数据数: " + lessonScheduleListCalculation.size());

        // 去重后 calculation 加入到 agenda 中
        if (lessonScheduleListCalculation.size() > 0) {
            for (int i = 0; i < lessonScheduleListCalculation.size(); i++) {
                lessonScheduleListDisplay.add(lessonScheduleListCalculation.get(i));
            }
        }
        Logger.e("-*-*-*-*-*-*-*- display 数据数 after: " + lessonScheduleListDisplay.size());

        for (int i = 0; i < lessonScheduleListDisplay.size(); i++) {
            formatWebviewAgenda(lessonScheduleListDisplay.get(i));
        }
        if (isOnlyCache) {
            Logger.e("-=-=-=-=-=-=- 缓存 + 计算个数%s", agendaListOnWebView.size());
            // 将数据传入 webview 显示
            if (agendaListOnWebView.size() > 0) {
                lessonData.setValue(agendaListOnWebView);
            }
            // 获取 online config
            getTeacherLessonScheduleConfigList(false);
        } else {
            Logger.e("-=-=-=-=-=-=- 云上 + 计算个数%s", agendaListOnWebView.size());
            if (agendaListOnWebView.size() > 0) {
                lessonData.setValue(agendaListOnWebView);
            }
//            addCalculationToOnline();
        }
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
        agendaListOnWebView.add(0, agendaEntity);
    }

    public void getStartTime(int time) {
        this.startTime1 = time;
    }


    /**
     * lessonScheduleConfig
     *
     * @param id
     */
    public void getLessonSchedule(String id) {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getLessonScheduleForReschedule(id)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(value -> {
                            liveData.setValue(value);
                            Logger.e("========value====" + value);
                            dismissDialog();
                        }, throwable -> {
                            Logger.e("========studentList====" + throwable.getMessage());
                            dismissDialog();
                        }));
    }

    public void getLessonType(String lessonId) {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getLessonType(lessonId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(data -> {
                            dismissDialog();
                            if (data != null) {
                                List<LessonTypeEntity> lessonTypes = ListenerService.shared.teacherData.getLessonTypes();
                                lessonTypes = lessonTypes.stream().filter(item -> !item.isDeleted()).collect(Collectors.toList());

                                List<LessonTypeEntity> sameInstrumentLessonTypes = lessonTypes.stream().filter(lessonTypeEntity -> lessonTypeEntity.getInstrumentId().equals(data.getInstrumentId())).collect(Collectors.toList());
                                if (sameInstrumentLessonTypes.size() == 0) {
                                    return;
                                }
                                List<LessonTypeEntity> sameDurationLessonTypes = sameInstrumentLessonTypes.stream().filter(lessonTypeEntity -> Math.abs(lessonTypeEntity.getTimeLength() - data.getTimeLength()) < 30).collect(Collectors.toList());

                                if (sameDurationLessonTypes.size() == 0) {
                                    oldConfig.setLessonTypeId(sameInstrumentLessonTypes.get(0).getId());
                                    oldConfig.setLessonType(sameInstrumentLessonTypes.get(0));
                                    lessonTypeEntityMutableLiveData.setValue(sameInstrumentLessonTypes.get(0));
                                } else {
                                    oldConfig.setLessonTypeId(sameDurationLessonTypes.get(0).getId());
                                    oldConfig.setLessonType(sameDurationLessonTypes.get(0));
                                    lessonTypeEntityMutableLiveData.setValue(sameDurationLessonTypes.get(0));
                                }


                            }

                        }, throwable -> {
                            Logger.e("========studentList====" + throwable.getMessage());
                            dismissDialog();
                        }));
    }

    public void getStudentInfo(String studentId) {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentInfo(studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(value -> {
                            studentInfoEntity.setValue(value);

                            dismissDialog();
                        }, throwable -> {
                            Logger.e("========studentList====" + throwable.getMessage());
                            dismissDialog();
                        }));
    }


    public class UIClickObservable {
        public SingleLiveEvent<Void> currenceTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> startTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> endTime = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> selectLessonType = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recBiWeekly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> recMonthly = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> rb1 = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> showTestStudentDialog = new SingleLiveEvent<>();
    }

    //从0开始 周日是0 以此类推
    public void setRepeatTypeWeekDay(int weekDay) {

        boolean isAdd = true;
        for (int i = weekList.size() - 1; i >= 0; i--) {
            if (weekList.get(i) == weekDay) {
                isAdd = false;
                weekList.remove(i);
            }
        }

        if (isAdd) {
            weekList.add(weekDay);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekList);
        setWeekIsChecked(weekDay);
        checkWeekIsClickable();
    }

    public void clearRepeatTypeWeekDay() {
        wk0checked.set(false);
        wk1checked.set(false);
        wk2checked.set(false);
        wk3checked.set(false);
        wk4checked.set(false);
        wk5checked.set(false);
        wk6checked.set(false);

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
        if (scheduleConfigEntity.getRepeatType() == 2) {
        }
    }

    public void getRepeatTypeMonthDay(int type) {
        scheduleConfigEntity.setRepeatTypeMonthDayType(type);
    }

    public void setRepeatTypeMonthType(String day) {
        scheduleConfigEntity.setRepeatTypeMonthDay(day);
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

    public BindingCommand biWeekly7 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(6);
        }
    });
    public BindingCommand biWeekly6 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(5);
        }
    });
    public BindingCommand biWeekly5 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(4);
        }
    });
    public BindingCommand biWeekly4 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(3);
        }
    });
    public BindingCommand biWeekly3 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(2);
        }
    });
    public BindingCommand biWeekly2 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(1);
        }
    });
    public BindingCommand biWeekly1 = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            getRepeatTypeBiWeekDay(0);
        }
    });


    //点击保存按钮 保存数据
    private void setLessonSchedule(TKButton submitButton) {


        scheduleConfigEntity.setId(String.valueOf(SnowFlakeShortUrl.nextId()));
        scheduleConfigEntity.setTeacherId(UserService.getInstance().getCurrentUserId());
        scheduleConfigEntity.setStudioId(SLCacheUtil.getCurrentStudioId());
        scheduleConfigEntity.setStudentId(studentId);
        scheduleConfigEntity.setLessonTypeId(lessonId);
        scheduleConfigEntity.setStartDateTime(startTime1);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setCreateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setSpecialPrice(specialPrice);
        String memo = "";
        if (memoString.get() != null && !memoString.get().equals("Optional")) {
            memo = memoString.get();
        }
        scheduleConfigEntity.setMemo(memo);
        int diff = TimeUtils.getUTCWeekdayDiff(startTime1 * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : scheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);
//        Logger.json(SLJsonUtils.toJsonString(scheduleConfigEntity));

        List<SetLessonConfigEntity> setLessonConfigEntities = new ArrayList<>();
        SetLessonConfigEntity entity = new SetLessonConfigEntity();
        entity.setLessonType(scheduleConfigEntity.getLessonType());
        entity.setLessonScheduleConfig(scheduleConfigEntity);
        setLessonConfigEntities.add(entity);
        //
        Logger.e("=======开始上传=====" + SLJsonUtils.toJsonString(weekDays));

        /**
         * enum TKInvitedStatus: String, HandyJSONEnum {
         *     // 未被邀请
         *     case none = "-1"
         *     // 已发送邀请,等待回应
         *     case sentPendding = "0"
         *     // 已确认,接受邀请
         *     case confirmed = "1"
         *     // 已拒绝邀请
         *     case rejected = "2"
         *     // 课程已结束/过期
         *     case archived = "3"
         * }
         */
        boolean invitedStatusIsInviteAndResend = false;
        if (studentListEntity.getInvitedStatus().equals("-1") || studentListEntity.getInvitedStatus().equals("0")) {
            invitedStatusIsInviteAndResend = true;
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .setLessonScheduleConfig(setLessonConfigEntities, invitedStatusIsInviteAndResend)
                        .subscribe(aBoolean -> {
                            submitButton.stopLoading();
                            SLToast.success("Save successfully!");
                            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.REFRESH_LESSON);
                            if (isTestUser) {
                                uc.showTestStudentDialog.call();
                            } else {
                                finish();
                            }
                        }, throwable -> {
                            Logger.e("=====失败=%s", throwable.getMessage());
                            SLToast.showError();
                            submitButton.stopLoading();
                        })
        );


    }

    public void deleteLesson() {


        showDialog();

        if (oldConfig.getLessonCategory().equals(LessonTypeEntity.TKLessonCategory.group)){
            addSubscribe(
                    TKApi.deleteGroupLesson(oldConfig.getId())
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(),true)
                            .subscribe(d -> {
                                SLToast.success("Successfully!");
                                Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                                Messenger.getDefault().send(oldConfig, MessengerUtils.REFRESH_LESSON);
                                finish();
                            }, throwable -> {
                                SLToast.error("Please check your connection and try again.");

                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })
            );


            return;
        }

        int starTime = 0;
        LessonScheduleConfigEntity data = oldConfig;
        starTime = data.getStartDateTime();
        String studentId = data.getStudentId();
        Map<String, Object> map = new HashMap<>();
//        map.put("time", TimeUtils.getCurrentTime());
        map.put("configId", data.getId());
//        map.put("studentId", studentId);
//        map.put("teacherId", data.getTeacherId());
//        map.put("newScheduleData", "");
//        map.put("isUpdate", false);

//        if ((data.getRepeatType() == 0 && starTime >= TimeUtils.getCurrentTime()) || starTime >= TimeUtils.getCurrentTime()) {
//            map.put("isUpdate", false);
//        } else {
//            map.put("isUpdate", true);
//        }

        CloudFunctions
                .deleteLessonScheduleConfigV2(map)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult()) {
                            SLToast.success("Successfully!");
                            Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                            Messenger.getDefault().send(oldConfig, MessengerUtils.REFRESH_LESSON);
                            finish();
                        }
                    } else {
                        Logger.e("====== 删除 lesson 异常:" + task.getException().getMessage());
                        SLToast.error("Please check your connection and try again.");
                    }
                });


//
//        Map<String, Object> data = new HashMap<>();
//        data.put("cancelType", "ALL_LESSONS");
//        data.put("scheduleConfigId", oldConfig.getId());
////        data.put("selectedLessonScheduleId", lesson.getId());
//        showDialog();
//
//        FirebaseFunctions
//                .getInstance()
//                .getHttpsCallable("lessonService-cancelLessonsWithType")
//                .call(data)
//                .addOnCompleteListener(task -> {
//
//                    dismissDialog();
//                    if (task.getException() == null) {
//                        SLToast.success("Successfully!");
//                        Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
//                        Messenger.getDefault().send(oldConfig, MessengerUtils.REFRESH_LESSON);
//                        finish();
//                    } else {
//                        SLToast.error("Please check your connection and try again.");
//                        Logger.e("失败==>%s", task.getException().getMessage());
//                    }
//                });
//

    }

    public void deleteStudentLesson() {
        List<Map<String, Object>> datas = new ArrayList<>();

        for (LessonScheduleConfigEntity lessonScheduleConfigEntity : studentListEntity.getUnConfirmedLessonConfig()) {
            Map<String, Object> map = new HashMap<>();
            map.put("time", (System.currentTimeMillis() / 1000) + "");
            map.put("configId", lessonScheduleConfigEntity.getId());
            map.put("studentId", lessonScheduleConfigEntity.getStudentId());
            map.put("teacherId", "");
            map.put("newScheduleData", "");
            map.put("isUpdate", true);
            datas.add(map);
        }
        if (datas.size() > 0) {
            showDialog();
            addSubscribe(
                    CloudFunctions
                            .deleteLessonScheduleConfigs(datas)
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                SLToast.success("Delete successfully!");
                                Messenger.getDefault().send(studentId, MessengerUtils.CLEAR_UNCONFIRMED_LESSONS);
                                finish();
                            }, throwable -> {

                                Logger.e("失败,失败原因" + throwable.getMessage());
                                SLToast.showError();
                            })

            );
        }
    }

    public void confirmStudentLesson() {
        showDialog();

        scheduleConfigEntity.setTeacherId(UserService.getInstance().getCurrentUserId());
        scheduleConfigEntity.setStudentId(studentId);
        scheduleConfigEntity.setStartDateTime(startTime1);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setCreateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
        scheduleConfigEntity.setLessonTypeId(lessonId);
        scheduleConfigEntity.setSpecialPrice(specialPrice);
        String memo = "";
        if (memoString.get() != null && !memoString.get().equals("Optional")) {
            memo = memoString.get();
        }
        scheduleConfigEntity.setMemo(memo);
        int diff = TimeUtils.getUTCWeekdayDiff(startTime1 * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : scheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        SetLessonConfigEntity entity = new SetLessonConfigEntity();
        entity.setLessonType(scheduleConfigEntity.getLessonType());
        entity.setLessonScheduleConfig(scheduleConfigEntity);
//        Logger.e("======%s", SLJsonUtils.toJsonString(entity));
        Map<String, Object> stringObjectMap = SLJsonUtils.toMaps(SLJsonUtils.toJsonString(scheduleConfigEntity));

        Map<String, Object> data = new HashMap<>();
        data.put("config", stringObjectMap);
        addSubscribe(
                CloudFunctions.teacherConfirmStudentLesson(data)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            SLToast.success("Confirm successfully!");
                            dismissDialog();
                            Messenger.getDefault().send(studentId, MessengerUtils.CLEAR_UNCONFIRMED_LESSONS);
                            finish();
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }


    public void rescheduleAllV2(TKButton tkButton) {
        int diff = TimeUtils.getUTCWeekdayDiff(startTime1 * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : scheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);
        scheduleConfigEntity.setLessonTypeId(lessonId);
        scheduleConfigEntity.setStartDateTime(startTime1);
        scheduleConfigEntity.setSpecialPrice(specialPrice);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
        String memo = "";
        if (memoString.get() != null && !memoString.get().equals("Optional")) {
            memo = memoString.get();
        }
        scheduleConfigEntity.setMemo(memo);
        scheduleConfigEntity.location = selectLocation;
        scheduleConfigEntity.setStudioId(SLCacheUtil.getCurrentStudioId());
        scheduleConfigEntity.setCreateTimestamp(TimeUtils.getCurrentTime());
        scheduleConfigEntity.setUpdateTimestamp(TimeUtils.getCurrentTime());
        Map<String, Object> data = new HashMap<>();
        String id = scheduleConfigEntity.getId();
//        scheduleConfigEntity.setLessonCategory(oldConfig.getLessonCategory());
//        scheduleConfigEntity.setGroupLessonStudents(oldConfig.getGroupLessonStudents());
        data.put("configId", id);
        LessonScheduleConfigEntity lessonScheduleConfigEntity = CloneObjectUtils.cloneObject(scheduleConfigEntity);
        lessonScheduleConfigEntity.setId(IDUtils.getId());
        data.put("newConfig", SLJsonUtils.toMaps(SLJsonUtils.toJsonString(lessonScheduleConfigEntity)));


        FirebaseFunctions
                .getInstance()
                .getHttpsCallable("scheduleService-updateLessonScheduleConfig")
                .call(data)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    tkButton.stopLoading();
                    if (task.getException() == null) {
                        SLToast.success("Update successfully!");
                        Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                        Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.REFRESH_LESSON);
                        finish();
                    } else {
                        SLToast.error("Please check your connection and try again.");
                        Logger.e("失败==>%s", task.getException().getMessage());
                    }
                });

    }

    /**
     * rescheduleAll
     */
    public void rescheduleAll(TKButton submitButton) {
//        Logger.json(SLJsonUtils.toJsonString(scheduleConfigEntity));
//        Logger.json(SLJsonUtils.toJsonString(oldConfig));
        int diff = TimeUtils.getUTCWeekdayDiff(startTime1 * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : scheduleConfigEntity.getRepeatTypeWeekDay()) {
            int i = integer + diff;
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);
        scheduleConfigEntity.setLessonTypeId(lessonId);
        scheduleConfigEntity.setStartDateTime(startTime1);
        scheduleConfigEntity.setSpecialPrice(specialPrice);
        scheduleConfigEntity.setLessonStatus(1);
        scheduleConfigEntity.setUpdateTime(System.currentTimeMillis() / 1000 + "");
        String memo = "";
        if (memoString.get() != null && !memoString.get().equals("Optional")) {
            memo = memoString.get();
        }
        scheduleConfigEntity.setMemo(memo);

        int starTime = scheduleConfigEntity.getStartDateTime();
        String studentId = scheduleConfigEntity.getStudentId();
        Map<String, Object> map = new HashMap<>();
        map.put("time", TimeUtils.getCurrentTime());
        map.put("configId", oldConfig.getId());
        map.put("studentId", studentId);
        map.put("teacherId", scheduleConfigEntity.getTeacherId());
        map.put("newScheduleData", SLJsonUtils.toJsonString(scheduleConfigEntity));


        if ((scheduleConfigEntity.getRepeatType() == 0 && starTime >= (System.currentTimeMillis() / 1000)) || starTime >= (System.currentTimeMillis() / 1000)) {
            map.put("isUpdate", false);
        } else {
            map.put("isUpdate", true);
        }

        CloudFunctions
                .deleteLessonScheduleConfig(map)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult()) {
                            Logger.e("====成功");
                            submitButton.stopLoading();
                            SLToast.success("Rescheduled successfully!");
                            Messenger.getDefault().send(scheduleConfigEntity, MessengerUtils.REFRESH_LESSON);
                            finish();
                        }
                    } else {
                        submitButton.stopLoading();
                        SLToast.error("Please check your connection and try again.");
                    }
                });
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
