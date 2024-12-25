package com.spelist.tunekey.ui.student.sLessons.vm;

import android.app.Application;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.UnderlineSpan;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

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
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleMaterialEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.TKAddress;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.TKStudioRoom;
import com.spelist.tunekey.entity.TKUserRole;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.activity.MaterialsActivity;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsFolderViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsGridVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsLinkVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.ui.teacher.students.activity.PracticeActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.text.Collator;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

public class StudentLessonDetailViewModel extends ToolbarViewModel {
    public ObservableField<Boolean> isShowLocation = new ObservableField<>(false);
    public MutableLiveData<SpannableStringBuilder> locationString = new MutableLiveData<>(new SpannableStringBuilder(""));
    public MutableLiveData<String> locationTitleString = new MutableLiveData<>("");
    public boolean roomIsHaveAddress = false;

    public MutableLiveData<Boolean> isShowAchievementArrow = new MutableLiveData<>(false);
    public MutableLiveData<Boolean> isShowMaterialsArrow = new MutableLiveData<>(false);
    public MutableLiveData<Boolean> isShowNoteAdd = new MutableLiveData<>(false);
    public MutableLiveData<String> selfStudy = new MutableLiveData<>(" 0 hrs");
    public MutableLiveData<String> assignment = new MutableLiveData<>(" No assignment");
    public MutableLiveData<Integer> assignmentColor = new MutableLiveData<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
    public ObservableField<Boolean> isShowTeacherNotes = new ObservableField<>(false);
    public ObservableField<Boolean> isShowTeacherPrivateNotes = new ObservableField<>(false);
    public ObservableField<Boolean> isParent = new ObservableField<>(false);

    public ObservableField<Boolean> isShowStudentNotes = new ObservableField<>(false);
    public ObservableField<String> studentName = new ObservableField<>("");
    public ObservableField<String> studentId = new ObservableField<>("");

    public ObservableField<Boolean> isShowNoteTip = new ObservableField<>(false);
    public ObservableField<Boolean> isShowAchievementTip = new ObservableField<>(false);
    public ObservableField<Boolean> isShowMaterialsTip = new ObservableField<>(false);
    public ObservableField<String> preparationText = new ObservableField<>("Preparation");

    public MaterialsViewModel materialsViewModel;
    public LessonScheduleEntity lesson;

    public MutableLiveData<String> noteString = new MutableLiveData<>("");
    public MutableLiveData<String> teacherNoteString = new MutableLiveData<>("");
    public MutableLiveData<String> teacherPrivateNoteString = new MutableLiveData<>("");

    public List<MaterialEntity> lessonMaterials = new ArrayList<>();
    public int endTime;
    public int startTime;
    public ObservableField<String> teacherId = new ObservableField<>("");
    public ObservableField<String> teacherName = new ObservableField<>("");

    public ObservableField<String> memo = new ObservableField<>();
    public ObservableField<Boolean> isShowMemo = new ObservableField<>(false);

    public StudentLessonDetailViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {

    }


    public void initData(LessonScheduleEntity data) {
        lesson = data;
        if (lesson == null) {
            return;
        }
        UserEntity currentUserData = SLCacheUtil.getCurrentUserData(SLCacheUtil.getCurrentUserId());
        Logger.e("user==>%s", SLJsonUtils.toJsonString(currentUserData));
        isParent.set(currentUserData != null && currentUserData.getRoleIds().contains(UserEntity.UserRole.parents));

        teacherId.set(data.getTeacherId());
        teacherName.set(data.getTeacherName());
        studentId.set(data.getStudentId());
        setNormalToolbar(TimeUtils.timeFormat(data.getTKShouldDateTime(), "MMM dd, hh:mm a"));
        if (data.getConfigEntity() != null && data.getConfigEntity().getMemo() != null && !data.getConfigEntity().getMemo().equals("")) {
            isShowMemo.set(true);
            memo.set(data.getConfigEntity().getMemo());
        } else {
            isShowMemo.set(false);
        }
        if (lesson.getLocation() != null && lesson.getLocation().getId().equals("") && lesson.getLocation().getType().equals(TKLocation.LocationType.remote)) {
            lesson.getLocation().setId(lesson.getLocation().getRemoteLink());
        }
        if (lesson.getLocation() != null && !lesson.getLocation().getId().equals("")) {
            initLocation();
        }
        initPracticeData();
        initNoteData();
        initAchievement();
        initMaterials();
        readTip();
        initListener();
    }

    private void initLocation() {


        String s = "";
        String title = "";
        isShowLocation.set(true);

        if (lesson.getLocation().getType().equals(TKLocation.LocationType.studioRoom)) {
            s = lesson.getLocation().getPlace();
            title = "Location: ";
            if (SLCacheUtil.getStudioInfo() != null && SLCacheUtil.getStudioInfo().getAddressDetail() != null && !SLCacheUtil.getStudioInfo().getAddressDetail().toShowString().equals("")) {
                roomIsHaveAddress = true;
                s = SLCacheUtil.getStudioInfo().getAddressDetail().toShowString();
            } else {
                List<TKStudioRoom> roomsData = ListenerService.shared.studentData.getRoomsData();
                for (TKStudioRoom roomsDatum : roomsData) {
                    if (roomsDatum.getId().equals(lesson.getLocation().getPlace())) {
                        s = roomsDatum.getName();
                    }
                }
            }

        } else if (lesson.getLocation().getType().equals(TKLocation.LocationType.remote)) {
            title = "Online: ";
            s = lesson.getLocation().getRemoteLink();
        } else if (lesson.getLocation().getType().equals(TKLocation.LocationType.otherPlace)) {
            title = "Location: ";
            s = lesson.getLocation().getPlace();
        }
        SpannableStringBuilder spannableString = new SpannableStringBuilder(s);
        if (!lesson.getLocation().getType().equals(TKLocation.LocationType.studioRoom) || roomIsHaveAddress) {
            UnderlineSpan underlineSpan = new UnderlineSpan();
            spannableString.setSpan(underlineSpan, 0, s.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        locationString.setValue(spannableString);
        locationTitleString.setValue(title);

    }

    private void initListener() {
//

        initLessonScheduleListener();
        initAchievementListener();
        initMaterialsListener();
    }

    private void initMaterialsListener() {
        DatabaseService.Collections.lessonScheduleMaterial()
                .whereEqualTo("lessonScheduleId", lesson.getId())
                .addSnapshotListener((value, error) -> {
                    if (error != null || value == null) {
                        return;
                    }
                    ListenerService.SnapshotData<LessonScheduleMaterialEntity> practiceData = ListenerService.handleSnapshot(value, LessonScheduleMaterialEntity.class);
                    if (lesson == null) {
                        return;
                    }
                    for (LessonScheduleMaterialEntity item : practiceData.getAdded()) {
                        boolean isHave = false;
                        for (LessonScheduleMaterialEntity oldItem : lesson.getMaterialData()) {
                            if (item.getId().equals(oldItem.getId())) {
                                isHave = true;
                            }
                        }
                        if (!isHave) {
                            lesson.getMaterialData().add(item);
                        }
                    }
                    for (LessonScheduleMaterialEntity item : practiceData.getModified()) {
                        for (int i = 0; i < lesson.getMaterialData().size(); i++) {
                            if (lesson.getMaterialData().get(i).getId().equals(item.getId())) {
                                lesson.getMaterialData().set(i, item);
                            }
                        }
                    }

                    for (LessonScheduleMaterialEntity removedItem : practiceData.getRemoved()) {
                        lesson.getMaterialData().removeIf(item -> item.getId().equals(removedItem.getId()));
                    }
                    initMaterials();
                });
    }

    private void initAchievementListener() {
        DatabaseService.Collections.achievement()
                .whereEqualTo("scheduleId", lesson.getId())
                .addSnapshotListener((value, error) -> {
                    if (error != null || value == null) {
                        return;
                    }
                    ListenerService.SnapshotData<AchievementEntity> practiceData = ListenerService.handleSnapshot(value, AchievementEntity.class);
                    if (lesson == null) {
                        return;
                    }

                    for (AchievementEntity item : practiceData.getAdded()) {
                        boolean isHave = false;
                        for (AchievementEntity oldItem : lesson.getAchievement()) {
                            if (item.getId().equals(oldItem.getId())) {
                                isHave = true;
                            }
                        }
                        if (!isHave) {
                            lesson.getAchievement().add(item);
                        }
                    }

                    for (AchievementEntity item : practiceData.getModified()) {
                        for (int i = 0; i < lesson.getAchievement().size(); i++) {
                            if (lesson.getAchievement().get(i).getId().equals(item.getId())) {
                                lesson.getAchievement().set(i, item);
                            }
                        }
                    }

                    for (AchievementEntity removedItem : practiceData.getRemoved()) {
                        lesson.getAchievement().removeIf(item -> item.getId().equals(removedItem.getId()));
                    }
                    initAchievement();


                });
    }

    private void initLessonScheduleListener() {
        DatabaseService.Collections.lessonSchedule()
                .document(lesson.getId())
                .addSnapshotListener((value, error) -> {
                    if (error != null || value == null) {
                        return;
                    }
                    LessonScheduleEntity lessonScheduleEntity = value.toObject(LessonScheduleEntity.class);
                    if (lessonScheduleEntity == null) {
                        return;
                    }
                    lesson.setTeacherNote(lessonScheduleEntity.getTeacherNote());
                    lesson.setStudentNote(lessonScheduleEntity.getStudentNote());
                    isShowTeacherNotes.set(!lessonScheduleEntity.getTeacherNote().isEmpty());
                    isShowTeacherPrivateNotes.set(!lessonScheduleEntity.getTeacherToParentNote().isEmpty());
                    isShowStudentNotes.set(!lessonScheduleEntity.getStudentNote().isEmpty());
                    isShowNoteAdd.setValue(false);
                    if (lesson.getConfigEntity() != null) {
                        isShowNoteAdd.setValue(lessonScheduleEntity.getStudentNote().isEmpty() && lesson.getConfigEntity().getLessonCategory() != LessonTypeEntity.TKLessonCategory.group);
                    } else if (lessonScheduleEntity.getConfigEntity() != null) {
                        isShowNoteAdd.setValue(lessonScheduleEntity.getStudentNote().isEmpty() && lessonScheduleEntity.getLessonCategory() != LessonTypeEntity.TKLessonCategory.group);
                    }
                    teacherNoteString.setValue(lessonScheduleEntity.getTeacherNote());
                    teacherPrivateNoteString.setValue(lessonScheduleEntity.getTeacherToParentNote());
                    noteString.setValue(lessonScheduleEntity.getStudentNote());
                });
    }

    private void initHomeworkListener() {
        DatabaseService.Collections.practice()
                .whereEqualTo("studentId", lesson.getStudentId())
                .whereLessThan("startTime", endTime)
                .whereGreaterThanOrEqualTo("startTime", lesson.getShouldDateTime())
                .addSnapshotListener((value, error) -> {
                    if (error != null) {
                        return;
                    }
                    ListenerService.SnapshotData<TKPractice> practiceData = ListenerService.handleSnapshot(value, TKPractice.class);
                    if (lesson == null) {
                        return;
                    }
                    for (TKPractice item : practiceData.getAdded()) {
                        boolean isHave = false;
                        for (TKPractice oldItem : lesson.getPracticeData()) {
                            if (item.getId().equals(oldItem.getId())) {
                                isHave = true;
                            }
                        }
                        if (!isHave) {
                            lesson.getPracticeData().add(item);
                        }
                    }


                    for (TKPractice item : practiceData.getModified()) {
                        for (int i = 0; i < lesson.getPracticeData().size(); i++) {
                            if (lesson.getPracticeData().get(i).getId().equals(item.getId())) {
                                lesson.getPracticeData().set(i, item);
                            }
                        }
                    }

                    for (TKPractice removedItem : practiceData.getRemoved()) {
                        lesson.getPracticeData().removeIf(item -> item.getId().equals(removedItem.getId()));
                    }
                    Logger.e("lesson.getPracticeData()==>%s", lesson.getPracticeData().size());
                    initPracticeData();


                });
    }

    private void readTip() {

        if (lesson == null) {
            return;
        }
        if (!lesson.getTeacherNote().isEmpty() && !lesson.isStudentReadTeacherNote()) {
            isShowNoteTip.set(true);
            Map<String, Object> map = new HashMap<>();
            map.put("studentReadTeacherNote", true);
            lesson.setStudentReadTeacherNote(true);
            addSubscribe(UserService
                    .getStudioInstance()
                    .updateNotes(lesson.getId(), map)
                    .subscribe(status -> {
                        Messenger.getDefault().send(lesson, MessengerUtils.STUDENT_NOTE_CHANGED);
                        TKApi.updateLessonVersion(lesson.getId());
                        Logger.e("=====更新Note成功=");
                    }, throwable -> {
                        Logger.e("=====更新Note失败=" + throwable.getMessage());
                    }));

        }

        if (!lesson.getAchievement().isEmpty()) {
            List<AchievementEntity> needAchievement = new ArrayList<>();
            for (AchievementEntity achievementEntity : lesson.getAchievement()) {
                if (!achievementEntity.isStudentRead()) {
                    isShowAchievementTip.set(true);
                    needAchievement.add(achievementEntity);
                }
            }
            if (needAchievement.size() > 0) {
                addSubscribe(
                        LessonService
                                .getInstance()
                                .readAchievement(needAchievement)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread(), true)
                                .subscribe(data -> {
                                    Logger.e("readAchievement成功");

                                }, throwable -> {
                                    Logger.e("readAchievement失败,失败原因" + throwable.getMessage());
                                })

                );
            }

        }

        if (!lesson.getMaterialData().isEmpty()) {
            List<LessonScheduleMaterialEntity> needMaterials = new ArrayList<>();
            for (LessonScheduleMaterialEntity materialDatum : lesson.getMaterialData()) {
                if (!materialDatum.isStudentRead()) {
                    needMaterials.add(materialDatum);
                    isShowMaterialsTip.set(true);
                    materialDatum.setStudentRead(true);
                }
            }
            if (needMaterials.size() > 0) {
                addSubscribe(
                        LessonService
                                .getInstance()
                                .readMaterials(needMaterials)
                                .subscribeOn(Schedulers.io())
                                .observeOn(AndroidSchedulers.mainThread(), true)
                                .subscribe(data -> {
                                    Logger.e("readMaterials成功");
                                    Messenger.getDefault().send(this.lesson, MessengerUtils.STUDENT_READ_MATERIAL);
                                }, throwable -> {
                                    Logger.e("readMaterials失败,失败原因" + throwable.getMessage());
                                })

                );
            }
        }


    }

    public void upDateNotes(String note) {
        Map<String, Object> map = new HashMap<>();
        map.put("studentNote", note);
        if (note.equals("")) {
            SLToast.info("Delete successful!");
        }
        lesson.setStudentNote(note);
        noteString.setValue(note);
        teacherNoteString.setValue(lesson.getTeacherNote());
        teacherPrivateNoteString.setValue(lesson.getTeacherToParentNote());
        isShowStudentNotes.set(!lesson.getStudentNote().equals(""));
        isShowNoteAdd.setValue(lesson.getStudentNote().isEmpty() && lesson.getConfigEntity().getLessonCategory() != LessonTypeEntity.TKLessonCategory.group);
        addSubscribe(UserService
                .getStudioInstance()
                .updateNotes(lesson.getId(), map)
                .subscribe(status -> {
                    Messenger.getDefault().send(lesson, MessengerUtils.STUDENT_NOTE_CHANGED);
                    TKApi.updateLessonVersion(lesson.getId());
                    Logger.e("=====更新Note成功=");
                }, throwable -> {
                    Logger.e("=====更新Note失败=" + throwable.getMessage());
                }));
    }


    private void initMaterials() {
        try {
            materialsObList.clear();
            List<LessonScheduleMaterialEntity> materialData = lesson.getMaterialData();
            if (materialData.isEmpty()) {
                return;
            }
            List<MaterialEntity> materials = CloneObjectUtils.cloneObject(ListenerService.shared.studentData.getMaterials());
            lessonMaterials = new ArrayList<>();
            List<MaterialEntity> teacherMaterials = CloneObjectUtils.cloneObject(ListenerService.shared.studentData.getTeacherMaterials());
//            teacherMaterialsData = teacherMaterials;
            String currentId = SLCacheUtil.getCurrentUserId();
            for (MaterialEntity teacherMaterial : teacherMaterials) {
                if (teacherMaterial.getStudentIds().contains(currentId)) {
                    materials.add(teacherMaterial);
                }
            }
            for (LessonScheduleMaterialEntity materialDatum : materialData) {
                for (MaterialEntity material : materials) {
                    if (material.getId().equals(materialDatum.getMaterialId())) {
                        lessonMaterials.add(material);
                    }
                }
            }
            List<MaterialEntity> data = new ArrayList<>();

            for (MaterialEntity lessonMaterial : lessonMaterials) {
                boolean isHave = false;
                for (MaterialEntity datum : data) {
                    if (datum.getId().equals(lessonMaterial.getId())) {
                        isHave = true;
                    }
                }
                if (!isHave) {
                    data.add(lessonMaterial);
                }

            }
//            Logger.e("data==>%s",data.size());
//            Logger.e("lessonMaterials==>%s",lessonMaterials.size());

            lessonMaterials = data;
//            lessonMaterials.sort((o1, o2) -> {
//                int a = Integer.parseInt(o1.getCreateTime());
//                int b = Integer.parseInt(o2.getCreateTime());
//                return b - a;
//            });
            lessonMaterials.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));


            List<String> folderIds = new ArrayList<>();
            for (MaterialEntity material : lessonMaterials) {
                if (material.getType() == -2) {
                    folderIds.add(material.getId());
                }
            }
            for (MaterialEntity material : lessonMaterials) {
                if (materialsObList.size() >= 5) {
                    break;
                }
                if (material.getFolder().equals("") || (!material.getFolder().equals("") && !folderIds.contains(material.getFolder()))) {
                    MaterialsMultiItemViewModel<StudentLessonDetailViewModel> item;
                    if (material.getType() == MaterialEntity.Type.folder) {
                        item = new MaterialsFolderViewModel<>(this, material);
                        MaterialsFolderViewModel<StudentLessonDetailViewModel> folderItem = (MaterialsFolderViewModel<StudentLessonDetailViewModel>) item;
                        folderItem.setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));

                    } else if (material.getType() == MaterialEntity.Type.youtube) {
                        item = new MaterialsLinkVMV2<>(this, material);
                    } else {
                        item = new MaterialsGridVMV2<>(this, material);
                    }
                    item.isNotShowShare.set(true);
                    item.isShowMoreButton.set(false);
                    materialsObList.add(item);
                }


//                if (material.getType() == -2) {
//                    if (material.getMaterials().size() > 0) {
//                        material.getMaterials().sort((o1, o2) -> {
//                            int a = Integer.parseInt(o1.getCreateTime());
//                            int b = Integer.parseInt(o2.getCreateTime());
//                            return b - a;
//                        });
//                        MaterialsFolderViewModel<StudentLessonDetailViewModel> item = new MaterialsFolderViewModel<>(this, material);
//                        materialsObList.add(item);
//                    }
//                } else if (material.getType() != -1) {
//                    if (material.getFolder().equals("") || !folderIds.contains(material.getFolder())) {
//                        if (material.getType() == 6) {
//                            MaterialsLinkVMV2<StudentLessonDetailViewModel> item = new MaterialsLinkVMV2<>(this,
//                                    material);
//                            materialsObList.add(item);
//                        } else {
//                            MaterialsGridVMV2<StudentLessonDetailViewModel> item = new MaterialsGridVMV2<>(this,
//                                    material);
//                            materialsObList.add(item);
//                        }
//                    }
//                }
            }
            Logger.e("materialsObList==>%s", materialsObList.size());
            uc.materialsObserverData.setValue(materialsObList);
            isShowMaterialsArrow.setValue(materialsObList.size() > 0);
        } catch (Throwable e) {

        }

    }


    private void initAchievement() {
        if (lesson == null) {
            return;
        }
        achievementDataList.clear();
        List<AchievementEntity> achievement = lesson.getAchievement();
        if (!achievement.isEmpty()) {
            for (AchievementEntity achievementEntity : achievement) {
                achievementDataList.add(new StudentLessonAchievementItemViewModel(this, achievementEntity));
            }
            isShowAchievementArrow.setValue(true);
        }
    }

    private void initNoteData() {
        try {
            if (lesson == null) {
                return;
            }
            if (ListenerService.shared.user != null && ListenerService.shared.user.getName() != null && studentName != null) {
                studentName.set(ListenerService.shared.user.getName());
            }
            isShowTeacherNotes.set(!lesson.getTeacherNote().isEmpty());
            isShowTeacherPrivateNotes.set(!lesson.getTeacherToParentNote().isEmpty());
            isShowStudentNotes.set(!lesson.getStudentNote().isEmpty());
            isShowNoteAdd.setValue(lesson.getStudentNote().isEmpty() && lesson.getConfigEntity().getLessonCategory() != LessonTypeEntity.TKLessonCategory.group);
            noteString.setValue(lesson.getStudentNote());
            teacherNoteString.setValue(lesson.getTeacherNote());
            teacherPrivateNoteString.setValue(lesson.getTeacherToParentNote());
            addSubscribe(
                    LessonService
                            .getInstance()
                            .getScheduleById(lesson.getId())
                            .subscribeOn(Schedulers.io())
                            .observeOn(AndroidSchedulers.mainThread(), true)
                            .subscribe(data -> {
                                isShowTeacherNotes.set(!data.getTeacherNote().isEmpty());
                                isShowTeacherPrivateNotes.set(!data.getTeacherToParentNote().isEmpty());
                                isShowStudentNotes.set(!data.getStudentNote().isEmpty());
                                isShowNoteAdd.setValue(data.getStudentNote().isEmpty() && lesson.getConfigEntity().getLessonCategory() != LessonTypeEntity.TKLessonCategory.group);
                                teacherNoteString.setValue(data.getTeacherNote());
                                teacherPrivateNoteString.setValue(data.getTeacherToParentNote());
                                noteString.setValue(data.getStudentNote());

                            }, throwable -> {
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            })

            );

        } catch (Throwable e) {

        }


    }

    private void initPracticeData() {
        try {
            if (lesson.getShouldDateTime() > TimeUtils.getCurrentTime()) {
                preparationText.set("Preparation");
            } else {
                preparationText.set("Practice after lesson");
//            initHomeworkListener();
            }
            List<TKPractice> practiceData = CloneObjectUtils.cloneObject(lesson.getPracticeData());
            List<TKPractice> itemDatas = new ArrayList<>();
            for (TKPractice item : practiceData) {
                if (item.isAssignment()) {
                    int index = -1;
                    for (int i = 0; i < itemDatas.size(); i++) {
                        TKPractice newItem = itemDatas.get(i);
                        if (newItem.getName().equals(item.getName())) {
                            index = i;
                        }
                    }
                    if (index >= 0) {
                        itemDatas.get(index).getRecordData().addAll(item.getRecordData());
                        if (item.isDone()) {
                            itemDatas.get(index).setDone(true);
                        }
                        itemDatas.get(index).setTotalTimeLength(item.getTotalTimeLength() + itemDatas.get(index).getTotalTimeLength());
                    } else {
                        itemDatas.add(item);
                    }
                } else {
                    boolean isHave = false;
                    for (TKPractice itemData : itemDatas) {
                        if (itemData.getId().equals(item.getId())) {
                            isHave = true;
                        }
                    }
                    if (!isHave) {
                        itemDatas.add(item);
                    }
                }
            }
            practiceData = itemDatas;


            if (practiceData.size() > 0) {
                List<TKPractice> assignmentData = new ArrayList<>();
                List<TKPractice> studyData = new ArrayList<>();
                for (TKPractice item : practiceData) {
                    if (!item.isAssignment()) {
                        studyData.add(item);
                    } else {
                        assignmentData.add(item);
                    }
                }
                double totalTime = 0;
                for (TKPractice item : studyData) {
                    totalTime += item.getTotalTimeLength();
                }
                if (totalTime > 0) {
                    totalTime = totalTime / 60 / 60;
                    if (totalTime <= 0.1) {
                        selfStudy.setValue(" 0.1 hrs");
                    } else {
                        selfStudy.setValue(" " + String.format("%.1f", totalTime) + " hrs");
                    }
                } else {
                    selfStudy.setValue(" 0 hrs");
                }
                if (assignmentData.size() <= 0) {
                    assignment.setValue(" No assignment");
                    assignmentColor.setValue(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
                    return;
                }
                boolean isComplete = true;
                for (TKPractice item : assignmentData) {
                    if (!item.isDone()) {
                        isComplete = false;
                        break;
                    }
                }
                assignment.setValue(isComplete ? " Completed" : lesson.getShouldDateTime() > TimeUtils.getCurrentTime() ? " Incomplete" : " Uncompleted");
                assignmentColor.setValue(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), isComplete ? R.color.kermit_green : R.color.red));
            }
        } catch (Throwable e) {

        }

    }

    public ObservableList<StudentLessonAchievementItemViewModel> achievementDataList = new ObservableArrayList<>();

    public ItemBinding<StudentLessonAchievementItemViewModel> itemAchievementBinding =
            ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_student_lesson_achievement));

    //给RecyclerView添加ObservableList
    public ObservableList<MaterialsMultiItemViewModel> materialsObList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<MaterialsMultiItemViewModel> materialsItemBinding =
            ItemBinding.of((itemBinding, position, item) -> {
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

    public static class UIEventObservable {
        public SingleLiveEvent<Void> clickLessonNotes = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickEditNote = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> clickAchievements = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickMaterials = new SingleLiveEvent<>();
        public SingleLiveEvent<ObservableList<MaterialsMultiItemViewModel>> materialsObserverData =
                new SingleLiveEvent<>();

    }

    public UIEventObservable uc = new UIEventObservable();

    public BindingCommand clickPractice = new BindingCommand(() -> {
        if (endTime != 0) {

        }
        Bundle bundle = new Bundle();
//        bundle.putSerializable("data", (Serializable) lastLessonPractices);
//        bundle.putSerializable("lessonData", (Serializable) selectlesson);

        bundle.putInt("startTime", (int) lesson.getShouldDateTime());
        bundle.putInt("endTime", endTime);
//        bundle.putInt("startTime", startTime);
        Logger.e("start==>%s=>%s", TimeUtils.getTimestampFormatYMD(lesson.getShouldDateTime() * 1000L), TimeUtils.getTimestampFormatYMD(endTime * 1000L));
        bundle.putInt("type", 2);
        bundle.putSerializable("data", (Serializable) lesson.getPracticeData());


        startActivity(PracticeActivity.class, bundle);
    });
    public BindingCommand clickLessonNotes = new BindingCommand(() -> {
        uc.clickLessonNotes.call();
    });

    public BindingCommand clickAchievements = new BindingCommand(() -> {
        uc.clickAchievements.call();
    });

    public BindingCommand clickMaterials = new BindingCommand(() -> {
        uc.clickMaterials.call();
    });
    public BindingCommand clickMaterialsToDetail = new BindingCommand(() -> {
        Bundle bundle = new Bundle();
        bundle.putString("type", "show");
        bundle.putSerializable("data", (Serializable) lessonMaterials);
        startActivity(MaterialsActivity.class, bundle);
    });
    public BindingCommand clickEditNote = new BindingCommand(() -> {
        uc.clickEditNote.call();
    });


}
