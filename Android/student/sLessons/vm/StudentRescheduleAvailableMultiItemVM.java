package com.spelist.tunekey.ui.student.sLessons.vm;

import androidx.annotation.NonNull;

import com.spelist.tunekey.entity.AvailableTimesEntity;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;

/**
 * com.spelist.tunekey.ui.materials.item
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleAvailableMultiItemVM<VM extends BaseViewModel> extends ItemViewModel<VM> {
    private Class<VM> clazz;
    private AvailableTimesEntity data;

    public StudentRescheduleAvailableMultiItemVM(@NonNull VM viewModel, AvailableTimesEntity data) {
        super(viewModel);
        this.data = data;

    }

    public AvailableTimesEntity getData(){
        return data;
    }


}
