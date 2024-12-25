package com.spelist.tunekey.ui.teacher.lessons.vm;

import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonSchedulePlanEntity;

import java.util.HashMap;
import java.util.Map;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class LessonPlanItemViewModel extends ItemViewModel<LessonDetailsVM> {
    public ObservableField<String> plan = new ObservableField<>();
    public ObservableField<Drawable> checkImage = new ObservableField<>(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_red_3x));
    public ObservableField<LessonScheduleEntity> lessonData = new ObservableField<>();
    public ObservableField<Boolean> isDone = new ObservableField<>(false);
    public ObservableField<Boolean> isNextPlan = new ObservableField<>(false);

    public LessonSchedulePlanEntity lessonPlanData;


    public int isSelected;


    public LessonPlanItemViewModel(@NonNull LessonDetailsVM viewModel, LessonSchedulePlanEntity lessonSchedulePlanEntity, LessonScheduleEntity lessonScheduleEntity, boolean isNextLessonPlan) {
        super(viewModel);
        this.lessonPlanData = lessonSchedulePlanEntity;
        this.plan.set(lessonSchedulePlanEntity.getPlan());
        this.isNextPlan.set(isNextLessonPlan);
        lessonData.set(lessonScheduleEntity);
        isDone.set(lessonSchedulePlanEntity.isDone());
        checkImage.set(ContextCompat.getDrawable(TApplication.mApplication, lessonSchedulePlanEntity.isDone() ? R.mipmap.check_box_on : R.mipmap.checkbox_red_3x));
    }

    public void editPlan(String plan) {
        this.plan.set(plan);
        this.lessonPlanData.setPlan(plan);
    }

    public BindingCommand<View> itemClick = new BindingCommand<>(view -> {
        Logger.e("sdsdssd==>%s","sdsdsdsd");
//        viewModel.isChecked(type, lessonSchedulePlanEntity);
        if (isNextPlan.get()) {
            viewModel.clickEditPlan(lessonPlanData.getId(), plan.get(), true);
        } else {
            if (lessonData.get().getLessonStatus() == 0) {
                viewModel.clickEditPlan(lessonPlanData.getId(), plan.get(), false);
            }
        }
    });

    public BindingCommand<View> clickCheckButton = new BindingCommand<>(view -> {
        if (lessonData.get() == null){
            return;
        }
        if (isNextPlan.get()){
            return;
        }
        if (lessonData.get().getLessonStatus() > 0) {
            if (lessonPlanData.isDone()) {
                lessonPlanData.setDone(false);
                checkImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_red_3x));
            } else {
                lessonPlanData.setDone(true);
                checkImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.check_box_on));
            }
            isDone.set(lessonPlanData.isDone());
            Map<String, Object> map = new HashMap<>();
            map.put("done", lessonPlanData.isDone());
            viewModel.upDateLessonPlan(map, lessonPlanData.getId(), 1);
        }
    });


}
