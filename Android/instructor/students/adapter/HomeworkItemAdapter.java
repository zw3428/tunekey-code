package com.spelist.tunekey.ui.teacher.students.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.LessonScheduleAssignmentEntity;

import java.util.List;


public class HomeworkItemAdapter extends RecyclerView.Adapter<HomeworkItemAdapter.ViewHolder> {
    private List<LessonScheduleAssignmentEntity> date;
    Context context;

    public HomeworkItemAdapter(Context context, List<LessonScheduleAssignmentEntity> list) {
        this.context = context;
        this.date = list;
        Logger.e("====" + date.size());
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView textView;
        //   ImageView imageView;

        public ViewHolder(View itemView) {
            super(itemView);
            textView = itemView.findViewById(R.id.tv_text);
            // imageView = itemView.findViewById(R.id.img_calender);
        }
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_homework, parent, false);
        HomeworkItemAdapter.ViewHolder holder = new HomeworkItemAdapter.ViewHolder(view);
        return holder;
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        if (date.get(position).getAssignment() == null) {
            holder.textView.setText("null");
            Logger.e("==25=");
        } else {
            holder.textView.setText(date.get(position).getAssignment());
        }
        //   holder.imageView.setImageResource(R.mipmap.calendar);
    }

    @Override
    public int getItemCount() {
        Logger.e("85854=="+date.size());
        return date.size();
    }


}


