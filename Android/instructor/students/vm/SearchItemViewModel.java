package com.spelist.tunekey.ui.teacher.students.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonSearchVM;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class SearchItemViewModel<VM extends BaseViewModel> extends ItemViewModel<VM> {
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> email = new ObservableField<>();
    public ObservableField<String> userId = new ObservableField<>();

    public StudentListEntity data;
    private int pos;
    private String text;

    public SearchItemViewModel(@NonNull VM viewModel, StudentListEntity studentListEntity, int pos, String text) {
        super(viewModel);
        this.pos = pos;
        this.text = text;
        editData(studentListEntity);
    }

    public void editData(StudentListEntity studentListEntity) {
        this.data = studentListEntity;
        name.set(studentListEntity.getName());
        email.set(studentListEntity.getEmail());
        userId.set(studentListEntity.getStudentId());
    }

    public BindingCommand<View> clickItem = new BindingCommand<>(view -> {
        if (viewModel instanceof SearchViewModel) {
            SearchViewModel model = (SearchViewModel) viewModel;
            model.clickItem(pos);
        }
        if (viewModel instanceof LessonSearchVM) {
            LessonSearchVM model = (LessonSearchVM) viewModel;
            model.clickItem(data);
        }
    });
}
