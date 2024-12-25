package com.spelist.tunekey.ui.teacher.students.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tunekey.R;
import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tunekey.entity.StudentListEntity;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class AddressBodyItemViewModel extends ItemViewModel<AddressBookViewModel> {
    public AddressBookViewModel viewModel;
    public StudentListEntity studentEntity;
    public MutableLiveData<String> userId = new MutableLiveData<>();
    public MutableLiveData<String> name = new MutableLiveData<>();
    public MutableLiveData<String> account = new MutableLiveData<>();
    public MutableLiveData<AddressBookEntity> data = new MutableLiveData<>();
    public boolean isSelect = false;
    public ObservableField<Integer> picChecked = new ObservableField<>();
    public boolean isEnable = true;

    public AddressBodyItemViewModel(@NonNull AddressBookViewModel viewModel, AddressBookEntity addressBookEntity) {
        super(viewModel);
        this.viewModel = viewModel;
        data.setValue(addressBookEntity);
        name.setValue(addressBookEntity.getName());
        userId.setValue("");
        String contact = addressBookEntity.getEmail();
        if (contact == null || contact.equals("")){
            contact = addressBookEntity.getPhone();
        }
        this.account.setValue(contact);
        setSelect(false);
    }

    // app contact
    public AddressBodyItemViewModel(AddressBookViewModel viewModel, StudentListEntity studentEntity) {
        super(viewModel);
        this.viewModel = viewModel;
        this.studentEntity = studentEntity;
        this.name.setValue(studentEntity.getName());
        userId.setValue(studentEntity.getStudentId());
        this.account.setValue(studentEntity.getEmail());
        isSelect = false;
        AddressBookEntity addressBookEntity = new AddressBookEntity();
        addressBookEntity.setEmail(studentEntity.getEmail());
        addressBookEntity.setuId(studentEntity.getStudentId());
        addressBookEntity.setName(studentEntity.getName());
        data.setValue(addressBookEntity);

        setSelect(false);

    }


    public void setSelect(boolean isSelect){
        this.isSelect = isSelect;
        if (isSelect) {
            picChecked.set(R.mipmap.checkboxon3);
        } else {
            picChecked.set(R.mipmap.checkbox_off);
        }
    }





    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
        if (!isEnable){
            return;
        }
        if (isSelect) {
            setSelect(false);
            viewModel.changeDate(data.getValue(),false);
        }else {
            setSelect(true);
            viewModel.changeDate(data.getValue(),true);
        }
    });
}
