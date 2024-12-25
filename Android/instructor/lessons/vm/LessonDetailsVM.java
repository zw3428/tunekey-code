package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;
import androidx.recyclerview.widget.GridLayoutManager;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Source;
import com.google.firebase.functions.FirebaseFunctions;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;

import com.spelist.tunekey.api.network.MaterialService;

import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;

import com.spelist.tunekey.api.network.TKApi;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.dialog.studioAddLesson.StudioAddLessonHost;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.LessonCancellationEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleExEntity;
import com.spelist.tunekey.entity.LessonScheduleMaterialEntity;
import com.spelist.tunekey.entity.LessonSchedulePlanEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.ui.balance.BalanceListAc;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.studentList.StudentListAc;
import com.spelist.tunekey.ui.studio.team.teamHome.student.detail.StudioStudentDetailAc;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsHistoryAc;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsHistoryVM;
import com.spelist.tunekey.ui.teacher.materials.activity.MaterialsActivity;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsFolderViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsGridVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsLinkVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.ui.teacher.students.activity.AchievementActivity;
import com.spelist.tunekey.ui.teacher.students.activity.NotesActivity;
import com.spelist.tunekey.ui.teacher.students.activity.PracticeActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TKUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.text.Collator;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.goldze.mvvmhabit.utils.SnowFlakeShortUrl;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/18
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LessonDetailsVM extends ToolbarViewModel {
    public ObservableField<Boolean> isShowButton = new ObservableField<>(true);
    public ObservableField<Boolean> isGroupLesson = new ObservableField<>(false);

    public ObservableField<String> buttonText = new ObservableField<>("START LESSON");
    public ObservableField<String> lessonInfoString = new ObservableField<>("");
    public ObservableField<List<LessonScheduleEntity>> data = new ObservableField<>();
    public MutableLiveData<Integer> selectIndex = new MutableLiveData<>(0);
    public MutableLiveData<String> titleString = new MutableLiveData<>("");
    public MutableLiveData<LessonScheduleEntity> selectData = new MutableLiveData<>(new LessonScheduleEntity());
    public List<TKPractice> lastLessonPractices = new ArrayList<>();
    public LessonScheduleEntity nextLessonData;

    public ObservableField<String> lastLessonSelfStudyString = new ObservableField<>("0 hrs");
    public ObservableField<String> lastLessonHomeworkString = new ObservableField<>("No assignment");

    public ObservableField<Boolean> isShowTeacherNotes = new ObservableField<>(false);
    public ObservableField<Boolean> isShowTeacherToParentNotes = new ObservableField<>(false);

    public ObservableField<Boolean> isShowStudentNotes = new ObservableField<>(false);

    public ObservableField<GridLayoutManager> gridLayoutManager = new ObservableField<>();
    public MutableLiveData<List<MaterialEntity>> materialsData = new MutableLiveData<>(new ArrayList<>());
    public List<LessonScheduleMaterialEntity> lessonMaterialsData = new ArrayList<>();
    public ObservableField<Boolean> isShowNextLessonPlan = new ObservableField<>(true);
    public ObservableField<Boolean> isShowCountDownView = new ObservableField(false);

    public boolean isFromStudio = false;
    public LessonScheduleEntity nowLesson;
    public List<TKPractice> lastLessonHomeworks = new ArrayList<>();
    public ObservableField<Boolean> isShowCopyLastHomework = new ObservableField<>(false);
    public ObservableField<Boolean> isShowCopyThisPlan = new ObservableField<>(false);
    public ObservableField<String> memo = new ObservableField<>("");
    public ObservableField<Boolean> isShowMemo = new ObservableField<>(false);

    private List<LessonTypeEntity> allLessonType = new ArrayList<>();
    public boolean isSureRescheduleAndCancel = false;
    public ObservableField<Boolean> isShowActionButton = new ObservableField<>(true);

    public boolean isCanReschedule = true;
    public boolean isCanCancelLesson = true;

    public ObservableField<Boolean> isShowAttendanceButton = new ObservableField<>(false);
    public ObservableField<String> attendanceString = new ObservableField<>("");
    public ObservableField<String> attendanceButtonString = new ObservableField<>("Report Attendance");
    public ObservableField<Boolean> isShowAttendance = new ObservableField<>(false);
    public boolean isHaveNoshow = false;

    public ObservableField<Boolean> isShowLessonPlanHistory = new ObservableField<>(false);
    public ObservableField<Boolean> isShowNoteHistory = new ObservableField<>(false);
    public ObservableField<Boolean> isShowHomeworkHistory = new ObservableField<>(false);
    public ObservableField<Boolean> isShowAwardHistory = new ObservableField<>(false);
    public ObservableField<Boolean> isShowMaterilasHistory = new ObservableField<>(false);


    public LessonDetailsVM(@NonNull Application application) {
        super(application);
    }

    @SuppressLint("ResourceType")
    @Override
    public void initToolbar() {
        setNormalToolbar("");
        setRightFirstImgVisibility(View.VISIBLE);
        setRightFirstImgIcon(R.mipmap.ic_more_vertical);
//        setRightButtonText("Reschedule");
//        setRightButtonVisibility(View.VISIBLE);
    }


    /***************************开始-- 点击事件相关 --开始*********************/
    public UIEventObservable uc = new UIEventObservable();


    public static class UIEventObservable {
        public SingleLiveEvent<Void> clickAddLessonPlan = new SingleLiveEvent<>();
        public SingleLiveEvent<Map<String, Object>> clickEditLessonPlan = new SingleLiveEvent<>();
        public SingleLiveEvent<String> showShareLesson = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> clickEditNotes = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddNotes = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickNoShow = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> clickAddMaterials = new SingleLiveEvent<>();
        public SingleLiveEvent<Map<String, Object>> clickMaterialItem = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddAchievement = new SingleLiveEvent<>();
        public SingleLiveEvent<AchievementEntity> clickAchievementItem = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddHomework = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> clickEditHomework = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddNextPlan = new SingleLiveEvent<>();
        public SingleLiveEvent<LessonScheduleEntity> nowLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickMore = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> attendanceDone = new SingleLiveEvent<>();

    }

    @Override
    protected void clickRightFirstImgButton() {
        super.clickRightFirstImgButton();
        uc.clickMore.call();
    }

    public void toStudentBalance() {
        showDialog();

//        getLessonType(true);
        getLessonType(false);
    }

    /**
     * 获取Lesson type
     */
    private void getLessonType(boolean isCache) {
        addSubscribe(UserService.getStudioInstance().getLessonTypeListByTeacherId(selectData.getValue().getTeacherId(), isCache).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(value -> {
            allLessonType.clear();
            allLessonType.addAll(value);
            Logger.e("获取到的Lesson type 个数:%s", allLessonType.size());
            getScheduleConfig(isCache);
        }, throwable -> {
            Logger.e("=====getLessonType=" + throwable.getMessage());
        }));
    }

    /**
     * 获取课程详细信息
     */
    private void getScheduleConfig(boolean isCache) {

        addSubscribe(LessonService.getInstance().getScheduleConfigByStudentIdAndNoDelete(selectData.getValue().getStudentId(), selectData.getValue().getTeacherId(), isCache).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {

            List<LessonScheduleConfigEntity> data = new ArrayList<>();
            for (LessonScheduleConfigEntity item : d) {
                for (LessonTypeEntity lessonTypeEntity : allLessonType) {
                    if (item.getLessonTypeId().equals(lessonTypeEntity.getId())) {
                        item.setLessonType(lessonTypeEntity);

                    }
                }
                if (item.getLessonType() != null) {
                    data.add(item);
                }
            }
            try {
                data.sort((o1, o2) -> (Integer.parseInt(o2.getCreateTime())) - Integer.parseInt(o1.getCreateTime()));
            } catch (Throwable e) {
                Logger.e("排序失败==>%s", e.getMessage());
            }
            StudentListEntity studentData = selectData.getValue().getStudentData();
            if (studentData == null) {
                for (StudentListEntity studentListEntity : ListenerService.shared.teacherData.getStudentList()) {
                    if (selectData.getValue().getStudentId().equals(studentListEntity.getStudentId())) {
                        studentData = studentListEntity;
                    }
                }
            }

            Bundle bundle = new Bundle();
            bundle.putSerializable("studentData", studentData);
            bundle.putSerializable("lessonConfigs", (Serializable) data);
            bundle.putSerializable("role", 1);
            startActivity(BalanceListAc.class, bundle);
            dismissDialog();
        }, throwable -> {
            dismissDialog();
            SLToast.showError();
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }


    /**
     * 点击添加Practice
     */
    public BindingCommand clickPractice = new BindingCommand(() -> {
        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            List<String> ids = new ArrayList<>();

            for (Map.Entry<String, LessonScheduleConfigEntity.GroupLessonStudent> entry : selectData.getValue().getGroupLessonStudents().entrySet()) {
                LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(entry.getValue()), LessonScheduleConfigEntity.GroupLessonStudent.class);
                if (value.getRegistrationTimestamp() <= selectData.getValue().getShouldDateTime()) {
                    ids.add(entry.getKey());
                }
            }
            Bundle bundle = new Bundle();
            bundle.putSerializable("studentIds", (Serializable) ids);
            bundle.putSerializable("lessonData", (Serializable) selectData.getValue());
            bundle.putSerializable("lastLessonData", (Serializable) selectData.getValue());

            bundle.putSerializable("practiceData", (Serializable) lastLessonPractices);

            startActivity(StudentListAc.class, bundle);
        } else {
            Bundle bundle = new Bundle();
            bundle.putSerializable("data", (Serializable) lastLessonPractices);
            bundle.putSerializable("lessonData", (Serializable) selectData.getValue());
            startActivity(PracticeActivity.class, bundle);
        }

    });

    /**
     * 点击添加Lesson plan
     */
    public BindingCommand clickAddLessonPlan = new BindingCommand(() -> uc.clickAddLessonPlan.call());

    /**
     * 点击添加Notes
     */
    public BindingCommand clickAddNotes = new BindingCommand(() -> uc.clickAddNotes.call());
    /**
     * 点击NoShow
     */
    public BindingCommand clickNoShow = new BindingCommand(() -> {
//        if (isHaveNoshow) {
//            removeNoShow();
//        } else {
//            uc.clickNoShow.call();
//        }
        uc.clickNoShow.call();

    });

    /**
     * 点击修改Notes
     */
    public BindingCommand clickEditNote = new BindingCommand(() -> uc.clickEditNotes.call());

    /**
     * 点击添加Material
     */
    public BindingCommand clickAddMaterial = new BindingCommand(() -> uc.clickAddMaterials.call());

    /**
     * 点击添加Achievement
     */
    public BindingCommand clickAddAchievement = new BindingCommand(() -> uc.clickAddAchievement.call());

    /**
     * 点击添加NextLessonPlan
     */
    public BindingCommand clickAddNextLessonPlan = new BindingCommand(() -> uc.clickAddNextPlan.call());

    public BindingCommand clickAddHomework = new BindingCommand(() -> uc.clickAddHomework.call());

    public BindingCommand clickLessonPlanHistory = new BindingCommand(() -> {
        getLessonPlanHistory(300, true, false);
    });
    public BindingCommand clickNoteHistory = new BindingCommand(() -> {
        Bundle bundle = new Bundle();
        bundle.putString("studentId", selectData.getValue().getStudentId());
//            bundle.putSerializable("data", (Serializable) noteLessonData);
        startActivity(NotesActivity.class, bundle);
    });
    public BindingCommand clickHomeworkHistory = new BindingCommand(() -> {
        getHomeWorkHistory(300, true);

    });
    public BindingCommand clickMaterialsHistory = new BindingCommand(() -> {
        getMaterials(300, true);
    });
    public BindingCommand clickAwardHistory = new BindingCommand(() -> {
        getAwardHistory(300, true);
    });
    public BindingCommand clickNextLessonPlanHistory = new BindingCommand(() -> {
        getLessonPlanHistory(300, true, true);

    });


    /**
     * 点击复制上一节课的homework
     */
    public BindingCommand clickCopyHomework = new BindingCommand(() -> {
        List<String> s = new ArrayList<>();
        for (TKPractice lastLessonHomework : lastLessonHomeworks) {
            s.add(lastLessonHomework.getName());
        }
        addHomeworks(s);
    });

    /**
     * 点击复制上一节课的lessonPlan
     */
    public BindingCommand clickCopyThisPlan = new BindingCommand(() -> addNextLessonTypes());


    /**
     * 点击MaterialsItem
     *
     * @param materialEntity
     * @param view
     */
    public void clickMaterialsItem(MaterialEntity materialEntity, View view) {
        Map<String, Object> map = new HashMap<>();
        map.put("data", materialEntity);
        map.put("view", view);
        uc.clickMaterialItem.setValue(map);
    }

    /**
     * 点击Achievement item
     *
     * @param achievementEntity
     */
    public void clickAchievementItem(AchievementEntity achievementEntity) {
        uc.clickAchievementItem.setValue(achievementEntity);
    }

    /**
     * 点击底部button
     */
    public TKButton.ClickListener clickBottomButton = tkButton -> {
        if (selectData.getValue() != null) {
            if (selectData.getValue().getLessonStatus() == 0) {
                selectData.getValue().setLessonStatus(1);
                buttonText.set("FINISH LESSON");
                isShowButton.set(true);

            } else if (selectData.getValue().getLessonStatus() == 1) {
                selectData.getValue().setLessonStatus(2);
                isShowButton.set(false);
            }

            selectData.setValue(selectData.getValue());
            if (selectData.getValue().isRescheduled() || selectData.getValue().isCancelled() || selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
                isShowAttendanceButton.set(false);
                isShowAttendance.set(false);
            } else {
                isShowAttendanceButton.set(true);
                isShowAttendance.set(true);
            }
            int index = selectIndex.getValue();
            data.get().get(index).setLessonStatus(selectData.getValue().getLessonStatus());
            Map<String, Object> map = new HashMap<>();
            map.put("lessonStatus", selectData.getValue().getLessonStatus());
            addSubscribe(UserService.getStudioInstance().updateNotes(selectData.getValue().getId(), map).subscribe(status -> {
                AppDataBase.getInstance().lessonDao().insert(data.get().get(index));
                Logger.e("=====更新lessonStatus成功=");
                TKApi.updateLessonVersion(selectData.getValue().getId());
            }, throwable -> {
                Logger.e("=====更新lessonStatus失败=" + throwable.getMessage());
            }));
            getData();
        }
    };

    /**
     * 点击修改Plan
     *
     * @param id
     * @param plan
     */
    public void clickEditPlan(String id, String plan, boolean isNextLessonPlan) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", id);
        map.put("plan", plan);
        map.put("type", isNextLessonPlan ? 3 : 1);
        uc.clickEditLessonPlan.setValue(map);
    }

    /**
     * 点击修改Homework
     *
     * @param practice
     */
    public void clickEditHomework(TKPractice practice) {
        uc.clickEditHomework.setValue(practice);
    }

    /**
     * 点击学生item
     */
    public void clickStudent() {
        Bundle bundle = new Bundle();
        bundle.putSerializable("data", selectData.getValue().getStudentData());
        startActivity(StudioStudentDetailAc.class, bundle);
    }

    public void clickGroupStudent() {
        List<String> ids = new ArrayList<>();

        for (Map.Entry<String, LessonScheduleConfigEntity.GroupLessonStudent> entry : selectData.getValue().getGroupLessonStudents().entrySet()) {
            LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(entry.getValue()), LessonScheduleConfigEntity.GroupLessonStudent.class);
            if (value.getRegistrationTimestamp() <= selectData.getValue().getShouldDateTime()) {
                ids.add(entry.getKey());
            }
        }
        Bundle bundle = new Bundle();
        bundle.putSerializable("studentIds", (Serializable) ids);
        startActivity(StudentListAc.class, bundle);
    }

    public void clickCancelLessonByAllLessonAndThisAndUpcomingLesson(String text, LessonScheduleConfigEntity configEntity, LessonScheduleEntity lesson) {
        String type = "";
        if (text.equals("This & following lessons")) {
            type = "THIS_AND_FOLLOWING_LESSONS";
        } else {
            type = "ALL_LESSONS";
        }
        Map<String, Object> data = new HashMap<>();
        data.put("cancelType", type);
        data.put("scheduleConfigId", configEntity.getId());
        data.put("selectedLessonScheduleId", lesson.getId());
        showDialog();

        FirebaseFunctions.getInstance().getHttpsCallable("lessonService-cancelLessonsWithType").call(data).addOnCompleteListener(task -> {

            dismissDialog();
            if (task.getException() == null) {
                SLToast.success("Successfully!");
                lesson.setCancelled(true);
                AppDataBase.getInstance().lessonDao().insert(lesson);
                Messenger.getDefault().sendNoMsg(MessengerUtils.SEND_RESCHEDULE_SUCCESS);
                Messenger.getDefault().send(configEntity, MessengerUtils.REFRESH_LESSON);
                finish();
            } else {
                SLToast.error("Please check your connection and try again.");
                Logger.e("失败==>%s", task.getException().getMessage());
            }
        });


    }

    public void clickCancelLessonByAllLessonAndThisAndUpcomingLessonV2(String text, LessonScheduleEntity lesson) {
        String type = "";
        if (text.equals("This & following lessons")) {
            type = "CURRENT_AND_FOLLOWING";
        } else {
            type = "ALL";
        }

        showDialog();
        addSubscribe(TKApi.INSTANCE.cancelLesson(lesson, type).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            finish();
            SLToast.success("Successfully cancelled!");
        }, throwable -> {
            dismissDialog();
            SLToast.error("Cancellation failed, please try again!");
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }

    public void clickThisCancelLessonV2() {

        showDialog();
        addSubscribe(TKApi.INSTANCE.cancelLesson(selectData.getValue(), "CURRENT").subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            finish();
//                            SLToast.success("Successfully cancelled!");
        }, throwable -> {
            dismissDialog();
            SLToast.error("Cancellation failed, please try again!");
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }
    public void clickGroupCancelLesson(String type) {
        String t = "";
        if (type.equals("This lesson")){
            t = "THIS_LESSON";
        }else if (type.equals("This & following lessons")){
            t = "THIS_AND_FOLLOWING_LESSONS";
        }else {
            t = "ALL_LESSONS";
        }

        showDialog();
        addSubscribe(TKApi.INSTANCE.cancelGroupLesson(selectData.getValue(), t).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            finish();
//                            SLToast.success("Successfully cancelled!");
        }, throwable -> {
            dismissDialog();
            SLToast.error("Cancellation failed, please try again!");
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }

    public void clickCancelLesson() {
        List<LessonScheduleEntity> lessons = CloneObjectUtils.cloneObject(data.get());
        int defIndex = -1;
        for (int i = 0; i < lessons.size(); i++) {
            if (lessons.get(i).getId().equals(selectData.getValue().getId())) {
                defIndex = i;
                break;
            }
        }
        if (defIndex == -1) {
            return;
        }
        LessonScheduleEntity lesson = lessons.get(defIndex);
        if (lesson.isCancelled()) {
            SLToast.warning("This lesson has been cancelled before!");
            return;
        }
        if (lesson.isRescheduled()) {
            SLToast.warning("This lesson has been rescheduled before!");
            return;
        }
        showDialog();
        String currentTimeString = TimeUtils.getCurrentTimeString();

        LessonCancellationEntity cancellationEntity = new LessonCancellationEntity().setId(lesson.getId()).setOldScheduleId(lesson.getId()).setType(-1).setStudentId(lesson.getStudentId()).setTeacherId(lesson.getTeacherId()).setTimeBefore(lesson.getShouldDateTime() + "").setCreateTime(currentTimeString).setUpdateTime(currentTimeString);
        addSubscribe(LessonService.getInstance().cancelScheduleFromTeacher(cancellationEntity).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            finish();
            SLToast.success("Successfully cancelled!");
        }, throwable -> {
            dismissDialog();
            SLToast.error("Cancellation failed, please try again!");
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));


    }

    public void clickReschedule() {
//        Bundle bundle = new Bundle();
//        List<LessonScheduleEntity> lessonScheduleEntities = CloneObjectUtils.cloneObject(data.get());
//        int currentTime = TimeUtils.getCurrentTime();
//        lessonScheduleEntities.removeIf(scheduleEntity -> {
//            if (scheduleEntity.getTKShouldDateTime() < currentTime || scheduleEntity.isRescheduled()) {
//                return true;
//            } else {
//                return false;
//            }
//        });
//        int defIndex = 0;
//        for (int i = 0; i < lessonScheduleEntities.size(); i++) {
//            if (lessonScheduleEntities.get(i).getId().equals(selectData.getValue().getId())) {
//                defIndex = i;
//                break;
//            }
//        }
//        bundle.putSerializable("data", (Serializable) lessonScheduleEntities);
//        if (selectIndex.getValue() != null) {
//            bundle.putInt("defSelect", defIndex);
//        }
//        startActivity(RescheduleByTeacherAc.class, bundle);
    }

    public void sentRescheduleByGroup(String message, LessonScheduleEntity oldData, StudioAddLessonHost.SelectTimeLocationData newData) {
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
        if (location != null && !location.getId().equals("SetLater")) {
            newLocation = SLJsonUtils.toMaps(SLJsonUtils.toJsonString(location));
        }
        String finalNewTeacherId = newTeacherId;
        TKLocation finalLocation = location;
        int diff = 0;
        if (oldData.getConfigEntity() != null) {
            diff = TimeUtils.getRescheduleDiff(oldData.getConfigEntity().startDateTime, (int) newData.getSelectedTimestamp());
        } else {
            LessonScheduleConfigEntity collect = AppDataBase.getInstance().lessonConfigDao().getById(oldData.getLessonScheduleConfigId());

            if (collect != null) {
                diff = TimeUtils.getRescheduleDiff(collect.getStartDateTime(), (int) newData.getSelectedTimestamp());
            }
        }
        long selectedTimestamp = newData.getSelectedTimestamp();
        selectedTimestamp = selectedTimestamp + (diff * 3600);
        long finalSelectedTimestamp = selectedTimestamp;
        addSubscribe(TKApi.INSTANCE.rescheduleGroupLesson(oldData.getStudioId(), selectedTimestamp, newLocation, newTeacherId, oldData.getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
//            if (confirmImmediately) {
                LessonScheduleEntity newLesson = CloneObjectUtils.cloneObject(oldData);
                newLesson.setCreateTime(TimeUtils.getCurrentTimeString());
                newLesson.setUpdateTime(TimeUtils.getCurrentTimeString());
                newLesson.setUpdateTimestamp(TimeUtils.getCurrentTime());
                newLesson.setCreateTimestamp(TimeUtils.getCurrentTime());
                if (!finalNewTeacherId.equals("")) {
                    newLesson.setTeacherId(finalNewTeacherId);
                }
                if (finalLocation != null && !finalLocation.getId().equals("SetLater")) {
                    newLesson.setLocation(finalLocation);
                }

                newLesson.setShouldDateTime(finalSelectedTimestamp);
                newLesson.setId(newLesson.getStudioId() + ":" + newLesson.getLessonScheduleConfigId() + ":" + newLesson.getShouldDateTime());
                oldData.setRescheduleId(newLesson.getId());
                oldData.setRescheduled(true);
                List<LessonScheduleEntity> data = new ArrayList<>();
                data.add(oldData);
                data.add(newLesson);
                new Thread(() -> AppDataBase.getInstance().lessonDao().insertAll(data)).start();
//
//            } else {
//                oldData.setRescheduled(true);
//                new Thread(() -> AppDataBase.getInstance().lessonDao().insert(oldData)).start();
//            }

            dismissDialog();
//                            SLToast.success("Rescheduled successfully!");
            finish();
        }, throwable -> {
            Logger.e("失败,失败原因" + throwable.getMessage());
            dismissDialog();

            SLToast.showError();
        }));
    }


    public void sentRescheduleV2(String message, LessonScheduleEntity oldData, StudioAddLessonHost.SelectTimeLocationData newData, boolean confirmImmediately) {
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
        if (location != null && !location.getId().equals("SetLater")) {
            newLocation = SLJsonUtils.toMaps(SLJsonUtils.toJsonString(location));
        }
        String finalNewTeacherId = newTeacherId;
        TKLocation finalLocation = location;
        int diff = 0;
        if (oldData.getConfigEntity() != null) {
            diff = TimeUtils.getRescheduleDiff(oldData.getConfigEntity().startDateTime, (int) newData.getSelectedTimestamp());
        } else {
            LessonScheduleConfigEntity collect = AppDataBase.getInstance().lessonConfigDao().getById(oldData.getLessonScheduleConfigId());

            if (collect != null) {
                diff = TimeUtils.getRescheduleDiff(collect.getStartDateTime(), (int) newData.getSelectedTimestamp());
            }
        }
        long selectedTimestamp = newData.getSelectedTimestamp();
        selectedTimestamp = selectedTimestamp + (diff * 3600);
        long finalSelectedTimestamp = selectedTimestamp;
        addSubscribe(TKApi.INSTANCE.reschedule(oldData.getStudioId(), oldData.getSubStudioId(), selectedTimestamp, newLocation, newTeacherId, oldData.getId(), confirmImmediately).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            if (confirmImmediately) {
                LessonScheduleEntity newLesson = CloneObjectUtils.cloneObject(oldData);
                newLesson.setCreateTime(TimeUtils.getCurrentTimeString());
                newLesson.setUpdateTime(TimeUtils.getCurrentTimeString());
                newLesson.setUpdateTimestamp(TimeUtils.getCurrentTime());
                newLesson.setCreateTimestamp(TimeUtils.getCurrentTime());
                if (!finalNewTeacherId.equals("")) {
                    newLesson.setTeacherId(finalNewTeacherId);
                }
                if (finalLocation != null && !finalLocation.getId().equals("SetLater")) {
                    newLesson.setLocation(finalLocation);
                }

                newLesson.setShouldDateTime(finalSelectedTimestamp);
                newLesson.setId(newLesson.getStudioId() + ":" + newLesson.getStudentId() + ":" + newLesson.getShouldDateTime());
                oldData.setRescheduleId(newLesson.getId());
                oldData.setRescheduled(true);
                List<LessonScheduleEntity> data = new ArrayList<>();
                data.add(oldData);
                data.add(newLesson);
                new Thread(() -> AppDataBase.getInstance().lessonDao().insertAll(data)).start();

            } else {
                oldData.setRescheduled(true);
                new Thread(() -> AppDataBase.getInstance().lessonDao().insert(oldData)).start();
            }

            dismissDialog();
//                            SLToast.success("Rescheduled successfully!");
            finish();
        }, throwable -> {
            Logger.e("失败,失败原因" + throwable.getMessage());
            dismissDialog();

            SLToast.showError();
        }));
    }


    @Override
    protected void clickRightTextButton() {
        super.clickRightTextButton();
//        clickReschedule();
    }

    /***************************结束-- 点击事件相关 --结束*********************/


    /***************************开始-- 数据相关 --开始*********************/
    public void initData() {
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            TKRoleAndAccess data = TKRoleAndAccess.getData();
            if (data != null) {
                isCanReschedule = data.getAllowRescheduleLesson() && data.getAllowRescheduleLesson4Request();
                isCanCancelLesson = data.getAllowCancelLesson() && data.getAllowCancelLesson4Request();
            }
        }

//        for (int i = 0; i < data.get().size(); i++) {
//            LessonBeforeItemViewModel item = new LessonBeforeItemViewModel(this,
//                    data.get().get(i), i, i != data.get().size() - 1);
//            observableList.add(item);
//        }
//        lessonInfoString.set(TimeUtils.timeFormat(data.get().get(0).getTKShouldDateTime(), "hh:mm a, MMM dd") + " - " + data.get().get(0).getLessonStatusString());
        lessonInfoString.set(data.get().get(0).getLessonStatusString());

    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, "historyLessonPlan", ArrayList.class, data -> {
            for (String d : (ArrayList<String>) data) {
                addLessonPlan(1, d);
            }
        });
        Messenger.getDefault().register(this, "historyNextLessonPlan", ArrayList.class, data -> {
            for (String d : (ArrayList<String>) data) {
                addLessonPlan(3, d);
            }
        });
        Messenger.getDefault().register(this, "historyHomework", ArrayList.class, data -> {
            addHomeworks((ArrayList<String>) data);
        });

        Messenger.getDefault().register(this, "updateLessonNote", LessonScheduleEntity.class, data -> {
            upDateNotes(data.teacherNote,data.teacherToParentNote);
        });

        Messenger.getDefault().register(this, MessengerUtils.REFRESH_NOW_LESSON, LessonScheduleEntity.class, lessonScheduleEntity -> {
            if (lessonScheduleEntity.getId().equals("-999")) {
                nowLesson = null;
            } else {
                nowLesson = lessonScheduleEntity;
            }
            checkClassNow();
        });
        Messenger.getDefault().register(this, MessengerUtils.SHOW_COUNT_DOWN_VIEW, this::checkClassNow);

        Messenger.getDefault().register(this, MessengerUtils.SELECT_MATERIALS, String.class, s -> {
            shareMaterials(s, true);
        });
        Messenger.getDefault().register(this, MessengerUtils.SELECT_MATERIALS_SILENTLY, String.class, s -> {
            shareMaterials(s, false);
        });
        Messenger.getDefault().register(this, MessengerUtils.SEND_RESCHEDULE_SUCCESS, () -> {
            finish();
//            Handler handler = new Handler();
//            handler.postDelayed(new Runnable() {
//                @Override
//                public void run() {
//                    /**
//                     *要执行的操作
//                     */
//
//                }
//            }, 500);//3

        });
    }

    private void shareMaterials(String s, boolean isSendEmail) {
        List<MaterialEntity> materialsData = SLJsonUtils.toList(s, MaterialEntity.class);
        List<LessonScheduleMaterialEntity> deleteData = new ArrayList<>();
        for (LessonScheduleMaterialEntity oldData : lessonMaterialsData) {
            boolean isHave = false;
            for (MaterialEntity newData : materialsData) {
                if (oldData.getMaterialId().equals(newData.getId())) {
                    isHave = true;
                    break;
                }
            }
            if (!isHave) {
                deleteData.add(oldData);
            }
        }
        addSubscribe(
                LessonService.getInstance().addLessonScheduleMaterialAndDelete(
                                selectData.getValue(), materialsData, deleteData, isSendEmail)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("======%s", "添加materials 成功");
                        }, throwable -> {
                            Logger.e("======%s", "添加materials 失败" + throwable.getMessage());

                        })

        );


        materialsList.clear();
        materialsData.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
        List<MaterialEntity> teacherMaterials = ListenerService.shared.teacherData.getHomeMaterials();
        this.materialsData.setValue(materialsData);
        List<String> folderIds = new ArrayList<>();
        for (MaterialEntity material : materialsData) {
            if (material.getType() == -2) {
                folderIds.add(material.getId());
            }
        }
        for (MaterialEntity material : materialsData) {
//                        List<MaterialEntity> homeData = new ArrayList<>();
//                                    if (material.getFolder().equals("") ||  !material.getFolder().equals("")) {
//                        homeData.add(material);
            MaterialsMultiItemViewModel<LessonDetailsVM> item;
            if (material.getType() == MaterialEntity.Type.folder) {
                item = new MaterialsFolderViewModel<>(this, material);
                MaterialsFolderViewModel<LessonDetailsVM> folderItem = (MaterialsFolderViewModel<LessonDetailsVM>) item;
                folderItem.setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
            } else if (material.getType() == MaterialEntity.Type.youtube) {
                item = new MaterialsLinkVMV2<>(this, material);
            } else {
                item = new MaterialsGridVMV2<>(this, material);
            }
            item.isNotShowShare.set(true);
            item.isShowMoreButton.set(false);
            materialsList.add(item);
        }
    }


    /**
     * 左右切换课程
     */
    public void changePage() {
        if (data.get() == null) {
            return;
        }
        int index = selectIndex.getValue();
        if (data.get().get(index).getLessonStatus() == 0) {
            buttonText.set("START LESSON");
            isShowButton.set(true);
//            if (data.get().get(index).isRescheduled()||data.get().get(index).isCancelled()){
//                setRightButtonVisibility(View.GONE);
//            }else {
//                setRightButtonVisibility(View.VISIBLE);
//            }
            isShowAttendanceButton.set(false);
            isShowAttendance.set(false);

        } else if (data.get().get(index).getLessonStatus() == 1) {
            buttonText.set("FINISH LESSON");
            isShowButton.set(true);
            isShowAttendanceButton.set(data.get().get(index).getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);
            isShowAttendance.set(data.get().get(index).getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);

//            setRightButtonVisibility(View.GONE);
        } else {
            buttonText.set("LESSON");
            isShowButton.set(false);
            isShowAttendanceButton.set(data.get().get(index).getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);
            isShowAttendance.set(data.get().get(index).getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);


//            setRightButtonVisibility(View.GONE);
        }
//        lessonInfoString.set(TimeUtils.timeFormat(data.get().get(index).getTKShouldDateTime(), "hh:mm a, MMM dd") + " - " + data.get().get(index).getLessonStatusString());
        lessonInfoString.set(data.get().get(index).getLessonStatusString());


        if (data.get().get(index).isRescheduled() || data.get().get(index).isCancelled() || data.get().get(index).getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            isShowAttendanceButton.set(false);
            isShowAttendance.set(false);

        }
        if (data.get().get(index).isRescheduled() || data.get().get(index).isCancelled() || data.get().get(index).getShouldDateTime() <= TimeUtils.getCurrentTime()) {
//            setRightButtonVisibility(View.GONE);
//            setRightFirstImgVisibility(View.GONE);
            isSureRescheduleAndCancel = false;
        } else {
//            setRightButtonVisibility(View.VISIBLE);
//            setRightFirstImgVisibility(View.VISIBLE);
            isSureRescheduleAndCancel = true;
        }
        selectData.setValue(data.get().get(index));
        titleString.setValue(TimeUtils.timeFormat(selectData.getValue().getTKShouldDateTime(), "hh:mm a, MMM d"));
        isGroupLesson.set(selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group);

        initShowMore();
        getData();
    }

    public void getData() {
        nextLessonData = null;
        lastLessonPractices.clear();
        lastLessonSelfStudyString.set("0 hrs");
        lastLessonHomeworkString.set("No assignment");
        lessonPlanList.clear();
        materialsList.clear();
        materialsData.setValue(new ArrayList<>());
        achievementList.clear();
        nextLessonPlanList.clear();
        homeworkList.clear();
        practiceList.clear();
        lastLessonHomeworks.clear();
        isShowCopyLastHomework.set(false);
        if (TKUtils.INSTANCE.currentUserIsStudio()) {

            if (selectData.getValue() != null && selectData.getValue().getTeacherId().equals(SLCacheUtil.getCurrentUserId())) {
                isShowActionButton.set(true);
            } else {
                isShowActionButton.set(false);
            }
        } else {
            isShowActionButton.set(true);
        }

        int index = selectIndex.getValue();
        if (selectData.getValue().getConfigEntity() != null && selectData.getValue().getConfigEntity().getMemo() != null && !selectData.getValue().getConfigEntity().getMemo().equals("")) {
            isShowMemo.set(true);
            memo.set(selectData.getValue().getConfigEntity().getMemo());
        } else {
            isShowMemo.set(false);
        }
//        if (selectData.getValue().getAttendance() != null && selectData.getValue().getAttendance().size() > 0) {
//            isShowAttendance.set(true);
//            StringBuilder attendanceS = new StringBuilder();
//            for (int i = 0; i < selectData.getValue().getAttendance().size(); i++) {
//                attendanceS.append("Attendance: ");
//                attendanceS.append(selectData.getValue().getAttendance().get(i).showString());
//                if (i != selectData.getValue().getAttendance().size() - 1) {
//                    attendanceS.append("\n");
//                }
//            }
//            isShowAttendance.set(true);
//            attendanceString.set(attendanceS.toString());
//        } else {
//            isShowAttendance.set(false);
//        }
        getPreAndNextData(index);
        getLessonPlan(index);
        getNoteData(index);
        getMaterialsData(index);
        getAchievement(index);
        getHomework(index);
        getFlowUp();
        getHistoryData();
    }

    private void getHistoryData() {
        isShowLessonPlanHistory.set(false);
        isShowNoteHistory.set(false);
        isShowHomeworkHistory.set(false);
        isShowAwardHistory.set(false);
        if (selectData.getValue() == null || selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            return;
        }
        getLessonPlanHistory(1, false, false);
        getNoteHistory(1, false);
        getHomeWorkHistory(1, false);
        getAwardHistory(1, false);
        getMaterials(1, false);
    }

    private void getLessonPlanHistory(int limit, boolean isToHistory, boolean isNext) {
        AtomicBoolean isLoad = new AtomicBoolean(false);
        addSubscribe(
                TKApi.getLessonPlanByTIdAndSId(limit, selectData.getValue().getStudentId(), selectData.getValue().getTeacherId(), selectData.getValue().getShouldDateTime())
                        .subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            List<LessonSchedulePlanEntity> cacheData = d.get(Source.CACHE);
                            List<LessonSchedulePlanEntity> serverData = d.get(Source.SERVER);
                            List<LessonSchedulePlanEntity> data = new ArrayList<>();
                            if (cacheData != null) {
                                data = cacheData;
                            }
                            if (serverData != null) {
                                data = serverData;
                            }
                            isShowLessonPlanHistory.set(data.size() > 0);
                            if (data.size() > 0 && isToHistory && !isLoad.get()) {
                                Map<String, List<LessonSchedulePlanEntity>> map = new HashMap<>();
                                List<LessonDetailsHistoryVM.Data> historyDatas = new ArrayList<>();
                                for (LessonSchedulePlanEntity item : data) {
                                    String time = TimeUtils.timeFormat(item.getShouldDateTime(), "MMM dd, yyyy");
                                    if (map.get(time) != null) {
                                        map.get(time).add(item);
                                    } else {
                                        List<LessonSchedulePlanEntity> list = new ArrayList<>();
                                        list.add(item);
                                        map.put(time, list);
                                    }
                                }
                                map.forEach((key, value) -> {
                                    LessonDetailsHistoryVM.Data historyData = new LessonDetailsHistoryVM.Data();
                                    historyData.setTime(key);
                                    historyData.setTimeStamp((int) (TimeUtils.timeToStamp(key, "MMM dd, yyyy") / 1000));
                                    List<LessonDetailsHistoryVM.Data.Content> contents = new ArrayList<>();
                                    for (LessonSchedulePlanEntity lessonSchedulePlanEntity : value) {
                                        LessonDetailsHistoryVM.Data.Content content = new LessonDetailsHistoryVM.Data.Content();
                                        content.setContent(lessonSchedulePlanEntity.getPlan());
                                        contents.add(content);
                                    }
                                    historyData.setContentList(contents);
                                    historyDatas.add(historyData);
                                });

                                Bundle bundle = new Bundle();
                                bundle.putSerializable("data", (Serializable) historyDatas);
                                if (isNext) {
                                    bundle.putString("type", "historyNextLessonPlan");
                                } else {
                                    bundle.putString("type", "historyLessonPlan");
                                }

                                startActivity(LessonDetailsHistoryAc.class, bundle);
                                isLoad.set(true);
                            }


                        }, throwable -> {
                            Logger.e("getHistoryData=>getLessonPlanHistory失败,失败原因" + throwable.getMessage());
                        }));
    }

    private void getNoteHistory(int limit, boolean isToHistory) {
        List<LessonScheduleEntity> d = TKApi.getNoteByTIdAndSId(limit, selectData.getValue().getStudentId(), selectData.getValue().getTeacherId(), selectData.getValue().getShouldDateTime());
        Logger.e("getHistoryData=>getNoteHistory成功", d.size());
        isShowNoteHistory.set(d.size() > 0);

    }

    private void getHomeWorkHistory(int limit, boolean isToHistory) {
        AtomicBoolean isLoad = new AtomicBoolean(false);

        addSubscribe(
                TKApi.getHomeworkByTIdAndSId(limit, selectData.getValue().getStudentId(), selectData.getValue().getTeacherId(), selectData.getValue().getShouldDateTime())
                        .subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            Logger.e("getHistoryData=>getHomeWorkHistory成功", d.size());
                            List<TKPractice> cacheData = d.get(Source.CACHE);
                            List<TKPractice> serverData = d.get(Source.SERVER);
                            List<TKPractice> data = new ArrayList<>();
                            if (cacheData != null) {
                                data = cacheData;
                            }
                            if (serverData != null) {
                                data = serverData;
                            }
                            isShowHomeworkHistory.set(data.size() > 0);
                            if (data.size() > 0 && isToHistory && !isLoad.get()) {
                                Map<String, List<TKPractice>> map = new HashMap<>();
                                List<LessonDetailsHistoryVM.Data> historyDatas = new ArrayList<>();
                                for (TKPractice item : data) {
                                    String time = TimeUtils.timeFormat(item.getShouldDateTime(), "MMM dd, yyyy");
                                    if (map.get(time) != null) {
                                        map.get(time).add(item);
                                    } else {
                                        List<TKPractice> list = new ArrayList<>();
                                        list.add(item);
                                        map.put(time, list);
                                    }
                                }
                                map.forEach((key, value) -> {
                                    LessonDetailsHistoryVM.Data historyData = new LessonDetailsHistoryVM.Data();
                                    historyData.setTime(key);
                                    historyData.setTimeStamp((int) (TimeUtils.timeToStamp(key, "MMM dd, yyyy") / 1000));
                                    List<LessonDetailsHistoryVM.Data.Content> contents = new ArrayList<>();
                                    for (TKPractice lessonSchedulePlanEntity : value) {
                                        LessonDetailsHistoryVM.Data.Content content = new LessonDetailsHistoryVM.Data.Content();
                                        content.setContent(lessonSchedulePlanEntity.getName());
                                        contents.add(content);
                                    }
                                    historyData.setContentList(contents);
                                    historyDatas.add(historyData);
                                });

                                Bundle bundle = new Bundle();
                                bundle.putSerializable("data", (Serializable) historyDatas);
                                bundle.putString("type", "historyHomework");
                                startActivity(LessonDetailsHistoryAc.class, bundle);
                                isLoad.set(true);
                            }

                        }, throwable -> {
                            Logger.e("getHistoryData=>getHomeWorkHistory失败,失败原因" + throwable.getMessage());
                        }));
    }

    private void getAwardHistory(int limit, boolean isToHistory) {
        AtomicBoolean isLoad = new AtomicBoolean(false);

        addSubscribe(
                TKApi.getAwardByTIdAndSId(limit, selectData.getValue().getStudentId(), selectData.getValue().getTeacherId(), selectData.getValue().getShouldDateTime())
                        .subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            Logger.e("getHistoryData=>getAwardHistory成功", d.size());
                            List<AchievementEntity> cacheData = d.get(Source.CACHE);
                            List<AchievementEntity> serverData = d.get(Source.SERVER);
                            List<AchievementEntity> data = new ArrayList<>();
                            if (cacheData != null) {
                                data = cacheData;
                            }
                            if (serverData != null) {
                                data = serverData;
                            }
                            isShowAwardHistory.set(data.size() > 0);
                            if (data.size() > 0 && isToHistory && !isLoad.get()) {
                                isLoad.set(true);

                                Bundle bundle = new Bundle();
                                bundle.putSerializable("data", (Serializable) data);
                                startActivity(AchievementActivity.class, bundle);
                            }

                        }, throwable -> {
                            Logger.e("getHistoryData=>getAwardHistory失败,失败原因" + throwable.getMessage());
                        }));
    }

    private void getMaterials(int limit, boolean isToHistory) {
        List<MaterialEntity> materials = AppDataBase.getInstance().materialDao().getForNoteNotEmptyAndStudioIdAndStudent(selectData.getValue().getStudioId(), selectData.getValue().getTeacherId(), selectData.getValue().getStudentId(), limit);
        isShowMaterilasHistory.set(materials.size() > 0);
        if (materials.size() > 0 && isToHistory) {
            List<MaterialEntity> materialsData = new ArrayList<>();
            List<MaterialEntity> teacherMaterials = AppDataBase.getInstance().materialDao().getByCreatorIdFromList(SLCacheUtil.getCurrentUserId());
            for (MaterialEntity teacherMaterial : teacherMaterials) {
                if (teacherMaterial.getStudentIds().contains(selectData.getValue().getStudentId())) {
                    if (materials.stream().noneMatch(it -> it.getId().equals(teacherMaterial.getId()))) {
                        materials.add(teacherMaterial);
                    }
                }
            }
            List<String> folderIds = new ArrayList<>();
            for (MaterialEntity material : materials) {
                if (material.getType() == -2) {
                    folderIds.add(material.getId());
                }
            }

            materials.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
            for (MaterialEntity material : materials) {


                if (material.getFolder().equals("") || (!material.getFolder().equals("") && !folderIds.contains(material.getFolder()))) {

//                                    if (material.getFolder().equals("") || (!folderIds.contains(material.getFolder()) && !material.getFolder().equals(""))) {
                    materialsData.add(material);

                }

            }


            Bundle bundle = new Bundle();
            bundle.putSerializable("data", (Serializable) materialsData);
            bundle.putString("type", "show");
            startActivity(MaterialsActivity.class, bundle);
        }

    }

    private void getFlowUp() {
        if (selectData.getValue() == null) {
            return;
        }

        Logger.e("selectData.getValue().getAttendance()==>%s", SLJsonUtils.toJsonString(selectData.getValue().getAttendance()));
        if (selectData.getValue().getAttendance().size() > 0) {
            StringBuilder attendanceS = new StringBuilder();
            attendanceS.append("Attendance: ");
            attendanceS.append(selectData.getValue().getAttendance().get(0).showString());
            attendanceString.set(attendanceS.toString());
            attendanceButtonString.set("Report Attendance");
        } else {
            isHaveNoshow = false;
            attendanceString.set("");
            attendanceButtonString.set("Report Attendance");
        }
//
//        List<TKFollowUp> followUpData = new ArrayList<>();
//        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
//            followUpData = CloneObjectUtils.cloneObject(ListenerService.shared.teacherData.getFollowUps());
//        } else {
//            followUpData = CloneObjectUtils.cloneObject(ListenerService.shared.studioData.getFollowUps());
//        }
//
//        try {
//
//                TKLessonNoShow noShow = null;
//                for (TKFollowUp item : followUpData) {
//                    if (item.getColumn().equals(TKFollowUp.Column.noshows)) {
//                        if (item.getNoShowData().getLessonScheduleId().equals(selectData.getValue().getId())) {
//                            noShow = item.getNoShowData();
//                            Logger.e("sdsdsdsdsdsdsd==>%s",item.getId());
//                        }
//                    }
//                }
//                Logger.e("==noShownoShow====%s", SLJsonUtils.toJsonString(noShow));
//                if (selectData.getValue().isRescheduled() ||selectData.getValue().isCancelled()|| selectData.getValue().getLessonStatus() == 0) {
//                    isShowAttendanceButton.set(false);
//                    isShowAttendance.set(false);
//                }else {
//                    isShowAttendanceButton.set(true);
//                    isShowAttendance.set(true);
//                }
//                if (noShow != null) {
//                    isHaveNoshow = true;
//                    StringBuilder attendanceS = new StringBuilder();
//                    attendanceS.append("Attendance: ");
//                    attendanceS.append(noShow.getNote());
//                    attendanceString.set(attendanceS.toString()+" "+TimeUtils.timeFormat((long) noShow.getCreateTime(),"hh:mma, MM/dd/yyyy"));
//                    attendanceButtonString.set("Report Attendance");
//                }else{
//                    isHaveNoshow = false;
//                    attendanceString.set("");
//                    attendanceButtonString.set("Report Attendance");
//                }
//
//
//        } catch (Exception e) {
//            Logger.e("Noshow 失败==>%s", e.getMessage());
//        }


    }

    /**
     * 获取上一节课的数据
     *
     * @param index
     */
    private void getPreAndNextData(int index) {


        String teacherId = selectData.getValue().getTeacherId();
        String studentId = selectData.getValue().getStudentId();
        int time = (int) selectData.getValue().getShouldDateTime();
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(LessonService.getInstance().getLastLessonByTIdAndSIdAndTime(selectData.getValue().getLessonScheduleConfigId(), time).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
            if (index == selectIndex.getValue()) {
//                                Logger.e("获取到的上一节课的数据======%s", SLJsonUtils.toJsonString(data));
                selectData.getValue().setLastLessonData(data);
                getLastLessonPractice(data, index);
            }

        }, throwable -> {
            Logger.e("失败,失败原因" + throwable.getMessage());

        }));
        addSubscribe(LessonService.getInstance().getNextLessonByTIdAndSIdAndTime(teacherId, studentId, time).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
            if (index == selectIndex.getValue()) {
                nextLessonData = data;

                isShowNextLessonPlan.set(true);
                getNextLessonPlanData(data, index);
            }

        }, throwable -> {
            isShowNextLessonPlan.set(false);
            Logger.e("获取到的下一节课的数据 失败" + throwable.getMessage());
        }));
    }


    /**
     * 获取上一节课的Practice数据
     *
     * @param lessonData
     * @param index
     */
    @SuppressLint("DefaultLocale")
    public void getLastLessonPractice(LessonScheduleEntity lessonData, int index) {
        if (selectData.getValue() == null) {
            return;
        }
        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            AtomicBoolean isSuccess = new AtomicBoolean(false);
            List<String> ids = new ArrayList<>();

            for (Map.Entry<String, LessonScheduleConfigEntity.GroupLessonStudent> entry : selectData.getValue().getGroupLessonStudents().entrySet()) {
                LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(entry.getValue()), LessonScheduleConfigEntity.GroupLessonStudent.class);
                if (value.getRegistrationTimestamp() <= selectData.getValue().getShouldDateTime()) {
                    ids.add(entry.getKey());
                }
            }
            addSubscribe(LessonService.getInstance().getPracticeByStartTimeAndEndTimeAndSIds(lessonData.getShouldDateTime(), selectData.getValue().getShouldDateTime(), ids).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
//                            Logger.e("data==>%s==%s", data.size(), SLJsonUtils.toJsonString(data));
                initPracticeData(lessonData, index, isSuccess, data);
            }, throwable -> {
                Logger.e("失败,失败原因" + throwable.getMessage());
            }));
        } else {
            AtomicBoolean isSuccess = new AtomicBoolean(false);
            addSubscribe(LessonService.getInstance().getPracticeByStartTimeAndEndTimeAndSId(lessonData.getShouldDateTime(), selectData.getValue().getShouldDateTime(), lessonData.getStudentId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
//                            Logger.e("data==>%s==%s", SLJsonUtils.toJsonString(data), lessonData.getTKShouldDateTime());
                initPracticeData(lessonData, index, isSuccess, data);
            }, throwable -> {
                Logger.e("失败,失败原因" + throwable.getMessage());
            }));
        }


    }

    private void initPracticeData(LessonScheduleEntity lessonData, int index, AtomicBoolean isSuccess, List<TKPractice> data) {
        if (index == selectIndex.getValue()) {
            if (!isSuccess.get()) {
                lastLessonPractices = data;

                double homeworkCount = 0;
                double homeworkDoneCount = 0;
                double practiceTotalTime = 0;
                for (TKPractice item : data) {
                    if (!item.isAssignment()) {
                        practiceTotalTime += item.getTotalTimeLength();
                    } else {
                        if (item.getShouldDateTime() == lessonData.getShouldDateTime()) {
                            boolean isAdd = true;
                            for (TKPractice lastLessonHomework : lastLessonHomeworks) {
                                if (lastLessonHomework.getName().equals(item.getName())) {
                                    isAdd = false;
                                    break;
                                }
                            }
                            if (isAdd) {
                                lastLessonHomeworks.add(item);
                            }
                            homeworkCount += 1;
                            if (item.isDone()) {
                                homeworkDoneCount += 1;
                            }
                        }
                    }
                }
                if (homeworkCount != 0) {
                    homeworkDoneCount = homeworkDoneCount / homeworkCount;
                    lastLessonHomeworkString.set((int) (homeworkDoneCount * 100) + "% completion");
                } else {
                    lastLessonHomeworkString.set("No assignment");
                }
                if (practiceTotalTime > 0) {
                    practiceTotalTime = practiceTotalTime / 60 / 60;
                    if (practiceTotalTime <= 0.1) {
                        lastLessonSelfStudyString.set("0.1 hrs");
                    } else {
                        lastLessonSelfStudyString.set(String.format("%.1f", practiceTotalTime) + " hrs");
                    }
                } else {
                    lastLessonSelfStudyString.set("0 hrs");
                }
                isShowCopyLastHomework.set(lastLessonHomeworks.size() > 0 && homeworkList.size() == 0 && selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);
            }
        }
        isSuccess.set(data.size() > 0);
    }

    /**
     * 获取下一节课的LesosnType
     */
    private void getNextLessonPlanData(LessonScheduleEntity nextLessonData, int index) {
        if (selectData.getValue() == null) {
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(UserService.getInstance().getLessonPlan(nextLessonData.getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
            if (index == selectIndex.getValue()) {
                nextLessonPlanList.clear();
                for (LessonSchedulePlanEntity item : data) {
                    LessonPlanItemViewModel model = new LessonPlanItemViewModel(this, item, selectData.getValue(), true);
                    nextLessonPlanList.add(model);
                }
                isShowCopyThisPlan.set(lessonPlanList.size() > 0 && nextLessonPlanList.size() == 0);
            }
            isSuccess.set(true);
        }, throwable -> {
            if (!isSuccess.get()) {
                Logger.e("失败,失败原因" + throwable.getMessage());
            }
        }));
    }

    /**
     * 获取Lesson plan
     *
     * @param index
     */
    private void getLessonPlan(int index) {
        if (selectData.getValue() == null) {
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(UserService.getInstance().getLessonPlan(selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
            lessonPlanList.clear();
            if (index == selectIndex.getValue()) {
                for (LessonSchedulePlanEntity item : data) {
                    LessonPlanItemViewModel model = new LessonPlanItemViewModel(this, item, selectData.getValue(), false);
                    lessonPlanList.add(model);
                }
            }
            isShowCopyThisPlan.set(lessonPlanList.size() > 0 && nextLessonPlanList.size() == 0);
//                            if (this.data.get().get(index).getLessonStatus() == 0 && lessonPlanList.size() > 0) {
//                                lessonInfoString.set(TimeUtils.timeFormat(this.data.get().get(index).getTKShouldDateTime(), "hh:mm a, MMM dd") + " - Ready to start");
//                            } else {
//                                lessonInfoString.set(TimeUtils.timeFormat(this.data.get().get(index).getTKShouldDateTime(), "hh:mm a, MMM dd") + " - " + this.data.get().get(index).getLessonStatusString());
//                            }
            if (this.data.get().get(index).getLessonStatus() == 0 && lessonPlanList.size() > 0) {
                lessonInfoString.set("Ready to start");
            } else {
                lessonInfoString.set(this.data.get().get(index).getLessonStatusString());
            }

            isSuccess.set(true);
        }, throwable -> {
            if (!isSuccess.get()) {
                Logger.e("失败,失败原因" + throwable.getMessage());
            }
        }));
    }

    /**
     * 更新LessonPlan
     *
     * @param data 更新的数据
     * @param id   lessonPlan 的id
     */
    public void upDateLessonPlan(Map<String, Object> data, String id, int type) {
        String plan = (String) data.get("plan");
        if (plan != null) {
            if (type == 1) {
                for (LessonPlanItemViewModel model : lessonPlanList) {
                    if (model.lessonPlanData.getId().equals(id)) {
                        model.editPlan(plan);
                    }
                }
            }
            if (type == 3) {
                for (LessonPlanItemViewModel model : nextLessonPlanList) {
                    if (model.lessonPlanData.getId().equals(id)) {
                        model.editPlan(plan);
                    }
                }
            }
        }
        addSubscribe(UserService.getStudioInstance().updateLessonPlan(id, data).subscribe(status -> {
            Logger.e("更新LessonPlan成功");

        }, throwable -> {
            Logger.e("更新LessonPlan失败:%s", throwable.getMessage());
        }));
    }

    /**
     * 添加新的lesson plan
     *
     * @param type
     * @param plan
     */
    public void addLessonPlan(int type, String plan) {
        //获取随机ID
        String planId = String.valueOf(SnowFlakeShortUrl.nextId());
        long shouldDateTime = 0;
        String lessonScheduleId = "";
        if (type == 1) {
            shouldDateTime = data.get().get(selectIndex.getValue()).getShouldDateTime();
            lessonScheduleId = data.get().get(selectIndex.getValue()).getId();
        } else if (type == 3) {
            if (nextLessonData != null) {
                shouldDateTime = nextLessonData.getShouldDateTime();
                lessonScheduleId = nextLessonData.getId();
            } else {
                Logger.e("======%s", "没有获取到下一节课");
                return;
            }
        }

        LessonSchedulePlanEntity lessonSchedulePlanEntity = new LessonSchedulePlanEntity().setId(planId).setLessonScheduleId(lessonScheduleId).setStudioId(SLCacheUtil.getCurrentStudioId()).setPlan(plan).setDone(false).setShouldDateTime(shouldDateTime).setStudentId(data.get().get(selectIndex.getValue()).getStudentId()).setTeacherId(data.get().get(selectIndex.getValue()).getTeacherId()).setCreateTime(System.currentTimeMillis() / 1000 + "").setUpdateTime(System.currentTimeMillis() / 1000 + "");
        if (type == 1) {
            lessonPlanList.add(new LessonPlanItemViewModel(this, lessonSchedulePlanEntity, selectData.getValue(), false));
        }
        if (type == 3) {
            nextLessonPlanList.add(new LessonPlanItemViewModel(this, lessonSchedulePlanEntity, selectData.getValue(), true));
        }
        isShowCopyThisPlan.set(lessonPlanList.size() > 0 && nextLessonPlanList.size() == 0);

        addSubscribe(UserService.getStudioInstance().addLessonPlan(lessonSchedulePlanEntity).subscribe(status -> {
            Logger.e("=====上传Lesson plan成功===" + status);
            if (this.data.get().get(selectIndex.getValue()).getLessonStatus() == 0) {
//                        lessonInfoString.set(TimeUtils.timeFormat(this.data.get().get(selectIndex.getValue()).getTKShouldDateTime(), "hh:mm a, MMM dd") + " - Ready to start");
                lessonInfoString.set("Ready to start");

            }
        }, throwable -> {
            Logger.e("=====上传失败===" + throwable.getMessage());
        }));
    }

    /**
     * 删除 lesson plan
     *
     * @param id   要删除的id
     * @param type 1是lesson plan 3是nextLessonPlan
     */
    public void deletePlan(String id, int type) {
        SLToast.success("Delete successfully!");
        if (type == 1) {
            for (int i = 0; i < lessonPlanList.size(); i++) {
                if (lessonPlanList.get(i).lessonPlanData.getId().equals(id)) {
                    lessonPlanList.remove(i);
                }
            }
        } else if (type == 3) {
            for (int i = 0; i < nextLessonPlanList.size(); i++) {
                if (nextLessonPlanList.get(i).lessonPlanData.getId().equals(id)) {
                    nextLessonPlanList.remove(i);
                }
            }
        }
        isShowCopyThisPlan.set(lessonPlanList.size() > 0 && nextLessonPlanList.size() == 0);

        addSubscribe(UserService.getStudioInstance().deleteLessonPlan(id).subscribe(status -> {
            Logger.e("=====删除成功=");
        }, throwable -> {
            Logger.e("=====删除失败=" + throwable.getMessage());
        }));
    }

    /**
     * 获取 note 数据
     *
     * @param index
     */
    private void getNoteData(int index) {
        if (selectData.getValue() != null) {
            isShowTeacherNotes.set(!selectData.getValue().getTeacherNote().equals(""));
            isShowTeacherToParentNotes.set(!selectData.getValue().getTeacherToParentNote().equals(""));
            isShowStudentNotes.set(!selectData.getValue().getStudentNote().equals(""));
        }
    }

    /**
     * 更新note
     *
     * @param note
     */
    public void upDateNotes(String note,String parentNote) {
        Map<String, Object> map = new HashMap<>();
        map.put("teacherNote", note);
        map.put("teacherToParentNote", parentNote);
        SLToast.info("Save successful!");


        if (!note.equals("")) {
//            SLToast.info("Save successful!");
            map.put("studentReadTeacherNote", false);
        }
        for (LessonScheduleEntity item : data.get()) {
            if (item.getId().equals(selectData.getValue().getId())) {
                item.setTeacherNote(note);
                item.setTeacherToParentNote(parentNote);
            }
        }
        LessonScheduleEntity lessonScheduleEntity = selectData.getValue().setTeacherNote(note);

        selectData.setValue(lessonScheduleEntity);
        isShowTeacherNotes.set(!selectData.getValue().getTeacherNote().equals(""));
        isShowTeacherToParentNotes.set(!selectData.getValue().getTeacherToParentNote().equals(""));

        int index = selectIndex.getValue();
        data.get().get(index).setTeacherNote(selectData.getValue().getTeacherNote());

        addSubscribe(UserService.getStudioInstance().updateNotes(selectData.getValue().getId(), map).subscribe(status -> {
            AppDataBase.getInstance().lessonDao().insert(data.get().get(index));
            Logger.e("=====更新Note成功=");
            TKApi.updateLessonVersion(selectData.getValue().getId());
        }, throwable -> {
            Logger.e("=====更新Note失败=" + throwable.getMessage());
        }));
    }


    /**
     * 获取materials数据
     *
     * @param index
     */
    private void getMaterialsData(int index) {

        if (selectData.getValue() == null) {
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(LessonService.getInstance().getLessonScheduleMaterialByScheduleId(selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
                    Logger.e("MaterialsData==>%s", data.size());
                    isSuccess.set(true);
                    if (index == selectIndex.getValue()) {
                        lessonMaterialsData = data;
                        materialsList.clear();
//<<<<<<< HEAD
//
//
//                                List<MaterialEntity> materialsData;
//                                if (!TKUtils.INSTANCE.currentUserIsStudio()) {
//                                    materialsData = ListenerService.shared.teacherData.getHomeMaterials();
//                                    initMaterialsData(data, materialsData);
//                                } else {
//                                    if (selectData.getValue().getTeacherId().equals(SLCacheUtil.getCurrentUserId())) {
//                                        materialsData = AppDataBase.getInstance().materialDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
//                                        initMaterialsData(data, materialsData);
//                                    } else {
//                                        List<String> ids = new ArrayList<>();
//                                        for (LessonScheduleMaterialEntity datum : data) {
//                                            ids.add(datum.getMaterialId());
//                                        }
//                                        addSubscribe(
//                                                MaterialService.getInstance().getByIds(ids)
//                                                        .subscribeOn(Schedulers.io())
//                                                        .observeOn(AndroidSchedulers.mainThread(), true)
//                                                        .subscribe(d -> {
//                                                            initMaterialsData(data, d);
//                                                        }, throwable -> {
//                                                            Logger.e("失败,失败原因" + throwable.getMessage());
//                                                        })
//                                        );
//=======
                        List<MaterialEntity> materialsData;
                        if (!TKUtils.INSTANCE.currentUserIsStudio()) {
                            materialsData = ListenerService.shared.teacherData.getHomeMaterials();
//                                    Logger.e("materialsData==>%s", materialsData.size());
                            initMaterialsData(data, materialsData);
                        } else {
                            List<String> ids = new ArrayList<>();
                            for (LessonScheduleMaterialEntity datum : data) {
                                ids.add(datum.getMaterialId());
                            }
                            addSubscribe(MaterialService.getInstance().getByIds(ids).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
                                initMaterialsData(data, d);
                            }, throwable -> {
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            }));
                        }
//                                List<MaterialEntity> materialsData = ListenerService.shared.teacherData.getHomeMaterials();
//                                materialsData.removeIf(materialEntity -> {
//                                    boolean isHave = false;
//                                    for (LessonScheduleMaterialEntity item : data) {
//                                        if (materialEntity.getId().equals(item.getMaterialId())) {
//                                            isHave = true;
//                                            break;
//                                        }
//                                    }
//                                    return !isHave;
//                                });
//                                materialsData.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
//                                List<MaterialEntity> teacherMaterials = ListenerService.shared.teacherData.getHomeMaterials();
//                                this.materialsData.setValue(materialsData);
//
//                                for (MaterialEntity material : materialsData) {
////                                    if (material.getFolder().equals("") ||  !material.getFolder().equals("")) {
//                                    MaterialsMultiItemViewModel<LessonDetailsVM> item;
//                                    if (material.getType() == MaterialEntity.Type.folder) {
//                                        item = new MaterialsFolderViewModel<>(this, material);
//                                        MaterialsFolderViewModel<LessonDetailsVM> folderItem = (MaterialsFolderViewModel<LessonDetailsVM>) item;
//                                        folderItem.setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
//                                    } else if (material.getType() == MaterialEntity.Type.youtube) {
//                                        item = new MaterialsLinkVMV2<>(this, material);
//                                    } else {
//                                        item = new MaterialsGridVMV2<>(this, material);
////>>>>>>> latest-release
//                                    }
//                                    item.isNotShowShare.set(true);
//                                    materialsList.add(item);
//                                }
//
                    }

                }, throwable -> {
                    if (!isSuccess.get()) {
                    }
                    Logger.e("getMaterialsData 失败,失败原因" + throwable.getMessage());
                })

        );

    }

    private void initMaterialsData(List<LessonScheduleMaterialEntity> data, List<MaterialEntity> materialsData) {
        materialsData.removeIf(materialEntity -> {
            boolean isHave = false;
            for (LessonScheduleMaterialEntity item : data) {
                if (materialEntity.getId().equals(item.getMaterialId())) {
                    isHave = true;
                    break;
                }
            }
            return !isHave;
        });
        materialsData.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
        List<MaterialEntity> teacherMaterials = ListenerService.shared.teacherData.getHomeMaterials();
        this.materialsData.setValue(materialsData);

        for (MaterialEntity material : materialsData) {
            MaterialsMultiItemViewModel<LessonDetailsVM> item;
            if (material.getType() == MaterialEntity.Type.folder) {
                item = new MaterialsFolderViewModel<>(this, material);
                MaterialsFolderViewModel<LessonDetailsVM> folderItem = (MaterialsFolderViewModel<LessonDetailsVM>) item;
                folderItem.setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
            } else if (material.getType() == MaterialEntity.Type.youtube) {
                item = new MaterialsLinkVMV2<>(this, material);
            } else {
                item = new MaterialsGridVMV2<>(this, material);
            }
            item.isNotShowShare.set(true);
            item.isShowMoreButton.set(false);
            materialsList.add(item);
        }


//        materialsData.removeIf(materialEntity -> {
//            boolean isHave = false;
//            for (LessonScheduleMaterialEntity item : data) {
//                if (materialEntity.getId().equals(item.getMaterialId())) {
//                    isHave = true;
//                    break;
//                }
//            }
//            return !isHave;
//        });
//        materialsData.sort((o1, o2) -> {
//            int a = Integer.parseInt(o1.getCreateTime());
//            int b = Integer.parseInt(o2.getCreateTime());
//            return b - a;
//        });
//        Logger.e("initMaterialsData==>%s", materialsData.size());
//        this.materialsData.setValue(materialsData);
//        List<String> folderIds = new ArrayList<>();
//        for (MaterialEntity material : materialsData) {
//            if (material.getType() == -2) {
//                folderIds.add(material.getId());
//            }
//        }
//        for (MaterialEntity material : materialsData) {
//            if (material.getType() == -2) {
//                if (material.getMaterials().size() > 0) {
//                    material.getMaterials().sort((o1, o2) -> {
//                        int a = Integer.parseInt(o1.getCreateTime());
//                        int b = Integer.parseInt(o2.getCreateTime());
//                        return b - a;
//                    });
//                    MaterialsFolderViewModel<LessonDetailsVM> item = new MaterialsFolderViewModel<>(this, material);
//                    item.isNotShowShare.set(true);
//                    materialsList.add(item);
//                }
//            } else if (material.getType() != -1) {
//                if (material.getFolder().equals("") || !folderIds.contains(material.getFolder())) {
//                    if (material.getType() == 6) {
//                        MaterialsLinkVMV2<LessonDetailsVM> item = new MaterialsLinkVMV2<>(this,
//                                material);
//                        item.isNotShowShare.set(true);
//                        materialsList.add(item);
//                    } else {
//                        MaterialsGridVMV2<LessonDetailsVM> item = new MaterialsGridVMV2<>(this,
//                                material);
//                        item.isNotShowShare.set(true);
//                        materialsList.add(item);
//                    }
//                }
//            }
//        }
    }


    /**
     * 获取Achievement数据
     *
     * @param index
     */
    private void getAchievement(int index) {
        if (selectData.getValue() == null) {
            return;
        }
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(UserService.getInstance().getAchievement(selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
                    isSuccess.set(true);
                    Logger.e("getAchievement======%s", data.size());
                    if (index == selectIndex.getValue()) {
                        achievementList.clear();
                        for (AchievementEntity item : data) {
//                                    LessonAchievementItemViewModel achievementItemViewModel = new LessonAchievementItemViewModel(this,item);
                            achievementList.add(new LessonAchievementItemViewModel(this, item));
                        }
                    }
                }, throwable -> {
                    Logger.e("getAchievement失败,失败原因" + throwable.getMessage());
                })

        );

    }

    /**
     * 添加achievement
     *
     * @param type
     * @param title
     * @param desc
     */
    public void addAchievement(int type, String title, String desc) {
        AchievementEntity achievementEntity = new AchievementEntity();

        //获取随机ID
        String id = IDUtils.getId();
        achievementEntity.setId(id).setStudentId(selectData.getValue().getStudentId()).setTeacherId(selectData.getValue().getTeacherId()).setStudioId(SLCacheUtil.getCurrentStudioId()).setScheduleId(selectData.getValue().getId()).setShouldDateTime(selectData.getValue().getShouldDateTime()).setType(type).setDate(System.currentTimeMillis() / 1000 + "").setName(title).setDesc(desc).setCreateTime(System.currentTimeMillis() / 1000 + "").setUpdateTime(System.currentTimeMillis() / 1000 + "");
        achievementList.add(new LessonAchievementItemViewModel(this, achievementEntity));
        addSubscribe(UserService.getStudioInstance().addAchievement(achievementEntity).subscribe(status -> {
//                    LessonAchievementItemViewModel item = new LessonAchievementItemViewModel(this, achievementEntity);
//                    observableListAchievement.add(item);
            Logger.e("=====上传Achievement成功=");

        }, throwable -> {
            Logger.e("=====上传Achievement失败=" + throwable.getMessage());
        }));
    }

    /**
     * 修改Achievement
     *
     * @param id
     * @param type
     * @param title
     * @param desc
     */
    public void editAchievement(String id, int type, String title, String desc) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", title);
        map.put("desc", desc);
        map.put("type", type);
        for (LessonAchievementItemViewModel lessonAchievementItemViewModel : achievementList) {
            if (lessonAchievementItemViewModel.achievementEntity.getId().equals(id)) {
                lessonAchievementItemViewModel.achievementEntity.setName(title);
                lessonAchievementItemViewModel.achievementEntity.setType(type);
                lessonAchievementItemViewModel.achievementEntity.setDesc(desc);
                lessonAchievementItemViewModel.setData();
            }
        }
        addSubscribe(UserService.getStudioInstance().updateAchievement(id, map).subscribe(status -> {
            Logger.e("更新tAchievement成功");
        }, throwable -> {
            Logger.e("=====更新tAchievement失败=" + throwable.getMessage());
        }));
    }

    /**
     * 删除Achievement
     *
     * @param id
     */
    public void deleteAchievement(String id) {
        SLToast.success("Retract successfully!");

        for (int i = 0; i < achievementList.size(); i++) {
            if (achievementList.get(i).achievementEntity.getId().equals(id)) {
                achievementList.remove(i);
            }
        }
        Logger.e("======%s", achievementList.size());
        addSubscribe(UserService.getStudioInstance().deleteAchievement(id).subscribe(status -> {
            Logger.e("删除tAchievement成功");

        }, throwable -> {
            Logger.e("=====删除tAchievement失败=" + throwable.getMessage());
        }));
    }


    /**
     * 获取homework
     *
     * @param index
     */
    private void getHomework(int index) {
        if (selectData.getValue() == null) {
            return;
        }
        Logger.e("======%s", selectData.getValue().getId());
        addSubscribe(UserService.getInstance().getPracticeByScheduleId(selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(data -> {
                    if (index == selectIndex.getValue()) {
                        homeworkList.clear();
                        practiceList = data;
                        Logger.e("获取Homework成功: %s", data.size());
                        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
                            for (TKPractice item : practiceList) {
                                boolean isHave = false;
                                for (LessonHomeworkItemViewModel lessonHomeworkItemViewModel : homeworkList) {
                                    if (lessonHomeworkItemViewModel.practice.getAssignmentId().equals(item.getAssignmentId())) {
                                        isHave = true;
                                        break;
                                    }
                                }
                                if (!isHave && item.getStartTime() == item.getShouldDateTime()) {
                                    homeworkList.add(new LessonHomeworkItemViewModel(this, item));
                                }
                            }
                        } else {
                            for (TKPractice item : data) {
                                if (item.getStartTime() == item.getShouldDateTime()) {
                                    homeworkList.add(new LessonHomeworkItemViewModel(this, item));
                                }
                            }
                        }

                        isShowCopyLastHomework.set(lastLessonHomeworks.size() > 0 && homeworkList.size() == 0 && selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);
                    }
                }, throwable -> {
                    Logger.e("获取Homework失败,失败原因" + throwable.getMessage());

                })

        );
    }

    public void addNextLessonTypes() {
        List<String> type = new ArrayList<>();
        for (LessonPlanItemViewModel lessonPlanItemViewModel : lessonPlanList) {
            type.add(lessonPlanItemViewModel.lessonPlanData.getPlan());
        }


        long shouldDateTime = 0;
        String lessonScheduleId = "";
        if (nextLessonData != null) {
            shouldDateTime = nextLessonData.getShouldDateTime();
            lessonScheduleId = nextLessonData.getId();
        } else {
            Logger.e("======%s", "没有获取到下一节课");
            return;
        }
        List<LessonSchedulePlanEntity> planEntityList = new ArrayList<>();
        for (String s : type) {
            LessonSchedulePlanEntity lessonSchedulePlanEntity = new LessonSchedulePlanEntity().setId(IDUtils.getId()).setLessonScheduleId(lessonScheduleId).setStudioId(SLCacheUtil.getCurrentStudioId()).setPlan(s).setDone(false).setShouldDateTime(shouldDateTime).setStudentId(data.get().get(selectIndex.getValue()).getStudentId()).setTeacherId(data.get().get(selectIndex.getValue()).getTeacherId()).setCreateTime(System.currentTimeMillis() / 1000 + "").setUpdateTime(System.currentTimeMillis() / 1000 + "");
            planEntityList.add(lessonSchedulePlanEntity);
            nextLessonPlanList.add(new LessonPlanItemViewModel(this, lessonSchedulePlanEntity, selectData.getValue(), true));

        }
        isShowCopyThisPlan.set(lessonPlanList.size() > 0 && nextLessonPlanList.size() == 0);
        FirebaseFirestore.getInstance().runTransaction(transaction -> {
            for (LessonSchedulePlanEntity data : planEntityList) {
                transaction.set(DatabaseService.Collections.lessonSchedulePlan().document(data.getId()), data, SetOptions.merge());
            }
            return null;
        }).addOnCompleteListener(task -> {
            if (task.getException() == null) {
                Logger.e("add nextLesson plan");
            } else {
                Logger.e("=====add Homework失败=" + task.getException().getMessage());
            }
        });
    }

    public void addHomeworks(List<String> names) {
        String time = TimeUtils.getCurrentTime() + "";
        List<TKPractice> tkPractices = new ArrayList<>();
        String assignmentId = IDUtils.getId();
        for (String name : names) {
            TKPractice practice = new TKPractice().setId(IDUtils.getId()).setAssignmentId(assignmentId).setStudentId(selectData.getValue().getStudentId()).setStudioId(SLCacheUtil.getCurrentStudioId()).setTeacherId(selectData.getValue().getTeacherId()).setStartTime((int) selectData.getValue().getShouldDateTime()).setName(name).setAssignment(true).setScheduleConfigId(selectData.getValue().getLessonScheduleConfigId()).setLessonScheduleId(selectData.getValue().getId()).setShouldDateTime((int) selectData.getValue().getShouldDateTime()).setUpdateTime(time).setCreateTime(time);
            tkPractices.add(practice);
            homeworkList.add(new LessonHomeworkItemViewModel(this, practice));
            practiceList.add(practice);
        }
        isShowCopyLastHomework.set(false);
        FirebaseFirestore.getInstance().runTransaction(transaction -> {
            for (TKPractice tkPractice : tkPractices) {
                transaction.set(DatabaseService.Collections.practice().document(tkPractice.getId()), tkPractice, SetOptions.merge());
            }
            return null;
        }).addOnCompleteListener(task -> {
            if (task.getException() == null) {
                Logger.e("add Homework成功");
            } else {
                Logger.e("=====add Homework失败=" + task.getException().getMessage());
            }
        });

    }

    /**
     * 添加homework
     *
     * @param name
     */
    public void addHomework(String name) {
        String time = TimeUtils.getCurrentTime() + "";
        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            List<TKPractice> data = new ArrayList<>();
            List<String> ids = new ArrayList<>();
            for (Map.Entry<String, LessonScheduleConfigEntity.GroupLessonStudent> entry : selectData.getValue().getGroupLessonStudents().entrySet()) {
                LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(entry.getValue()), LessonScheduleConfigEntity.GroupLessonStudent.class);
                if (value.getRegistrationTimestamp() <= selectData.getValue().getShouldDateTime()) {
                    ids.add(entry.getKey());
                }
            }
            String assignmentId = IDUtils.getId();
            for (String id : ids) {
                TKPractice practice = new TKPractice().setId(IDUtils.getId()).setAssignmentId(assignmentId).setStudentId(id).setStudioId(SLCacheUtil.getCurrentStudioId()).setTeacherId(selectData.getValue().getTeacherId()).setStartTime((int) selectData.getValue().getShouldDateTime()).setName(name).setAssignment(true).setScheduleConfigId(selectData.getValue().getLessonScheduleConfigId()).setLessonScheduleId(selectData.getValue().getId()).setShouldDateTime((int) selectData.getValue().getShouldDateTime()).setUpdateTime(time).setCreateTime(time);
                data.add(practice);
            }
            homeworkList.add(new LessonHomeworkItemViewModel(this, data.get(0)));
            isShowCopyLastHomework.set(false);
            practiceList.addAll(data);
            addSubscribe(UserService.getInstance().addPractices(data).subscribe(status -> {
                Logger.e("add Homework成功");
            }, throwable -> {
                Logger.e("=====add Homework失败=" + throwable.getMessage());
            }));
        } else {
            TKPractice practice = new TKPractice().setId(IDUtils.getId()).setAssignmentId(IDUtils.getId()).setStudentId(selectData.getValue().getStudentId()).setStudioId(SLCacheUtil.getCurrentStudioId()).setTeacherId(selectData.getValue().getTeacherId()).setStartTime((int) selectData.getValue().getShouldDateTime()).setName(name).setAssignment(true).setScheduleConfigId(selectData.getValue().getLessonScheduleConfigId()).setLessonScheduleId(selectData.getValue().getId()).setShouldDateTime((int) selectData.getValue().getShouldDateTime()).setUpdateTime(time).setCreateTime(time);
            homeworkList.add(new LessonHomeworkItemViewModel(this, practice));
            practiceList.add(practice);
            isShowCopyLastHomework.set(false);

            addSubscribe(UserService.getInstance().addPractice(practice).subscribe(status -> {
                Logger.e("add Homework成功");
            }, throwable -> {
                Logger.e("=====add Homework失败=" + throwable.getMessage());
            }));
        }

    }

    /**
     * 修改Homework
     *
     * @param id
     */
    public void editHomework(String id, String name) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", name);
        TKPractice practice = null;
        for (LessonHomeworkItemViewModel item : homeworkList) {
            if (item.practice.getId().equals(id)) {
                practice = item.practice;
                item.practice.setName(name);
                item.plan.set(name);
            }
        }
        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            if (practice == null) {
                return;
            }
            List<String> ids = new ArrayList<>();
            for (TKPractice tkPractice : practiceList) {
                if (tkPractice.getAssignmentId().equals(practice.getAssignmentId())) {
                    tkPractice.setName(name);
                    ids.add(tkPractice.getId());
                }
            }

            addSubscribe(UserService.getInstance().updatePractices(ids, map).subscribe(status -> {
                Logger.e("更新Homework成功");
            }, throwable -> {
                Logger.e("=====更新Homework失败=" + throwable.getMessage());
            }));
        } else {

            addSubscribe(UserService.getInstance().updatePractice(id, map).subscribe(status -> {
                Logger.e("更新Homework成功");
            }, throwable -> {
                Logger.e("=====更新Homework失败=" + throwable.getMessage());
            }));
        }

    }

    /**
     * 删除Homework
     *
     * @param id
     */
    public void deleteHomework(String id) {
        SLToast.success("Delete successfully!");
        TKPractice practice = null;
        for (int i = 0; i < homeworkList.size(); i++) {
            if (homeworkList.get(i).practice.getId().equals(id)) {
                practice = homeworkList.get(i).practice;
                homeworkList.remove(i);
                break;
            }
        }
        isShowCopyLastHomework.set(lastLessonHomeworks.size() > 0 && homeworkList.size() == 0 && selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.single);
        if (selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
            if (practice == null) {
                return;
            }
            List<String> ids = new ArrayList<>();
            for (TKPractice tkPractice : practiceList) {
                if (tkPractice.getAssignmentId().equals(practice.getAssignmentId())) {
                    ids.add(tkPractice.getId());
                }
            }
            TKPractice finalPractice = practice;
            practiceList.removeIf(tkPractice -> tkPractice.getAssignmentId().equals(finalPractice.getAssignmentId()));
            addSubscribe(UserService.getInstance().deletePractices(ids).subscribe(status -> {
                Logger.e("删除Homework成功");

            }, throwable -> {
                Logger.e("=====删除Homework失败=" + throwable.getMessage());
            }));

        } else {
            addSubscribe(UserService.getInstance().deletePractice(id).subscribe(status -> {
                Logger.e("删除Homework成功");

            }, throwable -> {
                Logger.e("=====删除Homework失败=" + throwable.getMessage());
            }));
        }

    }


    /***************************结束-- 数据相关 --结束***********************/


    /***************************开始-- RecyclerView item 及 binding 创建 --开始*********************/

    //给RecyclerView添加ObservableList
    public ObservableList<LessonBeforeItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<LessonBeforeItemViewModel> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_lesson_before));


    public ObservableList<LessonPlanItemViewModel> lessonPlanList = new ObservableArrayList<>();
    public ItemBinding<LessonPlanItemViewModel> lessonPlanItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_lesson_plan));

    public ObservableList<MaterialsMultiItemViewModel> materialsList = new ObservableArrayList<>();
    public ItemBinding<MaterialsMultiItemViewModel> materialsItemBinding = ItemBinding.of((itemBinding, position, item) -> {
        //通过item的类型, 动态设置Item加载的布局
        int itemType = (int) item.getData().getType();
        switch (itemType) {
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_FILE:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_IMG:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_PPT:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_WORD:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_MP3:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_VIDEO:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_LINK:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_TXT:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_PDF:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_EXCEL:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_GOOGLE_DRAWINGS:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_GOOGLE_FORMS:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_GOOGLE_SLIDES:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_GOOGLE_SHEET:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_GOOGLE_DOC:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_KEYNOTE:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_NUMBERS:
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_PAGES:
                itemBinding.set(BR.itemGridViewModel, R.layout.item_grid_material_student);
                break;
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_YOUTUBE:
                itemBinding.set(BR.itemLinkViewModel, R.layout.item_link_material_student);
                break;
            case MaterialsViewModel.MULTI_MATERIAL_TYPE_FOLDER:
                itemBinding.set(BR.itemFolderViewModel, R.layout.item_folder_material_student);
                break;
        }
    });
    public ObservableList<LessonAchievementItemViewModel> achievementList = new ObservableArrayList<>();
    public ItemBinding<LessonAchievementItemViewModel> achievementItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_lesson_achievement));

    public ObservableList<LessonPlanItemViewModel> nextLessonPlanList = new ObservableArrayList<>();
    public ItemBinding<LessonPlanItemViewModel> nextLessonPlanItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_lesson_plan));


    public List<TKPractice> practiceList = new ArrayList<>();
    public ObservableList<LessonHomeworkItemViewModel> homeworkList = new ObservableArrayList<>();
    public ItemBinding<LessonHomeworkItemViewModel> homeworkItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_lesson_homework));

    /***************************结束-- RecyclerView item 及 binding 创建 --结束***********************/

    public void checkClassNow() {
        if (nowLesson != null) {
            long nowTime = TimeUtils.getCurrentTime();
            long endTime = nowLesson.getTKShouldDateTime() + (nowLesson.getShouldTimeLength() * 60L);
            if (nowTime >= nowLesson.getTKShouldDateTime() && nowTime < endTime && nowLesson.getLessonStatus() != 2) {
                isShowCountDownView.set(true);
                uc.nowLesson.setValue(nowLesson);

            } else {
                isShowCountDownView.set(false);

            }
        }
    }

    public void updateAttendance(int type) {
        showDialog();
        LessonScheduleExEntity.LessonAttendanceEntity attendance = new LessonScheduleExEntity.LessonAttendanceEntity();
        attendance.setId(IDUtils.getId());
        attendance.setCreateTime(TimeUtils.getCurrentTime());
        attendance.setType(type);


        Map<String, Object> map = new HashMap<>();
        List<LessonScheduleExEntity.LessonAttendanceEntity> attendanceList = CloneObjectUtils.cloneObject(selectData.getValue().getAttendance());
        attendanceList.add(attendance);
        attendanceList.sort((lessonAttendanceEntity, t1) -> (int) (t1.getCreateTime() - lessonAttendanceEntity.getCreateTime()));

        map.put("attendance", attendanceList);
        addSubscribe(LessonService.getInstance().updateLesson(selectData.getValue().getId(), map).subscribe(status -> {
            dismissDialog();
            for (LessonScheduleEntity item : data.get()) {
                if (item.getId().equals(selectData.getValue().getId())) {
                    item.setAttendance(attendanceList);
                }
            }
            selectData.getValue().setAttendance(attendanceList);

            LessonScheduleEntity lessonScheduleEntity = selectData.getValue();
            selectData.setValue(lessonScheduleEntity);
            int index = selectIndex.getValue();
            data.get().get(index).setAttendance(selectData.getValue().getAttendance());
            StringBuilder attendanceS = new StringBuilder();
            for (int i = 0; i < attendanceList.size(); i++) {
                attendanceS.append("Attendance: ");
                attendanceS.append(attendanceList.get(i).showString());
                if (i != attendanceList.size() - 1) {
                    attendanceS.append("\n");
                }
            }

//                    isShowAttendance.set(true);
//                    attendanceString.set(attendanceS.toString());
        }, throwable -> {
            dismissDialog();
            Logger.e("=====updateAttendance失败=" + throwable.getMessage());
        }));
    }

    public void removeNoShow() {
        showDialog();
        addSubscribe(TKApi.INSTANCE.removeNoShow(selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            SLToast.showSuccess();
            attendanceString.set("");
            attendanceButtonString.set("Report Attendance");
            isHaveNoshow = false;
        }, throwable -> {
            dismissDialog();
            SLToast.showError();
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }

    public void retractNoShow(String note) {
        showDialog();
        addSubscribe(TKApi.INSTANCE.retractNoShow(note, selectData.getValue().getId(), selectData.getValue().getStudentId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            SLToast.showSuccess();
            Logger.e("selectData.getValue().getId()==>%s", selectData.getValue().getId());
            StringBuilder attendanceS = new StringBuilder();
            attendanceS.append("Attendance: ");
            attendanceS.append(note);
            attendanceString.set(attendanceS.toString() + " " + TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mma, MM/dd/yyyy"));
            attendanceButtonString.set("Report Attendance");
            isShowAttendance.set(true);
            uc.attendanceDone.call();
            isHaveNoshow = true;
        }, throwable -> {
            dismissDialog();
            SLToast.showError();
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }

    public void retractLateAndPresent(String note) {
        showDialog();
        addSubscribe(TKApi.INSTANCE.retractLateAndPresent(note, selectData.getValue().getId()).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(d -> {
            dismissDialog();
            SLToast.showSuccess();
            Logger.e("selectData.getValue().getId()==>%s", selectData.getValue().getId());
            StringBuilder attendanceS = new StringBuilder();
            attendanceS.append("Attendance: ");
            attendanceS.append(note);
            attendanceString.set(attendanceS.toString() + " " + TimeUtils.timeFormat(TimeUtils.getCurrentTime(), "hh:mma, MM/dd/yyyy"));
            attendanceButtonString.set("Report Attendance");
            isShowAttendance.set(true);
            isHaveNoshow = true;
        }, throwable -> {
            if (selectData.getValue().getAttendance().size() > 0) {
                if (selectData.getValue().getAttendance().get(0).getNote().equals("Present")) {
                    return;
                }
            }
            dismissDialog();
            SLToast.showError();
            Logger.e("失败,失败原因" + throwable.getMessage());
        }));
    }

    private void initShowMore() {
        boolean reschedule = false;
        boolean cancel = false;
        if (isSureRescheduleAndCancel) {
            if (this.isCanReschedule) {
                reschedule = true;
            }
            if (this.isCanCancelLesson) {
                cancel = true;
            }
        }
        if (selectData.getValue().lessonCategory == LessonTypeEntity.TKLessonCategory.group) {
            rightFirstImgVisibility.set(View.VISIBLE);
            return;
        }
        if (!cancel && !reschedule) {
            rightFirstImgVisibility.set(View.GONE);
        } else {
            rightFirstImgVisibility.set(View.VISIBLE);
        }
    }

    public void getShareLink(String configId) {
        showDialog();
        addSubscribe(TKApi.createDynamicLink("https://tunekey.app/join/groupLesson/" + configId, "https://tunekey.app/link/")

                .subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread(), true).subscribe(it -> {
                    dismissDialog();
                    uc.showShareLesson.postValue(it);
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("失败,失败原因" + throwable.getMessage());
                }));
    }
}
