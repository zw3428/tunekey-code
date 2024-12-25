package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.app.Activity;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ScrollView;
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.databinding.ActivityLessonTypeBinding;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.ui.studio.profile.lessonTypeUseHistory.LessonTypeUseHistoryAc;
import com.spelist.tunekey.ui.teacher.addLessonType.AddLessonDetailActivity;
import com.spelist.tunekey.ui.teacher.students.activity.NewContactActivity;
import com.spelist.tunekey.ui.teacher.students.adapter.LessonTypeAdapter;
import com.spelist.tunekey.ui.teacher.students.fragments.NewContactFragment;
import com.spelist.tunekey.ui.teacher.students.vm.LessonTypeVM;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import cn.we.swipe.helper.WeSwipe;
import me.goldze.mvvmhabit.base.BaseActivity;

public class LessonTypeActivity extends BaseActivity<ActivityLessonTypeBinding, LessonTypeVM> {
    public LessonTypeEntity lessonTypeEntity = new LessonTypeEntity();
    private List<LessonTypeEntity> lessonTypeEntities = new ArrayList<>();
    private LessonTypeAdapter adapter;
    private int flag;
    private WeSwipe attach;
    private String selectDataId = "";

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_lesson_type;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        viewModel.type = getIntent().getIntExtra("type", 0);

        viewModel.isStudentLook = getIntent().getBooleanExtra("isStudentLook", false);
        viewModel.teacherId = getIntent().getStringExtra("teacherId");
        viewModel.studioId = getIntent().getStringExtra("studioId");
        if (getIntent().getStringExtra("selectDataId") != null) {
            selectDataId = getIntent().getStringExtra("selectDataId");
        }
        Logger.e("isStudentLook==>%s", viewModel.isStudentLook);
        if (viewModel.isStudentLook) {
            binding.addLayout.setVisibility(View.INVISIBLE);
        }

        viewModel.getLessonType();
        getDate();
        flag = getIntent().getIntExtra("flag", 0);
        RecyclerView recyclerView = binding.rvLessonType;
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);
        adapter = new LessonTypeAdapter(this, lessonTypeEntities, viewModel.isStudentLook, selectDataId);
        recyclerView.setAdapter(adapter);
        attach = WeSwipe.attach(recyclerView);
        if (viewModel.isStudentLook || !viewModel.isCanEditLessonTypeAndDelete) {
            attach.setEnable(false);
            return;
        }
        //adapter.addData(lessonTypeEntities.size(), lessonTypeEntity);
        adapter.setOnItemClickListener(new LessonTypeAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(View view, int position, LessonTypeEntity lessonTypeEntity) {
                if (!viewModel.isCanEditLessonTypeAndDelete) {
                    return;
                }
                if (flag == NewContactFragment.REQUEST_CODE) {
                    Intent intent = new Intent(LessonTypeActivity.this, NewContactActivity.class);
                    intent.putExtra("lessonType", (Serializable) lessonTypeEntity);
                    setResult(Activity.RESULT_OK, intent);
                    finish();
                    overridePendingTransition(R.anim.push_right_in, R.anim.push_right_out);

                } else if (flag == AddLessonStepActivity.REQUEST_CODE) {
                    Intent intent = new Intent(LessonTypeActivity.this, AddLessonStepActivity.class);
                    intent.putExtra("lessonType", (Serializable) lessonTypeEntity);
                    setResult(Activity.RESULT_OK, intent);
                    finish();
                    overridePendingTransition(R.anim.push_right_in, R.anim.push_right_out);

                } else {
                    if (viewModel.type == 0) {
                        Intent intent = new Intent(getApplicationContext(), AddLessonDetailActivity.class);
                        intent.putExtra("lessonType", lessonTypeEntity);
                        startActivity(intent);
                    } else if (viewModel.type == 1) {
                        Intent intent = new Intent(getApplicationContext(), LessonTypeUseHistoryAc.class);
                        intent.putExtra("lessonType", lessonTypeEntity);
                        startActivity(intent);
                    }
                }
            }

            @Override
            public void onDeleteClick(int pos, LessonTypeEntity lessonTypeEntity) {
                attach.recoverAll(() -> {

                });
//
                Dialog dialogView = SLDialogUtils.showTwoButton(LessonTypeActivity.this
                        , "Delete lesson type?"
                        , "Deleting this lesson type won't affect the scheduled lessons. However, deleted lesson types will be permanently removed from the list"
                        , "Delete"
                        , "Go back");
                TextView leftButton = dialogView.findViewById(R.id.left_button);
                leftButton.setTextColor(ContextCompat.getColor(getApplication().getApplicationContext(), R.color.red));

                leftButton.setOnClickListener(v -> {
                    dialogView.dismiss();
                    adapter.notifyItemRemoved(pos);
                    viewModel.deleteLessonType(lessonTypeEntity.getId());
                    adapter.removeData(pos);
                });

            }

            @Override
            public void onEditClick(int pos, LessonTypeEntity lessonTypeEntity) {
                attach.recoverAll(() -> {

                });
                Intent intent = new Intent(getApplicationContext(), AddLessonDetailActivity.class);
                intent.putExtra("lessonType", lessonTypeEntity);
                startActivity(intent);
            }
        });

    }

    public void getDate() {
        viewModel.liveData.observe(this, aVoid -> {
            lessonTypeEntities = aVoid;
            adapter.updateData(lessonTypeEntities);
            attach.recoverAll(() -> {

            });
            if (viewModel.isStudentLook) {
                return;
            }
            new Handler().postDelayed(() -> {
                binding.scrollView.fullScroll(ScrollView.FOCUS_DOWN);//滚动到底部
            }, 220);
        });
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.refreshCurrency.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void unused) {
                adapter.notifyDataSetChanged();
            }
        });
        viewModel.uc.addLessonType.observe(this, aVoid -> {
            Intent intent = new Intent(LessonTypeActivity.this, AddLessonDetailActivity.class);
            intent.putExtra("page", "0");
            startActivity(intent);

        });

    }
}
