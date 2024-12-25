package com.spelist.tunekey.ui.teacher.lessons.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tunekey.R;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.utils.ViewAdapter;

import java.util.List;


public class DialogLessonTypeAdapter extends RecyclerView.Adapter<DialogLessonTypeAdapter.lessonTypeViewHolder> {

    public Context context;
    private List<DialogLessonTypeData> mDataList;

    public DialogLessonTypeAdapter(List<DialogLessonTypeData> dataList, @NonNull Context context) {
        this.context = context;
        this.mDataList = dataList;
    }

    @NonNull
    @Override
    public lessonTypeViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_dialog_lesson_type, parent, false);
        return new lessonTypeViewHolder(view);
    }

    @SuppressLint("SetTextI18n")
    @Override
    public void onBindViewHolder(@NonNull lessonTypeViewHolder holder, int position) {
        DialogLessonTypeData data = mDataList.get(position);
        holder.lessonTitle.setText(data.getTitle());
        holder.lessonContent.setText(data.getType() + ", " + data.getTimeLength() + "mins, " + "$" + data.getPrice());
        holder.lessonImg.setImageResource(R.mipmap.img_guitar_on);
//            setImageForStorage
        ViewAdapter.setImageForStorage(holder.lessonImg,data.getImgUrl(), R.mipmap.ic_logo, false,false);
        holder.itemView.setOnClickListener(v -> {
            Bundle bundle = new Bundle();
            bundle.putString("lessonTypeId", data.getId());
            Intent intent = new Intent(holder.itemView.getContext(), AddLessonStepActivity.class);
            intent.putExtra("toAddLesson", bundle);
            holder.itemView.getContext().startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return mDataList.size();
    }

    public class lessonTypeViewHolder extends RecyclerView.ViewHolder {

        ImageView lessonImg;
        TextView lessonTitle;
        TextView lessonContent;

        lessonTypeViewHolder(@NonNull View itemView) {
            super(itemView);
            lessonImg =  itemView.findViewById(R.id.lesson_img);
            lessonTitle=   itemView.findViewById(R.id.lesson_title);
            lessonContent=itemView.findViewById(R.id.lesson_content);
        }
    }
}
