package com.spelist.tunekey.ui.teacher.lessons.dialog.rescheduleBox;

import android.graphics.Paint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.DataBindingUtil;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.databinding.ItemRescheduleBoxBinding;
import com.spelist.tunekey.entity.LessonRescheduleEntity;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.List;

/**
 * com.spelist.tunekey.ui.lessons.dialog.rescheduleBox
 * 2021/2/5
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleBoxAdapter extends RecyclerView.Adapter<RescheduleBoxAdapter.ViewHolder> {
    public interface clickItem{
        void clickConfirm(int pos);
        void clickReschedule(int pos);
        void clickDeclined(int pos);
        void clickRetract(int pos);
        void clickClose(int pos);
    }
    private RescheduleBoxAdapter.clickItem onItemClickListener;
    public void setOnItemClickListener(RescheduleBoxAdapter.clickItem onItemClickListener){
        this.onItemClickListener = onItemClickListener;
    }


    private List<LessonRescheduleEntity> datas;

    public RescheduleBoxAdapter(List<LessonRescheduleEntity> datas) {
        this.datas = datas;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_reschedule_box, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        if (position==0){
            holder.binding.headerView.setVisibility(View.VISIBLE);
        }else {
            holder.binding.headerView.setVisibility(View.GONE);
        }


        //初始化Button
        holder.binding.confirmButton.setVisibility(View.GONE);
        holder.binding.rescheduleButton.setVisibility(View.GONE);
        holder.binding.declinedButton.setVisibility(View.GONE);
        holder.binding.retractButton.setVisibility(View.GONE);
        holder.binding.centerRetractButton.setVisibility(View.GONE);
        holder.binding.closeButton.setVisibility(View.GONE);
        holder.binding.afterQuestionImg.setVisibility(View.GONE);
        holder.binding.afterLayout.setVisibility(View.GONE);
        holder.binding.statusTv.setText("");
        holder.binding.arrowImg.setVisibility(View.VISIBLE);




        LessonRescheduleEntity data = datas.get(position);
        double timeBefore = 0;
        if (!data.getTimeBefore().equals("")) {
            timeBefore = Double.parseDouble(data.getTKBefore());
        }
        double timeAfter = 0;
        if (!data.getTimeAfter().equals("")) {
            timeAfter = Double.parseDouble(data.getTKAfter());
            if (timeAfter < TimeUtils.getCurrentTime()){
                timeAfter = 0;
            }
        }
        if (timeAfter == 0) {
            holder.binding.afterLayout.setVisibility(View.GONE);
            holder.binding.afterQuestionImg.setVisibility(View.VISIBLE);
        } else {
            holder.binding.afterLayout.setVisibility(View.VISIBLE);
            holder.binding.afterQuestionImg.setVisibility(View.GONE);
            holder.binding.afterDayTV.setText(TimeUtils.timeFormat((long) timeAfter, "d"));
            holder.binding.afterMonthTV.setText(TimeUtils.timeFormat((long) timeAfter, "MMM"));
            holder.binding.afterTimeTv.setText(TimeUtils.timeFormat((long) timeAfter, "hh:mm a"));
        }

        holder.binding.beforeDayTV.setText(TimeUtils.timeFormat((long) timeBefore, "d"));
        holder.binding.beforeMonthTV.setText(TimeUtils.timeFormat((long) timeBefore, "MMM"));
        holder.binding.beforeTimeTv.setText(TimeUtils.timeFormat((long) timeBefore, "hh:mm a"));

        String studentName = "";
        if (data.getStudentData() != null) {
            studentName = data.getStudentData().getName();
        }

        int mainColor = ContextCompat.getColor(TApplication.getInstance().getBaseContext(), R.color.main);


        if (data.isCancelLesson()) {
            //被关闭的课程
            holder.binding.arrowImg.setVisibility(View.GONE);
            holder.binding.afterQuestionImg.setVisibility(View.GONE);
            holder.binding.afterLayout.setVisibility(View.GONE);

            holder.binding.beforeDayTV.getPaint().setFlags(Paint.STRIKE_THRU_TEXT_FLAG);
            holder.binding.beforeMonthTV.getPaint().setFlags(Paint.STRIKE_THRU_TEXT_FLAG);
            holder.binding.beforeTimeTv.getPaint().setFlags(Paint.STRIKE_THRU_TEXT_FLAG);
            holder.binding.infoTv.setText(SLStringUtils.getSpan(studentName + " canceled the lesson", mainColor, studentName));
            holder.binding.statusTv.setText("");
            holder.binding.closeButton.setVisibility(View.VISIBLE);
        } else if (data.getRetracted()) {
            //被恢复原有的课程
//            holder.binding.beforeTimeTv.getPaint().setFlags(Paint.HINTING_OFF);
            holder.binding.afterLayout.setVisibility(View.VISIBLE);
            holder.binding.statusTv.setText("");
            holder.binding.infoTv.setText(SLStringUtils.getSpan(studentName + " retraced the reschedule request", mainColor, studentName));
            holder.binding.closeButton.setVisibility(View.VISIBLE);
        } else if (data.getSenderId().equals(UserService.getInstance().getCurrentUserId())
                || (data.getConfirmerId().equals(UserService.getInstance().getCurrentUserId())
                && data.getTeacherRevisedReschedule())) {
            if (data.getConfirmType() == 1 || (data.getConfirmType() == -1 && !data.isTeacherRead())) {
                holder.binding.afterLayout.setVisibility(View.VISIBLE);
                holder.binding.statusTv.setText("");
                holder.binding.closeButton.setVisibility(View.VISIBLE);
                String text = "";
                if (data.getRetracted()) {
                    text = studentName + " retraced the reschedule request";
                } else {
                    if (data.getConfirmType() == 1) {
                        text = studentName + " confirmed the reschedule request";
                    } else if (data.getConfirmType() == -1) {
                        text = studentName + " declined the reschedule request";
                    }
                }
                holder.binding.infoTv.setText(SLStringUtils.getSpan(text, mainColor, studentName));

            } else {
                holder.binding.afterLayout.setVisibility(View.VISIBLE);
                holder.binding.statusTv.setText("Pending: ");
                holder.binding.centerRetractButton.setVisibility(View.VISIBLE);
                String text = "";
                if (studentName.equals("")) {
                    text = "Awaiting reschedule confirmation";
                } else {
                    text = "Awaiting reschedule confirmation from " + studentName;
                }

//                if (timeAfter == 0) {
//                    holder.binding.centerRetractButton.setVisibility(View.VISIBLE);
//                } else {
//                    holder.binding.confirmButton.setVisibility(View.VISIBLE);
//                    holder.binding.rescheduleButton.setVisibility(View.VISIBLE);
//                }
                if (timeAfter != 0 ){
                    holder.binding.afterLayout.setVisibility(View.VISIBLE);
                    if (data.getStudentRevisedReschedule()) {
                        text = studentName + " sent a reschedule request";
                        holder.binding.statusTv.setText("");
                        holder.binding.confirmButton.setVisibility(View.VISIBLE);
                        holder.binding.rescheduleButton.setVisibility(View.VISIBLE);
                        holder.binding.centerRetractButton.setVisibility(View.GONE);

                        if (data.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                            holder.binding.retractButton.setVisibility(View.VISIBLE);
                        } else {
                            holder.binding.retractButton.setVisibility(View.GONE);
                        }
                    }else {
                        if (data.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                            holder.binding.centerRetractButton.setVisibility(View.VISIBLE);
                        } else {
                            holder.binding.centerRetractButton.setVisibility(View.GONE);
                        }
                    }
                }else {
                    holder.binding.afterQuestionImg.setVisibility(View.VISIBLE);
                }

                holder.binding.infoTv.setText(SLStringUtils.getSpan(text, mainColor, studentName));
            }
        } else {
            String text = "";
            holder.binding.afterLayout.setVisibility(View.VISIBLE);
            if (data.getTeacherRevisedReschedule()) {
                holder.binding.statusTv.setText("Pending: ");

                if (studentName.equals("")) {
                    text = "Awaiting reschedule confirmation";
                } else {
                    text = "Awaiting reschedule confirmation from " + studentName;
                }
                holder.binding.confirmButton.setVisibility(View.VISIBLE);
                holder.binding.rescheduleButton.setVisibility(View.VISIBLE);
                if (data.getSenderId().equals(UserService.getInstance().getCurrentUserId())) {
                    holder.binding.retractButton.setVisibility(View.VISIBLE);
                } else {
                    holder.binding.retractButton.setVisibility(View.GONE);
                }
            } else {
                text = "Reschedule request " + studentName;
                holder.binding.statusTv.setText("");
                holder.binding.confirmButton.setVisibility(View.VISIBLE);
                holder.binding.rescheduleButton.setVisibility(View.VISIBLE);
                holder.binding.declinedButton.setVisibility(View.VISIBLE);
            }
            if (timeAfter==0){
                text = studentName + " sent a reschedule request";
                holder.binding.statusTv.setText("");
                if (!data.getTeacherRevisedReschedule()){
                    holder.binding.confirmButton.setVisibility(View.GONE);
                    holder.binding.rescheduleButton.setVisibility(View.GONE);
                    holder.binding.retractButton.setVisibility(View.GONE);
                    holder.binding.centerRetractButton.setVisibility(View.VISIBLE);
                }
            }
            holder.binding.infoTv.setText(SLStringUtils.getSpan(text, mainColor, studentName));
        }
        //初始化点击事件
        holder.binding.confirmButton.setOnClickListener(v -> onItemClickListener.clickConfirm(position));
        holder.binding.rescheduleButton.setOnClickListener(v -> onItemClickListener.clickReschedule(position));
        holder.binding.declinedButton.setOnClickListener(v -> onItemClickListener.clickDeclined(position));
        holder.binding.retractButton.setOnClickListener(v -> onItemClickListener.clickRetract(position));
        holder.binding.centerRetractButton.setOnClickListener(v -> onItemClickListener.clickRetract(position));
        holder.binding.closeButton.setOnClickListener(v -> onItemClickListener.clickClose(position));
        holder.binding.afterQuestionImg.setOnClickListener(v -> onItemClickListener.clickReschedule(position));
        holder.binding.afterLayout.setOnClickListener(v -> {
            if (holder.binding.closeButton.getVisibility() != View.VISIBLE){
                onItemClickListener.clickReschedule(position);
            }
        });




    }

    @Override
    public int getItemCount() {
        return datas.size();
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        public ItemRescheduleBoxBinding binding;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            binding = DataBindingUtil.bind(itemView);
        }
    }
}
