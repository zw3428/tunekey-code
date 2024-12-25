package com.spelist.tunekey.ui.student.sLessons.vm;

import android.annotation.SuppressLint;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKStudioEvent;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/3/17
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentUpcomingEventItemVM extends StudentUpcomingMultiItemViewModel<StudentUpcomingVM> {

    public ObservableField<String> day = new ObservableField<>("");
    public ObservableField<String> month = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public ObservableField<String> title = new ObservableField<>("");
    public ObservableField<String> desc = new ObservableField<>("");
    public ObservableField<Boolean> isHaveDesc = new ObservableField<>(false);

    public TKStudioEvent data;
    public String color = "#71D9C2";

    public StudentUpcomingEventItemVM(@NonNull StudentUpcomingVM viewModel, int pos, Type type, LessonScheduleEntity lessonData, TKStudioEvent event) {
        super(viewModel, pos, type, lessonData, event);
        if (event != null) {
            this.data = event;
            initData();
        }
    }

    private void initData() {
        desc.set(data.getDescription());
        isHaveDesc.set(data.getDescription().length() > 0);
        day.set(TimeUtils.timeFormat((long) data.getStartTime(), "dd"));
        month.set(TimeUtils.timeFormat((long) data.getStartTime(), "MMM"));
        time.set(data.getTimeString());
        title.set(data.getTitle());
    }
}
