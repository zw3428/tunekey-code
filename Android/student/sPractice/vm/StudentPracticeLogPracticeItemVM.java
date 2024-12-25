package com.spelist.tunekey.ui.student.sPractice.vm;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.ui.teacher.students.vm.PracticeDetailVM;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.sPractice.vm
 * 2021/4/21
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeLogPracticeItemVM<VM extends BaseViewModel> extends ItemViewModel<VM> {
    public TKPractice data = new TKPractice();
    public ObservableField<Integer> image = new ObservableField<>(R.mipmap.checkbox);
    public ObservableField<String> text = new ObservableField<>("");
    public ObservableField<String> time = new ObservableField<>("");
    public ObservableField<Boolean> isShowPlay = new ObservableField<>(false);
    public ObservableField<Integer> playImage = new ObservableField<>(R.mipmap.ic_play_primary);

    public int fatherPos;

    public StudentPracticeLogPracticeItemVM(@NonNull VM viewModel, TKPractice data, int fatherPos) {
        super(viewModel);
        this.fatherPos = fatherPos;
        this.data = data;
        if (data.isManualLog()) {
            image.set(R.mipmap.manual_log);
        } else {
            if (data.isDone()) {
                image.set(R.mipmap.checkbox);
            } else {
                image.set(R.mipmap.checkbox_red);
            }
        }
        text.set(data.getName().trim());
        isShowPlay.set(data.getRecordData().size() > 0);
        if (data.getTotalTimeLength() > 0) {
            double totalTime = data.getTotalTimeLength() / 60;
            if (totalTime < 0.1 && totalTime > 0) {
                totalTime = 0.1;
            }
            String timeString = String.format("%.1f", totalTime) + "min";
            time.set(timeString);
        } else {
            time.set("");
        }
        if (data.getRecordData().size() > 0) {
            boolean isHaveVideo = false;
            for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
                if (recordDatum.getFormat().equals(".mp4")) {
                    isHaveVideo = true;
                    break;
                }
            }
            playImage.set(isHaveVideo ? R.mipmap.ic_video_play_primary : R.mipmap.ic_play_primary);
        }
    }

    public BindingCommand clickPlay = new BindingCommand(() -> {
        if (viewModel instanceof StudentPracticeLogVM) {
            if (data.getRecordData().size() > 0) {
                StudentPracticeLogVM vm = (StudentPracticeLogVM) viewModel;
                vm.clickPlay(data, fatherPos);
            }
        }
        if (viewModel instanceof PracticeDetailVM) {
            if (data.getRecordData().size() > 0) {
                PracticeDetailVM vm = (PracticeDetailVM) viewModel;
                vm.clickPlay(data, fatherPos);
            }
        }


    });

}
