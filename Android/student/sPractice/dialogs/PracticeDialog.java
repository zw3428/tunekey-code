package com.spelist.tunekey.ui.student.sPractice.dialogs;

import android.content.Context;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;

import androidx.annotation.NonNull;
import androidx.databinding.DataBindingUtil;

import com.lxj.xpopup.core.BottomPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.MaxCountLayoutManager;
import com.spelist.tunekey.databinding.DialogPracticeBinding;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.ui.student.sPractice.adapter.DialogPracticeAdapter;
import com.spelist.tunekey.ui.student.sPractice.adapter.DialogPracticeHistoryAdapter;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.SLUiUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * com.spelist.tunekey.ui.sPractice.dialogs
 * 2021/4/21
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class PracticeDialog extends BottomPopupView {
    private DialogPracticeBinding binding;
    private List<TKPractice> data = new ArrayList<>();
    private List<TKPractice> practiceHistoryData = new ArrayList<>();
    private String titleString = "";
    //0: 手工Log, 2:startPractice
    private int type = 0;
    //0: 选择页面, 1:添加页面, 2:添加时间页面
    private int style = 0;
    private DialogPracticeAdapter practiceAdapter;
    private DialogPracticeHistoryAdapter practiceHistoryAdapter;
    private long addTime = 0;


    private ClickListener mClickListener;

    public interface ClickListener {
        //0添加log,1更新log
        void onClick(TKPractice practice, int type);
    }

    public void setOnClickListener(ClickListener clickListener) {
        this.mClickListener = clickListener;

    }


    public PracticeDialog(@NonNull Context context, List<TKPractice> data, List<TKPractice> practiceHistoryData, int type,long addTime) {
        super(context);
        this.addTime = addTime;
        for (TKPractice datum : data) {
            datum.setSelect(false);
            this.data.add(CloneObjectUtils.cloneObject(datum));
        }
        for (TKPractice practiceHistoryDatum : practiceHistoryData) {
            this.practiceHistoryData.add(CloneObjectUtils.cloneObject(practiceHistoryDatum));
        }
        this.type = type;
        if (type == 0) {
            titleString = "Log Manually";
        } else {
            titleString = "Record Practice";
        }

    }

    @Override
    protected int getImplLayoutId() {
        return R.layout.dialog_practice;
    }

    @Override
    protected void onCreate() {
        super.onCreate();
        binding = DataBindingUtil.bind(getPopupImplView());
        if (binding == null) {
            return;
        }
        binding.title.setText(titleString);
        binding.leftButton.setClickListener(tkButton -> {
            dialog.dismiss();
        });
        if (type == 1){
            binding.rightButton.setText("GET STARTED");
        }
        binding.main.setOnClickListener(v -> {
            if (binding.timeInputView.isFocus) {
                binding.timeInputView.setNoFocus();
            }
            if (binding.addPracticeInputView.isFocus) {
                binding.addPracticeInputView.setNoFocus();
            }
        });
        intPracticeData();
    }

    private void intPracticeData() {
        MaxCountLayoutManager layout = new MaxCountLayoutManager(getContext());
        layout.setMaxCount(5);
        binding.practiceRecyclerView.setLayoutManager(layout);
        if (data.size() > 0) {
            data.get(0).setSelect(true);
        } else {
            binding.rightButton.setEnabled(false);
        }

        practiceAdapter = new DialogPracticeAdapter(data);

        binding.practiceRecyclerView.setAdapter(practiceAdapter);
        binding.rightButton.setClickListener(tkButton -> {
            if (type==0){
                initAddTimeData(practiceAdapter.getSelectData(), false);
            }else {
                mClickListener.onClick(practiceAdapter.getSelectData(), 1);
                dialog.dismiss();
            }
        });
        binding.addPractice.setOnClickListener(v -> {
            binding.rightButton.setClickListener(null);
            initAddPracticeData();
        });
    }

    private void initAddPracticeData() {
        titleString = "Add Piece";
        binding.title.setText(titleString);

        MaxCountLayoutManager layout = new MaxCountLayoutManager(getContext());
        layout.setMaxCount(3);
        binding.practiceHistoryRecyclerView.setLayoutManager(layout);
        practiceHistoryAdapter = new DialogPracticeHistoryAdapter(practiceHistoryData);
        binding.practiceHistoryRecyclerView.setAdapter(practiceHistoryAdapter);
        binding.addPracticeInputView.setVisibility(GONE);
        binding.rightButton.setEnabled(false);
        binding.addPracticeInputView.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                binding.rightButton.setEnabled(s.toString().length() > 0);
            }
        });
        practiceHistoryAdapter.setOnItemClickListener(position -> {
            binding.practiceHistoryRecyclerView.post(() -> {
                binding.addPracticeInputView.setInputText(practiceHistoryData.get(position).getName());
            });
        });
        binding.addPracticeInputView.setVisibility(VISIBLE);
        binding.addPracticeInputView.setFocus();
        binding.practiceLayout.setVisibility(GONE);
        binding.addPracticeLayout.setVisibility(VISIBLE);
        binding.addPracticeInputView.setOnFocusChangeListener(isFocus -> {
//            if (isFocus) {
//                binding.practiceHistoryRecyclerView.setVisibility(GONE);
//            } else {
//                binding.practiceHistoryRecyclerView.setVisibility(VISIBLE);
//            }
        });
        binding.rightButton.setClickListener(tkButton -> {
            if (binding.addPracticeInputView.isFocus) {
                binding.addPracticeInputView.setNoFocus();
            }
            TKPractice practice = new TKPractice();
            practice.setName(binding.addPracticeInputView.getInputText());
            practice.setId(IDUtils.getId())
                    .setStudentId(UserService.getInstance().getCurrentUserId())
                    .setStartTime(TimeUtils.getCurrentTime())
                    .setCreateTime(TimeUtils.getCurrentTimeString())
                    .setUpdateTime(TimeUtils.getCurrentTimeString());
            if (type == 0){
                initAddTimeData(practice, true);
            }else {
                mClickListener.onClick(practice, 0);
                dialog.dismiss();
            }
        });
    }

    private void initAddTimeData(TKPractice practice, boolean isAddPractice) {
        titleString = "Log for "+TimeUtils.timeFormat(addTime,"MM/dd/yyyy");
        binding.title.setText(titleString);
        if (isAddPractice) {
            SLUiUtils.expandAndCollapse(binding.addPracticeLayout, 300);
        } else {
            SLUiUtils.expandAndCollapse(binding.practiceLayout, 300);
        }
        SLUiUtils.expandAndCollapse(binding.addTimeLayout, 300);
        binding.timeInputView.editTextView.setInputType(InputType.TYPE_CLASS_NUMBER);
        binding.timeInputView.setFocus();
        if (practice.getTotalTimeLength() != 0) {
            binding.timeInputView.setInputText(String.format("%.1f", practice.getTotalTimeLength() / 60));
        } else {
            binding.timeInputView.setInputText("");
        }

        binding.timeInputView.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                try {
                    //大于300 变成300
                    if (Double.parseDouble(s.toString()) > 300) {
                        binding.timeInputView.setInputText("300");
                    }
                    binding.rightButton.setEnabled(s.toString().length() > 0);

                }catch (Exception e){

                }
            }
        });

        binding.rightButton.setEnabled(false);
        binding.rightButton.setText("CONFIRM");
        binding.rightButton.setClickListener(tkButton -> {
            if (mClickListener == null) {
                return;
            }
            if (isAddPractice) {
                addPractice(practice, Double.parseDouble(binding.timeInputView.getInputText()));
            } else {
                updatePractice(practice, Double.parseDouble(binding.timeInputView.getInputText()));

            }
        });
    }

    private void addPractice(TKPractice practice, double time) {

        practice.setId(IDUtils.getId())
                .setStudentId(UserService.getInstance().getCurrentUserId())
                .setStartTime(TimeUtils.getCurrentTime())
                .setTotalTimeLength(time * 60)
                .setCreateTime(TimeUtils.getCurrentTimeString())
                .setUpdateTime(TimeUtils.getCurrentTimeString())
                .setDone(true)
                .setManualLog(true);
        mClickListener.onClick(practice, 0);
        dialog.dismiss();
    }

    private void updatePractice(TKPractice practice, double time) {
        practice.setTotalTimeLength(time * 60)
                .setDone(true)
                .setManualLog(true);
        mClickListener.onClick(practice, 1);
        dialog.dismiss();
    }


}
