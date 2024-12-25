package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.vm.StudentPracticeLogDayItemVM;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.students.vm
 * 2021/5/11
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeDetailVM extends ToolbarViewModel {
    public List<TKPracticeAssignment> practiceData = new ArrayList<>();

    public PracticeDetailVM(@NonNull @NotNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {

    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<TKPractice> clickPlayPractice = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> refData = new SingleLiveEvent<>();


    }


    public void initData(List<TKPractice> data) {
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
            if (!item.isDone()){

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
        for (TKPracticeAssignment practiceDatum : practiceData) {

            practiceDatum.setPractice(sortData(practiceDatum.getPractice()));
        }
        practiceData.sort((o1, o2) -> (int) (o2.getStartTime()-o1.getStartTime()));

        for (TKPracticeAssignment item : practiceData) {
            StudentPracticeLogDayItemVM itemVM = new StudentPracticeLogDayItemVM(this, item, observableList.size());
            observableList.add(itemVM);
        }
        uc.refData.call();
    }


    @NonNull
    private List<TKPractice> sortData(List<TKPractice> assignment) {
        List<TKPractice> newData = new ArrayList<>();
        List<String> notUploadPracticeFileId = SLCacheUtil.getNotUploadPracticeFileId(UserService.getInstance().getCurrentUserId());
        for (TKPractice tkPractice :assignment) {
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
            if (pos == -1 ) {
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
            if (o1.getRecordData().size()>0){
                o1Time = o1.getRecordData().get(0).getStartTime();
            }
            if (o2.getRecordData().size()>0){
                o2Time = o2.getRecordData().get(0).getStartTime();
            }
            return o2Time-o1Time;

        });
        return newData;
    }


    //给RecyclerView添加ObservableList
    public ObservableList<StudentPracticeLogDayItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<StudentPracticeLogDayItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_student_log_day));

    /**
     * 点击播放录音
     *
     * @param practice
     */
    public void clickPlay(TKPractice practice, int pos) {
//        practiceVM.clickPlay(practice,pos);
        practice.setFatherPos(pos);
        uc.clickPlayPractice.setValue(practice);
    }

}
