package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.app.Application;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.Instrument;
import com.spelist.tunekey.entity.StudentListEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class SelectStudentViewModel extends ToolbarViewModel {
    public MutableLiveData<StudentListEntity> addStudent = new MutableLiveData<>();
    private List<StudentListEntity> list = new ArrayList<>();
    private StudentListEntity studentListEntity = new StudentListEntity();

    public SelectStudentViewModel(@NonNull Application application) {
        super(application);
        // getDate();

    }

    @Override
    public void initToolbar() {
        setTitleString("Select Student");
        setLeftButtonIcon(R.mipmap.ic_back_primary);
        setLeftImgButtonVisibility(View.VISIBLE);

    }

    @Override
    protected void clickLeftImgButton() {
        finish();
    }

    //给RecyclerView添加ObservableList
    public ObservableList<SelectStudentItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<SelectStudentItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<SelectStudentItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, SelectStudentItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.item_select_student);
        }
    });

    private void getDate(List<StudentListEntity> studentListEntities) {
        for (int i = 0; i < studentListEntities.size(); i++) {
            SelectStudentItemViewModel item = new SelectStudentItemViewModel(this, studentListEntities.get(i), i);
            observableList.add(item);
        }
    }


    public void getStudentList() {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListForTeacher(false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(studentList -> {
                            list = studentList;
                            dismissDialog();
                            getDate(studentList);
                        }, throwable -> {
                            dismissDialog();
                        }));
    }

    public void intentAddLesson(StudentListEntity studentListEntity){
        addStudent.setValue(studentListEntity);

    }

    @Override
    protected void clickCancelSearch() {
        super.clickCancelSearch();

    }

    public void search(String text) {
        observableList.clear();
        if (text.equals("")) {
            getDate(list);
            return;
        }
        List<StudentListEntity> collect = list.stream().filter(studentListEntity -> studentListEntity.getName().trim().toLowerCase().contains(text.trim().toLowerCase())).collect(Collectors.toList());
        getDate(collect);
    }
}
