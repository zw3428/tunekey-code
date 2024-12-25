package com.spelist.tunekey.ui.teacher.students.activity;

import android.annotation.SuppressLint;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivityPracticeDetailBinding;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordHistoryDialog;
import com.spelist.tunekey.ui.teacher.students.vm.PracticeDetailVM;
import com.spelist.tunekey.utils.BaseRecyclerAdapter;
import com.spelist.tunekey.utils.BaseRecyclerHolder;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class PracticeDetailActivity extends BaseActivity<ActivityPracticeDetailBinding, PracticeDetailVM>{
    private BaseRecyclerAdapter<TKPracticeAssignment> adapter;
    /**
     * 初始化根布局
     *
     * @param savedInstanceState
     * @return 布局layout的id
     */
    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_practice_detail;
    }

    /**
     * 初始化ViewModel的id
     *
     * @return BR的id
     */
    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        String title = getIntent().getStringExtra("title");
        List<TKPractice> data = (List<TKPractice>) getIntent().getSerializableExtra("data");
        viewModel.initData(data);
        viewModel.setNormalToolbar(title);



        adapter = new BaseRecyclerAdapter<TKPracticeAssignment>(this, viewModel.practiceData, R.layout.item_student_log_day_v2) {
            @Override
            public void convert(BaseRecyclerHolder holder, TKPracticeAssignment item, int fPos, boolean isScrolling) {

                String date = TimeUtils.timeFormat(item.getStartTime(), "MMM d, yyyy");
                holder.setText(R.id.title, date);

                double totalTime = 0;
                String time = "";
                for (TKPractice p : item.getPractice()) {
                    totalTime += p.getTotalTimeLength();
                }
                if (totalTime > 0) {
                    totalTime = totalTime / 60;
                    if (totalTime <= 0.1) {
                        time = " 0.1 min";
                    } else {
                        time = (" " + String.format("%.1f", totalTime) + " min");
                    }
                } else {
                    time = (" 0 min");
                }
                holder.setText(R.id.time, time);
                RecyclerView recyclerView = holder.getView(R.id.recyclerView);
                recyclerView.setItemAnimator(null);
                recyclerView.setLayoutManager(new LinearLayoutManager(PracticeDetailActivity.this));

                BaseRecyclerAdapter<TKPractice> itemAdapter = new BaseRecyclerAdapter<TKPractice>(PracticeDetailActivity.this, item.getPractice(), R.layout.item_student_log_practice_v2) {
                    @Override
                    public void convert(BaseRecyclerHolder holder, TKPractice data, int position, boolean isScrolling) {
                        Drawable image = ContextCompat.getDrawable(PracticeDetailActivity.this, R.mipmap.checkbox);
                        Drawable playImage = ContextCompat.getDrawable(PracticeDetailActivity.this, R.mipmap.checkbox);
                        String text = "";
                        String time = "";
                        boolean isShowPlay = false;
                        if (data.isManualLog()) {
                            image = ContextCompat.getDrawable(PracticeDetailActivity.this, R.mipmap.manual_log);
                        } else {
                            if (data.isDone()) {
                                image = ContextCompat.getDrawable(PracticeDetailActivity.this, R.mipmap.checkbox);
                            } else {
                                image = ContextCompat.getDrawable(PracticeDetailActivity.this, R.mipmap.checkbox_red);
                            }
                        }

                        text = (data.getName().trim());
                        isShowPlay = (data.getRecordData().size() > 0);
                        if (data.getTotalTimeLength() > 0) {
                            double totalTime = data.getTotalTimeLength() / 60;
                            if (totalTime < 0.1 && totalTime > 0) {
                                totalTime = 0.1;
                            }
                            @SuppressLint("DefaultLocale") String timeString = String.format("%.1f", totalTime) + "min";
                            time = (timeString);
                        } else {
                            time = ("");
                        }
                        if (data.getRecordData().size() > 0) {
                            boolean isHaveVideo = false;
                            for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
                                if (recordDatum.getFormat().equals(".mp4")) {
                                    isHaveVideo = true;
                                    break;
                                }
                            }
                            playImage = ContextCompat.getDrawable(PracticeDetailActivity.this, (isHaveVideo ? R.mipmap.ic_video_play_primary : R.mipmap.ic_play_primary));
                        }

                        holder.setImageDrawable(R.id.imageView, image);
                        holder.setText(R.id.nameTv, text);
                        ImageView playButton = holder.getView(R.id.playButton);
                        playButton.setImageDrawable(playImage);
                        playButton.setVisibility(isShowPlay ? View.VISIBLE : View.GONE);
                        holder.setText(R.id.timeTv, time);
                        playButton.setOnClickListener(v -> {
                            viewModel.clickPlay(data, fPos);
                        });

                    }
                };
                recyclerView.setAdapter(itemAdapter);

            }
        };
        binding.recyclerView.setAdapter(adapter);
        
    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.refData.observe(this,unused -> {
            if (adapter!=null){
                adapter.refreshData(viewModel.practiceData);
            }
        });
        viewModel.uc.clickPlayPractice.observe(this, practice -> {
            RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(this, CloneObjectUtils.cloneObject(practice),this,0,true);
            recordHistoryDialog.showDialog();
//修改practice
//
//            new RxPermissions(this)
//                    .request(Manifest.permission.READ_EXTERNAL_STORAGE
//                            , Manifest.permission.WRITE_EXTERNAL_STORAGE)
//                    .subscribe(aBoolean -> {
//                        if (aBoolean) {
//                            PlayPracticeDialog playPracticeDialog = new PlayPracticeDialog(this, practice, false);
//                            new XPopup.Builder(this)
//                                    .isDestroyOnDismiss(true)
//                                    .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
//                                    .dismissOnTouchOutside(false)
//                                    .enableDrag(false)
//                                    .asCustom(playPracticeDialog)
//                                    .show();
//
//                        }else{
//                            SLToast.warning("Please allow to access your device and try again.");
//                        }
//                    });

        });
    }
}