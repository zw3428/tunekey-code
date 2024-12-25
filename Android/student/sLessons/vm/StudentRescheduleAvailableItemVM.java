package com.spelist.tunekey.ui.student.sLessons.vm;

import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.AvailableTimesEntity;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/4/7
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleAvailableItemVM extends StudentRescheduleAvailableMultiItemVM<StudentRescheduleVM> {
    public ObservableField<Drawable> background = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.drawable.bg_with_border1_corner5));
    public ObservableField<Integer> textColor = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
    public ObservableField<String> text = new ObservableField<>("");
    public boolean isSelectData = false;


    public StudentRescheduleAvailableItemVM(@NonNull StudentRescheduleVM viewModel, AvailableTimesEntity data) {
        super(viewModel, data);
        text.set(data.getShowFormat());
    }

    public void changeIsSelectData(boolean isSelectData) {
        if (isSelectData){
            background.set(ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.drawable.blue_border));
            textColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
        }else {
            background.set(ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.drawable.bg_with_border1_corner5));
            textColor.set(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary));
        }
    }

    @Override
    protected void onClickItem(View view) {
        super.onClickItem(view);
        if (isSelectData){
            return;
        }
        changeIsSelectData(true);
        viewModel.clickAvailableItem(getData());
        isSelectData = true;
    }
}
