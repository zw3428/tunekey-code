package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.ItemViewModel;

/**
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/29
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleByTeacherItemVM extends ItemViewModel<RescheduleByTeacherVM> {
    public ObservableField<String> timeStr = new ObservableField<>("");
    public ObservableField<String> nameStr = new ObservableField<>("");
    public ObservableField<String> userId = new ObservableField<>("");

    public ObservableField<Drawable> checkedImg = new ObservableField<>(ContextCompat.getDrawable(TApplication.mApplication,R.mipmap.check));
    public ObservableField<Drawable> unCheckedImg = new ObservableField<>(ContextCompat.getDrawable(TApplication.mApplication,R.mipmap.checkbox_off));
    public LessonScheduleEntity data;

    public RescheduleByTeacherItemVM(@NonNull RescheduleByTeacherVM viewModel , LessonScheduleEntity data) {
        super(viewModel);
        this.data = data;
        timeStr.set(TimeUtils.timeFormat(data.getTKShouldDateTime(),"hh:mm a, MMM d"));
        nameStr.set(data.getStudentData().getName());
        userId.set(data.getStudentId());

    }

    @Override
    protected void onClickItem(View view) {
        super.onClickItem(view);
        isChecked.set(!isChecked.get());
    }
}
