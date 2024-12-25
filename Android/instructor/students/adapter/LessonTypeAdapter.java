package com.spelist.tunekey.ui.teacher.students.adapter;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.lihang.ShadowLayout;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.LessonTypeEntity;

import java.util.ArrayList;
import java.util.List;

import cn.we.swipe.helper.WeSwipeHelper;

public class LessonTypeAdapter extends RecyclerView.Adapter<LessonTypeAdapter.ViewHolder> {

    private Context context;
    private LayoutInflater layoutInflater;
    private List<LessonTypeEntity> entityList = new ArrayList<>();
    private Boolean isSelected = false;
    private boolean isStudentLook = false;
    private String selectDataId = "";

    public LessonTypeAdapter(Context context, List<LessonTypeEntity> list) {
        this.context = context;
        layoutInflater = LayoutInflater.from(context);
        entityList = list;
    }

    public LessonTypeAdapter(Context context, List<LessonTypeEntity> list, boolean isStudentLook, String selectDataId) {
        this.context = context;
        this.selectDataId = selectDataId;
        layoutInflater = LayoutInflater.from(context);
        entityList = list;
        this.isStudentLook = isStudentLook;
    }

    public void updateData(List<LessonTypeEntity> entityList) {
        this.entityList = entityList;
        notifyDataSetChanged();
    }

    public void removeData(int position) {
        entityList.remove(position);
        //删除动画
        notifyItemRemoved(position);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public LessonTypeAdapter.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = layoutInflater.inflate(R.layout.item_student_lessontype, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull LessonTypeAdapter.ViewHolder holder, @SuppressLint("RecyclerView") int position) {
        holder.itemLessonTypeInfo.setText(entityList.get(position).getInfo());
        holder.itemLessonTypeTitle.setText(entityList.get(position).getName());

        if (!selectDataId.equals("") && entityList.get(position).getId().equals(selectDataId)) {
            holder.mainLayout.setBackground(ContextCompat.getDrawable(context,R.drawable.blue_border));
            holder.itemLessonNextImg.setImageResource(R.mipmap.ic_check_primary);
        } else {
            holder.mainLayout.setBackground(ContextCompat.getDrawable(context,R.drawable.border_none));
            holder.itemLessonNextImg.setImageResource(R.mipmap.transparent);
        }
        if (selectDataId.equals("") ){
            holder.itemLessonNextImg.setImageResource(R.mipmap.ic_arrow_primary_next);
        }

        RequestOptions placeholder = new RequestOptions()
                .placeholder(R.drawable.def_instrument)
                .error(R.drawable.def_instrument);
        Glide.with(holder.itemLessonTypeImg.getContext())
                .load(entityList.get(position).getInstrumentPath())
                .apply(placeholder)
                .into(holder.itemLessonTypeImg);
        if (isStudentLook) {
            holder.itemLessonNextImg.setVisibility(View.INVISIBLE);
        }
        if (mOnItemClickListener != null) {
            holder.itemLessonTypeLayout.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    int pos = position;
                    mOnItemClickListener.onItemClick(holder.itemView, pos, entityList.get(pos));
//                    if (isSelected) {
//                        holder.itemLessonTypeSelectedImg.setVisibility(View.VISIBLE);
//                        isSelected = false;
//                    } else {
//                        isSelected = true;
//                        holder.itemLessonTypeSelectedImg.setVisibility(View.GONE);
//                    }
                }
            });

            holder.itemLessonDeleteImg.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mOnItemClickListener.onDeleteClick(position, entityList.get(position));

                }
            });

            holder.itemLessonEditImg.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mOnItemClickListener.onEditClick(position, entityList.get(position));
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return entityList == null ? 0 : entityList.size();
    }

    public class ViewHolder extends RecyclerView.ViewHolder implements WeSwipeHelper.SwipeLayoutTypeCallBack {
        public ImageView itemLessonTypeImg;
        public TextView itemLessonTypeTitle;
        public TextView itemLessonTypeInfo;
        public ShadowLayout itemLessonTypeLayout;
        public ImageView itemLessonTypeSelectedImg;
        public LinearLayout itemLessonTypeEditLayout;
        public ImageView itemLessonEditImg;
        public ImageView itemLessonDeleteImg;
        public ImageView itemLessonNextImg;
        public ConstraintLayout mainLayout;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            mainLayout = itemView.findViewById(R.id.mainLayout);
            itemLessonTypeImg = (ImageView) itemView.findViewById(R.id.item_lesson_type_img);
            itemLessonTypeTitle = (TextView) itemView.findViewById(R.id.item_lesson_type_title);
            itemLessonTypeInfo = (TextView) itemView.findViewById(R.id.item_lesson_type_info);
            itemLessonTypeLayout = itemView.findViewById(R.id.item_lesson_type_layout);
            itemLessonTypeSelectedImg = (ImageView) itemView.findViewById(R.id.item_lesson_type_selected_img);
            itemLessonTypeEditLayout = itemView.findViewById(R.id.item_lesson_type_edit_layout);
            itemLessonDeleteImg = itemView.findViewById(R.id.item_lesson_type_delete);
            itemLessonEditImg = itemView.findViewById(R.id.item_lesson_type_edit);
            itemLessonNextImg = itemView.findViewById(R.id.item_lesson_type_next_img);
            itemLessonNextImg.setVisibility(View.VISIBLE);
        }


        @Override
        public float getSwipeWidth() {
            return itemLessonTypeEditLayout.getWidth() + 30;
        }

        @Override
        public View needSwipeLayout() {
            return itemLessonTypeLayout;
        }


        @Override
        public View onScreenView() {
            return itemLessonTypeLayout;
        }
    }

    public interface OnItemClickListener {
        void onItemClick(View view, int position, LessonTypeEntity lessonTypeEntity);

        void onDeleteClick(int pos, LessonTypeEntity lessonTypeEntity);

        void onEditClick(int pos, LessonTypeEntity lessonTypeEntity);

    }

    private LessonTypeAdapter.OnItemClickListener mOnItemClickListener;

    public void setOnItemClickListener(LessonTypeAdapter.OnItemClickListener mOnItemClickListener) {
        this.mOnItemClickListener = mOnItemClickListener;
    }


}
