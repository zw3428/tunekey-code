package com.spelist.tunekey.ui.teacher.students.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tools.custom.AddressBookEntity;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class AddressBookItemViewModel extends ItemViewModel<AddressBookViewModel> {
    public MutableLiveData<AddressBookEntity> data = new MutableLiveData<>();
    public int circleType;
    public ObservableField<String> text = new ObservableField<>("");
    private int pos;
    public ObservableField<String> userId = new ObservableField<>("");
    public Boolean isEnable = true;



    public AddressBookItemViewModel(@NonNull AddressBookViewModel viewModel, AddressBookEntity addressBookEntity, int pos) {
        super(viewModel);
        data.setValue(addressBookEntity);
        userId.set(addressBookEntity.getuId());
        this.viewModel = viewModel;
        this.circleType = 0; // 0: closeCircle, 1: checkCircle, 2: emptyCircle
        this.pos = pos;

    }



    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
//        itemVisibility(View.GONE);
        if (isEnable){
            viewModel.changChecked(data.getValue());
        }
    });

}
