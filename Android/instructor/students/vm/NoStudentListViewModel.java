package com.spelist.tunekey.ui.teacher.students.vm;

import android.app.Application;

import androidx.annotation.NonNull;

import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.customView.SLToast;

import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;

public class NoStudentListViewModel extends ToolbarViewModel {
    //封装一个点击事件观察者
    public NoStudentListViewModel.UIClickObservable uc = new NoStudentListViewModel.UIClickObservable();
    public SingleLiveEvent<Boolean> stopLoading = new SingleLiveEvent<>();

    public NoStudentListViewModel(@NonNull Application application) {
        super(application);
    }

    @Override
    public void initToolbar() {
        setTitleString("Students");
    }

    public class UIClickObservable {
        public SingleLiveEvent<Void> showToast = new SingleLiveEvent<>();

    }


    public BindingCommand showToast = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            uc.showToast.call();

        }
    });
    public void inviteStudent(List<Map<String,Object>> data){
        CloudFunctions
                .addStudent(data)
                .addOnCompleteListener(task -> {
                    dismissDialog();
                    if (task.isSuccessful()) {
                        if (task.getResult() != null && task.getResult().size() > 0 ) {
                            Logger.e("====== 添加成功:" + task.getResult());
                            }
                            stopLoading.setValue(true);
                        }else {
                        SLToast.error("添加失败");
                        Logger.e("====== 添加失败:" + task.getResult());
                    }
                });

    }




}
