package com.spelist.tunekey.ui.teacher.students.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class NewContactItemViewModel extends ItemViewModel<NewContactViewModel> {
    public MutableLiveData<AddressBookEntity> data = new MutableLiveData<>();
    public ObservableField<Boolean> isSelected = new ObservableField<>(false);
    public ObservableField<Boolean> isComplete = new ObservableField<>(false);
    public ObservableField<Integer> completeImg = new ObservableField<>(R.mipmap.check);
    public ObservableField<Integer> unCompleteImg = new ObservableField<>(R.mipmap.checkwenhao);
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> userId = new ObservableField<>();
    public ObservableField<Integer> nameColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(),R.color.fourth));
    public ObservableField<Integer> selectNameColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(),R.color.main));

    private int pos;

    public NewContactItemViewModel(@NonNull NewContactViewModel viewModel, AddressBookEntity addressBookEntity, int pos) {
        super(viewModel);
        this.viewModel = viewModel;
        data.setValue(addressBookEntity);
        name.set(addressBookEntity.getName());
        userId.set(addressBookEntity.getuId());
        this.pos = pos;

    }

    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
        viewModel.changePage(pos);
        //点击时变大
        isSelected.set(true);
    });


}
