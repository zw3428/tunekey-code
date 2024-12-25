package com.spelist.tunekey.ui.teacher.students.vm;

import android.graphics.drawable.Drawable;
import android.text.SpannableStringBuilder;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.utils.SLTools;

import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingAction;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

public class StudentDetailProfileFragmentItemViewModel extends ItemViewModel<StudentDetailV2VM> {
    public ObservableField<String> lessonTimeInfo = new ObservableField<>("");
    public ObservableField<Drawable> lessonTimeInfoBackground = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(),R.drawable.student_details_lesson_time_main));
    public ObservableField<Integer> lessonTimeInfoTextColor= new ObservableField<>(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(),R.color.main));
    public ObservableField<Boolean> isShowLessonTimeInfo = new ObservableField<>(false);

    public ObservableField<String> lessonTypeName = new ObservableField<>();
    public ObservableField<SpannableStringBuilder> lessonTypeInfo = new ObservableField<>();
    public ObservableField<String> imagePath = new ObservableField<>();
    public ObservableField<Integer> image = new ObservableField<>();
    public ObservableField<Boolean> isStudentLook = new ObservableField<>(false);

    public LessonScheduleConfigEntity data;
    private Boolean isEdit;
    public ObservableField<Integer> instrumentPlaceholder = new ObservableField<>(R.drawable.def_instrument);


//    public StudentDetailProfileFragmentItemViewModel(@NonNull StudentDetailProfileFragmentViewModel viewModel, LessonTypeEntity lesson, int pos) {
//        super(viewModel);
//        this.pos = pos;
//        editData(lesson);
//    }

    public StudentDetailProfileFragmentItemViewModel(@NonNull StudentDetailV2VM viewModel, LessonScheduleConfigEntity config,boolean isEdit) {
        super(viewModel);
        this.isEdit = isEdit;
        initData(config);
        isStudentLook.set(viewModel.isStudentLook.get());
    }


    public void initData(LessonScheduleConfigEntity config) {
        this.data = config;
        lessonTypeName.set(config.getLessonType().getName());
        lessonTypeInfo.set(SLTools.getLessonScheduleConfigDetailedInfo(config,viewModel.isStudentLook.get()));
        imagePath.set(config.getLessonType().getInstrumentPath());
        changeEditType(isEdit);
    }


    /**
     * 设置time info 文字 type: 0绿色,type:1 红色
     * @param info
     * @param type
     */
    public void setTimeInfo(String info,int type){
        if (info.equals("")){
            isShowLessonTimeInfo.set(false);
        }else {
            isShowLessonTimeInfo.set(true);
            lessonTimeInfo.set(info);
            if (type == 0 ){
                lessonTimeInfoBackground.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(),R.drawable.student_details_lesson_time_main));
                lessonTimeInfoTextColor.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(),R.color.main));
            }else {
                lessonTimeInfoBackground.set(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(),R.drawable.student_details_lesson_time_red));
                lessonTimeInfoTextColor.set(ContextCompat.getColor(TApplication.getInstance().getApplicationContext(),R.color.red));
            }
        }
    }

    public BindingCommand clickItem = new BindingCommand(new BindingAction() {
        @Override
        public void call() {
            viewModel.clickLessonItem(data);
        }
    });




    public void changeEditType(boolean isEdit) {
        this.isEdit = isEdit;
        if (this.isEdit) {
            image.set(R.mipmap.ic_delete_red);
        } else {
            image.set(R.mipmap.ic_arrow_primary_next);
        }
    }

}
