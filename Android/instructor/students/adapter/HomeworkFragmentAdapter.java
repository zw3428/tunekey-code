package com.spelist.tunekey.ui.teacher.students.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.StudentHomeworkEntity;

import java.util.List;

public class HomeworkFragmentAdapter extends RecyclerView.Adapter<HomeworkFragmentAdapter.ViewHolder> {
    private List<StudentHomeworkEntity> date;
    Context context;

    public HomeworkFragmentAdapter(Context context, List<StudentHomeworkEntity> list) {
        this.context = context;
        this.date = list;
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView date;
        ImageView imageView;
        RecyclerView recyclerView;

        public ViewHolder(View itemView) {
            super(itemView);
            date = itemView.findViewById(R.id.tv_date);
            imageView = itemView.findViewById(R.id.img_calender);
            recyclerView = itemView.findViewById(R.id.rv_addView);
        }
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_fragment_homework, parent, false);
        ViewHolder holder = new ViewHolder(view);
        return holder;

    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {

        if (date.get(position).getShouldDate() == null) {
            holder.date.setText("null");
        } else {
            holder.date.setText(date.get(position).getShouldDate());
        }
        holder.imageView.setImageResource(R.mipmap.calendar);

        LinearLayoutManager layoutManager = new LinearLayoutManager(context);
        holder.recyclerView.setLayoutManager(layoutManager);
        HomeworkItemAdapter homeworkItemAdapter = new HomeworkItemAdapter(context, date.get(position).getAssignmentEntityList());
        Logger.e("=="+date.get(position).getAssignmentEntityList().size());
        holder.recyclerView.setAdapter(homeworkItemAdapter);


    }

    @Override
    public int getItemCount() {
        return date.size();
    }


}
