package com.spelist.tunekey.ui.teacher.insights.vm;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.entity.StudentListEntity;

import org.jetbrains.annotations.NotNull;

import me.goldze.mvvmhabit.base.ItemViewModel;

/**
 * com.spelist.tunekey.ui.insights.vm
 * 2021/5/31
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class LearningStudentItemVM extends ItemViewModel<LearningVM> {
    public ObservableField<String> name = new ObservableField<>("");
    public ObservableField<String> id = new ObservableField<>("");
    public ObservableField<String> info = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public LearningStudentItemVM(@NonNull @NotNull LearningVM viewModel, StudentListEntity data) {
        super(viewModel);
        name.set(data.getName());
        id.set(data.getStudentId());
        info.set(data.getAchievementCount()+" awards");
        double timeLength = 0;
        if (data.getPracticeTime()  > 0) {

            time.set(String.format("%.1f", data.getPracticeTime()));
        }else {
            time.set("0");
        }
    }
}
