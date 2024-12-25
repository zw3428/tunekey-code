package com.spelist.tunekey.ui.student.sLessons.vm;

import androidx.annotation.NonNull;

import com.spelist.tools.viewModel.ToolbarViewModel;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKStudioEvent;

import me.goldze.mvvmhabit.base.ItemViewModel;

/**
 * com.spelist.tunekey.ui.materials.item
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentUpcomingMultiItemViewModel<S extends ToolbarViewModel> extends ItemViewModel<StudentUpcomingVM> {
   public static enum Type {
        UPCOMING,
        STUDIO_EVENT,
    }
    public Type type;
    public LessonScheduleEntity lessonData;
    public TKStudioEvent studioEventData;
    public String id = "";

    public StudentUpcomingMultiItemViewModel(@NonNull StudentUpcomingVM viewModel, int pos, Type type, LessonScheduleEntity lessonData, TKStudioEvent event) {
        super(viewModel);
        this.type = type;
        this.lessonData = lessonData;
        this.studioEventData = event;
        if (type == Type.UPCOMING) {
            id = lessonData.getId();
        } else if (type == Type.STUDIO_EVENT) {
            id = studioEventData.getId();
        }
    }
}
