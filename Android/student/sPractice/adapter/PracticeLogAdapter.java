package com.spelist.tunekey.ui.student.sPractice.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tunekey.R;
import com.spelist.tunekey.utils.FuncUtils;

import java.util.List;

public class PracticeLogAdapter extends RecyclerView.Adapter<PracticeLogAdapter.PracticeLogViewHolder> {

    private List<PracticeLog> practiceLogs;
    Context context;
    private String testContent[] = new String[5];

    public PracticeLogAdapter(Context context, List<PracticeLog> practiceLogs) {
        this.context = context;
        this.practiceLogs = practiceLogs;
        initTestContent();
    }

    private void initTestContent() {
        testContent[0] = "Practice Hotel California";
        testContent[1] = "Review Beatles Sheet Music";
        testContent[2] = "Strumming outside";
        testContent[3] = "Attempt the eMinor scale\" (complete)";
        testContent[4] = "Jamming at Joe's house";
    }

    @NonNull
    @Override
    public PracticeLogAdapter.PracticeLogViewHolder onCreateViewHolder(@NonNull ViewGroup parent,
                                                            int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_student_practice_log, parent, false);
        PracticeLogViewHolder holder = new PracticeLogViewHolder(view);
        return holder;
    }

    @Override
    public void onBindViewHolder(@NonNull PracticeLogAdapter.PracticeLogViewHolder holder, int position) {

        PracticeLog data = practiceLogs.get(position);

        if (holder instanceof PracticeLogViewHolder) {
            holder.timeLength.setText(data.getTimeLength());
            holder.monthDate.setText(data.getDate());
        }

        if (holder.practiceLogAddView.getChildCount() == 0) {
            for (int i = 0; i < FuncUtils.getRandomNumber(1,4); i++) {
                TextView content;
                ImageView icon1;
                ImageView icon2;

                View addView = LayoutInflater.from(context).inflate(R.layout.item_student_practice_log_item, null);
                content = addView.findViewById(R.id.content);
                icon1 = addView.findViewById(R.id.icon1);
                icon2 = addView.findViewById(R.id.icon2);

                if (position == 0) {
                    icon1.setVisibility(View.VISIBLE);
                    icon2.setVisibility(View.GONE);
                }
                content.setText(testContent[FuncUtils.getRandomNumber(0,4)]);
                holder.practiceLogAddView.addView(addView);
            }
        }
    }

    @Override
    public int getItemCount() {
        return practiceLogs.size();
    }

    static class PracticeLogViewHolder extends RecyclerView.ViewHolder {

        TextView timeLength;
        TextView monthDate;
        /*TextView content;
        ImageView icon1;
        ImageView icon2;*/
        LinearLayout practiceLogAddView;

        public PracticeLogViewHolder(@NonNull View itemView) {
            super(itemView);
            timeLength = itemView.findViewById(R.id.time_length);
            monthDate = itemView.findViewById(R.id.month_date);
            /*content = itemView.findViewById(R.id.content);
            icon1 = itemView.findViewById(R.id.icon1);
            icon2 = itemView.findViewById(R.id.icon2);*/
            practiceLogAddView = itemView.findViewById(R.id.practice_log_add_view);
        }
    }
}
