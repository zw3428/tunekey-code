package com.spelist.tunekey.ui.teacher.students.vm;

import android.text.SpannableStringBuilder;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.LessonScheduleEntity;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import me.goldze.mvvmhabit.base.ItemViewModel;

public class NotesItemViewModel extends ItemViewModel<NotesViewModel> {

    public ObservableField<SpannableStringBuilder> myNoteSpan = new ObservableField<>(new SpannableStringBuilder(""));
    public ObservableField<SpannableStringBuilder> studentNoteSpan = new ObservableField<>(new SpannableStringBuilder(""));


    public ObservableField<String> date = new ObservableField<>("");
    public ObservableField<Boolean> myNotesVisible = new ObservableField<>();
    public ObservableField<Boolean> studentNotesVisible = new ObservableField<>();

    public NotesItemViewModel(@NonNull NotesViewModel viewModel, LessonScheduleEntity lessonScheduleEntity) {
        super(viewModel);
        myNotesVisible.set(false);
        studentNotesVisible.set(false);
        if (!lessonScheduleEntity.getTeacherNote().equals("")) {
            myNotesVisible.set(true);
            String str = "Me: " +lessonScheduleEntity.getTeacherNote();
            myNoteSpan.set(SLStringUtils.getSpan(str,ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary),"Me: "));
        }
        if (!lessonScheduleEntity.getStudentNote().equals("")) {
            studentNotesVisible.set(true);
            String str = "Student: " +lessonScheduleEntity.getStudentNote();
            studentNoteSpan.set(SLStringUtils.getSpan(str,ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.primary),"Student: "));
        }
        this.date.set(timeDate(String.valueOf(lessonScheduleEntity.getShouldDateTime())));
    }

    /**
     * 调用此方法输入所要转换的时间戳输入例如（1402733340）输出（"英文月份缩写 日期"）
     *
     * @param time
     * @return
     */
    public static String timeDate(String time) {
        SimpleDateFormat sdr = new SimpleDateFormat("MMM d", Locale.ENGLISH);
        @SuppressWarnings("unused")
        int i = Integer.parseInt(time);
        String times = sdr.format(new Date(i * 1000L));
        return times;
    }
}
