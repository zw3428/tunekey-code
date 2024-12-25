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
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class LessonBeforeItemViewModel extends ItemViewModel<LessonDetailsVM> {
    public LessonScheduleEntity data;
    public ObservableField<String> name = new ObservableField<>();
    public ObservableField<String> lessonInfo = new ObservableField<>("");
    public ObservableField<String> logoPath = new ObservableField<>();
    public ObservableField<String> timeString = new ObservableField<>("");
    public ObservableField<Integer> isShowLeftLine = new ObservableField<>(View.VISIBLE);
    public ObservableField<Integer> isShowRightLine = new ObservableField<>(View.VISIBLE);

    public ObservableField<Drawable> progressLine1 = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.dividing_lineColor));
    public ObservableField<Drawable> progressStep2 = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.border_circle));
    public ObservableField<Drawable> progressStep3 = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.border_circle));
    public ObservableField<Drawable> progressLine2 = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.dividing_lineColor));
    public ObservableField<Integer> progressStepTextColor2 = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
    public ObservableField<Integer> progressStepTextColor3 = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
    public ObservableField<Integer> progressStepBottomTextColor2 = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
    public ObservableField<Integer> progressStepBottomTextColor3 = new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
    public ObservableField<Integer> instrumentPlaceholder = new ObservableField<>(R.drawable.def_instrument);
    public ObservableField<String> memo = new ObservableField<>();
    public ObservableField<Boolean> isShowMemo = new ObservableField<>(false);
    private int position;

    public LessonBeforeItemViewModel(@NonNull LessonDetailsVM viewModel, LessonScheduleEntity data, int pos, boolean isShowRightLine) {
        super(viewModel);
        this.data = data;
        name.set(data.getStudentName());
        if (data.getLessonType()!=null){
            this.logoPath.set(data.getLessonType().getInstrumentPath());
        }
//        if (data.getConfigEntity().getRepeatType() == 0) {
//            lessonInfo.set("$" + data.getPrice());
//        } else if (data.getConfigEntity().getRepeatType() == 1) {
//            lessonInfo.set("$" + data.getPrice() + ", weekly");
//        } else if (data.getConfigEntity().getRepeatType() == 2) {
//            lessonInfo.set("$" + data.getPrice() + ", bi-weekly");
//        } else if (data.getConfigEntity().getRepeatType() == 3) {
//            lessonInfo.set("$" + data.getPrice() + ", monthly");
//        }
        lessonInfo.set(data.getDetailedInfo());
        this.position = pos;


        isShowLeftLine.set(pos != 0 ? View.VISIBLE : View.INVISIBLE);
        this.isShowRightLine.set(isShowRightLine ? View.VISIBLE : View.INVISIBLE);
        timeString.set(TimeUtils.timeFormat(data.getTKShouldDateTime(), "hh:mm a"));


        switch (data.getLessonStatus()) {
            case 0:
                progressLine1.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.dividing_lineColor));
                progressStep2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.border_circle));
                progressStep3.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.border_circle));
                progressLine2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.dividing_lineColor));
                progressStepTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                progressStepTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                progressStepBottomTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                progressStepBottomTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                break;
            case 1:
                progressLine1.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.main));
                progressStep2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.main_circle_12));
                progressStep3.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.border_circle));
                progressLine2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.dividing_lineColor));
                progressStepTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.white));
                progressStepTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                progressStepBottomTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.main));
                progressStepBottomTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.fourth));
                break;
            case 2:
                progressLine1.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.main));
                progressStep2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.main_circle_12));
                progressStep3.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.main_circle_12));
                progressLine2.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.color.main));
                progressStepTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.white));
                progressStepTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.white));
                progressStepBottomTextColor2.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.main));
                progressStepBottomTextColor3.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(), R.color.main));
                break;
        }



    }

    public BindingCommand clickItem = new BindingCommand(() -> {
                    viewModel.clickStudent();
    }

    );
}
