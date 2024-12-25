package com.spelist.tunekey.ui.student.sPractice.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
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
public class DialogPracticeAdapter extends RecyclerView.Adapter<DialogPracticeAdapter.ViewHolder> {

    private List<TKPractice> data = new ArrayList<>();

    public DialogPracticeAdapter(List<TKPractice> data) {
        this.data = data;
    }
    public TKPractice getSelectData(){
        TKPractice selectData = new TKPractice();
        for (TKPractice datum : data) {
            if (datum.isSelect()) {
                selectData = datum;
            }
        }

        return selectData;
    }


    @NonNull
    @Override

    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_dialog_studnet_practice, parent, false);
        return new ViewHolder(view);
    }


    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        if (data.get(position).isSelect()){
            holder.checkBox.setImageResource(R.mipmap.radiobutton_on);
        }else {
            holder.checkBox.setImageResource(R.mipmap.checkbox_off);
        }
        holder.text.setText(data.get(position).getName());
        holder.itemView.setOnClickListener(v -> {
            for (TKPractice item : data) {
                item.setSelect(false);
            }
            data.get(position).setSelect(true);
            notifyDataSetChanged();
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

    public class ViewHolder extends RecyclerView.ViewHolder {
        private ImageView checkBox;
        private TextView text;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            checkBox = itemView.findViewById(R.id.checkBox);
            text = itemView.findViewById(R.id.text);
        }
    }
}
