package com.spelist.tunekey.ui.teacher.students.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.spelist.tunekey.R;
import com.spelist.tunekey.ui.teacher.addLessonType.Lesson;

import java.util.List;

public class SelfStudyFragmentAdapter extends RecyclerView.Adapter<SelfStudyFragmentAdapter.ViewHolder> {
    private List<Lesson> date;
    Context context;

    public SelfStudyFragmentAdapter(Context context, List<Lesson> list) {
        this.context = context;
        this.date = list;
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView name;
        ImageView imageView;
        RecyclerView recyclerView;

        public ViewHolder(View itemView) {
            super(itemView);
            name = itemView.findViewById(R.id.tv_date);
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

        if (date.get(position).getName() == null) {
            holder.name.setText("null");
        } else {
            holder.name.setText(date.get(position).getName());
        }

        Glide.with(context).load(R.mipmap.calendar).into(holder.imageView);
//
//        for (int a = 0; a < 3; a++) {
//            View addView = LayoutInflater.from(context).inflate(R.layout.item_homework, null);
//            holder.linAddView.addView(addView);
//        }
    }

    @Override
    public int getItemCount() {
        return date.size();
    }


}
