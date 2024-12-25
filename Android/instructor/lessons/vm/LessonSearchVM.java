package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;

import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.SearchStudentLessonDetailAc;
import com.spelist.tunekey.ui.teacher.students.vm.SearchItemViewModel;
import com.spelist.tunekey.utils.SLCacheUtil;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;

/**
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/28
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LessonSearchVM extends ToolbarViewModel {
    private List<StudentListEntity> allData = new ArrayList<>();

    public LessonSearchVM(@NonNull Application application) {
        super(application);
        initData();
    }

    @Override
    public void initToolbar() {
        setNormalToolbar("");
        searchIsVisible.set(true);
    }

    public UIEventObservable uc = new UIEventObservable();

    public static class UIEventObservable {
        public SingleLiveEvent<Void> clickCancelSearch = new SingleLiveEvent<>();
    }


    @Override
    protected void clickLeftImgButton() {
        super.clickLeftImgButton();
        finish();
    }

    @Override
    protected void clickCancelSearch() {
        super.clickCancelSearch();
        uc.clickCancelSearch.call();
    }

    private void initData() {
        allData = SLCacheUtil.getStudentList(UserService.getInstance().getCurrentUserId());
    }
    public void search(String s){
        observableList.clear();
        if (s.equals("")){
            return;
        }
        for (int i = 0; i < allData.size(); i++) {
            if (allData.get(i).getName().contains(s)) {
                SearchItemViewModel<LessonSearchVM> item = new SearchItemViewModel<>(this, allData.get(i), i, s);
                observableList.add(item);
            }
        }
    }
    public void clickItem(StudentListEntity data){
        Bundle bundle = new Bundle();
        bundle.putSerializable("studentData",data);
        startActivity(SearchStudentLessonDetailAc.class,bundle);
    }

    //给RecyclerView添加ObservableList
    public ObservableList<SearchItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<SearchItemViewModel> itemBinding = ItemBinding.of((itemBinding, position, item) -> itemBinding.set(BR.itemViewModel, R.layout.layout_search_student));


}
