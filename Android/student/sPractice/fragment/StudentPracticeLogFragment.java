package com.spelist.tunekey.ui.student.sPractice.fragment;

import android.annotation.SuppressLint;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.databinding.FragmentStudentPracticeLogBinding;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.vm.StudentPracticeFragmentV2VM;
import com.spelist.tunekey.ui.student.sPractice.vm.StudentPracticeLogVM;
import com.spelist.tunekey.utils.BaseRecyclerAdapter;
import com.spelist.tunekey.utils.BaseRecyclerHolder;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.tatarka.bindingcollectionadapter2.BR;

/**
 * com.spelist.tunekey.ui.sPractice.fragment
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeLogFragment extends BaseFragment<FragmentStudentPracticeLogBinding, StudentPracticeLogVM> {

    private BaseRecyclerAdapter<TKPracticeAssignment> adapter;
    private LinearLayoutManager layoutManager;

    /**
     * 初始化根布局
     *
     * @param inflater
     * @param container
     * @param savedInstanceState
     * @return 布局layout的id
     */
    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_practice_log;
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
    }

    public void setData(StudentPracticeFragmentV2VM practiceVM, String logDate) {
        if (viewModel != null) {
            viewModel.practiceVM = practiceVM;
            List<String> notUploadPracticeFileId = SLCacheUtil.getNotUploadPracticeFileId(UserService.getInstance().getCurrentUserId());

            List<TKPracticeAssignment> tkPracticeAssignments = CloneObjectUtils.cloneObject(practiceVM.practiceData);
            for (TKPracticeAssignment tkPracticeAssignment : tkPracticeAssignments) {
                for (TKPractice tkPractice : tkPracticeAssignment.getPractice()) {
                    tkPractice.getRecordData().removeIf(record -> {
                        if (record.isUpload()) {
                            return false;
                        } else {
                            return !(notUploadPracticeFileId.contains(record.getId()));
                        }
                    });
                }
            }

            for (TKPracticeAssignment tkPracticeAssignment : tkPracticeAssignments) {
                List<TKPractice> newData = new ArrayList<>();
                for (TKPractice oldItem : tkPracticeAssignment.getPractice()) {
                    int pos = -1;
                    for (int i = 0; i < newData.size(); i++) {
                        TKPractice newItem = newData.get(i);
                        if (newItem.getName().equals(oldItem.getName())) {
                            pos = i;
                        }
                    }
                    if (pos == -1) {
                        for (TKPractice.PracticeRecord recordDatum : oldItem.getRecordData()) {
                            recordDatum.setPraicticeId(oldItem.getId());
                        }
                        newData.add(oldItem);
                    } else {
                        TKPractice newItem = newData.get(pos);
                        for (TKPractice.PracticeRecord recordDatum : oldItem.getRecordData()) {
                            recordDatum.setPraicticeId(oldItem.getId());
                        }
                        newItem.getRecordData().addAll(oldItem.getRecordData());
                        newItem.setTotalTimeLength(newItem.getTotalTimeLength() + oldItem.getTotalTimeLength());
                        if (oldItem.isDone()) {
                            newItem.setDone(true);
                        }
                        if (oldItem.isManualLog()) {
                            newItem.setManualLog(true);
                        }
                    }
                }
                for (TKPractice newDatum : newData) {
                    newDatum.getRecordData().sort((o1, o2) -> o2.getStartTime() - o1.getStartTime());
                }
//                newData.sort((o1, o2) -> {
////                    int o1Time = o1.getStartTime();
////                    int o2Time = o2.getStartTime();
////                    if (o1.getRecordData().size() > 0) {
////                        o1Time = o1.getRecordData().get(0).getStartTime();
////                    }
////                    if (o2.getRecordData().size() > 0) {
////                        o2Time = o2.getRecordData().get(0).getStartTime();
////                    }
//                    int o1Time = o1.getCreateTimes();
//                    int o2Time = o2.getCreateTimes();
//                    return o2Time - o1Time;
//
//                });
                tkPracticeAssignment.setPractice(newData);
            }

            viewModel.initData(tkPracticeAssignments);
            adapter.refreshData(tkPracticeAssignments);
            if (!logDate.equals("")) {
                int pos = -1;
                for (int i = 0; i < tkPracticeAssignments.size(); i++) {
                    if (logDate.equals(TimeUtils.timeFormat(tkPracticeAssignments.get(i).getStartTime(), "yyyy/MM/dd"))){
                        pos = i;
                        break;
                    }
                }
                Logger.e("pos==>%s",pos);
                if (pos != -1) {
//                    BaseRecyclerAdapter.moveToPosition(pos,binding.practiceList);
                    layoutManager.scrollToPositionWithOffset(pos,0);
                }
            }
        }
    }


    @Override
    public void initView() {
        super.initView();
        layoutManager = new LinearLayoutManager(getContext());
        binding.practiceList.setLayoutManager(layoutManager);
        binding.practiceList.setItemAnimator(null);
        adapter = new BaseRecyclerAdapter<TKPracticeAssignment>(getContext(), viewModel.data, R.layout.item_student_log_day_v2) {
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
                recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

                BaseRecyclerAdapter<TKPractice> itemAdapter = new BaseRecyclerAdapter<TKPractice>(getContext(), item.getPractice(), R.layout.item_student_log_practice_v2) {
                    @Override
                    public void convert(BaseRecyclerHolder holder, TKPractice data, int position, boolean isScrolling) {
                        Drawable image = ContextCompat.getDrawable(getContext(), R.mipmap.checkbox);
                        Drawable playImage = ContextCompat.getDrawable(getContext(), R.mipmap.checkbox);
                        String text = "";
                        String time = "";
                        boolean isShowPlay = false;
                        if (data.isManualLog()) {
                            image = ContextCompat.getDrawable(getContext(), R.mipmap.manual_log);
                        } else {
                            if (data.isDone()) {
                                image = ContextCompat.getDrawable(getContext(), R.mipmap.checkbox);
                            } else {
                                image = ContextCompat.getDrawable(getContext(), R.mipmap.checkbox_red);
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
                            playImage = ContextCompat.getDrawable(getContext(), (isHaveVideo ? R.mipmap.ic_video_play_primary : R.mipmap.ic_play_primary));
                        }

                        holder.setImageDrawable(R.id.imageView, image);
                        holder.setText(R.id.nameTv, text);
                        ImageView playButton = holder.getView(R.id.playButton);
                        playButton.setImageDrawable(playImage);
                        playButton.setVisibility(isShowPlay ? View.VISIBLE : View.GONE);
                        holder.setText(R.id.timeTv, time);
                        playButton.setOnClickListener(v -> {
                            viewModel.practiceVM.clickPlay(data, fPos);
                        });

                    }
                };
                recyclerView.setAdapter(itemAdapter);

            }
        };
        binding.practiceList.setAdapter(adapter);
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
    }
}
