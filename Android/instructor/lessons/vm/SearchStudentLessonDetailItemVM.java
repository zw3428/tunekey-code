package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.ItemViewModel;
import retrofit2.http.PUT;

/**
 * com.spelist.tunekey.ui.lessons.vm
 * 2021/1/29
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class SearchStudentLessonDetailItemVM extends ItemViewModel<SearchStudentLessonDetailVM> {
    public ObservableField<String> yearString = new ObservableField<>("2020");
    public ObservableField<String> dayString = new ObservableField<>("15");
    public ObservableField<String> monthString = new ObservableField<>("Jul");
    public ObservableField<String> timeString = new ObservableField<>("04:00 AM");
    private LessonScheduleEntity itemData ;

    public SearchStudentLessonDetailItemVM(@NonNull SearchStudentLessonDetailVM viewModel, LessonScheduleEntity entity) {
        super(viewModel);
        itemData = entity;
        yearString.set(TimeUtils.timeFormat(entity.getTKShouldDateTime(),"yyyy"));
        dayString.set(TimeUtils.timeFormat(entity.getTKShouldDateTime(),"d"));
        monthString.set(TimeUtils.timeFormat(entity.getTKShouldDateTime(),"MMM"));
        timeString.set(TimeUtils.timeFormat(entity.getTKShouldDateTime(),"hh:mm a"));
    }

    @Override
    protected void onClickItem(View view) {
        viewModel.clickItem(itemData);
    }
}
