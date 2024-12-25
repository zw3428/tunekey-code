package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class DialogLessonTypeItemViewModel extends ItemViewModel {

    public MutableLiveData<Integer> imgUrl = new MutableLiveData<>();
    public MutableLiveData<String> title = new MutableLiveData<>();
    public MutableLiveData<String> content = new MutableLiveData<>();
    private String visibilityType[] = new String[2];

    public DialogLessonTypeItemViewModel(@NonNull BaseViewModel viewModel) {
        super(viewModel);
    }

    public DialogLessonTypeItemViewModel(LessonsViewModel lessonsViewModel, int img, String title, int type, int timeLength, String price) {
        super(lessonsViewModel);
        visibilityType[0] = "Private";
        visibilityType[1] = "Public";
        this.imgUrl.setValue(img);
        this.title.setValue(title);
        this.content.setValue(visibilityType[type] + ", " + timeLength + "minutes, " + "$" + price);
        Log.e("", "*-*-*-*-*-*-*-*-*-*-*-*-: " + visibilityType + "*-*-*-*-*-*-*-*-*-*-*-*" + content);
    }

    public BindingCommand itemClick = new BindingCommand(new BindingAction() {
        @Override
        public void call() {

        }
    });
}
