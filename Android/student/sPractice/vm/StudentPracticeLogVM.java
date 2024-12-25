package com.spelist.tunekey.ui.student.sPractice.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.sPractice.vm
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeLogVM extends BaseViewModel {
    public List<TKPracticeAssignment> data = new ArrayList<>();
    public StudentPracticeFragmentV2VM practiceVM ;
    public StudentPracticeLogVM(@NonNull Application application) {
        super(application);
    }


    public void initData(List<TKPracticeAssignment> data){
        this.data = data;
//        observableList.clear();
//        for (TKPracticeAssignment item : data) {
//            item.setLayoutManager(new LinearLayoutManager(getApplication()));
//            StudentPracticeLogDayItemVM itemVM = new StudentPracticeLogDayItemVM(this,item,observableList.size());
//            observableList.add(itemVM);
//        }
    }

    //给RecyclerView添加ObservableList
    public ObservableList<StudentPracticeLogDayItemVM> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<StudentPracticeLogDayItemVM> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.item_student_log_day));
    /**
     * 点击播放录音
     * @param practice
     */
    public void clickPlay(TKPractice practice,int pos){
        practiceVM.clickPlay(practice,pos);
    }


}
