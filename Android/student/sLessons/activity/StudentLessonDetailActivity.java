package com.spelist.tunekey.ui.student.sLessons.activity;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.fragment.app.FragmentManager;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.TextEnlargementDialog;
import com.spelist.tunekey.databinding.ActivityStudentLessonDetailBinding;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKStudioRoom;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentLessonDetailViewModel;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLUiUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;

public class StudentLessonDetailActivity extends BaseActivity<ActivityStudentLessonDetailBinding, StudentLessonDetailViewModel> {

    private boolean materialIsExpand = false;
    private boolean achievementIsExpand = true;
    private GridLayoutManager gridLayoutManager;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_lesson_detail;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        LessonScheduleEntity data = (LessonScheduleEntity) getIntent().getSerializableExtra("data");
        viewModel.materialsViewModel = new MaterialsViewModel(getApplication());
        viewModel.materialsViewModel.roleType.setValue(1);
        viewModel.materialsViewModel.gridLayoutManager.set(new GridLayoutManager(this, 3));
        viewModel.endTime = getIntent().getIntExtra("endTime", (int) data.getShouldDateTime());
        viewModel.startTime = getIntent().getIntExtra("startTime",TimeUtils.getCurrentTime());
        viewModel.initData(data);
    }

    @Override
    public void initView() {
        super.initView();
        binding.locationLayout.setOnClickListener(view -> {
            if (viewModel.lesson.getLocation().getType().equals(TKLocation.LocationType.studioRoom)&& viewModel.roomIsHaveAddress) {
                toMap(viewModel.locationString.getValue().toString());

            } else if (viewModel.lesson.getLocation().getType().equals(TKLocation.LocationType.remote)) {
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(checkUrl(viewModel.locationString.getValue().toString()))));
                } catch (Throwable e) {
                    Logger.e("e==>%s",e.getMessage());

                    SLToast.error("Open browser failed");
                }
            } else if (viewModel.lesson.getLocation().getType().equals(TKLocation.LocationType.otherPlace)) {
                toMap(viewModel.locationString.getValue().toString());
            }
        });
        binding.achievementList.setItemAnimator(null);
        binding.achievementList.setLayoutManager(new LinearLayoutManager(this));
        gridLayoutManager = new GridLayoutManager(this, 3);
        rotateArrow(binding.achievementArrow,false);
        binding.materialsList.setLayoutManager(gridLayoutManager);
        binding.materialsList.setItemAnimator(null);
        binding.teacherNoteLayout.setOnClickListener(v -> {
            if (viewModel.teacherNoteString != null && viewModel.teacherNoteString.getValue() != null) {
                TextEnlargementDialog dialogFragment = TextEnlargementDialog.newInstance(viewModel.teacherNoteString.getValue());
                FragmentManager fragmentManager = getSupportFragmentManager();
                dialogFragment.show(fragmentManager, "1234");
            }
        });
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.materialsObserverData.observe(this, multiItemViewModels -> {
            gridLayoutManager.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                @Override
                public int getSpanSize(int position) {
                    if ( multiItemViewModels.get(position).getData().getType() == 6) {
                        return 3;
                    }else {
                        return 1;
                    }
                }
            });
        });

        viewModel.uc.clickLessonNotes.observe(this, aVoid -> {
            showUpPop("",false);
        });
        viewModel.uc.clickEditNote.observe(this, aVoid -> {
            showUpPop(viewModel.lesson.getStudentNote(),true);
        });
        viewModel.uc.clickAchievements.observe(this, aVoid -> {
            if (viewModel.isShowAchievementArrow.getValue()){
                SLUiUtils.expandAndCollapse(binding.achievementList,200);
                rotateArrow(binding.achievementArrow, achievementIsExpand);
                achievementIsExpand = !achievementIsExpand;
            }
        });
        viewModel.uc.clickMaterials.observe(this, aVoid -> {
            if (viewModel.isShowMaterialsArrow.getValue()){
                SLUiUtils.expandAndCollapse(binding.materialsLayout,200);
                rotateArrow(binding.materialItemArrow, materialIsExpand);
                materialIsExpand = !materialIsExpand;
            }
        });

    }
    @SuppressLint("SetTextI18n")
    public void showUpPop( String defaultText, boolean isEdit) {
        Dialog bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.lesson_plan_toast, null);
        EditText addText = contentView.findViewById(R.id.et_lesson_plan);
        TextView title = contentView.findViewById(R.id.title);
        TKButton cancel = contentView.findViewById(R.id.cancel);
        TKButton create = contentView.findViewById(R.id.create);
        addText.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        addText.setFocusable(true);
        addText.setFocusableInTouchMode(true);
        addText.requestFocus();
        FuncUtils.toggleSoftInput(addText, true);
        String topicString = "Add";
        if (isEdit) {
            topicString = "Edit";
            cancel.setText("DELETE");
            cancel.setType(2);
            create.setText("SAVE");
        }
        title.setText(topicString + " Note");
        create.setEnabled(false);
        addText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                create.setEnabled(s.toString().length() > 0);
            }
        });
        addText.setText(defaultText);
        addText.setSelection(addText.getText().toString().length());
        cancel.setClickListener(tkButton -> {
            if (isEdit) {
                viewModel.upDateNotes("");
            }
            bottomDialog.dismiss();
        });
        create.setClickListener(tkButton -> {
            String text = String.valueOf(addText.getText());
            viewModel.upDateNotes(text);
            bottomDialog.dismiss();
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗
    }
    private void rotateArrow(ImageView arrow, boolean isExpand) {
        if(isExpand) {
            arrow.animate().rotation(0);
        }else {
            arrow.animate().rotation(-180);
        }
    }
    public void toMap(String v) {
        // Create a Uri from an intent string. Use the result to create an Intent.
        try {
            if (isAvailable(this, "com.google.android.apps.maps")) {
                Uri gmmIntentUri = Uri.parse("geo:0,0?q=" + v);
                Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
                mapIntent.setPackage("com.google.android.apps.maps");
                startActivity(mapIntent);
            } else {
                Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&" + v);
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        } catch (Throwable e) {
            Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&" + v);
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
    }

    // Utility method to check if a package is available
    private boolean isAvailable(Context ctx, String packageName) {
        PackageManager pm = ctx.getPackageManager();
        try {
            pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }
    public String checkUrl(String url) {
        String checkUrl = "";
        if (url.contains("http")) {
            checkUrl = url;
        } else {
            checkUrl = "http://" + url;
        }
        return checkUrl;
    }

}
