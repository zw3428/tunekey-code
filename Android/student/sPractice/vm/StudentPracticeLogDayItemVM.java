package com.spelist.tunekey.ui.student.sPractice.vm;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.teacher.students.vm.PracticeDetailVM;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.sPractice.vm
 * 2021/4/21
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeLogDayItemVM<VM extends BaseViewModel> extends ItemViewModel<VM> {
    private TKPracticeAssignment data = new TKPracticeAssignment();
    public ObservableField<String> date = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");

    public int pos;
    public ObservableField<LinearLayoutManager> layoutManager = new ObservableField<>(new LinearLayoutManager(TApplication.getInstance().getBaseContext()));


    public StudentPracticeLogDayItemVM(@NonNull VM viewModel, TKPracticeAssignment practice,int pos) {
        super(viewModel);
        this.pos = pos;
        this.data = practice;
        long startTime = practice.getStartTime();
        if (viewModel instanceof PracticeDetailVM){
            date.set(TimeUtils.timeFormat(startTime,"MMM d, yyyy"));

        }else {
            date.set(TimeUtils.timeFormat(startTime,"MMM d, yyyy"));

        }

        double totalTime = 0;
        for (TKPractice item : practice.getPractice()) {
            totalTime += item.getTotalTimeLength();
        }
        if (totalTime > 0) {
            totalTime = totalTime / 60 ;
            if (totalTime <= 0.1) {
                time.set(" 0.1 min");
            } else {
                time.set(" " + String.format("%.1f", totalTime) + " min");
            }
        } else {
            time.set(" 0 min");
        }
        observableList.clear();
        for (TKPractice data : practice.getPractice()) {

            StudentPracticeLogPracticeItemVM itemVM = new StudentPracticeLogPracticeItemVM(viewModel,data,pos);
            observableList.add(itemVM);
        }

    }
    //给RecyclerView添加ObservableList
    public ObservableList<StudentPracticeLogPracticeItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<StudentPracticeLogPracticeItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_student_log_practice));



}
