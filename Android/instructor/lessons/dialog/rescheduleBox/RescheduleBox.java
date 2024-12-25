package com.spelist.tunekey.ui.teacher.lessons.dialog.rescheduleBox;

import android.content.Context;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.databinding.DataBindingUtil;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.BaseDialog;
import com.spelist.tunekey.databinding.DialogRescheduleBoxBinding;
import com.spelist.tunekey.entity.LessonRescheduleEntity;

import java.util.ArrayList;
import java.util.List;

/**
 * com.spelist.tunekey.ui.lessons.dialog
 * 2021/2/5
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class RescheduleBox   {
    public static class Builder {
        private Context context;
        private BaseDialog dialog;
        private DialogRescheduleBoxBinding binding;
        private RescheduleBoxAdapter adapter;


        private List<LessonRescheduleEntity> datas = new ArrayList<>();


        public Builder(Context context) {
            this.context = context;
        }

        public RescheduleBox.Builder create(List<LessonRescheduleEntity> datas) {
            this.datas.addAll(datas);
//            this.datas = datas;
            dialog = new BaseDialog(context, R.style.BottomDialog);
            binding = DataBindingUtil.inflate(LayoutInflater.from(context), R.layout.dialog_reschedule_box, null, false);
            View contentView = binding.getRoot();
            dialog.setContentView(contentView);
            ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
            layoutParams.width = dialog.getContext().getResources().getDisplayMetrics().widthPixels;
//
//            contentView.setLayoutParams(layoutParams);
            dialog.getWindow().setGravity(Gravity.CENTER);//弹窗位置
            dialog.getWindow().setWindowAnimations(R.style.Dialog_zoomInAndZoomOut_Animation);//弹窗样式
            initView();
            initData();

            dialog.show();
            return this;
        }


        public RescheduleBox.Builder clickButton(RescheduleBoxAdapter.clickItem clickListener) {
            adapter.setOnItemClickListener(clickListener);
            return this;
        }

        public void dismiss() {
            dialog.dismiss();
        }


        private void initData() {

        }


        private void initView() {
            binding.recyclerView.setLayoutManager(new LinearLayoutManager(context));
            adapter = new  RescheduleBoxAdapter(datas);
            binding.recyclerView.setAdapter(adapter);
            binding.mainLayout.setOnClickListener(v -> dismiss());
            binding.closeButton.setOnClickListener(v -> dismiss());
        }

    }

}
