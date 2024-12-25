package com.spelist.tunekey.ui.teacher.students.activity;

import android.app.Dialog;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.databinding.ActivityAchievementBinding;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.students.vm.AchievementViewModel;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;

public class AchievementActivity extends BaseActivity<ActivityAchievementBinding, AchievementViewModel> {
    private Dialog bottomDialog;
    private Dialog achievementDialog;
    private int achievementType;
    private LinearLayoutManager linearLayoutManager;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_achievement;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {

        Bundle bundle = getIntent().getExtras();
        assert bundle != null;
        viewModel.isStudentLook = bundle.getBoolean("isStudentLook", false);

        viewModel.data = (List<AchievementEntity>) bundle.getSerializable("data");
        if ((StudentListEntity) bundle.getSerializable("studentData")!=null){
            viewModel.studentData = (StudentListEntity) bundle.getSerializable("studentData");
        }
        if (viewModel.isStudentLook){
            viewModel.rightSecondImgVisibility.set(View.GONE);
        }

        linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvAchievement.setLayoutManager(linearLayoutManager);
        binding.rvAchievement.setItemAnimator(null);
        viewModel.initData();

    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.addAchievement.observe(this, aBoolean -> {
            if (aBoolean) {
                showAchievement();
            }
        });
        viewModel.filterAchievement.observe(this, new Observer<Integer>() {
            @Override
            public void onChanged(Integer value) {
                filterAchievement(value);
            }
        });
        viewModel.refList.observe(this, new Observer<Boolean>() {
            @Override
            public void onChanged(Boolean aBoolean) {
                if (aBoolean){
                    Logger.e("======%s", "=======");
                    linearLayoutManager.setStackFromEnd(true);
                    linearLayoutManager.scrollToPositionWithOffset(viewModel.data.size()-1, Integer.MIN_VALUE);
                }
            }
        });
    }

    public void showAchievement() {
        bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_add_achievement, null);
        LinearLayout Technique = contentView.findViewById(R.id.lin_tec);
        LinearLayout Notation = contentView.findViewById(R.id.lin_nota);
        LinearLayout Song = contentView.findViewById(R.id.song);
        LinearLayout Improv = contentView.findViewById(R.id.imp);
        LinearLayout GroupPlay = contentView.findViewById(R.id.group);
        LinearLayout Dedication = contentView.findViewById(R.id.dedication);
        LinearLayout listening = contentView.findViewById(R.id.lin_listening);
        LinearLayout reading = contentView.findViewById(R.id.lin_reading);
        LinearLayout creativity = contentView.findViewById(R.id.lin_creativity);
        LinearLayout memorization = contentView.findViewById(R.id.memorization);

        TKButton next = contentView.findViewById(R.id.cancel);

        ImageView check1 = contentView.findViewById(R.id.check1);
        ImageView check2 = contentView.findViewById(R.id.check2);
        ImageView check3 = contentView.findViewById(R.id.check3);
        ImageView check4 = contentView.findViewById(R.id.check4);
        ImageView check5 = contentView.findViewById(R.id.check5);
        ImageView check6 = contentView.findViewById(R.id.check6);
        ImageView check7 = contentView.findViewById(R.id.check7);
        ImageView check8 = contentView.findViewById(R.id.check8);
        ImageView check9 = contentView.findViewById(R.id.check9);
        ImageView check10 = contentView.findViewById(R.id.check10);
        final int[] achievementType = {8};
        check8.setVisibility(View.VISIBLE);
        check1.setVisibility(View.GONE);
        check2.setVisibility(View.GONE);
        check3.setVisibility(View.GONE);
        check4.setVisibility(View.GONE);
        check5.setVisibility(View.GONE);
        check6.setVisibility(View.GONE);
        check7.setVisibility(View.GONE);
        check9.setVisibility(View.GONE);
        check10.setVisibility(View.GONE);

        Technique.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.VISIBLE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 1;
            }
        });
        Notation.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.VISIBLE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 2;
            }
        });
        Song.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.VISIBLE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 3;
            }
        });
        Improv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.VISIBLE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 4;
            }
        });
        GroupPlay.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.VISIBLE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 5;
            }
        });

        Dedication.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.VISIBLE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 6;
            }
        });
        listening.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.VISIBLE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 8;
            }
        });
        reading.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.VISIBLE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 9;
            }
        });

        creativity.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.VISIBLE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                achievementType[0] = 7;
            }
        });
        memorization.setOnClickListener(v -> {
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.VISIBLE);
            achievementType[0] = 10;
        });

        next.setClickListener(v -> {
            showAchievementEdit(achievementType[0]);
            if (bottomDialog.isShowing()) {
                bottomDialog.dismiss();
            }
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗
    }

    public void showAchievementEdit(int type) {

        achievementDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_add_achievement_edit, null);

        TKButton create = contentView.findViewById(R.id.create);
        create.setEnabled(false);
        InputView title = contentView.findViewById(R.id.input_title);
        title.setFocus();
        InputView description = contentView.findViewById(R.id.input_des);
        title.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s.length() > 0 && description.getInputText().length() > 0) {
                    create.setEnabled(true);
                }else {
                    create.setEnabled(false);
                }
            }
        });

        description.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s.length() > 0 && title.getInputText().length() > 0) {
                    create.setEnabled(true);
                }else {
                    create.setEnabled(false);
                }
            }
        });

        create.setClickListener(tkButton -> {
            viewModel.addAchievement(type, title.getInputText(), description.getInputText());
            if (achievementDialog.isShowing()) {
                achievementDialog.dismiss();
            }
        });
        achievementDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        achievementDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        achievementDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        achievementDialog.show();//显示弹窗
    }

    public void filterAchievement(int type) {
        bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_filter_achievement, null);
        LinearLayout All = contentView.findViewById(R.id.lin_all);
        LinearLayout Technique = contentView.findViewById(R.id.lin_tec);
        LinearLayout Notation = contentView.findViewById(R.id.lin_nota);
        LinearLayout Song = contentView.findViewById(R.id.song);
        LinearLayout Improv = contentView.findViewById(R.id.imp);
        LinearLayout GroupPlay = contentView.findViewById(R.id.group);
        LinearLayout Dedication = contentView.findViewById(R.id.dedication);
        LinearLayout listening = contentView.findViewById(R.id.lin_listening);
        LinearLayout reading = contentView.findViewById(R.id.lin_reading);
        LinearLayout creativity = contentView.findViewById(R.id.lin_creativity);
        LinearLayout memorization = contentView.findViewById(R.id.memorization);

        TextView next = contentView.findViewById(R.id.cancel);
        ImageView check0 = contentView.findViewById(R.id.check0);
        ImageView check1 = contentView.findViewById(R.id.check1);
        ImageView check2 = contentView.findViewById(R.id.check2);
        ImageView check3 = contentView.findViewById(R.id.check3);
        ImageView check4 = contentView.findViewById(R.id.check4);
        ImageView check5 = contentView.findViewById(R.id.check5);
        ImageView check6 = contentView.findViewById(R.id.check6);
        ImageView check7 = contentView.findViewById(R.id.check7);
        ImageView check8 = contentView.findViewById(R.id.check8);
        ImageView check9 = contentView.findViewById(R.id.check9);
        ImageView check10 = contentView.findViewById(R.id.check10);


        int achievementType = type;
        if (achievementType == 0) {
            check0.setVisibility(View.VISIBLE);
            check1.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 1) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.VISIBLE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 2) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.VISIBLE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 3) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.VISIBLE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 4) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.VISIBLE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 5) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.VISIBLE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 6) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.VISIBLE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 7) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.VISIBLE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 8) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.VISIBLE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.GONE);
        } else if (achievementType == 9) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.VISIBLE);
            check10.setVisibility(View.GONE);
        }else if (achievementType == 10) {
            check0.setVisibility(View.GONE);
            check1.setVisibility(View.GONE);
            check2.setVisibility(View.GONE);
            check3.setVisibility(View.GONE);
            check4.setVisibility(View.GONE);
            check5.setVisibility(View.GONE);
            check6.setVisibility(View.GONE);
            check7.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            check9.setVisibility(View.GONE);
            check10.setVisibility(View.VISIBLE);
        }
        All.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.VISIBLE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.initData();
                bottomDialog.dismiss();
            }
        });
        Technique.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.VISIBLE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(1);
                bottomDialog.dismiss();
            }
        });
        Notation.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.VISIBLE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(2);
                bottomDialog.dismiss();
            }
        });
        Song.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.VISIBLE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(3);
                bottomDialog.dismiss();
            }
        });
        Improv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.VISIBLE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(4);
                bottomDialog.dismiss();
            }
        });
        GroupPlay.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.VISIBLE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(5);
                bottomDialog.dismiss();
            }
        });

        Dedication.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.VISIBLE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(6);
                bottomDialog.dismiss();
            }
        });
        listening.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.VISIBLE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(8);
                bottomDialog.dismiss();
            }
        });
        reading.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.VISIBLE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(9);
                bottomDialog.dismiss();
            }
        });

        creativity.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.VISIBLE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.GONE);
                viewModel.filterAchievement(7);
                bottomDialog.dismiss();
            }
        });
        memorization.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                check0.setVisibility(View.GONE);
                check1.setVisibility(View.GONE);
                check2.setVisibility(View.GONE);
                check3.setVisibility(View.GONE);
                check4.setVisibility(View.GONE);
                check5.setVisibility(View.GONE);
                check6.setVisibility(View.GONE);
                check7.setVisibility(View.GONE);
                check8.setVisibility(View.GONE);
                check9.setVisibility(View.GONE);
                check10.setVisibility(View.VISIBLE);
                viewModel.filterAchievement(10);
                bottomDialog.dismiss();
            }
        });

        next.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {


                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
                }
            }
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗
    }

}
