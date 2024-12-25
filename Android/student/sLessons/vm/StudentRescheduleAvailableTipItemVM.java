package com.spelist.tunekey.ui.student.sLessons.vm;

import android.graphics.drawable.Drawable;
import android.text.Spannable;
import android.text.SpannableString;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.CenterAlignImageSpan;
import com.spelist.tunekey.entity.AvailableTimesEntity;

import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.sLessons.vm
 * 2021/4/7
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentRescheduleAvailableTipItemVM extends StudentRescheduleAvailableMultiItemVM<StudentRescheduleVM> {
    public ObservableField<Boolean> isShowOtherTimeButton = new ObservableField<>(false);
    public ObservableField<Boolean> isShowTip = new ObservableField<>(false);
    public ObservableField<Boolean> isShowNormal = new ObservableField<>(false);
    public ObservableField<String> normalText = new ObservableField<>("");
    public ObservableField<SpannableString> tipText = new ObservableField<>(new SpannableString(""));


    public StudentRescheduleAvailableTipItemVM(@NonNull StudentRescheduleVM viewModel, AvailableTimesEntity data) {
        super(viewModel, data);
        String tip = "This time is available, but\n" +
                "inconvenient for the instructor. ";
        SpannableString spannable = new SpannableString(tip + "[info]");//用于可变字符串
        Drawable drawable = ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.mipmap.icinfo3x);
        drawable.setBounds(0, 0, drawable.getMinimumWidth()  -19, drawable.getMinimumHeight() - 19);
        CenterAlignImageSpan span = new CenterAlignImageSpan(drawable, CenterAlignImageSpan.CENTRE);
        spannable.setSpan(span, tip.length(), tip.length() + "[info]".length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        tipText.set(spannable);
        isShowOtherTimeButton.set(false);
        isShowTip.set(false);
        isShowNormal.set(false);

        if (data.getType() == 0){
        }else if (data.getType()==1){

        }else if (data.getType() ==2){
            isShowNormal.set(true);
            normalText.set("Convenient Time:");
        }else if (data.getType() ==3){
            isShowOtherTimeButton.set(true);
        }else if (data.getType() == 5){
            isShowNormal.set(true);
            normalText.set("Other Time:");
        }else if (data.getType() == 6){
            isShowTip.set(true);
        }else {
            isShowNormal.set(true);
            normalText.set("Available Time:");
        }
    }
    public void showTip(){
        isShowOtherTimeButton.set(false);
        isShowTip.set(true);
        isShowNormal.set(false);
    }
    public BindingCommand clickOtherTime = new BindingCommand(() -> {
       viewModel.initAvailableTime(viewModel.selectTime,true);
    });
    public BindingCommand clickTip = new BindingCommand(() -> {
        viewModel.uc.clickAvailableTip.call();
    });
}
