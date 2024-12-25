package com.spelist.tunekey.ui.teacher.students.vm;

import androidx.annotation.NonNull;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class UpgradPromptItemViewModel extends ItemViewModel<UpgradPromptViewModel> {
    public String text;
    public UpgradPromptItemViewModel(@NonNull UpgradPromptViewModel viewModel,String text) {
        super(viewModel);
        this.text = text;
    }
    public BindingCommand onItemClick = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            //点击之后将逻辑转到activity中处理
            viewModel.itemClickEvent.setValue(text);
        }
    });
}
