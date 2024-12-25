package com.spelist.tunekey.ui.teacher.students.vm;

import android.annotation.SuppressLint;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.students.vm
 * 2021/1/27
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeItemViewModel extends ItemViewModel<PracticeViewModel> {
    public ObservableField<String> title = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public ObservableField<Integer> timeColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));

    public ObservableField<String> assignmentRightString = new ObservableField<>("Incomplete");
    //    public ObservableField<Integer> assignmentRightColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
    public ObservableField<TKPracticeAssignment> data = new ObservableField<>();
    public ObservableField<LinearLayoutManager> assignmentLayoutManager = new ObservableField<>();
    public ObservableField<LinearLayoutManager> selfStudyLayoutManager = new ObservableField<>();
    public ObservableField<Boolean> isShowArrow = new ObservableField<>(false);
    private boolean isStudentDetails = false;
    public boolean isShowIncomplete;

    public PracticeItemViewModel(@NonNull PracticeViewModel viewModel, TKPracticeAssignment data, boolean isShowIncomplete,LinearLayoutManager assignmentLayoutManager,LinearLayoutManager selfStudyLayoutManager) {
        super(viewModel);
        this.isShowIncomplete = isShowIncomplete;
        initData(data);
        this.assignmentLayoutManager.set(assignmentLayoutManager);
        this.selfStudyLayoutManager.set(selfStudyLayoutManager);
    }
    public PracticeItemViewModel(@NonNull PracticeViewModel viewModel, boolean isStudentDetails,TKPracticeAssignment data, boolean isShowIncomplete,LinearLayoutManager assignmentLayoutManager,LinearLayoutManager selfStudyLayoutManager) {
        super(viewModel);
        this.isShowIncomplete = isShowIncomplete;
        this.isStudentDetails = isStudentDetails;
        initData(data);
        this.assignmentLayoutManager.set(assignmentLayoutManager);
        this.selfStudyLayoutManager.set(selfStudyLayoutManager);
    }


    @SuppressLint("DefaultLocale")
    private void initData(TKPracticeAssignment data) {
        this.data.set(data);
        title.set(data.getTime());
        double totalTime = 0;
        boolean isComplete = true;
        if (data.getTotalTime() > 0) {
            totalTime = data.getTotalTime() / 60L / 60L;
            if (totalTime <= 0.1) {
                time.set("0.1 hrs");
            } else {
                time.set(String.format("%.1f", totalTime) + " hrs");
            }
            isShowArrow.set(true);
            timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
        } else {
            isShowArrow.set(false);
            time.set("0 hrs");
            timeColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
        }
        if (isShowIncomplete) {
            if (isStudentDetails){
                assignmentRightString.set("");
            }else {
                assignmentRightString.set("Incomplete");
            }
        }else {
            assignmentRightString.set("Uncompleted");
        }

        for (TKPractice practice : data.getAssignment()) {
            if (!practice.isDone()){
                isComplete = false;
            }
            assignmentList.add(new PracticeItemInfoViewModel(viewModel,practice));
        }
        for (TKPractice practice : data.getSelfStudy()) {
            selfStudyList.add(new PracticeItemInfoViewModel(viewModel,practice));
        }
        if (isComplete){
            assignmentRightString.set("");
        }
    }

    //给RecyclerView添加ObservableList
    public ObservableList<PracticeItemInfoViewModel> assignmentList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<PracticeItemInfoViewModel> assignmentItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_practice_info));

    //给RecyclerView添加ObservableList
    public ObservableList<PracticeItemInfoViewModel> selfStudyList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<PracticeItemInfoViewModel> selfStudyItemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_practice_info));

    @Override
    protected void onClickItem(View view) {
        super.onClickItem(view);
        viewModel.clickToDetail(data.get());
    }

}
