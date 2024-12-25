package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.entity.StudentListEntity;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class SelectStudentItemViewModel extends ItemViewModel<SelectStudentViewModel> {
    public MutableLiveData<StudentListEntity> data = new MutableLiveData<>();
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> userId = new ObservableField<>();
    public ObservableField<String> phone = new ObservableField<>();

    public SelectStudentItemViewModel(@NonNull SelectStudentViewModel viewModel, StudentListEntity studentListEntity, int pos) {
        super(viewModel);
        data.setValue(studentListEntity);
        name.set(studentListEntity.getName());
        userId.set(studentListEntity.getStudentId());
        phone.set(!studentListEntity.getPhone().equals("") ? studentListEntity.getPhone() : studentListEntity.getEmail());
    }

    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
        viewModel.intentAddLesson(data.getValue());

    });

}
