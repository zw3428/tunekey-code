package com.spelist.tunekey.ui.teacher.students.activity;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.databinding.ActivityPracticeBinding;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordHistoryDialog;
import com.spelist.tunekey.ui.teacher.students.vm.PracticeViewModel;
import com.spelist.tunekey.utils.BaseRecyclerAdapter;
import com.spelist.tunekey.utils.BaseRecyclerHolder;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;

public class PracticeActivity extends BaseActivity<ActivityPracticeBinding, PracticeViewModel> {

    //1: teacher lesson detail, 2: student lesson detail, 3:Student detail
    private int type = 1;
    private BaseRecyclerAdapter<TKPracticeAssignment> adapter;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_practice;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        binding.recyclerView.setItemAnimator(null);
        binding.refreshLayout.setEnableRefresh(false);//是否启用下拉刷新功能
        binding.refreshLayout.setEnableLoadMore(false);//是否启用上拉加载功能
        binding.refreshLayout.setEnableAutoLoadMore(true);//是否启用列表惯性滑动到底部时自动加载更多
        binding.refreshLayout.setEnableLoadMoreWhenContentNotFull(true);//是否在列表不满一页时候开启上拉加载功能
        binding.refreshLayout.setEnableOverScrollDrag(true);//是否启用越界拖动（仿苹果效果）1.0.4
        binding.refreshLayout.setOnLoadMoreListener(refreshLayout -> {
//            viewModel.start = viewModel.end;
            viewModel.end = viewModel.start;
            viewModel.start = (int) (TimeUtils.addMonth(viewModel.start * 1000L, -3) / 1000L);
//            viewModel.endTime = (int) (TimeUtils.addMonth(viewModel.startTime * 1000L, 1) / 1000L);
            viewModel.getLessonData();
        });
    }

    @Override
    public void initData() {
        type = getIntent().getIntExtra("type", 1);
        if (type == 1) {
            List<TKPractice> data = (List<TKPractice>) getIntent().getSerializableExtra("data");
            LessonScheduleEntity lessonData = (LessonScheduleEntity) getIntent().getSerializableExtra("lessonData");
            if (data != null && lessonData != null && lessonData.getLastLessonData() != null) {
                viewModel.initData(data, lessonData);
            }
        } else if (type == 2) {
            List<TKPractice> data = (List<TKPractice>) getIntent().getSerializableExtra("data");
            viewModel.initStudentLessonData(data, getIntent().getIntExtra("startTime", 0), getIntent().getIntExtra("endTime", 0));
        } else if (type == 3) {
            List<TKPractice> data = (List<TKPractice>) getIntent().getSerializableExtra("data");
            String teacherId = getIntent().getStringExtra("teacherId");
            String studentId = getIntent().getStringExtra("studentId");
            viewModel.initStudentData(teacherId, studentId, data);
            binding.refreshLayout.setEnableLoadMore(true);//是否启用上拉加载功能
        }
        initAdapter();
    }

    private void initAdapter() {
        adapter = new BaseRecyclerAdapter<TKPracticeAssignment>(this, new ArrayList<>(), R.layout.item_practice_v2) {


            @Override
            public void convert(BaseRecyclerHolder holder, TKPracticeAssignment data, int position, boolean isScrolling) {
                ImageView practiceCalendar = (ImageView) holder.getView(R.id.practice_calendar);
                TextView titleTime = (TextView) holder.getView(R.id.titleTime);
                TextView totalTimeTv = (TextView) holder.getView(R.id.totalTime);
                ImageView arrow = (ImageView) holder.getView(R.id.arrow);
                LinearLayout itemAssignment = (LinearLayout) holder.getView(R.id.item_assignment);
                TextView assignmentInfo = (TextView) holder.getView(R.id.assignmentInfo);
                RecyclerView assignmentRecyclerView = (RecyclerView) holder.getView(R.id.assignmentRecyclerView);
                LinearLayout itemSelfStudy = (LinearLayout) holder.getView(R.id.item_selfStudy);
                TextView selfStudyInfo = (TextView) holder.getView(R.id.selfStudyInfo);
                RecyclerView selfStudyRecycleView = (RecyclerView) holder.getView(R.id.selfStudyRecycleView);

                titleTime.setText(data.getTime());
                arrow.setOnClickListener(v -> {
                    viewModel.clickToDetail(data);
                });
                totalTimeTv.setOnClickListener(v -> {
                    viewModel.clickToDetail(data);
                });

                boolean isComplete = true;
                if (data.getTotalTime() > 0) {
                    String timeString = "";
                    String hourString = "";
                    String minString = "";
                    String secondString = "";
                    int hour = ((int) data.getTotalTime()) / 3600;
                    if (hour > 0) {
                        hourString = hour + "h";
                    }
                    int min = ((int) data.getTotalTime()) % 3600 / 60;
                    if (min > 0) {
                        minString = min + "m";
                    }
                    int second = (((int) data.getTotalTime()) - hour * 3600 - min * 60) % 3600;
                    if (second > 0) {
                        secondString = second + "s";
                    }
                    timeString += hourString;

                    timeString += minString;
                    if (hour == 0) {
                        timeString += secondString;
                    }
                    totalTimeTv.setText(timeString);
                    arrow.setVisibility(View.VISIBLE);
                    totalTimeTv.setTextColor(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main));
                } else {
                    arrow.setVisibility(View.GONE);
                    totalTimeTv.setText("0 h");
                    totalTimeTv.setTextColor(ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.red));
                }
                if (viewModel.isShowIncomplete) {
                    if (type == 3) {
                        assignmentInfo.setText("");
                    } else {
                        assignmentInfo.setText("Incomplete");
                    }
                } else {
                    assignmentInfo.setText("Uncompleted");
                }
                if (data.getAssignment().size() > 0) {
                    itemAssignment.setVisibility(View.VISIBLE);
                } else {
                    itemAssignment.setVisibility(View.GONE);
                }
                if (data.getSelfStudy().size() > 0) {
                    itemSelfStudy.setVisibility(View.VISIBLE);
                } else {
                    itemSelfStudy.setVisibility(View.GONE);
                }
                for (TKPractice practice : data.getAssignment()) {
                    if (!practice.isDone()) {
                        isComplete = false;
                    }
                }
                initAssignmentAdapter(data.getAssignment(), assignmentRecyclerView);
                initAssignmentAdapter(data.getSelfStudy(), selfStudyRecycleView);
                if (isComplete) {
                    assignmentInfo.setText("");
                }
            }
        };
        binding.recyclerView.setAdapter(adapter);

    }

    private void initAssignmentAdapter(List<TKPractice> assignment, RecyclerView recyclerView) {
        BaseRecyclerAdapter<TKPractice> adapter = new BaseRecyclerAdapter<TKPractice>(this, assignment, R.layout.item_practice_info_v2) {
            @Override
            public void convert(BaseRecyclerHolder holder, TKPractice data, int position, boolean isScrolling) {
                ImageView leftImage = (ImageView) holder.getView(R.id.leftImage);
                TextView title = (TextView) holder.getView(R.id.title);
                ImageView play = (ImageView) holder.getView(R.id.play);
                title.setText(data.getName());
                if (data.getRecordData() != null && data.getRecordData().size() > 0) {
                    play.setVisibility(View.VISIBLE);
                    boolean isHaveVideo = false;
                    for (TKPractice.PracticeRecord recordDatum : data.getRecordData()) {
                        if (recordDatum.getFormat().equals(".mp4")) {
                            isHaveVideo = true;
                            break;
                        }
                    }
                    play.setImageResource(isHaveVideo ? R.mipmap.ic_video_play_primary : R.mipmap.ic_play_primary);
                } else {
                    play.setVisibility(View.GONE);
                }
                if (data.isDone()) {
                    leftImage.setImageDrawable(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox));
                    if (data.isManualLog()) {
                        leftImage.setImageDrawable(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.manual_log));
                    }
                } else {
                    leftImage.setImageDrawable(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_off));
                    if (data.isAssignment()) {
                        leftImage.setImageDrawable(ContextCompat.getDrawable(TApplication.mApplication, R.mipmap.checkbox_red));
                    }
                }
                play.setOnClickListener(v -> {
                    viewModel.clickPlay(data);
                });

            }
        };
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setItemAnimator(null);
        recyclerView.setAdapter(adapter);
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.refData.observe(this, practice -> {
            if (adapter != null) {
                adapter.refreshData(practice);
            }
        });
        viewModel.uc.clickPlayPractice.observe(this, practice -> {
            RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(this, CloneObjectUtils.cloneObject(practice), this, 0, true);
            recordHistoryDialog.showDialog();

            //修改practice
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
//                        }else{
//                            SLToast.warning("Please allow to access your device and try again.");
//
//                        }
//                    });

        });
        viewModel.uc.loadingComplete.observe(this, lessonScheduleEntities -> {
            binding.refreshLayout.finishLoadMore();
            if (lessonScheduleEntities.size() == 0) {
                binding.refreshLayout.setNoMoreData(true);
            }
        });
    }
}
