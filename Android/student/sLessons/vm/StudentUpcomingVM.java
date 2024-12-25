package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.StudioService;
import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKAPPVersion;
import com.spelist.tunekey.entity.TKFollowUp;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentLessonDetailActivity;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.StudioCalendarHomeEX;
import com.spelist.tunekey.entity.TKStudioEvent;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentLessonDetailActivity;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentUpcomingAc;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import retrofit2.http.HEAD;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/17
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentUpcomingVM extends ToolbarViewModel {
    public int startTimestamp = 0;
    public int endTimestamp = 0;
    // 正在展开的item
    public int openIndex = -1;
    public String openId = "";
    public Context context;
    public ObservableField<StudentUpcomingAc.MyRecyclerViewAdapter> adapterObservable = new ObservableField<>(new StudentUpcomingAc.MyRecyclerViewAdapter<>());
    public PolicyEntity policyData;
    public UserEntity teacherData;
    private List<LessonCancellationEntity> cancelData = new ArrayList<>();
    private List<LessonRescheduleEntity> rescheduleData = new ArrayList<>();
    public StudentListEntity studentData;
    public List<LessonTypeEntity> lessonTypes = new ArrayList<>();
    private List<LessonScheduleConfigEntity> scheduleConfigs = new ArrayList<>();
    public List<LessonScheduleConfigEntity> allScheduleConfigs = new ArrayList<>();
    public Map<String, LessonScheduleConfigEntity> lessonConfigMap = new HashMap<>();
    public Map<String, LessonTypeEntity> lessonTypeMap = new HashMap<>();
    public Map<String, LessonScheduleEntity> lessonScheduleIdMap = new HashMap<>();
    public Map<String, TKStudioEvent> studioEventIdMap = new HashMap<>();

    public Map<String, LessonCancellationEntity> cancelDataMap = new HashMap<>();
    public Map<String, LessonRescheduleEntity> rescheduleDataMap = new HashMap<>();
    public List<StudentUpcomingMultiItemViewModel> allData = new ArrayList<>();

    public HashMap<String, LessonScheduleEntity> onlineLessonData = new HashMap<>();
    public HashMap<String, LessonScheduleEntity> locationLessonData = new HashMap<>();
    public HashMap<String, TeacherInfoEntity> teacherInfoDataMap = new HashMap<>();
    private Disposable scheduleDisposable;


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


    public StudentUpcomingVM(@NonNull Application application) {
        super(application);

    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Upcoming");
        setRightButtonVisibility(View.VISIBLE);
        setRightButtonText("ADD LESSONS");

    }

    @Override
    protected void clickRightTextButton() {
        super.clickRightTextButton();
        uc.clickAddLesson.call();
    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
//        Messenger.getDefault().register(this, MessengerUtils.USER_NOTIFICATION_CHANGED, this::initLessonData);
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_CHANGE_LESSON_CONFIG, this::initLessonData);
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_TEACHER_CHANGED, this::initLessonData);
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_FOLLOW_UP_CHANGE, this::initLessonData);
    }

    public void initData() {
        for (TeacherInfoEntity teacherInfoEntity : AppDataBase.getInstance().teacherInfoDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId())) {
            teacherInfoDataMap.put(teacherInfoEntity.getUserId(), teacherInfoEntity);
        }
        setIsShowProgress(true);
        startTimestamp = TimeUtils.getCurrentTime();
        endTimestamp = (int) (TimeUtils.addMonth((startTimestamp * 1000L), 3) / 1000L);
        initLessonData();
    }

    private void initLessonData() {
        studentData = ListenerService.shared.studentData.getStudentData();
        List<LessonScheduleConfigEntity> configs = ListenerService.shared.studentData.getScheduleConfigs();
        scheduleConfigs = new ArrayList<>();
        allScheduleConfigs.clear();
        for (LessonScheduleConfigEntity scheduleConfig : configs) {
            if (scheduleConfig.getStudentId().equals(studentData.getStudentId()) || scheduleConfig.getGroupLessonStudents().get(studentData.getStudentId()) != null) {
                scheduleConfigs.add(scheduleConfig);
            }
            allScheduleConfigs.add(scheduleConfig);
        }

        for (LessonTypeEntity lessonType : lessonTypes) {
            lessonTypeMap.put(lessonType.getId(), lessonType);
        }
        for (LessonScheduleConfigEntity scheduleConfig : scheduleConfigs) {
            lessonConfigMap.put(scheduleConfig.getId(), scheduleConfig);
        }
        Logger.e("lessonConfigMap==>%s", lessonConfigMap.size());
        StudioCalendarHomeEX.refreshLessonSchedules(scheduleConfigs, startTimestamp, endTimestamp);
        initScheduleData();
//        getRescheduleData();
//        getCancelData();
        getFollowUpData();
        getStudioEventData();
    }

    private void getFollowUpData() {

        List<TKFollowUp> followUps = ListenerService.shared.studentData.getFollowUps();
        cancelData.clear();
        rescheduleData.clear();
        if (followUps != null && followUps.size() > 0) {
            for (TKFollowUp followUp : followUps) {
                if (followUp.getDataType().equals(TKFollowUp.DataType.reschedule)) {
                    LessonRescheduleEntity r = CloneObjectUtils.cloneObject(followUp.getRescheduleData());

                    rescheduleData.add(r);
                    rescheduleDataMap.put(r.getScheduleId(), r);
                }
                if (followUp.getDataType().equals(TKFollowUp.DataType.cancellation)) {
                    LessonCancellationEntity lessonCancellationEntity = CloneObjectUtils.cloneObject(followUp.getCancellationData());
                    cancelData.add(lessonCancellationEntity);
                    cancelDataMap.put(lessonCancellationEntity.getOldScheduleId(), lessonCancellationEntity);
                }
            }
        }
        initShowData();
    }

    private void getStudioEventData() {
        if (SLCacheUtil.getStudioInfo() != null && SLCacheUtil.getStudioInfo().getId() == null && SLCacheUtil.getStudioInfo().getId().equals("")) {
            return;
        }
        String studioId = SLCacheUtil.getStudioInfo().getId();

        String storefrontColor = SLCacheUtil.getStudioInfo().getStorefrontColor();
        if (storefrontColor.equals("")) {
            storefrontColor = "71D9C2";
        }
        String finalStorefrontColor = storefrontColor;
        addSubscribe(
                TKStudioEvent.Companion.getListByStudioId(studioId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
//                            studioEventIdMap.put(d.get(), d);
                            int currentTime = TimeUtils.getCurrentTime();
                            for (TKStudioEvent it : d) {
                                if (it.getEndTime() != 0.0 && it.getEndTime() < currentTime) {
                                    continue;
                                }
                                if (studioEventIdMap.get(it.getId()) == null) {
                                    studioEventIdMap.put(it.getId(), it);
                                    StudentUpcomingEventItemVM e = new StudentUpcomingEventItemVM(this, -1, StudentUpcomingMultiItemViewModel.Type.STUDIO_EVENT, null, it);
                                    e.color = finalStorefrontColor;
//                                    allData.add(e);
                                    lessonDataList.add(e);
                                }
                            }
                            allDataSort();
//                            lessonDataList.clear();
//                            for (StudentUpcomingMultiItemViewModel allDatum : allData) {
//                                lessonDataList.add(allDatum);
//                            }
                            uc.addComplete.call();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );

    }

    private void allDataSort() {
//        allData.sort((t0, t1) ->{
//            double t0Time = 0.0;
//            double t1Time = 0.0;
//            if (t0 instanceof StudentUpcomingItemVM){
//                t0Time = ((StudentUpcomingItemVM) t0).data.getShouldDateTime();
//            }else if (t0 instanceof StudentUpcomingEventItemVM){
//                t0Time = ((StudentUpcomingEventItemVM) t0).data.getStartTime();
//            }
//            if (t1 instanceof StudentUpcomingItemVM){
//                t1Time = ((StudentUpcomingItemVM) t1).data.getShouldDateTime();
//            }else if (t1 instanceof StudentUpcomingEventItemVM){
//                t1Time = ((StudentUpcomingEventItemVM) t1).data.getStartTime();
//            }
//            return (int) (t0Time-t1Time);
//        } );
        lessonDataList.sort((t0, t1) -> {
            double t0Time = 0.0;
            double t1Time = 0.0;
            if (t0 instanceof StudentUpcomingItemVM) {
                t0Time = ((StudentUpcomingItemVM) t0).data.getShouldDateTime();
            } else if (t0 instanceof StudentUpcomingEventItemVM) {
                t0Time = ((StudentUpcomingEventItemVM) t0).data.getStartTime();
            }
            if (t1 instanceof StudentUpcomingItemVM) {
                t1Time = ((StudentUpcomingItemVM) t1).data.getShouldDateTime();
            } else if (t1 instanceof StudentUpcomingEventItemVM) {
                t1Time = ((StudentUpcomingEventItemVM) t1).data.getStartTime();
            }
            return (int) (t0Time - t1Time);
        });
    }

    private void getCancelData() {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .studentGetCancellationListByStudentId(studentData.getStudentId())
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            cancelData = data;
//                            for (LessonCancellationEntity datum : data) {
//                                cancelDataMap.put(datum.getOldScheduleId(), datum);
//                            }
//                            Logger.e("获取cancel数据成功:%s", data.size());
//                            initShowData();
//                        }, throwable -> {
//                            Logger.e("获取cancel数据失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
    }

    private void getRescheduleData() {
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .studentGetRescheduleListByStudentId(studentData.getStudentId())
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            rescheduleData = data;
//                            for (LessonRescheduleEntity datum : data) {
//                                rescheduleDataMap.put(datum.getScheduleId(), datum);
//                            }
//                            Logger.e("获取Reschedule数据成功:%s", data.size());
//                            initShowData();
//                        }, throwable -> {
//                            Logger.e("获取Reschedule数据失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
    }

    public void initScheduleData() {
//        if (SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
//            addSubscribe(
//                    LessonService
//                            .getInstance()
//                            .studentRefreshLessonSchedule(scheduleConfigs, lessonTypes, startTimestamp, endTimestamp)
//                            .subscribeOn(Schedulers.io())
//                            .observeOn(AndroidSchedulers.mainThread(), true)
//                            .subscribe(da -> {
//                                getLessonData();
//                            }, throwable -> {
//                                setIsShowProgress(false);
//                                Logger.e("刷新课程失败,失败原因" + throwable.getMessage());
//                            }));
//        }else {
//            getLessonData();
//        }
        getLessonData();
    }

    private void getLessonData() {
//        String teacherId = studentData.getTeacherId();
//        if (studentData.getStudentApplyStatus() == 1) {
//            teacherId = "";
//        }
        if (scheduleDisposable != null) {
            scheduleDisposable.dispose();
        }
        List<String> configIds = new ArrayList<>();
        for (Map.Entry<String, LessonScheduleConfigEntity> entry : lessonConfigMap.entrySet()) {
            configIds.add(entry.getKey());
        }
        scheduleDisposable = AppDataBase.getInstance().lessonDao().getByStudentIdWithStartTimeAndEndTime(ListenerService.shared.studentData.getUser().getUserId(), startTimestamp, endTimestamp, configIds)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread(), true)
                .subscribe(data -> {
                    int nowTime = TimeUtils.getCurrentTime();
                    for (LessonScheduleEntity d : data) {
                        if (lessonConfigMap.get(d.getLessonScheduleConfigId()) != null) {
                            d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                        }
                    }
                    data.removeIf(item -> item.getTKShouldDateTime() < nowTime);
                    data.removeIf(item -> {
                        boolean isRemove = false;
                        LessonScheduleConfigEntity config = lessonConfigMap.get(item.getLessonScheduleConfigId());
                        if (config == null) {
                            isRemove = true;
                        } else {
                            if (config.getEndType() == 1 && item.getShouldDateTime() > config.getEndDate()) {
                                isRemove = true;
                            } else if (config.getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
                                LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(config.getGroupLessonStudents().get(ListenerService.shared.studentData.getUser().getUserId())), LessonScheduleConfigEntity.GroupLessonStudent.class);
                                if (value.status == LessonScheduleConfigEntity.GroupLessonStudent.Status.quit && value.getQuitTimestamp() < item.getShouldDateTime()) {
                                    isRemove = true;
                                }
                            }
                        }
                        return isRemove;
                    });
                    setIsShowProgress(false);

                    data.sort((o1, o2) -> (int) (o1.getShouldDateTime() - o2.getShouldDateTime()));

                    for (int i = 0; i < data.size(); i++) {
                        LessonScheduleEntity d = data.get(i);
                        SLCacheUtil.setLessonData(d);
                        if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
                            continue;
                        }
                        d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
                        d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
                        onlineLessonData.put(d.getId(), d);
                        if (lessonScheduleIdMap.get(d.getId()) == null) {
                            lessonDataList.add(new StudentUpcomingItemVM(this, i, StudentUpcomingMultiItemViewModel.Type.UPCOMING, d, null));

                        } else {
                            for (StudentUpcomingMultiItemViewModel item : lessonDataList) {
                                if (item.type == StudentUpcomingMultiItemViewModel.Type.UPCOMING) {
                                    if (item.lessonData.getId().equals(d.getId())) {
                                        StudentUpcomingItemVM item1 = (StudentUpcomingItemVM) item;
                                        item1.initData(d);
                                    }
                                }

                            }
                        }
                        lessonScheduleIdMap.put(d.getId(), d);
                    }
                    Logger.e("本地获取出来的课程==>%s==>%s", data.size(),lessonDataList.size());
                    try{
                        adapterObservable.get().notifyDataSetChanged();
                    }catch (Throwable e){
                    }
                    uc.loadingComplete.call();
                    uc.addComplete.call();

                    allDataSort();
                    initShowData();
                }, throwable -> {
                    Logger.e("失败,失败原因" + throwable.getMessage());
                });
        addSubscribe(scheduleDisposable);


//        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
//            lessonConfigMap.forEach((key, value) -> {
//
//                List<LessonScheduleEntity> data = StudioService.getInstance().getLessonTimeByRRuleAndStartTimeAndEndTime(value, startTimestamp, endTimestamp);
//                int nowTime = TimeUtils.getCurrentTime();
//                data.removeIf(item -> item.getTKShouldDateTime() < nowTime);
//                for (int i = 0; i < data.size(); i++) {
//                    LessonScheduleEntity d = data.get(i);
//                    SLCacheUtil.setLessonData(d);
//                    if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
//                        continue;
//                    }
//                    d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
//                    d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
//                    locationLessonData.put(d.getId(),d);
//                    if (lessonScheduleIdMap.get(d.getId()) == null) {
//                        lessonDataList.add(new StudentUpcomingItemVM(this, i,StudentUpcomingMultiItemViewModel.Type.UPCOMING, d,null));
//
//                    } else {
//                        for (StudentUpcomingMultiItemViewModel item : lessonDataList) {
//                            if (item.type == StudentUpcomingMultiItemViewModel.Type.UPCOMING){
//                                if (item.lessonData.getId().equals(d.getId())) {
//                                    StudentUpcomingItemVM item1 = (StudentUpcomingItemVM)item;
//                                    item1.initData(d);
//                                }
//                            }
//
//                        }
//                    }
//                    lessonScheduleIdMap.put(d.getId(), d);
//                }
//
//            });
//            uc.loadingComplete.call();
//            initShowData();
//        }
//
//
//
//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getScheduleByStudentIdAndTeacherIdAndTime( teacherId, startTimestamp, endTimestamp)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            setIsShowProgress(false);
//                            Logger.e("获取schedule成功: %s", data.size());
//                            data.sort((o1, o2) -> (int) (o1.getShouldDateTime() - o2.getShouldDateTime()));
//                            int nowTime = TimeUtils.getCurrentTime();
//                            data.removeIf(item -> item.getTKShouldDateTime() < nowTime);
//                            for (int i = 0; i < data.size(); i++) {
//                                LessonScheduleEntity d = data.get(i);
//                                SLCacheUtil.setLessonData(d);
//                                if (lessonConfigMap.get(d.getLessonScheduleConfigId()) == null) {
//                                    continue;
//                                }
//                                d.setConfigEntity(lessonConfigMap.get(d.getLessonScheduleConfigId()));
//                                d.setLessonType(lessonTypeMap.get(d.getLessonTypeId()));
//                                onlineLessonData.put(d.getId(),d);
//                                if (lessonScheduleIdMap.get(d.getId()) == null) {
//                                    lessonDataList.add(new StudentUpcomingItemVM(this, i,StudentUpcomingMultiItemViewModel.Type.UPCOMING, d,null));
//
//                                } else {
//                                    for (StudentUpcomingMultiItemViewModel item : lessonDataList) {
//                                        if (item.type == StudentUpcomingMultiItemViewModel.Type.UPCOMING){
//                                            if (item.lessonData.getId().equals(d.getId())) {
//                                                StudentUpcomingItemVM item1 = (StudentUpcomingItemVM)item;
//                                                item1.initData(d);
//                                            }
//                                        }
//
//                                    }
//                                }
//                                lessonScheduleIdMap.put(d.getId(), d);
//                            }
//                            uc.loadingComplete.call();
//                            uc.addComplete.call();
//                            allDataSort();
//                            StudioCalendarHomeEX.updateLessonData(locationLessonData,onlineLessonData);
//                            initShowData();
//                        }, throwable -> {
//                            setIsShowProgress(false);
//                            Logger.e("获取schedule失败,失败原因" + throwable.getMessage());
//                        }));
//
//
//

    }

    private void initShowData() {
        for (int i = 0; i < lessonDataList.size(); i++) {
            if (lessonDataList.get(i).type == StudentUpcomingMultiItemViewModel.Type.UPCOMING) {
                if (lessonDataList.get(i) instanceof StudentUpcomingItemVM) {
                    StudentUpcomingItemVM item = (StudentUpcomingItemVM) lessonDataList.get(i);
                    if (item.data.isCancelled() && cancelDataMap.get(item.data.getId()) != null) {
                        item.data.setCancelLessonData(cancelDataMap.get(item.data.getId()));
                    }
                    //设置reschedule数据
                    if (item.data.isRescheduled() && rescheduleDataMap.get(item.data.getId()) != null) {
                        item.data.setRescheduleLessonData(rescheduleDataMap.get(item.data.getId()));
                    }
                    item.initData(item.data);
                }
                //设置cancel数据
                if (lessonDataList.get(i).lessonData.isCancelled() && cancelDataMap.get(lessonDataList.get(i).lessonData.getId()) != null) {
                    lessonDataList.get(i).lessonData.setCancelLessonData(cancelDataMap.get(lessonDataList.get(i).lessonData.getId()));
                }
                //设置reschedule数据
                if (lessonDataList.get(i).lessonData.isRescheduled() && rescheduleDataMap.get(lessonDataList.get(i).lessonData.getId()) != null) {
                    lessonDataList.get(i).lessonData.setRescheduleLessonData(rescheduleDataMap.get(lessonDataList.get(i).lessonData.getId()));
                }
            }
        }
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


    public void studentDeleteLessonWithoutTeacher(LessonScheduleEntity lesson, boolean deleteUpcoming) {
        showDialog();
        addSubscribe(
                LessonService
                        .getInstance()
                        .studentDeleteLessonWithoutTeacher(lesson, deleteUpcoming)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            SLToast.success("Removed this lesson successfully");

                            finish();


                        }, throwable -> {
                            SLToast.error("Remove failed, try again later");
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );


    }


    public ObservableList<StudentUpcomingMultiItemViewModel> lessonDataList = new ObservableArrayList<>();

    //    public ItemBinding<StudentUpcomingItemVM> itemLessonBinding =
//            ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemLessonViewModel, R.layout.item_student_upcoming));
    //给RecyclerView添加ItemBinding
    public ItemBinding<StudentUpcomingMultiItemViewModel> itemLessonBinding =
            ItemBinding.of((itemBinding, position, item) -> {
                //通过item的类型, 动态设置Item加载的布局
                switch (item.type) {
                    case UPCOMING:
                        itemBinding.set(BR.itemLessonViewModel, R.layout.item_student_upcoming);
                        break;
                    case STUDIO_EVENT:
                        itemBinding.set(BR.viewModel, R.layout.item_studio_event_list_by_student_upcoming);
                        break;
                }
            });


    public UIEventObservable uc = new UIEventObservable();

    public void toDetails(LessonScheduleEntity data) {
        Bundle bundle = new Bundle();
        bundle.putSerializable("data", data);
        if (teacherData != null) {
            data.setTeacherName(teacherData.getName());
        }
        startActivity(StudentLessonDetailActivity.class, bundle);

    }


    public static class UIEventObservable {
        public SingleLiveEvent<Void> loadingComplete = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> clickDeleteLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> clickLessonCancel = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> clickAddTeacher = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> clickReAddTeacher = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> clickReschedule = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> addComplete = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddLesson = new SingleLiveEvent<>();

    }


    /**
     * item 点击展开收起
     *
     * @param id
     */
    public void clickExpandItem(String id) {
//        if (openIndex != -1 && pos != -1) {
//            StudentUpcomingItemVM item1 = (StudentUpcomingItemVM)lessonDataList.get(openIndex);
//            item1.isExpand.set(false);
//        }
//        openIndex = pos;
        if (!openId.equals("") && !id.equals("")) {
            int pos = -1;
            for (int i = 0; i < lessonDataList.size(); i++) {
                if (lessonDataList.get(i).lessonData != null && lessonDataList.get(i).lessonData.getId().equals(openId)) {
                    pos = i;
                    break;
                }
            }
            if (pos != -1) {
                StudentUpcomingItemVM item1 = (StudentUpcomingItemVM) lessonDataList.get(pos);
                item1.isExpand.set(false);
            }
        }
        openId = id;

    }

    /**
     * 点击 正在Reschedule 中的item
     *
     * @param pos
     */
    public void clickRescheduleItem(int pos) {

    }

    public void clickItemLeftButton(LessonScheduleEntity data, int pos) {
        if (studentData.getStudioId().equals("") && (studentData.getTeacherId().equals("") || studentData.getStudentApplyStatus() == 1)) {
            uc.clickDeleteLesson.setValue(data);
        } else {
            uc.clickLessonCancel.setValue(data);
        }
    }

    public void clickItemRightButton(LessonScheduleEntity data, int pos) {
        if (studentData.getStudioId().equals("") && (studentData.getTeacherId().equals("") || studentData.getStudentApplyStatus() == 1)) {
            if (studentData.getStudentApplyStatus() == 1) {
                showDialog();
                getOnlyTeacherData();
            } else {
                uc.clickAddTeacher.setValue(data);
            }
        } else {
            uc.clickReschedule.setValue(data);

        }
    }

    public void clickItemCenterButton(LessonScheduleEntity data, int pos) {
        uc.clickReschedule.setValue(data);
    }

    public void joinGroupLesson(String configId){
        showDialog();
        addSubscribe(
                        TKApi.joinGroupLesson(configId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(),true)
                        .subscribe(d -> {
                            dismissDialog();
                            SLToast.success("Join successfully!");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }
}
