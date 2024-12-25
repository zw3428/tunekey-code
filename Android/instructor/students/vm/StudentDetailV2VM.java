package com.spelist.tunekey.ui.teacher.students.vm;

import android.annotation.SuppressLint;
import android.app.Application;
import android.app.Dialog;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.recyclerview.widget.GridLayoutManager;

import com.google.firebase.firestore.SetOptions;
import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.CalendarService;
import com.spelist.tunekey.api.network.ChatService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.MaterialService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.CountriesCurrencies;
import com.spelist.tunekey.entity.InvoiceCalculation;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.entity.LessonScheduleAssignmentEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.StudioInfoEntity;
import com.spelist.tunekey.entity.TKInvoice;
import com.spelist.tunekey.entity.TKInvoiceStatus;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.TKTransaction;
import com.spelist.tunekey.entity.TransactionType;
import com.spelist.tunekey.ui.balance.BalanceListAc;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;
import com.spelist.tunekey.ui.student.sProfile.fragment.StudentProfileEditActivity;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsFolderViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsGridVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsLinkVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.ui.teacher.students.activity.AchievementActivity;
import com.spelist.tunekey.ui.teacher.students.activity.AttendanceListAc;
import com.spelist.tunekey.ui.teacher.students.activity.NotesActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTools;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.text.Collator;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.reactivex.Observable;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;


/**
 * com.spelist.tunekey.ui.students.vm
 * 2020/11/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentDetailV2VM extends ToolbarViewModel {
    public ObservableField<String> birthdayString = new ObservableField<>("Optional");
    public ObservableField<String> memoString = new ObservableField<>("Optional");

    public ObservableField<String> attendanceFirstString = new ObservableField<>("");
    public ObservableField<Boolean> attendanceIsHave = new ObservableField<>(false);
    public List<LessonScheduleEntity> attendanceListData = new ArrayList<>();

    public double birthday = 0;
    public ObservableField<String> image = new ObservableField<>();
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> userId = new ObservableField<>();

    public ObservableField<String> email = new ObservableField<>();
    public StudentListEntity studentData = new StudentListEntity();
    public boolean isAdd;
    private List<String> lessonIdList = new ArrayList<>();

    public ObservableField<String> total = new ObservableField<>();
    public ObservableField<String> achievementTitle = new ObservableField<>();
    public ObservableField<String> achievementType = new ObservableField<>();

    public ObservableField<String> top = new ObservableField<>();
    public ObservableField<String> notes = new ObservableField<>();
    public ObservableField<String> notesDate = new ObservableField<>();
    public ObservableField<String> notesDateMonth = new ObservableField<>();


    public ObservableField<Integer> studentInfoRightImg = new ObservableField<>(R.mipmap.next);
    public ObservableField<Boolean> lessonEditIsVisible = new ObservableField<>(false);
    public ObservableField<Boolean> addLessonButtonIsVisible = new ObservableField<>(false);
    public ObservableField<String> editString = new ObservableField<>("Add / Delete");
    public ObservableField<String> practiceHrsString = new ObservableField<>("0 hrs");
    public ObservableField<String> assignmentString = new ObservableField<>("0% completion");

    public ObservableField<Boolean> practiceIsVisible = new ObservableField<>(false);
    public ObservableField<Boolean> achievementIsVisible = new ObservableField<>(false);
    public ObservableField<Boolean> noteIsVisible = new ObservableField<>(false);
    public ObservableField<Boolean> materialIsVisible = new ObservableField<>(false);
    public ObservableField<Boolean> isStudentLook = new ObservableField<>(false);
    public ObservableField<Boolean> isShowLesson = new ObservableField<>(true);


    public boolean studentIsActive = true;
    public List<LessonTypeEntity> lessonTypeEntities = new ArrayList<>();
    public List<LessonScheduleConfigEntity> scheduleConfigData = new ArrayList<>();
    public boolean isEdit = false;
    public List<AchievementEntity> achievementData = new ArrayList<>();
    public List<TKPractice> practicesData = new ArrayList<>();

    public List<LessonScheduleEntity> noteLessonData = new ArrayList<>();
    public List<LessonScheduleEntity> allLessonData = new ArrayList<>();
    public ObservableField<GridLayoutManager> gridLayoutManager = new ObservableField<>();

    public List<MaterialEntity> materialsData = new ArrayList<>();
    private Map<String, LessonRescheduleEntity> rescheduleTimeData = new HashMap<>();
    public ObservableField<Integer> archiveColor = new ObservableField<>(ContextCompat.getColor(getApplication(), R.color.main));
    public ObservableField<Boolean> isShowArchive = new ObservableField<>(false);
    public ObservableField<Boolean> isShowDelete = new ObservableField<>(false);


    public ObservableField<Boolean> isShowBalance = new ObservableField<>(false);
    public ObservableField<Boolean> isShowBalanceLastPayment = new ObservableField<>(false);
    public ObservableField<String> balanceLastPayment = new ObservableField<>("");
    public ObservableField<Boolean> isShowBalanceNextBill = new ObservableField<>(false);
    public ObservableField<String> balanceNextBill = new ObservableField<>("");
    public ObservableField<Boolean> isShowAddInvoiceButton = new ObservableField<>(false);
    public ObservableField<String> addInvoiceString = new ObservableField<>("Add invoice");
    public boolean isCanCreateAndEditStudent = true;
    public boolean isCanDeleteStudent = true;
    public boolean isCanSetupLesson4Create = true;
    public boolean isCanSetupLesson4EditAndDelete = true;
    public String currentCurrenciesData = CountriesCurrencies.getLocationCurrencies().toInvoiceSettingData().getSymbol();


    public StudentDetailV2VM(@NonNull Application application) {
        super(application);

    }

    private void initMessage() {
        if (isStudentLook.get()) {
            Messenger.getDefault().register(this, MessengerUtils.STUDENT_PROFILE, () -> {
                getUserInfo();
            });
            Messenger.getDefault().register(this, MessengerUtils.REFRESH_AVATAR, String.class, time -> uc.refreshAvatar.setValue(time));

        }

        Messenger.getDefault().register(this, MessengerUtils.REFRESH_LESSON, LessonScheduleConfigEntity.class, config -> {
            getLessonType(true);
            getLessonType(false);
        });
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_ACHIEVEMENT_LIST_CHANGE, this::getAchievement);
        Messenger.getDefault().register(this, MessengerUtils.TEACHER_STUDENT_LIST_CHANGED, () -> {
            List<StudentListEntity> studentList = ListenerService.shared.teacherData.getStudentList();
            for (StudentListEntity studentListEntity : studentList) {
                if (studentData.getStudentId().equals(studentListEntity.getStudentId())) {
                    studentData = studentListEntity;
                }
            }
            initStudentStatus();
        });


    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Student Details");
    }

    public void initData() {
        initMessage();
        userId.set(studentData.getStudentId());
        if (!isStudentLook.get()) {
            name.set(studentData.getName());
            email.set(studentData.getEmail());
        }
        currentCurrenciesData = CountriesCurrencies.getLocationCurrencies().toInvoiceSettingData().getSymbol();

        if (SLCacheUtil.getStudioInfo() != null && SLCacheUtil.getStudioInfo().getCurrency() != null && !SLCacheUtil.getStudioInfo().getCurrency().getSymbol().equals("")) {
            currentCurrenciesData = SLCacheUtil.getStudioInfo().getCurrency().getSymbol();
        }
        if (studentData.getMemo()!=null&&!studentData.getMemo().equals("")) {
            memoString.set(studentData.getMemo());
        }else {
            memoString.set("Optional");
        }
        initStudentStatus();
        getUserInfo();
        getLessonType(true);
        getLessonType(false);
        getAchievement();
        getNote();
        getMaterials();
        getInvoiceAndTransaction();
    }

    private void getInvoiceAndTransaction() {
        addSubscribe(
                AppDataBase.getInstance().invoiceDao().getByTeacherIdAndStudentId(studentData.getTeacherId(), studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (isStudentLook.get()) {
                                d = d.stream().filter(it -> (!it.markAsPay && !it.status.equals(TKInvoiceStatus._void) && it.totalAmount > (it.paidAmount + it.waivedAmount))).collect(Collectors.toList());
                            } else {

                                d = d.stream().filter(it -> (!it.status.equals(TKInvoiceStatus._void) && it.totalAmount > (it.paidAmount + it.waivedAmount))).collect(Collectors.toList());
                            }
                            isShowBalanceNextBill.set(d.size() > 0);
                            if (d.size() > 0) {
                                StringBuilder st = new StringBuilder("");
                                for (TKInvoice invoice : d) {
                                    double unpaid = InvoiceCalculation.INSTANCE.getUnpaid(invoice);
                                    st.append(currentCurrenciesData).append(SLTools.getRound(unpaid, 2)).append(" due ").append(InvoiceCalculation.INSTANCE.getDueToString(invoice)).append(", ");
                                }
                                balanceNextBill.set(st.substring(0, st.length() - 2));
                            } else {
                                balanceNextBill.set("");
                            }
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }

                        }, throwable -> {
                            isShowBalanceNextBill.set(false);
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
        String studioId = ListenerService.shared.teacherData.getStudioData().getId();
        if (isStudentLook.get()) {
            studioId = SLCacheUtil.getCurrentStudioId();
        }
        addSubscribe(
                AppDataBase.getInstance().transactionDao().getByStudioIdAndPayerId(studioId, studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            d = d.stream().filter(it -> it.getTransactionType().equals(TransactionType.pay)).collect(Collectors.toList());
                            isShowBalanceLastPayment.set(d.size() > 0);
                            if (d.size() > 0) {
                                TKTransaction tkTransaction = d.get(0);
                                balanceLastPayment.set(currentCurrenciesData + SLTools.getRound(tkTransaction.getAmount(), 2) + " on " + TimeUtils.timeFormat((long) tkTransaction.getCreateTimestamp(), "MM/dd/yyyy"));
                            }
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                        }, throwable -> {
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowBalanceLastPayment.set(false);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    /**
     * 初始化学生状态
     */
    private void initStudentStatus() {
        if (!SLCacheUtil.getCurrentStudioIsSingleTeacher()) {
            TKRoleAndAccess data = TKRoleAndAccess.getData();
            if (data != null) {
                isCanCreateAndEditStudent = data.getAllowManageStudentAccount4CreateAndEdit();
                isCanDeleteStudent = data.getAllowManageStudentAccount4Delete();
                if (data.getAllowSetupLesson()) {
                    isCanSetupLesson4Create = data.getAllowSetupLesson4Create();
                    isCanSetupLesson4EditAndDelete = data.getAllowSetupLesson4EditAndDelete();
                }
            }
        }
        if (isCanSetupLesson4EditAndDelete){
            if (isCanSetupLesson4Create) {
                editString.set("Add / Delete");
            }else {
                editString.set("Delete");
            }
        }else {
            if (isCanSetupLesson4Create) {
                editString.set("Add");
            }else {
                editString.set("");
            }
        }
        isShowArchive.set(false);
        isShowDelete.set(false);
        if (studentData.getInvitedStatus().equals("-1")) {
            if (!studentData.getLessonTypeId().equals("")) {
                isShowArchive.set(isCanCreateAndEditStudent);
                archiveColor.set(ContextCompat.getColor(getApplication(), R.color.red));
            } else {
                isShowArchive.set(isCanCreateAndEditStudent);
                isShowDelete.set(isCanDeleteStudent);
                archiveColor.set(ContextCompat.getColor(getApplication(), R.color.main));
            }
        } else if (studentData.getInvitedStatus().equals("3")) {
            isShowDelete.set(isCanDeleteStudent);
        } else {
            isShowArchive.set(isCanCreateAndEditStudent);
            archiveColor.set(ContextCompat.getColor(getApplication(), R.color.red));
        }
    }

    /**
     * getMaterials
     */
    private void getMaterials() {
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        materialsObList.clear();
        materialsData.clear();
        addSubscribe(
                MaterialService
                        .getInstance()
                        .getMaterialByTeacherIdAndStudentId(studentData.getTeacherId(), studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(materials -> {
                            if (isSuccess.get()) {
                                return;
                            }
                            isSuccess.set(true);

                            List<MaterialEntity> teacherMaterials = CloneObjectUtils.cloneObject(ListenerService.shared.teacherData.getHomeMaterials());
                            for (MaterialEntity teacherMaterial : teacherMaterials) {
                                if (teacherMaterial.getStudentIds().contains(studentData.getStudentId())) {
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
                            if (materials.size() > 0) {
                                materialIsVisible.set(true);
                            } else {
                                materialIsVisible.set(false);
                            }
                            materials.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
                            for (MaterialEntity material : materials) {

                                if (materialsObList.size() >= 5) {
                                    break;
                                }
                                if (material.getFolder().equals("") || (!material.getFolder().equals("") && !folderIds.contains(material.getFolder()))) {

//                                    if (material.getFolder().equals("") || (!folderIds.contains(material.getFolder()) && !material.getFolder().equals(""))) {
                                    materialsData.add(material);

                                    MaterialsMultiItemViewModel<StudentDetailV2VM> item;
                                    if (material.getType() == MaterialEntity.Type.folder) {
                                        item = new MaterialsFolderViewModel<>(this, material);
                                        MaterialsFolderViewModel<StudentDetailV2VM> folderItem = (MaterialsFolderViewModel<StudentDetailV2VM>) item;
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

                            }
                            uc.materialsObserverData.setValue(materialsObList);


//                            List<String> folderIds = new ArrayList<>();
//                            for (MaterialEntity material : materials) {
//                                if (material.getType() == -2) {
//                                    folderIds.add(material.getId());
//                                }
//                            }
//                            for (MaterialEntity material : materials) {
//                                if (materialsObList.size() >= 5) {
//                                    break;
//                                }
//                                if (material.getType() == -2) {
//                                    if (material.getMaterials().size() > 0) {
//                                        material.getMaterials().sort((o1, o2) -> {
//                                            int a = Integer.parseInt(o1.getCreateTime());
//                                            int b = Integer.parseInt(o2.getCreateTime());
//                                            return b - a;
//                                        });
//                                        MaterialsFolderViewModel<StudentDetailV2VM> item = new MaterialsFolderViewModel<>(this, material);
//                                        materialsObList.add(item);
//                                    }
//                                } else if (material.getType() != -1) {
//                                    if (material.getFolder().equals("") || !folderIds.contains(material.getFolder())) {
//                                        if (material.getType() == 6) {
//                                            MaterialsLinkVMV2<StudentDetailV2VM> item = new MaterialsLinkVMV2<>(this,
//                                                    material);
//                                            materialsObList.add(item);
//                                        } else {
//                                            MaterialsGridVMV2<StudentDetailV2VM> item = new MaterialsGridVMV2<>(this,
//                                                    material);
//                                            materialsObList.add(item);
//                                        }
//                                    }
//                                }
//                            }
//                            uc.materialsObserverData.setValue(materialsObList);

                        }, throwable -> {
                            if (!isSuccess.get()) {
                                materialIsVisible.set(false);
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            }
                        })
        );
    }


    /**
     * 获取Note
     */
    private void getNote() {
        AtomicBoolean isSuccess = new AtomicBoolean(false);

        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleByStudentIdAndTeacherId(studentData.getTeacherId(), studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            isSuccess.set(true);
                            setAttendanceData(CloneObjectUtils.cloneObject(data));
                            allLessonData = data;
                            noteLessonData.clear();
                            for (LessonScheduleEntity item : data) {
                                if (!item.getTeacherNote().equals("") || !item.getStudentNote().equals("")) {
                                    noteLessonData.add(item);
                                }
                            }
                            if (allLessonData.size() > 0) {
                                initHomeworkData(allLessonData.get(allLessonData.size() - 1).getShouldDateTime());
                            } else {
                                practiceIsVisible.set(false);
                            }
                            if (noteLessonData.size() > 0) {
                                notesDate.set(TimeUtils.timeFormat(noteLessonData.get(0).getTKShouldDateTime(), "dd"));
                                notesDateMonth.set(TimeUtils.timeFormat(noteLessonData.get(0).getTKShouldDateTime(), "MMM"));
                                String noteString = "";
                                if (!noteLessonData.get(0).getTeacherNote().equals("")) {
                                    noteString = noteLessonData.get(0).getTeacherNote();
                                } else if (!noteLessonData.get(0).getStudentNote().equals("")) {
                                    noteString = noteLessonData.get(0).getStudentNote();
                                }
                                notes.set(noteString);
                                if (noteString.equals("")) {
                                    noteIsVisible.set(false);
                                } else {
                                    noteIsVisible.set(true);
                                }
                            } else {
                                noteIsVisible.set(false);

                            }

                        }, throwable -> {
                            if (!isSuccess.get()) {
                                noteIsVisible.set(false);
                                practiceIsVisible.set(false);
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            }
                        })
        );
    }

    private void setAttendanceData(List<LessonScheduleEntity> lessonData) {
        int nowTime = TimeUtils.getCurrentTime();
        List<LessonScheduleEntity> data = lessonData.stream().filter(it -> it.getShouldDateTime() <= nowTime).sorted((t0, t1) -> (int) (t1.getShouldDateTime() - t0.getShouldDateTime())).collect(Collectors.toList());
        attendanceListData = data;
        LessonScheduleEntity attendanceData = null;
        for (LessonScheduleEntity item : data) {
            if (item.getAttendance().size() > 0) {
                attendanceData = item;
                break;
            }
        }

        if (attendanceData != null) {
            attendanceIsHave.set(true);
            attendanceFirstString.set("Attendance: " + attendanceData.getAttendance().get(0).showString());
        } else {
            attendanceIsHave.set(false);
        }
    }

    /**
     * 获取作业
     *
     * @param startTime 从什么时间开始获取
     */
    @SuppressLint("DefaultLocale")
    private void initHomeworkData(long startTime) {
        AtomicBoolean isSuccess = new AtomicBoolean(false);

        addSubscribe(
                LessonService
                        .getInstance()
                        .getPracticeByStudentIdAndStartTime(0, studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            isSuccess.set(true);
                            practicesData.clear();
                            for (TKPractice practiceItem : data) {
                                if (practiceItem.isAssignment()) {
                                    int index = -1;
                                    for (int i = 0; i < practicesData.size(); i++) {
                                        TKPractice newItem = practicesData.get(i);
                                        if (newItem.getLessonScheduleId().equals(practiceItem.getLessonScheduleId())
                                                && newItem.getName().equals(practiceItem.getName())
                                                && newItem.getStartTime() == practiceItem.getStartTime()) {
                                            index = i;
                                        }
                                    }
                                    if (index >= 0) {
                                        practicesData.get(index).getRecordData().addAll(practiceItem.getRecordData());
                                        if (practiceItem.isDone()) {
                                            practicesData.get(index).setDone(true);
                                        }
                                        practicesData.get(index).setTotalTimeLength(practicesData.get(index).getTotalTimeLength()
                                                + practiceItem.getTotalTimeLength());
                                    } else {
                                        practicesData.add(practiceItem);
                                    }
                                } else {
                                    practicesData.add(practiceItem);
                                }
                            }
                            if (practicesData.size() > 0) {
                                double doneCount = 0;
                                double totalPractice = 0;
                                int assignmentCount = 0;
                                for (TKPractice item : practicesData) {
                                    if (item.isAssignment()) {
                                        assignmentCount += 1;
                                        if (item.isDone()) {
                                            doneCount += 1;
                                        }
                                    }
                                    if (!item.isAssignment()) {
                                        totalPractice += item.getTotalTimeLength();
                                    }
                                }
                                if (totalPractice > 0) {
                                    totalPractice = totalPractice / 60 / 60;
                                    if (totalPractice <= 0.1) {
                                        practiceHrsString.set("0.1 hrs");
                                    } else {
                                        practiceHrsString.set(String.format("%.1f", totalPractice) + " hrs");
                                    }
                                } else {
                                    practiceHrsString.set("0 hrs");
                                }
                                if (doneCount != 0) {
                                    doneCount = doneCount / (double) practicesData.size();
                                }
                                if (assignmentCount > 0) {
                                    assignmentString.set(((int) (doneCount * 100)) + "% completion");
                                } else {
                                    assignmentString.set("No assignment");
                                }
                                practiceIsVisible.set(true);
                            } else {
                                practiceIsVisible.set(false);
                            }

                        }, throwable -> {
                            if (!isSuccess.get()) {
                                practiceIsVisible.set(false);
                                Logger.e("失败,失败原因" + throwable.getMessage());
                            }
                        })

        );
    }

    /**
     * 获取Achievement
     */
    private void getAchievement() {
        List<StudentListEntity> studentListEntities = ListenerService.shared.teacherData.getStudentList();
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                UserService
                        .getInstance()
                        .getAchievementByTId(studentData.getTeacherId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(value -> {
                            isSuccess.set(true);
                            achievementData.clear();
                            Map<String, Integer> map = new HashMap<>();
                            //教师的achievementList 和学生列表 计算出每个学生有多少个achievement
                            for (int i = 0; i < value.size(); i++) {
                                String studentId = value.get(i).getStudentId();
                                for (StudentListEntity studentListEntity : studentListEntities) {

                                    if (map.get(studentListEntity.getStudentId()) != null) {
                                        if (studentId.equals(studentListEntity.getStudentId())) {
                                            map.put(studentListEntity.getStudentId(), map.get(studentListEntity.getStudentId()) + 1);
                                        }
                                    } else {
                                        if (studentId.equals(studentListEntity.getStudentId())) {
                                            map.put(studentListEntity.getStudentId(), 1);
                                        } else {
                                            map.put(studentListEntity.getStudentId(), 0);
                                        }
                                    }
                                }
                                if (studentId.equals(studentData.getStudentId())) {
                                    achievementData.add(value.get(i));
                                }
                            }
                            int index = getAchievementRanking(map);
                            if (index != 0) {
                                double num = (double) index / (double) map.size() * 100d;
                                top.set("Top " + (int) num + "%");
                            }
                            if (achievementData.size() > 0) {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    achievementData.sort((o1, o2) -> {
                                        int oT1 = Integer.parseInt(o1.getDate());
                                        int oT2 = Integer.parseInt(o2.getDate());
                                        return oT1 - oT2;
                                    });
                                }

                                total.set(achievementData.size() + " badges");
                                achievementType.set(achievementData.get(achievementData.size() - 1).getTypeString() + ": ");
                                achievementTitle.set(achievementData.get(achievementData.size() - 1).getName());
                                achievementIsVisible.set(true);
                            } else {
                                achievementIsVisible.set(false);
                            }
                        }, throwable -> {
                            if (!isSuccess.get()) {
                                achievementIsVisible.set(false);
                            }
                        }));

    }

    /**
     * 获取排名
     *
     * @param map
     * @return
     */
    private Integer getAchievementRanking(Map<String, Integer> map) {
        LinkedHashMap<String, Integer> linkedHashMap = new LinkedHashMap<>();
        List<Map.Entry<String, Integer>> list = new ArrayList<Map.Entry<String, Integer>>(map.size());
        list.addAll(map.entrySet());
        int num = map.size();
        for (int i = 0; i < num - 1; i++) {
            for (int j = 0; j < num - i - 1; j++) {
                Map.Entry<String, Integer> e1 = list.get(j);
                Map.Entry<String, Integer> e2 = list.get(j + 1);
                if (e1.getValue() < e2.getValue()) {
                    Collections.swap(list, j, j + 1);
                }
            }
        }
        for (int n = 0; n <= num - 1; n++) {
            Map.Entry<String, Integer> entry = list.get(n);
            linkedHashMap.put(entry.getKey(), entry.getValue());
        }
        int index = 0;
        int lastCount = -1;
        for (Map.Entry<String, Integer> item : linkedHashMap.entrySet()) {
            if (lastCount - item.getValue() != 0) {
                lastCount = item.getValue();
                index += 1;
                if (item.getKey().equals(studentData.getStudentId())) {
                    break;
                }
            }
        }
        return index;

    }

    /**
     * 获取学生信息
     */
    private void getUserInfo() {
        addSubscribe(
                UserService.getInstance().getUserById(studentData.getStudentId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(userEntity -> {

                            if (isStudentLook.get()) {

                                name.set(userEntity.getName());
                                email.set(userEntity.getEmail());
                            }
                            studentIsActive = userEntity.isActive();
                            if (userEntity.isActive() && !isStudentLook.get()) {
                                studentInfoRightImg.set(R.mipmap.icinfo3x);
                            } else {
                                studentInfoRightImg.set(R.mipmap.next);
                            }
                            if (userEntity.getBirthday() == 0) {
                                birthdayString.set("Optional");
                                birthday = 0;
                            } else {
                                birthday = userEntity.getBirthday();
                                birthdayString.set(TimeUtils.timeFormat((long) userEntity.getBirthday(), "MM/dd/yyyy"));
                            }
                        }, throwable -> {

                        })
        );
    }

    /**
     * 获取Lesson type
     */
    private void getLessonType(boolean isCache) {
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .getLessonTypeListByTeacherId(studentData.getTeacherId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(value -> {
                            lessonTypeEntities.clear();
                            lessonTypeEntities.addAll(value);
                            Logger.e("获取到的Lesson type 个数:%s", lessonTypeEntities.size());
                            getScheduleConfig(isCache);
                        }, throwable -> {
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                            Logger.e("=====getLessonType=" + throwable.getMessage());
                        })
        );

        if (SLCacheUtil.getStudioInfo() != null && !SLCacheUtil.getStudioInfo().getStudioType().equals(StudioInfoEntity.StudioType.singleInstructor)) {
            UserService
                    .getStudioInstance()
                    .getLessonTypeListByStudioId(studentData.getTeacherId(), isCache)
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread(), true)
                    .subscribe(value -> {
                        lessonTypeEntities.clear();
                        lessonTypeEntities.addAll(value);
                        Logger.e("获取到的Lesson type 个数:%s", lessonTypeEntities.size());
                        getScheduleConfig(isCache);
                    }, throwable -> {
                        isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                        isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                        if (isShowBalanceNextBill.get()) {
                            addInvoiceString.set("Record Payment");
                        } else {
                            addInvoiceString.set("Add Invoice");
                        }
                        Logger.e("=====getLessonType=" + throwable.getMessage());
                    });
        } else {

        }

    }

    /**
     * 获取课程详细信息
     */
    private void getScheduleConfig(boolean isCache) {
        AtomicBoolean isSuccess = new AtomicBoolean(false);
        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleConfigByStudentIdAndNoDelete(studentData.getStudentId(), studentData.getTeacherId(), isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            isSuccess.set(true);
                            scheduleConfigData.clear();
                            for (LessonScheduleConfigEntity item : data) {
                                for (LessonTypeEntity lessonTypeEntity : lessonTypeEntities) {
                                    if (item.getLessonTypeId().equals(lessonTypeEntity.getId())) {
                                        item.setLessonType(lessonTypeEntity);
                                    }
                                }
                                if (item.getLessonType() != null) {
                                    scheduleConfigData.add(item);
                                }
                            }
                            lessonObList.clear();
                            if (isStudentLook.get()) {
                                lessonEditIsVisible.set(false);
                                isShowLesson.set(scheduleConfigData.size() > 0);
                            } else {
                                if (scheduleConfigData.size() > 0) {
                                    lessonEditIsVisible.set(true);
                                    if (isEdit) {

                                        addLessonButtonIsVisible.set(isCanSetupLesson4Create);
                                    } else {
                                        addLessonButtonIsVisible.set(false);

                                    }
                                } else {
                                    lessonEditIsVisible.set(false);
                                    addLessonButtonIsVisible.set(isCanSetupLesson4Create);
                                    isEdit = false;
                                }
                            }
                            try {
                                scheduleConfigData.sort((o1, o2) -> (Integer.parseInt(o2.getCreateTime())) - Integer.parseInt(o1.getCreateTime()));
                            } catch (Throwable e) {
                                Logger.e("排序失败==>%s", e.getMessage());
                            }
                            for (int i = 0; i < scheduleConfigData.size(); i++) {
                                StudentDetailProfileFragmentItemViewModel itemViewModel = new StudentDetailProfileFragmentItemViewModel(this, scheduleConfigData.get(i), isEdit);
                                lessonObList.add(itemViewModel);
                            }
                            for (int i = 0; i < scheduleConfigData.size(); i++) {
                                String lessonEndTimeAndCount = CalendarService.getInstance().getLessonEndTimeAndCount(scheduleConfigData.get(i));
                                lessonObList.get(i).setTimeInfo(lessonEndTimeAndCount, lessonEndTimeAndCount.equals("Ended") ? 1 : 0);
                            }
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                            initTimeInfo(rescheduleTimeData);
                            loadAllRecentllyReschedule(isCache);
                        }, throwable -> {
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    public void loadAllRecentllyReschedule(boolean isCache) {
        List<String> ids = new ArrayList<>();

        for (LessonScheduleConfigEntity item : scheduleConfigData) {
            ids.add(item.getId());
        }
        addSubscribe(
                LessonService
                        .getInstance()
                        .getRescheduleByConfigIds(ids, isCache)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            rescheduleTimeData = data;
                            initTimeInfo(rescheduleTimeData);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );

    }

    private void initTimeInfo(Map<String, LessonRescheduleEntity> data) {
        data.forEach((configId, lessonRescheduleEntity) -> {
            for (StudentDetailProfileFragmentItemViewModel item : lessonObList) {
                if (item.data.getId().equals(configId)) {
                    long after = Long.parseLong(lessonRescheduleEntity.getTKBefore());
                    long before = Long.parseLong(lessonRescheduleEntity.getTKAfter());
                    Calendar afterDay = TimeUtils.getStartDay((int) after);
                    Calendar beforeDay = TimeUtils.getStartDay((int) before);
                    boolean isSameDay = afterDay.getTimeInMillis() == beforeDay.getTimeInMillis();

                    String infoString = "";

                    if (item.data.getRepeatType() == 0) {
                        infoString = "Has been rescheduled to " + TimeUtils.timeFormat(after, "EEEE") + (isSameDay ? "" : TimeUtils.timeFormat(after, " MM/dd/yyyy") + " at " + TimeUtils.timeFormat(after, "hh:mm a"));
                    } else {
                        infoString = "The lesson on " + TimeUtils.timeFormat(before, "EEEE MM/dd/yyyy") + " at " + TimeUtils.timeFormat(before, "hh:mm a") + " has been rescheduled to " + (isSameDay ? "" : TimeUtils.timeFormat(after, "EEEE MM/dd/yyyy ")) + "at " + TimeUtils.timeFormat(after, "hh:mm a");
                    }
                    item.setTimeInfo(infoString, 1);
                }
            }
        });
    }


    /**
     * 修改学生邮件
     *
     * @param studentListEntity
     */
    public void updateEmail(StudentListEntity studentListEntity) {
        Map<String, Object> map = new HashMap<>();
        map.put("uId", studentListEntity.getStudentId());
        map.put("email", studentListEntity.getEmail());
        showDialog();
        CloudFunctions
                .editEmail(map)
                .addOnCompleteListener(task -> {
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult()) {
                            updateStudent(studentListEntity, false, true);
                        }
                    } else {
                        dismissDialog();
                        Logger.e("======  异常:" + task.getException().getMessage());
                        SLToast.error("Update failed, please try again!");
                    }

                });
    }

    /**
     * 修改学生信息
     *
     * @param studentListEntity
     * @param isLoading
     */
    public void updateStudent(StudentListEntity studentListEntity, boolean isLoading, boolean isEditUser) {
        if (isLoading) {
            showDialog();
        }
        Map<String, Object> map = new HashMap<>();
        map.put("name", studentListEntity.getName());
        map.put("phone", studentListEntity.getPhone());
        map.put("email", studentListEntity.getEmail());

        name.set(studentListEntity.getName());
        email.set(studentListEntity.getEmail());
        this.studentData.setPhone(studentListEntity.getPhone());
        this.studentData.setEmail(studentListEntity.getEmail());
        this.studentData.setName(studentListEntity.getName());
        addSubscribe(UserService
                .getStudioInstance()
                .updateStudentListAndUserList(map, studentListEntity.getStudentId(), isEditUser)
                .subscribe(status -> {
                    //刷新列表
                    dismissDialog();
                    SLToast.success("Save Successful!");
                }, throwable -> {
                    dismissDialog();

                    Logger.e("=====更新失败=" + throwable.getMessage());
                    SLToast.error("Save failed, please try again!");
                }));
    }

    /**
     * 删除lesson
     *
     * @param pos
     */
    public void removeLesson(Integer pos) {


        showDialog();
        int starTime = 0;
        LessonScheduleConfigEntity data = lessonObList.get(pos).data;
        starTime = data.getStartDateTime();
        String studentId = data.getStudentId();
        Map<String, Object> map = new HashMap<>();
        map.put("time", TimeUtils.getCurrentTime());
        map.put("configId", data.getId());
        map.put("studentId", studentId);
        map.put("teacherId", data.getTeacherId());
        map.put("newScheduleData", "");


        if ((data.getRepeatType() == 0 && starTime >= TimeUtils.getCurrentTime()) || starTime >= TimeUtils.getCurrentTime()) {
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
                            Logger.e("====== 删除 config 成功:" + pos);
                            lessonObList.remove(lessonObList.get(pos));
                            isShowBalance.set(isShowBalanceLastPayment.get() || isShowBalanceNextBill.get() || lessonObList.size() > 0);
                            isShowAddInvoiceButton.set(isShowBalance.get() && !isStudentLook.get());
                            if (isShowBalanceNextBill.get()) {
                                addInvoiceString.set("Record Payment");
                            } else {
                                addInvoiceString.set("Add Invoice");
                            }
//                            lessonObList.remove(pos);
                            if (lessonObList.size() > 0) {
                                dismissDialog();
                                SLToast.success("Successfully deleted!");
                            } else {
                                updateStudentList(studentId);
                                lessonEditIsVisible.set(false);
                                addLessonButtonIsVisible.set(isCanSetupLesson4Create);
                            }
                        }
                    } else {
                        Logger.e("====== 删除 lesson 异常:" + task.getException().getMessage());
                        SLToast.error("Please check your connection and try again.");
                    }
                });
    }

    private void updateStudentList(String studentId) {
        Map<String, Object> map = new HashMap<>();
        map.put("invitedStatus", "3");
        addSubscribe(UserService
                .getStudioInstance()
                .updateStudentListAndUserList(map, studentId, true)
                .subscribe(status -> {
                    //刷新列表
                    dismissDialog();
                    SLToast.success("Successfully deleted!");
                }, throwable -> {
                    dismissDialog();
                    Logger.e("=====更新失败=" + throwable.getMessage());
                    SLToast.error("Please check your connection and try again.");
                }));
    }

    //封装一个点击事件观察者
    public StudentDetailV2VM.UIClickObservable uc = new UIClickObservable();

    public void clickItem(MaterialEntity materialEntity, View view) {
        Map<String, Object> map = new HashMap<>();
        map.put("data", materialEntity);
        map.put("view", view);
        uc.clickMaterialItem.setValue(map);
    }

    public static class UIClickObservable {
        public SingleLiveEvent<Void> clickInfo = new SingleLiveEvent<>();
        public SingleLiveEvent<Integer> clickDeleteLesson = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickAddLessonType = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clickStudentPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<Integer> clickLessonItem = new SingleLiveEvent<>();
        public SingleLiveEvent<String> refreshAvatar = new SingleLiveEvent<>();
        public SingleLiveEvent<ObservableList<MaterialsMultiItemViewModel>> materialsObserverData =
                new SingleLiveEvent<>();

        /**
         * 点击Item
         */
        public SingleLiveEvent<Map<String, Object>> clickMaterialItem = new SingleLiveEvent<>();


        /**
         * 进入materials 详情页
         */
        public SingleLiveEvent<List<MaterialEntity>> clickMaterialMore = new SingleLiveEvent<>();


    }

    public BindingCommand clickInfo = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            if (isStudentLook.get()) {
                Bundle bundle = new Bundle();
                bundle.putBoolean("isProfileComeIn", false);
                startActivity(StudentProfileEditActivity.class, bundle);
            } else {
                uc.clickInfo.call();
            }
        }
    });


    public BindingCommand clickEdit = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            changeEdit();
        }
    });

    public void changeEdit() {

        if (isEdit) {
//            editString.set("Add / Delete");
            if (isCanSetupLesson4EditAndDelete){
                if (isCanSetupLesson4Create) {
                    editString.set("Add / Delete");
                }else {
                    editString.set("Delete");
                }
            }else {
                if (isCanSetupLesson4Create) {
                    editString.set("Add");
                }else {
                    editString.set("");
                }
            }
        } else {
            editString.set("Done");
        }
        isEdit = !isEdit;
        if (isEdit) {

            addLessonButtonIsVisible.set(isCanSetupLesson4Create);
        } else {
            addLessonButtonIsVisible.set(false);

        }
        if (isCanSetupLesson4EditAndDelete) {
            for (StudentDetailProfileFragmentItemViewModel itemViewModel : lessonObList) {
                itemViewModel.changeEditType(isEdit);
            }
        }
    }

    public void closeEdit() {
        if (isCanSetupLesson4EditAndDelete){
            if (isCanSetupLesson4Create) {
                editString.set("Add / Delete");
            }else {
                editString.set("Delete");
            }
        }else {
            if (isCanSetupLesson4Create) {
                editString.set("Add");
            }else {
                editString.set("");
            }
        }
        isEdit = false;
        if (lessonObList.size() > 0) {
            addLessonButtonIsVisible.set(false);
        } else {
            addLessonButtonIsVisible.set(true);
        }
        for (StudentDetailProfileFragmentItemViewModel itemViewModel : lessonObList) {
            itemViewModel.changeEditType(false);
        }
    }

    public BindingCommand clickAddLessonType = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.clickAddLessonType.call();

        }
    });

    public BindingCommand linPractice = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.clickStudentPractice.call();
        }
    });
    public BindingCommand clickBalance = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            List<LessonScheduleConfigEntity> data = new ArrayList<>();
            for (StudentDetailProfileFragmentItemViewModel d : lessonObList) {
                data.add(d.data);
            }
            Bundle bundle = new Bundle();
            bundle.putSerializable("studentData", studentData);
            bundle.putSerializable("lessonConfigs", (Serializable) data);
            if (isStudentLook.get()) {
                bundle.putSerializable("role", 2);
            }else {
                bundle.putSerializable("role", 1);
            }
            startActivity(BalanceListAc.class, bundle);
        }
    });

    public BindingCommand clickAchievement = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            Bundle bundle = new Bundle();
            bundle.putSerializable("data", (Serializable) achievementData);
            bundle.putSerializable("studentData", studentData);
            bundle.putSerializable("isStudentLook", isStudentLook.get());
            startActivity(AchievementActivity.class, bundle);
        }
    });
    public BindingCommand clickNote = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            Bundle bundle = new Bundle();
            bundle.putSerializable("data", (Serializable) noteLessonData);
            startActivity(NotesActivity.class, bundle);

        }
    });
    public BindingCommand linMaterials = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.clickMaterialMore.call();
        }
    });
    public BindingCommand clickArchive = new BindingCommand(() -> {
        Dialog dialog = SLDialogUtils.showTwoButton(TApplication.currentActivity.get(), "", "Are you sure to Archive this student?", "Archive", "Go back");
        TextView leftButton = (TextView) dialog.findViewById(R.id.left_button);
        leftButton.setTextColor(ContextCompat.getColor(getApplication(), R.color.red));
        leftButton.setOnClickListener(v -> {
            dialog.dismiss();
            showDialog();
            List<String> id = new ArrayList<>();
            id.add(studentData.getStudentId());

            CloudFunctions
                    .archiveStudent(id)
                    .addOnCompleteListener(task -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            if (task.getResult() != null && task.getResult()) {
                                Logger.e("====== archiveStudent 成功:" + task.getResult());
                                SLToast.success("Archive Successfully!");
                                clearLesson();
                            } else {
                                SLToast.showError();
                            }
                        } else {
                            Logger.e("====== archiveStudent 异常:" + task.getException().getMessage());
                            SLToast.showError();
                        }

                    });
        });

    });

    private void clearLesson() {
        isEdit = false;
        editString.set("Add / Delete");
        addLessonButtonIsVisible.set(isCanSetupLesson4Create);
        lessonEditIsVisible.set(false);
        lessonObList.clear();
    }

    public BindingCommand clickDelete = new BindingCommand(() -> {
        Dialog dialog = SLDialogUtils.showTwoButton(TApplication.currentActivity.get(), "", "Are you sure to delete this student?", "Delete", "Go back");
        TextView leftButton = (TextView) dialog.findViewById(R.id.left_button);
        leftButton.setTextColor(ContextCompat.getColor(getApplication(), R.color.red));
        leftButton.setOnClickListener(v -> {
            dialog.dismiss();
            showDialog();
            List<String> id = new ArrayList<>();
            id.add(studentData.getStudentId());
            CloudFunctions
                    .deleteStudent(id)
                    .addOnCompleteListener(task -> {
                        dismissDialog();
                        if (task.isSuccessful()) {
                            if (task.getResult() != null && task.getResult()) {
                                SLToast.success("Deleted Successfully!");
                                finish();
                            } else {
                                SLToast.showError();

                            }
                        } else {
                            Logger.e("====== 删除 Student 异常:" + task.getException().getMessage());
                            SLToast.showError();
                        }

                    });
        });

    });
    public BindingCommand clickChat = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            toChatDetail();
        }
    });
    public BindingCommand clickAttendance = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            Bundle bundle = new Bundle();
            List<LessonScheduleEntity> data = new ArrayList<>();
            if (attendanceListData.size()>50){
                for (int i = 0; i < attendanceListData.size(); i++) {
                    if (i<=50){
                        data.add(attendanceListData.get(i));
                    }
                }
            }else{
                data = attendanceListData;
            }

            bundle.putSerializable("data", (Serializable) data);
            startActivity(AttendanceListAc.class,bundle);

        }
    });


    //给RecyclerView添加ObservableList
    public ObservableList<StudentDetailProfileFragmentItemViewModel> lessonObList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<StudentDetailProfileFragmentItemViewModel> lessonItemBinding = ItemBinding.of(new OnItemBind<StudentDetailProfileFragmentItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, StudentDetailProfileFragmentItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_lesson_during);
        }
    });

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


    /**
     * lessonItem点击事件
     */
    public void clickLessonItem(LessonScheduleConfigEntity data) {
        if (isStudentLook == null || isStudentLook.get()) {
            return;
        }


        int pos = 0;
        for (int i = 0; i < lessonObList.size(); i++) {
            if (lessonObList.get(i).data.getId().equals(data.getId())) {
                pos = i;
            }
        }
        if (isEdit) {
            uc.clickDeleteLesson.setValue(pos);
        } else {
            if (isCanSetupLesson4EditAndDelete){
                uc.clickLessonItem.setValue(pos);
            }
        }
    }

    public void toChatDetail() {
        if (studentData == null) {
            return;
        }
        addSubscribe(ChatService.getConversationInstance()
                .getFromLocal(ChatService.getConversationInstance().getPrivateConversationId(studentData.getStudentId()))
                .flatMap(conversation -> {
                    if (conversation.getId().equals("-1")) {
                        showDialog();
                        return ChatService.getConversationInstance().getPrivateWithoutLocal(studentData.getStudentId());
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
                    dismissDialog();
                    Bundle bundle = new Bundle();
                    bundle.putSerializable("conversation", data);
                    startActivity(ChatActivity.class, bundle);
                }, throwable -> {
                    dismissDialog();
                    SLToast.showError();
                    Logger.e("失败,失败原因" + throwable.getMessage());
                })

        );
    }

    public void updateBirthday() {
        setIsShowProgress(true);
        Map<String, Object> map = new HashMap<>();
        map.put("birthday", birthday);
        DatabaseService.Collections.user()
                .document(studentData.getStudentId())
                .set(map, SetOptions.merge())
                .addOnCompleteListener(runnable -> {
                    setIsShowProgress(false);
                });
    }
    public void updateMemo(String memo) {
        setIsShowProgress(true);
        Map<String, Object> map = new HashMap<>();
        map.put("memo", memo);
        String id = studentData.getId();
        if (id==null||id.equals("")){
            id = studentData.getTeacherId()+":"+studentData.getStudentId();
        }
        DatabaseService.Collections.teacherStudentList()
                .document(id)
                .set(map, SetOptions.merge())
                .addOnCompleteListener(runnable -> {
                    setIsShowProgress(false);
                });
    }
}
