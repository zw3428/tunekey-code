package com.spelist.tunekey.ui.teacher.students.activity;


import static com.spelist.tools.tools.SLStringUtils.isEmail;
import static com.spelist.tools.tools.SLStringUtils.isNoNull;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Intent;
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
import android.widget.TextView;

import androidx.core.content.ContextCompat;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.spelist.tools.custom.InputView;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.ActivityStudentDetailV2Binding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.student.sProfile.fragment.StudentProfileEditActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.ui.teacher.materials.MaterialsHelp;
import com.spelist.tunekey.ui.teacher.materials.activity.MaterialsActivity;
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailV2VM;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import me.goldze.mvvmhabit.base.BaseActivity;


public class StudentDetailV2Ac extends BaseActivity<ActivityStudentDetailV2Binding, StudentDetailV2VM> {


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_detail_v2;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        binding.birthdayLayout.setOnClickListener(view -> {
            StudentProfileEditActivity.DatePickerFragment newFragment = new StudentProfileEditActivity.DatePickerFragment(viewModel.birthday);
            newFragment.show(getSupportFragmentManager(), "datePicker");
            newFragment.setOnClickSaveListener(time -> {
                viewModel.birthday = time;
                viewModel.birthdayString.set(TimeUtils.timeFormat((long) viewModel.birthday , "MM/dd/yyyy"));
                viewModel.updateBirthday();
            });
        });
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvLesson.setLayoutManager(linearLayoutManager);
        binding.addLesson.setVisibility(View.GONE);
        binding.rvLesson.setItemAnimator(null);//设置动画为null来解决闪烁问题
        viewModel.gridLayoutManager.set(new GridLayoutManager(this, 3));

        binding.memoLayout.setOnClickListener(view -> {
            if (!viewModel.isStudentLook.get()){
                showAddMemo();
            }
        });
    }


    @Override
    public void initViewObservable() {
        viewModel.uc.refreshAvatar.observe(this, time -> {
            runOnUiThread(() -> binding.avatarView.refreshAvatar(time));
        });
//        super.initViewObservable();
        viewModel.uc.clickInfo.observe(this, aVoid -> {
            if (viewModel.studentIsActive) {
                showInfoPop();
            } else {
                showEditInfoPop();
            }
        });
        viewModel.uc.clickDeleteLesson.observe(this, new Observer<Integer>() {
            @Override
            public void onChanged(Integer pos) {
                Dialog dialog = SLDialogUtils.showTwoButton(StudentDetailV2Ac.this, "Delete Lesson", "Are you sure to delete this lesson?", "Delete", "Go back");
                TextView leftButton = dialog.findViewById(R.id.left_button);
                leftButton.setTextColor(ContextCompat.getColor(getApplication().getApplicationContext(), R.color.red));

                leftButton.setOnClickListener(v -> {
                    dialog.dismiss();
                    viewModel.changeEdit();
                    viewModel.removeLesson(pos);
                });
            }
        });
        viewModel.uc.clickAddLessonType.observe(this, aVoid -> {
            Intent intent = new Intent(this, AddLessonStepActivity.class);
            intent.putExtra("list", viewModel.studentData);
            intent.putExtra("buttonString", "ADD LESSON");
            startActivity(intent);
            viewModel.closeEdit();

        });
        viewModel.uc.clickLessonItem.observe(this, pos -> {
            Intent intent = new Intent(this, AddLessonStepActivity.class);
            intent.putExtra("editData", viewModel.scheduleConfigData.get(pos));
            intent.putExtra("buttonString", "UPDATE NOW");
            startActivity(intent);
            viewModel.closeEdit();
        });
        viewModel.uc.materialsObserverData.observe(this, multiItemViewModels ->
                Objects.requireNonNull(viewModel.gridLayoutManager.get()).setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                    @Override
                    public int getSpanSize(int position) {
                        if ((int) multiItemViewModels.get(position).getData().getType() == 6) {
                            return 3;
                        } else {
                            return 1;
                        }
                    }
                }));
        viewModel.uc.clickMaterialItem.observe(this, map -> {
            MaterialEntity entity = (MaterialEntity) map.get("data");
            if (entity.getType() == -2) {
//                replaceFragment(entity);
//                baseTitleViewModel.searchIsVisible.set(false);
//                if (moveItemHelperCallback != null) {
//                    moveItemHelperCallback.setDragIsEnable(true);
//                }
//                binding.titleLayout.searchEditText.setText("");
            } else {
                MaterialsHelp.clickMaterial(map, StudentDetailV2Ac.this);
            }
        });
        viewModel.uc.clickMaterialMore.observe(this, map -> {
            Intent intent = new Intent(StudentDetailV2Ac.this, MaterialsActivity.class);
            intent.putExtra("type", "show");
            intent.putExtra("data", (Serializable) viewModel.materialsData);
            startActivity(intent);
        });

        viewModel.uc.clickStudentPractice.observe(this, unused -> {
//            Bundle bundle = new Bundle();
////        bundle.putSerializable("data", (Serializable) lastLessonPractices);
////        bundle.putSerializable("lessonData", (Serializable) selectData.getValue());
////            bundle.putInt("startTime", (int) data.getValue().getShouldDateTime());
////            bundle.putInt("endTime",  endTime);
////            bundle.putInt("startTime", startTime);
//
//            bundle.putInt("type", 3);
//            bundle.putSerializable("data", (Serializable) viewModel.practicesData);
//            bundle.putSerializable("teacherId", viewModel.studentData.getTeacherId());
//            bundle.putSerializable("studentId", viewModel.studentData.getStudentId());
//            startActivity(PracticeActivity.class, bundle);


            Bundle bundle = new Bundle();
            bundle.putString("title","Practice");
            bundle.putSerializable("data", (Serializable) viewModel.practicesData);
            startActivity(PracticeDetailActivity.class, bundle);
        });
    }

    @Override
    public void initData() {
        super.initData();
        Intent intent = getIntent();
        viewModel.isStudentLook.set(intent.getBooleanExtra("isStudent", false));
        viewModel.studentData = (StudentListEntity) intent.getSerializableExtra("student");
        viewModel.initData();
    }

    /**
     * 显示student info的弹窗
     */
    private void showInfoPop() {
        BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(StudentDetailV2Ac.this)
                .addMenuItems(new MenuItem(viewModel.studentData.getEmail()));
        if (!viewModel.studentData.getPhone().equals("")) {
            bottomMenuFragment.addMenuItems(new MenuItem(viewModel.studentData.getPhone()));
        }
        bottomMenuFragment.addMenuItems(new MenuItem("Edit name"));
        bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
            if (position == 0) {
                sendEmail();
            } else if (position == 1) {
                if (!viewModel.studentData.getPhone().equals("")) {
                    sendPhone();
                } else {
                    showEditName();
                }

            } else {
                showEditName();
            }
        }).show();

    }

    private void showEditName() {

        Dialog bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_edit_name, null);
        InputView name = contentView.findViewById(R.id.name);
        TKButton cancel = contentView.findViewById(R.id.cancel);
        TKButton create = contentView.findViewById(R.id.create);

        name.setInputText(viewModel.studentData.getName());
        name.setFocus();


        create.setEnabled(false);
        name.editTextView.addTextChangedListener(new TextWatcher() {
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

        cancel.setClickListener(tkButton -> {
            bottomDialog.dismiss();
        });
        create.setClickListener(tkButton -> {
            String text = String.valueOf(name.getInputText());
            StudentListEntity studentListEntity = new StudentListEntity();
            studentListEntity.setId(viewModel.studentData.getStudentId());
            studentListEntity.setName(name.getInputText());
            studentListEntity.setStudentId(viewModel.studentData.getStudentId());
            studentListEntity.setEmail(viewModel.studentData.getEmail());
            if (isNoNull(viewModel.studentData.getPhone())) {
                studentListEntity.setPhone(viewModel.studentData.getPhone());
            } else {
                studentListEntity.setPhone("");
            }

            viewModel.updateStudent(studentListEntity, true, false);


            bottomDialog.dismiss();
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗

//        Dialog addStudentDialog = new Dialog(this, R.style.BottomDialog);
//        View contentView = LayoutInflater.from(this).inflate(R.layout.new_contact_toast, null);
//        //获取Dialog的监听
//
//        InputView name = contentView.findViewById(R.id.tv_name);
//        InputView email = contentView.findViewById(R.id.tv_email);
//        InputView phone = contentView.findViewById(R.id.tv_phone);
//
//        TextView cancel = (TextView) contentView.findViewById(R.id.tx_cancel);
//        TextView save = (TextView) contentView.findViewById(R.id.tx_save);
//
//        name.setInputText(viewModel.studentData.getName());
//        name.setFocus();
//
//        email.setInputTextNoFocus(viewModel.studentData.getEmail());
//        phone.setInputTextNoFocus(viewModel.studentData.getPhone());
//
//        phone.editTextView.setFocusableInTouchMode(false);//不可编辑
//        phone.editTextView.setKeyListener(null);//不可粘贴，长按不会弹出粘贴框
//        phone.editTextView.setClickable(false);//不可点击，但是这个效果我这边没体现出来，不知道怎没用
//        phone.editTextView.setFocusable(false);//不可编辑
//
//        email.editTextView.setFocusableInTouchMode(false);//不可编辑
//        email.editTextView.setKeyListener(null);//不可粘贴，长按不会弹出粘贴框
//        email.editTextView.setClickable(false);//不可点击，但是这个效果我这边没体现出来，不知道怎没用
//        email.editTextView.setFocusable(false);//不可编辑
//
//        cancel.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                if (addStudentDialog.isShowing()) {
//                    addStudentDialog.dismiss();
//                }
//            }
//        });
//
//        save.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                if (!isNoNull(name.getInputText())) {
//                    SLToast.error("Please check the name you entered!");
//                } else {
//                    StudentListEntity studentListEntity = new StudentListEntity();
//                    studentListEntity.setId(viewModel.studentData.getStudentId());
//                    studentListEntity.setName(name.getInputText());
//                    studentListEntity.setStudentId(viewModel.studentData.getStudentId());
//                    studentListEntity.setEmail(email.getInputText());
//                    if (isNoNull(phone.getInputText())) {
//                        studentListEntity.setPhone(phone.getInputText());
//                    } else {
//                        studentListEntity.setPhone("");
//                    }
//
//                    viewModel.updateStudent(studentListEntity, true, false);
//
//
//                    addStudentDialog.dismiss();
//                }
//
//            }
//        });
//
//        addStudentDialog.setContentView(contentView);
//        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
//        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
//        contentView.setLayoutParams(layoutParams);
//        addStudentDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
//        addStudentDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
//        addStudentDialog.show();//显示弹窗
    }

    /**
     * 显示修改info的弹窗
     */
    private void showEditInfoPop() {
        Dialog addStudentDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.new_contact_toast, null);
        //获取Dialog的监听

        InputView name = contentView.findViewById(R.id.tv_name);
        InputView email = contentView.findViewById(R.id.tv_email);
        InputView phone = contentView.findViewById(R.id.tv_phone);

        TextView cancel = (TextView) contentView.findViewById(R.id.tx_cancel);
        TextView save = (TextView) contentView.findViewById(R.id.tx_save);

        name.setInputText(viewModel.studentData.getName());
        email.setInputText(viewModel.studentData.getEmail());
        phone.setInputText(viewModel.studentData.getPhone());


        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (addStudentDialog.isShowing()) {
                    addStudentDialog.dismiss();
                }
            }
        });

        save.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isNoNull(name.getInputText())) {
                    SLToast.error("Please check the name you entered!");
                } else if (!isEmail(email.getInputText().trim())) {
                    SLToast.error("Please check the email you entered!");
                } else {
                    StudentListEntity studentListEntity = new StudentListEntity();
                    studentListEntity.setId(viewModel.studentData.getStudentId());
                    studentListEntity.setName(name.getInputText());
                    studentListEntity.setStudentId(viewModel.studentData.getStudentId());
                    studentListEntity.setEmail(email.getInputText());
                    if (isNoNull(phone.getInputText())) {
                        studentListEntity.setPhone(phone.getInputText());
                    } else {
                        studentListEntity.setPhone("");
                    }

                    if (viewModel.studentData.getEmail().equals(email.getInputText())) {
                        viewModel.updateStudent(studentListEntity, true, true);
                    } else {
                        viewModel.updateEmail(studentListEntity);
                    }


                    addStudentDialog.dismiss();
                }

            }
        });

        addStudentDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        addStudentDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        addStudentDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        addStudentDialog.show();//显示弹窗
    }

    private void sendPhone() {
        Intent intent = new Intent(Intent.ACTION_DIAL);
        Uri data = Uri.parse("tel:" + viewModel.studentData.getPhone());
        intent.setData(data);
        startActivity(intent);
    }

    @SuppressLint("IntentReset")
    private void sendEmail() {
        String[] TO = {viewModel.studentData.getEmail()};
        Intent emailIntent = new Intent(Intent.ACTION_SEND);
        emailIntent.setData(Uri.parse("mailto:"));
        emailIntent.setType("text/plain");
        emailIntent.putExtra(Intent.EXTRA_EMAIL, TO);

        try {
            startActivity(emailIntent);
        } catch (android.content.ActivityNotFoundException ex) {
            SLToast.error("Failed to open email, please try again!");
        }
    }
    private void showAddMemo() {
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

        title.setText("Memo");
        FuncUtils.toggleSoftInput(addText, true);
        create.setText("SAVE");
//        create.setEnabled(false);
//        addText.addTextChangedListener(new TextWatcher() {
//            @Override
//            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
//
//            }
//
//            @Override
//            public void onTextChanged(CharSequence s, int start, int before, int count) {
//
//            }
//
//            @Override
//            public void afterTextChanged(Editable s) {
//                create.setEnabled(s.toString().length() > 0);
//            }
//        });
        addText.setText(viewModel.studentData.getMemo());
        addText.setSelection(addText.getText().toString().length());
        cancel.setClickListener(tkButton -> {
            bottomDialog.dismiss();
        });
        create.setClickListener(tkButton -> {
            String text = String.valueOf(addText.getText());
            if (text.equals("")){
                viewModel.memoString.set("Optional");
            }else {
                viewModel.memoString.set(text);
            }
            viewModel.studentData.setMemo(text);
            viewModel.updateMemo(text);
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

}