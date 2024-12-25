package com.spelist.tunekey.ui.student.sPractice.vm;

import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.DatabaseService;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.activity.recordVideo.RecordVideoAc;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTimeUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

/**
 * com.spelist.tunekey.ui.sPractice.vm
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeFragmentV2VM extends ToolbarViewModel {
    public int endTimestamp;
    public int startTimestamp;
    public List<TKPracticeAssignment> practiceData = new ArrayList<>();
    public List<TKPracticeAssignment> allData = new ArrayList<>();
    public List<TKPractice> practiceHistoryData = new ArrayList<>();
    private int previousCount = 0;
    private int previousPreviousCount = 0;
    private boolean isLoadPreAssignmentData = false;
    public LessonScheduleEntity preLessonData;
    public String studentId = "";


    public StudentPracticeFragmentV2VM(@NonNull Application application) {
        super(application);
        initData();
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Practice");
        setLeftImgButtonVisibility(View.GONE);
    }

    public UIEventObservable uc = new UIEventObservable();


    public static class UIEventObservable {
        public SingleLiveEvent<Void> refData = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> stopMetronome = new SingleLiveEvent<>();

        public SingleLiveEvent<Integer> clickLogAndStartPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> clickPlayPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> recordPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> recordVideoPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> recordVideoDone = new SingleLiveEvent<>();
        public SingleLiveEvent<TKPractice> recordAudioDone = new SingleLiveEvent<>();

        public SingleLiveEvent<List<TKPractice>> logForDay = new SingleLiveEvent<>();

    }

    @Override
    protected void initMessengerData() {
        super.initMessengerData();
        Messenger.getDefault().register(this, MessengerUtils.PARENT_SELECT_KIDS_DONE, () -> {
            studentId = ListenerService.shared.studentData.getUser().getUserId();
            initData();
        });
        Messenger.getDefault().register(this, RecordVideoAc.RECORD_MESSAGE, TKPractice.class, new BindingConsumer<TKPractice>() {
            @Override
            public void call(TKPractice tkPractice) {
                uploadPractice(CloneObjectUtils.cloneObject(tkPractice), true);

            }
        });
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_PRACTICE_CHANGED, () -> {
            TKPracticeAssignment pData = new TKPracticeAssignment();
            pData.setStartTime(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L);
            pData.setEndTime(pData.getStartTime() + 86399);
            practiceData.clear();
            allData.clear();
            practiceData.add(pData);
            allData.add(CloneObjectUtils.cloneObject(pData));
            List<TKPractice> practiceData = new ArrayList<>();
            for (TKPractice item : ListenerService.shared.studentData.getPracticeData()) {
                practiceData.add(CloneObjectUtils.cloneObject(item));
            }
            practiceData.sort(Comparator.comparing(TKPractice::getStartTime).reversed());
            initShowData(practiceData);
        });
        Messenger.getDefault().register(this, MessengerUtils.STOP_METRONOME, () -> uc.stopMetronome.call());


    }

    private void initData() {
        studentId = ListenerService.shared.studentData.getUser().getUserId();
        int time = (int) (TimeUtils.addDay(TimeUtils.getCurrentTime() * 1000L, +1) / 1000L);
        endTimestamp = (int) (TimeUtils.getStartDay(time).getTimeInMillis() / 1000L - 1);
        startTimestamp = (int) (TimeUtils.addMonth(endTimestamp * 1000L, -3) / 1000L);
        TKPracticeAssignment pData = new TKPracticeAssignment();
        pData.setStartTime(TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L);
        pData.setEndTime(pData.getStartTime() + 86399);
        practiceData.add(pData);
        allData.add(CloneObjectUtils.cloneObject(pData));
        getPreLesson();
        getPracticeData();
    }

    private void getPreLesson() {
        List<TKPractice> listenerPracticeData = new ArrayList<>();
        for (TKPractice item : ListenerService.shared.studentData.getPracticeData()) {
            listenerPracticeData.add(CloneObjectUtils.cloneObject(item));
        }
        listenerPracticeData.sort(Comparator.comparing(TKPractice::getStartTime).reversed());
        initShowData(listenerPracticeData);
        List<String> configIds = new ArrayList<>();

        for (LessonScheduleConfigEntity scheduleConfig : ListenerService.shared.studentData.getScheduleConfigs()) {
            if (scheduleConfig.getLessonCategory() == LessonTypeEntity.TKLessonCategory.group&&scheduleConfig.getGroupLessonStudents().get(studentId)!=null) {
                    LessonScheduleConfigEntity.GroupLessonStudent groupLessonStudent = SLJsonUtils.toBean(SLJsonUtils.toJsonString(scheduleConfig.getGroupLessonStudents().get(studentId)), LessonScheduleConfigEntity.GroupLessonStudent.class);
                    if (groupLessonStudent.getStatus() == LessonScheduleConfigEntity.GroupLessonStudent.Status.active) {
                        configIds.add(scheduleConfig.getId());
                    }
            }else {
                if (scheduleConfig.getStudentId().equals(studentId)) {
                    configIds.add(scheduleConfig.getId());
                }
            }
        }
        List<LessonScheduleEntity> byStudentIdWithLastLessonTime = AppDataBase.getInstance().lessonDao().getByStudentIdWithLastLessonTime(studentId, TimeUtils.getCurrentTime(), configIds);
        if (byStudentIdWithLastLessonTime != null && byStudentIdWithLastLessonTime.size() > 0) {
            preLessonData = byStudentIdWithLastLessonTime.get(0);
            List<TKPractice> addData = new ArrayList<>();
            List<TKPractice> needAddData = new ArrayList<>();
            for (TKPracticeAssignment item : allData) {
                for (TKPractice practiceItem : item.getPractice()) {
                    if (practiceItem.getLessonScheduleId().equals(preLessonData.getId())) {
                        addData.add(practiceItem);
                    }
                }

            }
            for (TKPractice addItem : addData) {
                boolean isHave = false;
                for (TKPractice item : practiceData.get(0).getPractice()) {
                    if (addItem.getId().equals(item.getId()) || addItem.getAssignmentId().equals(item.getAssignmentId())) {
                        isHave = true;
                    }
                }
                if (!isHave) {
                    TKPractice add = new TKPractice()
                            .setId(IDUtils.getId())
                            .setStartTime((int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L) + 10)
                            .setTotalTimeLength(0)
                            .setDone(false)
                            .setRecordData(new ArrayList<>())
                            .setName(addItem.getName())
                            .setStudentId(addItem.getStudentId())
                            .setTeacherId(addItem.getTeacherId())
                            .setAssignment(true)
                            .setAssignmentId(addItem.getAssignmentId())
                            .setScheduleConfigId(addItem.getScheduleConfigId())
                            .setLessonScheduleId(addItem.getLessonScheduleId())
                            .setShouldDateTime(addItem.getShouldDateTime())
                            .setCreateTime(addItem.getCreateTime())
                            .setUpdateTime(addItem.getUpdateTime());
                    practiceData.get(0).getPractice().add(add);
                    needAddData.add(add);
                }
            }
            if (needAddData.size() > 0) {
                addPractice(needAddData, false, false, false);
            }
            sortData();
            uc.refData.call();
        }else {

        }

//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .getPreviousLessonByStudentId(studentId)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(data -> {
//                            Logger.e("data==>%s",(data != null));
//                            if (data != null) {
//                                preLessonData = data;
//                                List<TKPractice> addData = new ArrayList<>();
//                                List<TKPractice> needAddData = new ArrayList<>();
//                                for (TKPracticeAssignment item : allData) {
//
//                                    for (TKPractice practiceItem : item.getPractice()) {
//                                        if (practiceItem.getLessonScheduleId().equals(data.getId())) {
//                                            addData.add(practiceItem);
//                                        }
//                                    }
//
//                                }
//                                for (TKPractice addItem : addData) {
//                                    boolean isHave = false;
//                                    for (TKPractice item : practiceData.get(0).getPractice()) {
//                                        if (addItem.getId().equals(item.getId()) || addItem.getAssignmentId().equals(item.getAssignmentId())) {
//                                            isHave = true;
//                                        }
//                                    }
//                                    if (!isHave) {
//                                        TKPractice add = new TKPractice()
//                                                .setId(IDUtils.getId())
//                                                .setStartTime((int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L) + 10)
//                                                .setTotalTimeLength(0)
//                                                .setDone(false)
//                                                .setRecordData(new ArrayList<>())
//                                                .setName(addItem.getName())
//                                                .setStudentId(addItem.getStudentId())
//                                                .setTeacherId(addItem.getTeacherId())
//                                                .setAssignment(true)
//                                                .setAssignmentId(addItem.getAssignmentId())
//                                                .setScheduleConfigId(addItem.getScheduleConfigId())
//                                                .setLessonScheduleId(addItem.getLessonScheduleId())
//                                                .setShouldDateTime(addItem.getShouldDateTime())
//                                                .setCreateTime(addItem.getCreateTime())
//                                                .setUpdateTime(addItem.getUpdateTime());
//                                        practiceData.get(0).getPractice().add(add);
//                                        needAddData.add(add);
//                                    }
//                                }
//                                if (needAddData.size() > 0) {
//                                    addPractice(needAddData, false, false, false);
//                                }
//                                sortData();
//                                uc.refData.call();
//                            }
//                        }, throwable -> {
//                            Logger.e("失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
    }

    public void upDataPractice(Map<String, Object> data, String id) {
        showDialog();
        addSubscribe(
                LessonService
                        .getInstance()
                        .updatePractice(data, id)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();

                        }, throwable -> {
                            SLToast.showError();
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }


    public void addPractice(List<TKPractice> data, boolean isShowLoading, boolean isStartPractice, boolean isVideo) {
        if (isShowLoading) {
            showDialog();
        }
        Logger.e("要添加的个数%s", SLJsonUtils.toJsonString(data));
        addSubscribe(
                LessonService
                        .getInstance()
                        .addPractice(data)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            if (isShowLoading) {
                                dismissDialog();
                            }
                            Logger.e("======%s", "add成功");
                            if (isStartPractice) {
                                if (isVideo) {
                                    uc.recordVideoPractice.setValue(data.get(0));
                                } else {
                                    uc.recordPractice.setValue(data.get(0));

                                }
                            }
                        }, throwable -> {
                            Logger.e("addPractice失败,失败原因" + throwable.getMessage());
                            if (isShowLoading) {
                                dismissDialog();
                                SLToast.showError();
                            }
                        })
        );
    }

    private void sortData() {
        for (TKPracticeAssignment practiceDatum : practiceData) {
            List<TKPractice> collect = practiceDatum.getPractice().stream().sorted(Comparator.comparing(TKPractice::getCreateTimes).reversed()).collect(Collectors.toList());
//            collect = collect.stream().sorted(Comparator.comparing(TKPractice::isAssignment).reversed()).collect(Collectors.toList());
            collect = collect.stream().sorted(Comparator.comparing(TKPractice::isDone)).collect(Collectors.toList());
            practiceDatum.setPractice(collect);
        }


    }

    private void getPracticeData() {
        addSubscribe(
                LessonService
                        .getInstance()
                        .getPracticeByStartTimeAndSId(true, startTimestamp, endTimestamp, studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            data.sort(Comparator.comparing(TKPractice::getStartTime).reversed());
                            initShowData(data);
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void initShowData(List<TKPractice> data) {
        for (TKPractice item : data) {
            long startOfDayTime = TimeUtils.getStartDay(item.getStartTime()).getTimeInMillis() / 1000L;
            if (item.isDone() || (startOfDayTime == (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L) && item.isAssignment())) {
                boolean isHave = false;
                for (int i = 0; i < practiceData.size(); i++) {
                    if (practiceData.get(i).getStartTime() == startOfDayTime) {
                        isHave = true;
                        boolean isHavePractice = false;
                        for (TKPractice practice : practiceData.get(i).getPractice()) {
                            if (practice.getId().equals(item.getId())) {
                                isHavePractice = true;
                                break;
                            }
                        }
                        if (!isHavePractice) {
                            practiceData.get(i).getPractice().add(item);
                        }
                    }
                }
                if (!isHave) {
                    TKPracticeAssignment practiceAssignment = new TKPracticeAssignment()
                            .setStartTime(startOfDayTime)
                            .setEndTime(startOfDayTime + 86399);
                    practiceAssignment.getPractice().add(item);
                    practiceData.add(practiceAssignment);
                }
            }
        }


        for (TKPractice item : data) {
            long startOfDayTime = TimeUtils.getStartDay(item.getStartTime()).getTimeInMillis() / 1000L;
            boolean historyIsHave = false;
            for (TKPractice historyItem : practiceHistoryData) {
                if (historyItem.getId().equals(item.getId())) {
                    historyIsHave = true;
                    break;
                }
            }
            if (!historyIsHave) {
                practiceHistoryData.add(item);
            }
            boolean isHave = false;
            for (TKPracticeAssignment practiceItem : allData) {
                if (practiceItem.getStartTime() == startOfDayTime) {
                    isHave = true;
                    boolean isHavePractice = false;
                    for (TKPractice practice : practiceItem.getPractice()) {
                        if (practice.getId().equals(item.getId())) {
                            isHavePractice = true;
                            break;
                        }
                    }
                    if (!isHavePractice) {
                        practiceItem.getPractice().add(item);
                    }
                }
            }
            if (!isHave) {
                TKPracticeAssignment practiceAssignment = new TKPracticeAssignment()
                        .setStartTime(startOfDayTime)
                        .setEndTime(startOfDayTime + 86399);
                practiceAssignment.getPractice().add(item);
                allData.add(practiceAssignment);
            }
        }

        if (data.size() > 0) {
            previousCount++;
        }
        List<TKPractice> needAddData = new ArrayList<>();
        if (preLessonData != null && !isLoadPreAssignmentData) {
            List<TKPractice> addData = new ArrayList<>();
            for (TKPracticeAssignment item : allData) {
                for (TKPractice practiceItem : item.getPractice()) {
                    if (practiceItem.getLessonScheduleId().equals(preLessonData.getId())) {
                        addData.add(practiceItem);
                    }
                }
            }

            for (TKPractice addItem : addData) {
                boolean isHave = false;
                for (TKPractice item : practiceData.get(0).getPractice()) {
                    if (addItem.getId().equals(item.getId()) || addItem.getAssignmentId().equals(item.getAssignmentId())) {
                        isHave = true;
                        break;
                    }
                }
                if (!isHave) {

                    TKPractice add = new TKPractice()
                            .setId(IDUtils.getId())
                            .setStartTime((int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L) + 10)
                            .setTotalTimeLength(0)
                            .setDone(false)
                            .setRecordData(new ArrayList<>())
                            .setName(addItem.getName())
                            .setStudentId(addItem.getStudentId())
                            .setTeacherId(addItem.getTeacherId())
                            .setAssignment(true)
                            .setAssignmentId(addItem.getAssignmentId())
                            .setScheduleConfigId(addItem.getScheduleConfigId())
                            .setLessonScheduleId(addItem.getLessonScheduleId())
                            .setShouldDateTime(addItem.getShouldDateTime())
                            .setCreateTime(addItem.getCreateTime())
                            .setUpdateTime(addItem.getUpdateTime());
                    practiceData.get(0).getPractice().add(add);
                    needAddData.add(add);
                }
            }
            isLoadPreAssignmentData = true;
        }

        if (needAddData.size() > 0) {
            addPractice(needAddData, false, false, false);
        }
        previousPreviousCount = previousCount;
        previousCount = 0;
        sortData();
        uc.refData.call();
    }

    public TKButton.ClickListener clickLog = tkButton -> {
        uc.clickLogAndStartPractice.setValue(0);
    };

    public TKButton.ClickListener clickStartPractice = tkButton -> {
        uc.clickLogAndStartPractice.setValue(1);
    };

    /**
     * 点击log 列表中的播放
     *
     * @param data
     */
    public void clickPlay(TKPractice data, int pos) {
        data.setFatherPos(pos);
        uc.clickPlayPractice.setValue(data);
    }

    /**
     * 删除录音
     *
     * @param
     */
    public void deleteAudio(List<TKPractice.PracticeRecord> delete, TKPractice practice) {
        Map<String, Object> stringPracticeRecordMap = new HashMap<>();
        List<TKPractice.PracticeRecord> practiceRecords = new ArrayList<>();
        List<TKPractice.PracticeRecord> deleteData = new ArrayList<>();
//        for (TKPracticeAssignment practiceDatum : practiceData) {
//            for (TKPractice tkPractice : practiceDatum.getPractice()) {
//                for (TKPractice.PracticeRecord cc : deleteId) {
//                    if (cc.getPraicticeId().equals(tkPractice.getId())) {
//                        tkPractice.getRecordData().removeIf(practiceRecord -> {
//                            for (TKPractice.PracticeRecord s : deleteId) {
//                                if (practiceRecord.getId().equals(s.getId())) {
//                                    deleteData.add(practiceRecord);
//                                    return true;
//                                }
//                            }
//                            return false;
//                        });
//                        practiceRecords.addAll(tkPractice.getRecordData());
//                    }
//                }
//
//
//            }
//        }
        uc.refData.call();
        stringPracticeRecordMap.put("recordData", practiceRecords);

        FirebaseFirestore.getInstance().runTransaction(transaction -> {
            for (TKPractice.PracticeRecord practiceRecord : delete) {
                String praicticeId = practiceRecord.getPraicticeId();
                try {
                    TKPractice tkPractice = transaction.get(DatabaseService.Collections.practice().document(praicticeId)).toObject(TKPractice.class);
                    if (tkPractice != null) {
                        tkPractice.getRecordData().removeIf(record -> record.getId().equals(practiceRecord.getId()));
                        transaction.update(DatabaseService.Collections.practice().document(praicticeId), "recordData", tkPractice.getRecordData());
                    } else {
                        throw new FirebaseFirestoreException("get practice failed",
                                FirebaseFirestoreException.Code.UNKNOWN);
                    }


                } catch (Throwable throwable) {
                    throw new FirebaseFirestoreException("get practice failed",
                            FirebaseFirestoreException.Code.UNKNOWN);
                }
            }


            return null;
        }).addOnCompleteListener(btask -> {
            Logger.e("更新数据完成 是否成功==>%s", btask.getException() == null);
            uc.refData.call();

        });

//        addSubscribe(
//                LessonService
//                        .getInstance()
//                        .updatePractice(stringPracticeRecordMap, practice.getId())
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread(), true)
//                        .subscribe(d -> {
//                            dismissDialog();
////
//                            for (TKPractice.PracticeRecord data : deleteData) {
//                                StorageUtils.deleteStoreByPath("/practice/" + data.getId() + data.getFormat());
//                            }
//                            Logger.e("删除成功");
//
//                        }, throwable -> {
//                            SLToast.showError();
//                            dismissDialog();
//                            Logger.e("删除失败,失败原因" + throwable.getMessage());
//                        })
//
//        );
    }

    public void uploadPractice(TKPractice data, boolean isVideo) {
        showDialog();
        Map<String, Object> map = new HashMap<>();
        map.put("totalTimeLength", data.getTotalTimeLength());
        map.put("done", true);
        map.put("recordData", data.getRecordData());
        addSubscribe(
                LessonService
                        .getInstance()
                        .updatePractice(map, data.getId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            data.getRecordData().removeIf(practiceRecord -> practiceRecord.isOld());
                            Logger.e("222222==>%s",SLJsonUtils.toJsonString(data));
                            List<String> uploadData = new ArrayList<>();
                            for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
                                recordDatum.setPraicticeId(data.getId());
                                uploadData.add(recordDatum.getId());
                            }
                            SLCacheUtil.addNotUploadPracticeFileId(uploadData, studentId);
                            if (isVideo) {
//                                List<String> uploadData = new ArrayList<>();
//                                for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
//                                    recordDatum.setPraicticeId(data.getId());
//                                    uploadData.add(recordDatum.getId());
//                                }
//                                SLCacheUtil.addNotUploadPracticeFileId(uploadData, studentId);
                                uc.recordVideoDone.postValue(data);
                            } else {

                                uc.recordAudioDone.setValue(data);
                            }
                            uc.refData.call();
                        }, throwable -> {
                            SLToast.showError();
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    /**
     * 录音返回
     *
     * @param data
     * @param uploadData
     */
    public void uploadPractice(TKPractice data, List<RecordPracticeDialog.UploadRecode> uploadData) {
        showDialog();
        Map<String, Object> map = new HashMap<>();
        map.put("totalTimeLength", data.getTotalTimeLength());
        map.put("done", true);
        map.put("recordData", data.getRecordData());
        Logger.e("======%s", uploadData.size());
        addSubscribe(
                LessonService
                        .getInstance()
                        .updatePractice(map, data.getId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
//                            data.setRecordData()
//                            if (uploadData.size() > 0) {
//                                List<RecordPracticeDialog.UploadRecode> upData = new ArrayList<>(uploadData);
//                                List<RecordPracticeDialog.UploadRecode> practiceUpLoadList = SLCacheUtil.getPracticeUpLoadList();
//                                upData.addAll(practiceUpLoadList);
//                                SLCacheUtil.setPracticeUpLoadList(upData);
//                                StorageUtils.uploadPractices(upData);
//
//                            }
                        }, throwable -> {
                            SLToast.showError();
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    public void specifiedTimeHomeWork(String time) {
        int l = (int) (TimeUtils.timeToStamp(time + " 23:59:59", "yyyy/MM/dd HH:mm:ss") / 1000);
        showDialog();
        addSubscribe(
                LessonService.getInstance().getSpecifiedTimeLastLesson(l)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            uc.logForDay.setValue(d);
                            dismissDialog();
                        }, throwable -> {
                            uc.logForDay.setValue(new ArrayList<>());
                            dismissDialog();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );


    }

}
