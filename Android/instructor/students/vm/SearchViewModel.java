package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.entity.StudentListEntity;

import java.util.ArrayList;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;
import me.tatarka.bindingcollectionadapter2.OnItemBind;

public class SearchViewModel extends BaseViewModel {
    private List<StudentListEntity> studentListEntities = new ArrayList<>();
    public ObservableField<Boolean> selectItem = new ObservableField<>();
    public ObservableField<String> selectName = new ObservableField<>();
    public MutableLiveData<StudentListEntity> studentListEntityMutableLiveData = new MutableLiveData<>();
    private int pos;

    public SearchViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void onCreate() {
        super.onCreate();

    }

    public void searching(String text) {
        observableList.clear();
        if (!text.equals("")){
            for (int i = 0; i < studentListEntities.size(); i++) {
                if (studentListEntities.get(i).getName().contains(text)) {
                    Logger.e("===" + studentListEntities.get(i).getName());
                    SearchItemViewModel item = new SearchItemViewModel(SearchViewModel.this, studentListEntities.get(i), i, text);
                    observableList.add(item);
                }
            }
        }


    }

    public void getStudentList() {
        showDialog();
        addSubscribe(
                UserService
                        .getInstance()
                        .getStudentListForTeacher(true)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(studentList -> {
                            dismissDialog();
                            Logger.e("==========" + studentList.size());
                            if (studentList.size() > 0) {

                                studentListEntities = studentList;
                            } else {
                                Logger.e("==========");
                            }

                        }, throwable -> {
                            dismissDialog();
                        }));
    }

    //给RecyclerView添加ObservableList
    public ObservableList<SearchItemViewModel> observableList = new ObservableArrayList<>();
    //RecyclerView多布局添加ItemBinding
    public ItemBinding<SearchItemViewModel> itemBinding = ItemBinding.of(new OnItemBind<SearchItemViewModel>() {
        @Override
        public void onItemBind(ItemBinding itemBinding, int position, SearchItemViewModel item) {
            itemBinding.set(com.spelist.tunekey.BR.itemViewModel, R.layout.layout_search_student);
        }
    });

    public void clickItem(int pos) {
        this.pos = pos;
        selectName.set(studentListEntities.get(pos).getName());
        studentListEntityMutableLiveData.setValue(studentListEntities.get(pos));

    }

    public SearchViewModel.UIClickObservable uc = new SearchViewModel.UIClickObservable();

    public class UIClickObservable {
        public SingleLiveEvent<Void> search = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> searchBack = new SingleLiveEvent<>();
        public SingleLiveEvent<Void> clearAll = new SingleLiveEvent<>();

    }

    public BindingCommand search = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.search.call();

        }
    });
    public BindingCommand clearAll = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.clearAll.call();

        }
    });
    public BindingCommand searchBack = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.searchBack.call();
            finish();
        }
    });

}
