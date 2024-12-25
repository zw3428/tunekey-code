package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.LessonService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.teacher.students.activity.PracticeDetailActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLTimeUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

public class PracticeViewModel extends ToolbarViewModel {

    public boolean isShowIncomplete = false;
    public String teacherId = "";
    public String studentId = "";
    public int start = 0;
    public int end = 0;
    private List<TKPractice> data = new ArrayList<>();
    private List<TKPractice> allData = new ArrayList<>();
    private List<TKPracticeAssignment> showDatas = new ArrayList<>();

    public PracticeViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("Practice");
        setIsShowProgress(true);
    }

    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }


    /**
     * 从学生课程详情中进入
     *
     * @param data
     * @param startTime
     * @param endTime
     */
    public void initStudentLessonData(List<TKPractice> data, int startTime, int endTime) {
        allData = CloneObjectUtils.cloneObject(data);
        List<TKPractice> itemDatas = new ArrayList<>();
        for (TKPractice item : data) {
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

        TKPracticeAssignment practiceAssignment = new TKPracticeAssignment()
                .setStartTime(startTime)
                .setEndTime(endTime)
                .setPractice(itemDatas);
        List<TKPractice> assignment = new ArrayList<>();
        List<TKPractice> selfStudy = new ArrayList<>();
        String titleString = "";
        String startString = TimeUtils.timeFormat(practiceAssignment.getStartTime(), "MMM d");
        String endString = "";
        if (practiceAssignment.getEndTime() != -1) {
            if (SLTimeUtils.getMonth(practiceAssignment.getStartTime()) == SLTimeUtils.getMonth(practiceAssignment.getEndTime())) {
                endString = TimeUtils.timeFormat(practiceAssignment.getEndTime(), "MMM d");
            } else {
                endString = TimeUtils.timeFormat(practiceAssignment.getEndTime(), "d");
            }
        } else {
            endString = "Today";
        }
        titleString = startString + " - " + endString;
        double totalTime = 0;
        boolean isComplete = true;
        for (TKPractice practice : practiceAssignment.getPractice()) {
            totalTime += practice.getTotalTimeLength();
            if (practice.isAssignment()) {
                isComplete = false;
                assignment.add(practice);
            } else {
                if (practice.isDone()) {
                    selfStudy.add(practice);
                }
            }
        }
        isShowIncomplete = startTime >= TimeUtils.getCurrentTime();

        practiceAssignment.setTotalTime(totalTime);
        practiceAssignment.setTime(titleString);
        practiceAssignment.setAssignment(sortData(CloneObjectUtils.cloneObject(assignment)));
        practiceAssignment.setSelfStudy(sortData(CloneObjectUtils.cloneObject(selfStudy)));
        practiceAssignment.setAssignmentIsComplete(isComplete);
        observableList.add(new PracticeItemViewModel(this, practiceAssignment, isShowIncomplete, new LinearLayoutManager(getApplication().getApplicationContext()), new LinearLayoutManager(getApplication().getApplicationContext())));
        showDatas.add(practiceAssignment);
        uc.refData.setValue(showDatas);
        setIsShowProgress(false);
    }

    @NonNull
    private List<TKPractice> sortData(List<TKPractice> assignment) {
        List<TKPractice> newData = new ArrayList<>();
        List<String> notUploadPracticeFileId = SLCacheUtil.getNotUploadPracticeFileId(UserService.getInstance().getCurrentUserId());
        for (TKPractice tkPractice : assignment) {
            tkPractice.getRecordData().removeIf(record -> {
                if (record.isUpload()) {
                    return false;
                } else {
                    return !(notUploadPracticeFileId.contains(record.getId()));
                }
            });
        }
        for (TKPractice oldItem : assignment) {
            int pos = -1;
            for (int i = 0; i < newData.size(); i++) {
                TKPractice newItem = newData.get(i);
                if (newItem.getName().equals(oldItem.getName())) {
                    pos = i;
                }
            }
            if (pos == -1) {
                for (TKPractice.PracticeRecord recordDatum : oldItem.getRecordData()) {
                    recordDatum.setPraicticeId(oldItem.getId());
                }
                newData.add(oldItem);
            } else {
                TKPractice newItem = newData.get(pos);
                for (TKPractice.PracticeRecord recordDatum : oldItem.getRecordData()) {
                    recordDatum.setPraicticeId(oldItem.getId());
                }
                newItem.getRecordData().addAll(oldItem.getRecordData());
                newItem.setTotalTimeLength(newItem.getTotalTimeLength() + oldItem.getTotalTimeLength());
                if (oldItem.isDone()) {
                    newItem.setDone(true);
                }
                if (oldItem.isManualLog()) {
                    newItem.setManualLog(true);
                }
            }
        }
        for (TKPractice newDatum : newData) {
            newDatum.getRecordData().sort((o1, o2) -> o2.getStartTime() - o1.getStartTime());
        }
        newData.sort((o1, o2) -> {
            int o1Time = o1.getStartTime();
            int o2Time = o2.getStartTime();
            if (o1.getRecordData().size() > 0) {
                o1Time = o1.getRecordData().get(0).getStartTime();
            }
            if (o2.getRecordData().size() > 0) {
                o2Time = o2.getRecordData().get(0).getStartTime();
            }
            return o2Time - o1Time;

        });

        return newData;
    }

    /**
     * 设置数据 从老师课程中进入
     *
     * @param data
     */
    public void initData(List<TKPractice> data, LessonScheduleEntity scheduleEntity) {
        allData = data;
        List<TKPractice> itemDatas = new ArrayList<>();
        for (TKPractice item : data) {
            if (item.isAssignment()) {
                int index = -1;
                for (int i = 0; i < itemDatas.size(); i++) {
                    TKPractice newItem = itemDatas.get(i);
                    if (newItem.getLessonScheduleId().equals(item.getLessonScheduleId()) && newItem.getName().equals(item.getName()) && newItem.getStartTime() == item.getStartTime()) {
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
        TKPracticeAssignment practiceAssignment = new TKPracticeAssignment()
                .setStartTime(scheduleEntity.getLastLessonData().getShouldDateTime())
                .setEndTime(scheduleEntity.getShouldDateTime())
                .setPractice(itemDatas);

        isShowIncomplete = scheduleEntity.getTKShouldDateTime() >= TimeUtils.getCurrentTime();
        List<TKPractice> assignment = new ArrayList<>();
        List<TKPractice> selfStudy = new ArrayList<>();
        String titleString = "";
        String startString = TimeUtils.timeFormat(practiceAssignment.getStartTime(), "MMM d");
        String endString = "";
        if (practiceAssignment.getEndTime() != -1) {
            if (SLTimeUtils.getMonth(practiceAssignment.getStartTime()) == SLTimeUtils.getMonth(practiceAssignment.getEndTime())) {
                endString = TimeUtils.timeFormat(practiceAssignment.getEndTime(), "MMM d");
            } else {
                endString = TimeUtils.timeFormat(practiceAssignment.getEndTime(), "d");
            }
        } else {
            endString = "Today";
        }
        titleString = startString + " - " + endString;
        double totalTime = 0;
        boolean isComplete = true;
        for (TKPractice practice : practiceAssignment.getPractice()) {
            totalTime += practice.getTotalTimeLength();
            if (practice.isAssignment()) {
                if (!practice.isDone()) {
                    isComplete = false;
                }
                assignment.add(practice);
            } else {
                if (practice.isDone()) {
                    selfStudy.add(practice);
                }
            }
        }
        practiceAssignment.setTime(titleString);
        practiceAssignment.setTotalTime(totalTime);
        practiceAssignment.setAssignment(sortData(CloneObjectUtils.cloneObject(assignment)));
        practiceAssignment.setSelfStudy(sortData(CloneObjectUtils.cloneObject(selfStudy)));
        practiceAssignment.setAssignmentIsComplete(isComplete);
        observableList.add(new PracticeItemViewModel(this, practiceAssignment, isShowIncomplete, new LinearLayoutManager(getApplication().getApplicationContext()), new LinearLayoutManager(getApplication().getApplicationContext())));
        showDatas.add(practiceAssignment);
        uc.refData.setValue(showDatas);
        setIsShowProgress(false);
    }

    /**
     * 从学生详情进入
     */
    public void initStudentData(String teacherId, String studentId, List<TKPractice> data) {
        allData = data;
        this.teacherId = teacherId;
        this.studentId = studentId;


        for (TKPractice item : data) {
            if (item.isAssignment()) {
                int index = -1;
                for (int i = 0; i < this.data.size(); i++) {
                    TKPractice newItem = this.data.get(i);
                    if (newItem.getLessonScheduleId().equals(item.getLessonScheduleId()) && newItem.getName().equals(item.getName()) && newItem.getStartTime() == item.getStartTime()) {
                        index = i;
                    }
                }
                if (index > 0) {
                    this.data.get(index).getRecordData().addAll(item.getRecordData());
                    if (item.isDone()) {
                        this.data.get(index).setDone(true);
                    }
                    this.data.get(index).setTotalTimeLength(this.data.get(index).getTotalTimeLength() + item.getTotalTimeLength());
                } else {
                    this.data.add(item);
                }
            } else {
                boolean isHave = false;
                for (TKPractice itemData : this.data) {
                    if (itemData.getId().equals(item.getId())) {
                        isHave = true;
                    }
                }
                if (!isHave) {
                    this.data.add(item);
                }
            }
        }
        Logger.e("dad==>%s", data.size());
        start = (int) (TimeUtils.addMonth(TimeUtils.getCurrentTime() * 1000L, -3) / 1000L);
        end = TimeUtils.getCurrentTime();
        getLessonData();
    }

    public void getLessonData() {

        addSubscribe(
                LessonService
                        .getInstance()
                        .getScheduleByStudentIdAndTeacherIdAndTime(false, studentId, start, end)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            data.removeIf(item -> {
                                if (item.isCancelled() || (item.isRescheduled() && !item.getRescheduleId().equals(""))) {
                                    return true;
                                }
                                return false;
                            });

                            data.sort((o1, o2) -> (int) (o2.getShouldDateTime() - o1.getShouldDateTime()));
                            Logger.e("daddd==>%s", data.size());
                            initShowData(data);

                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    private void initShowData(List<LessonScheduleEntity> lessonData) {
//        observableList.clear();
        if (lessonData.size() == 0) {
            List<TKPracticeAssignment> sDatas = new ArrayList<>();
            for (TKPractice practiceItem : data) {
                if (practiceItem.getTeacherId().equals("") || practiceItem.getTeacherId().equals(teacherId)) {
                    TKPracticeAssignment showData = new TKPracticeAssignment();
                    showData.setStartTime(TimeUtils.getStartDay(practiceItem.getStartTime()).getTimeInMillis() / 1000L);
                    showData.setEndTime(TimeUtils.getEndDay(practiceItem.getStartTime()).getTimeInMillis() / 1000L);
                    showData.getPractice().add(practiceItem);
                    int pos =-1;
                    for (int i = 0; i < sDatas.size(); i++) {
                        if (sDatas.get(i).getStartTime() == showData.getStartTime()) {
                            pos = i;
                        }
                    }
                    if (pos !=-1){
                        sDatas.get(pos).getPractice().add(practiceItem);
                    }else {
                        sDatas.add(showData);
                    }
                }
            }

            for (TKPracticeAssignment sData : sDatas) {
                double totalTime = 0;
                boolean isComplete = true;
                List<TKPractice> assignment = new ArrayList<>();
                List<TKPractice> selfStudy = new ArrayList<>();
                for (TKPractice practice : sData.getPractice()) {
                    totalTime += practice.getTotalTimeLength();
                    if (practice.isAssignment()) {
                        if (!practice.isDone()) {
                            isComplete = false;
                        }
                        assignment.add(practice);
                    } else {
                        if (practice.isDone()) {
                            selfStudy.add(practice);
                        }
                    }
                }
                sData.setAssignment(sortData(CloneObjectUtils.cloneObject(assignment)));
                sData.setSelfStudy(sortData(CloneObjectUtils.cloneObject(selfStudy)));
                sData.setTotalTime(totalTime);
                sData.setAssignmentIsComplete(isComplete);
                String titleString = "";
                String startString = TimeUtils.timeFormat(sData.getStartTime(), "MMM d");
                titleString = startString ;
                sData.setTime(titleString);
                observableList.add(new PracticeItemViewModel(this, true, sData, isComplete, new LinearLayoutManager(getApplication().getApplicationContext()), new LinearLayoutManager(getApplication().getApplicationContext())));
                showDatas.add(sData);
            }
            uc.refData.setValue(showDatas);
        }

        for (int i = 0; i < lessonData.size(); i++) {
            LessonScheduleEntity item = lessonData.get(i);
            TKPracticeAssignment showData = new TKPracticeAssignment();
            int startDataTime = (int) item.getShouldDateTime();
            showData.setStartTime(item.getShouldDateTime());
            if (i == 0) {
                if (observableList.size() > 0) {
                    if (observableList.get(observableList.size() - 1).data != null && observableList.get(observableList.size() - 1).data.get() != null) {
                        showData.setEndTime(observableList.get(observableList.size() - 1).data.get().getStartTime());
                    }
                } else {
                    showData.setEndTime(-1);
                }

            } else {
                showData.setEndTime(lessonData.get(i - 1).getShouldDateTime());
            }
            for (TKPractice practiceItem : data) {
                if (practiceItem.getStartTime() >= startDataTime && practiceItem.getStartTime() <= (showData.getEndTime() == -1 ? TimeUtils.getCurrentTime() : showData.getEndTime())) {
                    if (practiceItem.getTeacherId().equals("") || practiceItem.getTeacherId().equals(teacherId)) {
                        showData.getPractice().add(practiceItem);
                    }
                }
            }

            double totalTime = 0;
            boolean isComplete = true;
            List<TKPractice> assignment = new ArrayList<>();
            List<TKPractice> selfStudy = new ArrayList<>();
            for (TKPractice practice : showData.getPractice()) {
                totalTime += practice.getTotalTimeLength();
                if (practice.isAssignment()) {
                    if (!practice.isDone()) {
                        isComplete = false;
                    }
                    assignment.add(practice);
                } else {
                    if (practice.isDone()) {
                        selfStudy.add(practice);
                    }
                }
            }
//            showData.setAssignment(assignment);
//            showData.setSelfStudy(selfStudy);
            showData.setAssignment(sortData(CloneObjectUtils.cloneObject(assignment)));
            showData.setSelfStudy(sortData(CloneObjectUtils.cloneObject(selfStudy)));
            showData.setTotalTime(totalTime);
            showData.setAssignmentIsComplete(isComplete);
            String titleString = "";
            String startString = TimeUtils.timeFormat(showData.getStartTime(), "MMM d");
            String endString = "";
            if (showData.getEndTime() != -1) {
                if (SLTimeUtils.getMonth(showData.getStartTime() * 1000L) == SLTimeUtils.getMonth(showData.getEndTime() * 1000L)) {

                    endString = TimeUtils.timeFormat(showData.getEndTime(), "d");
                } else {
                    endString = TimeUtils.timeFormat(showData.getEndTime(), "MMM d");
                }
            } else {
                endString = "Today";
            }
            titleString = startString + " - " + endString;
            showData.setTime(titleString);

            observableList.add(new PracticeItemViewModel(this, true, showData, isComplete, new LinearLayoutManager(getApplication().getApplicationContext()), new LinearLayoutManager(getApplication().getApplicationContext())));
            showDatas.add(showData);
        }

        uc.refData.setValue(showDatas);
        setIsShowProgress(false);
        uc.loadingComplete.setValue(lessonData);
    }

    //给RecyclerView添加ObservableList
    public ObservableList<PracticeItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<PracticeItemViewModel> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_practice));

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<TKPractice> clickPlayPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<List<LessonScheduleEntity>> loadingComplete = new SingleLiveEvent<>();
        public SingleLiveEvent<List<TKPracticeAssignment>> refData = new SingleLiveEvent<>();

    }

    public void clickPlay(TKPractice data) {
        if (data.getRecordData().size() > 0) {
            uc.clickPlayPractice.setValue(data);
        }
    }

    public void clickToDetail(TKPracticeAssignment data) {
        long startTime = data.getStartTime();
        long endTime = data.getEndTime();
        if (endTime == -1) {
            endTime = TimeUtils.getCurrentTime();
        }
        List<TKPractice> d = new ArrayList<>();
        for (TKPractice item : allData) {
            if (item.getStartTime() >= startTime && item.getStartTime() <= endTime) {
                d.add(item);
            }
        }


        if (d.size() > 0) {
            Bundle bundle = new Bundle();
            bundle.putString("title", data.getTime());
            bundle.putSerializable("data", (Serializable) d);
            startActivity(PracticeDetailActivity.class, bundle);
        }
    }
}
