package com.spelist.tunekey.ui.teacher.students.vm;

import android.annotation.SuppressLint;
import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.TKPractice;

import me.goldze.mvvmhabit.base.ItemViewModel;

/**
 * com.spelist.tunekey.ui.students.vm
 * 2021/1/27
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeItemInfoViewModel extends ItemViewModel<PracticeViewModel> {
    public ObservableField<TKPractice> data = new ObservableField<>();
    public ObservableField<Drawable> leftImage = new ObservableField<>(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_red));
    public ObservableField<Boolean> isShowPlayButton = new ObservableField<>(false);
    public ObservableField<Integer> playImage = new ObservableField<>(R.mipmap.ic_play_primary);

    public PracticeItemInfoViewModel(@NonNull PracticeViewModel viewModel, TKPractice data) {
        super(viewModel);
        initData(data);

    }

    @Override
    protected void onClickItem(View view) {
        super.onClickItem(view);
        viewModel.clickPlay(data.get());
    }

    @SuppressLint("DefaultLocale")
    private void initData(TKPractice data) {
        this.data.set(data);
        if (data.getRecordData() != null && data.getRecordData().size() > 0) {
            isShowPlayButton.set(true);
            boolean isHaveVideo = false;
            for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
                if (recordDatum.getFormat().equals(".mp4")) {
                    isHaveVideo = true;
                    break;
                }
            }
            playImage.set(isHaveVideo ? R.mipmap.ic_video_play_primary : R.mipmap.ic_play_primary);
        } else {
            isShowPlayButton.set(false);
        }
        if (data.isDone()) {
            leftImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox));
            if (data.isManualLog()) {
                leftImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.manual_log));
            }
        } else {
            leftImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_off));
            if (data.isAssignment()) {
                leftImage.set(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_red));
            }
        }
    }
}