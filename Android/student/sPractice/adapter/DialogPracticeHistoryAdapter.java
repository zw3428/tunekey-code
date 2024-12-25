package com.spelist.tunekey.ui.student.sPractice.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.TKPractice;

import java.util.ArrayList;
import java.util.List;

/**
 * com.spelist.tunekey.ui.sPractice.adapter
 * 2021/4/22
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class DialogPracticeHistoryAdapter extends RecyclerView.Adapter<DialogPracticeHistoryAdapter.ViewHolder> {

    private List<TKPractice> data = new ArrayList<>();

    public DialogPracticeHistoryAdapter(List<TKPractice> data) {
        this.data = data;
    }
    private ItemClickListener mItemClickListener ;
    public interface ItemClickListener{
        void onItemClick(int position) ;
    }
    public void setOnItemClickListener(ItemClickListener itemClickListener){
        this.mItemClickListener = itemClickListener ;

    }



    @NonNull
    @Override

    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_dialog_studnet_practice_history, parent, false);
        return new ViewHolder(view);
    }


    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        holder.text.setText(data.get(position).getName());
        holder.itemView.setOnClickListener(v -> {
            if (mItemClickListener!=null){
                mItemClickListener.onItemClick(position);
            }
        });



    }

    /**
     * Returns the total number of items in the data set held by the adapter.
     *
     * @return The total number of items in this adapter.
     */
    @Override
    public int getItemCount() {

        return data.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        private TextView text;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            text = itemView.findViewById(R.id.text);
        }
    }
}
