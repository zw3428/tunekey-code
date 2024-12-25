package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.Observer;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.custom.SwitchButton;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tools.tools.TimeUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.TKEditeTextDialog;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.customView.dialog.selectLessonV2.SelectLessonV2Dialog;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.databinding.ActivityAddLessonStepBinding;
import com.spelist.tunekey.entity.AutoInvoicingSetting;
import com.spelist.tunekey.entity.CountriesCurrencies;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.entity.TKLocation;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.loginAndOnboard.login.LoginActivity;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.filter.SelectInstructorOrStudentAc;
import com.spelist.tunekey.ui.teacher.lessons.vm.AddLessonStepViewModel;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SharePreferenceUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseActivity;

public class AddLessonStepActivity extends BaseActivity<ActivityAddLessonStepBinding, AddLessonStepViewModel> {

    public static final int REQUEST_CODE = 2;
    private Dialog bottomDialog;
    private Dialog endDialog;
    private int lessonMinuteLength;

    private WebView startWebView;

    public long oldStartTimeFromWebView = 0;
    public long startTimeFromWebView = 0;

    public long oldEndTimeFromWebView = 0;
    public long endTimeFromWebView = 0;
    private SubmitButton submitButton1;
    private String cuText = "";


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_add_lesson_step;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @SuppressLint("SetTextI18n")
    @Override
    public void initData() {
        Intent intent = getIntent();
        if (intent.getSerializableExtra("list") != null) {
            viewModel.isTestUser = intent.getBooleanExtra("isTest", false);
            viewModel.studentListEntity = (StudentListEntity) intent.getSerializableExtra("list");
            if (viewModel.studentListEntity.getUnConfirmedLessonConfig().size() == 0) {
                String buttonString = intent.getStringExtra("buttonString");
                if (SLStringUtils.isNoNull(buttonString)) {
                    binding.submitButton.setText(buttonString);
                } else {
                    binding.submitButton.setText("SEND INVITE");
                }
                viewModel.getStudentId(viewModel.studentListEntity.getStudentId());
                viewModel.initData1(0);
                binding.stName.setText(viewModel.studentListEntity.getName());
                binding.price.setTransText("Special price for " + viewModel.studentListEntity.getName());
                binding.stEmail.setText(viewModel.studentListEntity.getEmail());
                viewModel.name.set(viewModel.studentListEntity.getName());
                viewModel.userId.set(viewModel.studentListEntity.getStudentId());
                binding.linStartTime.setVisibility(View.GONE);
                binding.linRecurrence.setVisibility(View.GONE);
                binding.memoLayout.setVisibility(View.GONE);
                viewModel.title = "Add Lesson";
                viewModel.initToolbar();
                binding.submitButton.setEnabled(false);
                binding.confirmConfirmButton.setEnabled(false);
            } else {
                viewModel.title = "Add Lesson";
                viewModel.initToolbar();
                viewModel.getStudentId(viewModel.studentListEntity.getStudentId());
                viewModel.initData1(0);
                binding.stName.setText(viewModel.studentListEntity.getName());
                binding.price.setTransText("Special price for " + viewModel.studentListEntity.getName());
                binding.stEmail.setText(viewModel.studentListEntity.getEmail());
                viewModel.name.set(viewModel.studentListEntity.getName());
                viewModel.userId.set(viewModel.studentListEntity.getStudentId());
                binding.linStartTime.setVisibility(View.GONE);
                binding.linRecurrence.setVisibility(View.GONE);
                binding.memoLayout.setVisibility(View.GONE);
                binding.submitButton.setVisibility(View.GONE);
                binding.confirmLessonLayout.setVisibility(View.VISIBLE);
                viewModel.oldConfig = viewModel.studentListEntity.getUnConfirmedLessonConfig().get(0);
                if (viewModel.oldConfig.getMemo() != null && !viewModel.oldConfig.getMemo().equals("Optional")) {
                    viewModel.memoString.set(viewModel.oldConfig.getMemo().equals("") ? "Optional" : viewModel.oldConfig.getMemo());
                }
                if (viewModel.oldConfig.getSpecialPrice() != -1) {
                    binding.price.setInputText(FuncUtils.doubleTrans((viewModel.oldConfig.getSpecialPrice())));
                    initSpecial(viewModel.oldConfig.getSpecialPrice(), Double.parseDouble(viewModel.oldConfig.getLessonType().getPrice()));
                }

                viewModel.getLessonType(viewModel.oldConfig.getLessonTypeId());
                binding.confirmConfirmButton.setEnabled(false);
                binding.confirmDeleteButton.setClickListener(tkButton -> {
                    Dialog dialog = SLDialogUtils.showTwoButton(this, "Delete Lesson?", "Are you sure to delete this lesson?", "Delete", "Go back");
                    dialog.findViewById(R.id.left_button).setOnClickListener(v -> {
                        viewModel.deleteStudentLesson();
                        dialog.dismiss();
                    });
                });
                binding.confirmConfirmButton.setClickListener(tkButton -> {
                    viewModel.confirmStudentLesson();
                });
            }


        } else if (intent.getSerializableExtra("reschedule") != null) {
//            agendaOnWebviewEntity = (AgendaOnWebviewEntity) intent.getSerializableExtra("reschedule");
//            viewModel.getStudentId(agendaOnWebviewEntity.getStudentId());
            viewModel.initData1(0);
//            viewModel.getLessonSchedule(agendaOnWebviewEntity.getLessonScheduleConfigId());
//            viewModel.getStudentInfo(agendaOnWebviewEntity.getStudentId());
//            viewModel.getLessonType(agendaOnWebviewEntity.getLessonTypeId());
//            viewModel.name.set(agendaOnWebviewEntity.getStudentName());
//            viewModel.userId.set(agendaOnWebviewEntity.getStudentId());
            binding.linSelectLesson.setVisibility(View.GONE);
            binding.linLessonType.setVisibility(View.VISIBLE);
            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                binding.priceLayout.setVisibility(View.VISIBLE);
            }
            binding.linStartTime.setVisibility(View.VISIBLE);
            binding.linRecurrence.setVisibility(View.VISIBLE);
            binding.memoLayout.setVisibility(View.VISIBLE);
            binding.submitButton.setText("UPDATE NOW");
            viewModel.title = "Lesson";
            viewModel.initToolbar();
        } else if (intent.getSerializableExtra("editData") != null) {
            viewModel.oldConfig = (LessonScheduleConfigEntity) intent.getSerializableExtra("editData");
//            viewModel.testOldConfig = CloneObjectUtils.cloneObject(viewModel.oldConfig);
            if (viewModel.oldConfig == null) {
                finish();
                return;
            }


            viewModel.selectLocation = viewModel.oldConfig.location;
            viewModel.locationString.set(viewModel.oldConfig.location.getTkString());

            if (viewModel.oldConfig.getMemo() != null && !viewModel.oldConfig.getMemo().equals("Optional")) {
                viewModel.memoString.set(viewModel.oldConfig.getMemo().equals("") ? "Optional" : viewModel.oldConfig.getMemo());
            }
            viewModel.isEdit = true;
            String studentId = viewModel.oldConfig.getStudentId();
            List<StudentListEntity> studentList = new ArrayList<>();
            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                studentList = ListenerService.shared.teacherData.getStudentList();
            } else {
                studentList = AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
                binding.priceLayout.setVisibility(View.GONE);
                binding.teacherLayout.setVisibility(View.VISIBLE);
                TeacherInfoEntity teacherInfo = AppDataBase.getInstance().teacherInfoDao().getByUserId(viewModel.oldConfig.teacherId);
                if (teacherInfo != null && teacherInfo.userData != null) {
                    viewModel.teacherName.set(teacherInfo.getUserData().getName());
                    viewModel.teacherUserId.set(teacherInfo.getUserData().getUserId());
                }
            }

            for (StudentListEntity item : studentList) {
                if (studentId.equals(item.getStudentId())) {
                    viewModel.studentListEntity = item;
                }
            }
            binding.stName.setText(viewModel.studentListEntity.getName());
            binding.price.setTransText("Special price for " + viewModel.studentListEntity.getName());
            if (viewModel.oldConfig.getSpecialPrice() != -1) {
                binding.price.setInputText(FuncUtils.doubleTrans((viewModel.oldConfig.getSpecialPrice())));
                initSpecial(viewModel.oldConfig.getSpecialPrice(), Double.parseDouble(viewModel.oldConfig.getLessonType().getPrice()));
            }

            binding.stEmail.setText(viewModel.studentListEntity.getEmail());
            viewModel.name.set(viewModel.studentListEntity.getName());
            viewModel.userId.set(viewModel.studentListEntity.getStudentId());
            viewModel.initData1(viewModel.oldConfig.getStartDateTime());
            LessonTypeEntity typeEntity = new LessonTypeEntity();
            for (LessonTypeEntity item : viewModel.lessonTypeList) {
                if (item.getId().equals(viewModel.oldConfig.getLessonTypeId())) {
                    typeEntity = item;
                }
            }
            selectLessonType(typeEntity);
            binding.submitButton.setText("UPDATE NOW");
            viewModel.title = "Lesson";
            viewModel.initToolbar();
            binding.linSelectLesson.setVisibility(View.GONE);
            binding.linLessonType.setVisibility(View.VISIBLE);

            if (viewModel.oldConfig.getLessonCategory().equals(LessonTypeEntity.TKLessonCategory.single)) {
                viewModel.isShowGroupStudent.set(false);
            } else {
                viewModel.isShowGroupStudent.set(true);
                viewModel.groupStudentSizeString.set(viewModel.oldConfig.getGroupLessonStudents().size() + " students");
                if (viewModel.scheduleConfigEntity.getLessonType().getMaxStudents() == -1) {
                    viewModel.groupStudentSizeInfoString.set("");
                } else {
                    int pastSize = viewModel.scheduleConfigEntity.getLessonType().getMaxStudents() - viewModel.oldConfig.getGroupLessonStudents().size();
                    if (pastSize == 0) {
                        viewModel.groupStudentSizeInfoString.set("Full");
                    } else {
                        viewModel.groupStudentSizeInfoString.set(pastSize + " spots available");
                    }
                }
            }


            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                binding.priceLayout.setVisibility(View.VISIBLE);
            }
            binding.linStartTime.setVisibility(View.VISIBLE);
            viewModel.startTimeString.set(TimeUtils.getCurrentTime(viewModel.oldConfig.getStartDateTime()));
//            binding.tvStartTime.setText(TimeUtils.getCurrentTime(viewModel.oldConfig.getStartDateTime()));
            viewModel.getStartTime(viewModel.oldConfig.getStartDateTime());
            oldStartTimeFromWebView = viewModel.oldConfig.getStartDateTime();
            startTimeFromWebView = viewModel.oldConfig.getStartDateTime();

            binding.linRecurrence.setVisibility(View.VISIBLE);
            binding.memoLayout.setVisibility(View.VISIBLE);
            if (viewModel.oldConfig.getRepeatType() == 0) {
                binding.linRecurrenceDetail.setVisibility(View.GONE);
                binding.swRec.setToggleOff();
            } else if (viewModel.oldConfig.getRepeatType() == 1) {
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.swRec.setToggleOn();
                binding.imgWeekly.setVisibility(View.VISIBLE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.VISIBLE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(1);
                int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
                for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
                    int i = integer + (-diff);
                    if (i < 0) {
                        i = 6;
                    } else if (i > 6) {
                        i = 0;
                    }
                    viewModel.setRepeatTypeWeekDay(i);
                }

            } else if (viewModel.oldConfig.getRepeatType() == 2) {
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.swRec.setToggleOn();
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.VISIBLE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.VISIBLE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(2);
                int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
                for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
                    int i = integer + (-diff);
                    if (i < 0) {
                        i = 6;
                    } else if (i > 6) {
                        i = 0;
                    }
                    viewModel.setRepeatTypeWeekDay(i);
                }
            }
            if (viewModel.oldConfig.getEndType() == 0) {
                binding.swEnd.setToggleOff();
            } else if (viewModel.oldConfig.getEndType() == 1) {
                binding.swEnd.setToggleOn();
                binding.linEnd.setVisibility(View.VISIBLE);
                binding.rb3.setChecked(true);
                binding.rb4.setChecked(false);
                if (viewModel.oldConfig.getEndCount() == 0) {
                    viewModel.oldConfig.setEndCount(10);
                }
                binding.tvCurrenceTime.setText(viewModel.oldConfig.getEndCount() + "");
                binding.tvEndsDate.setText(TimeUtils.timestampToString(viewModel.oldConfig.getEndDate(), "MMM d ，yyyy"));
                oldEndTimeFromWebView = viewModel.oldConfig.getEndDate();
                endTimeFromWebView = viewModel.oldConfig.getEndDate();
            } else if (viewModel.oldConfig.getEndType() == 2) {
                binding.swEnd.setToggleOn();
                if (viewModel.scheduleConfigEntity.getLessonType().get_package() == 0) {
                    binding.linEnd.setVisibility(View.VISIBLE);
                    binding.rb3.setChecked(false);
                    binding.rb4.setChecked(true);
                    binding.tvCurrenceTime.setText(viewModel.oldConfig.getEndCount() + "");
                    if (viewModel.oldConfig.getEndDate() == 0) {
                        if (viewModel.oldConfig.getStartDateTime() > (System.currentTimeMillis() / 1000)) {
                            viewModel.oldConfig.setEndDate((int) (com.spelist.tunekey.utils.TimeUtils.addMonth(viewModel.oldConfig.getStartDateTime() * 1000L, 1) / 1000L));
                        } else {
                            viewModel.oldConfig.setEndDate((int) (com.spelist.tunekey.utils.TimeUtils.addMonth(System.currentTimeMillis(), 1) / 1000L));
                        }
                    }
                    binding.tvEndsDate.setText(TimeUtils.timestampToString(viewModel.oldConfig.getEndDate(), "MMM d ，yyyy"));
                }
                oldEndTimeFromWebView = viewModel.oldConfig.getEndDate();
                endTimeFromWebView = viewModel.oldConfig.getEndDate();
            }
            viewModel.scheduleConfigEntity = CloneObjectUtils.cloneObject(viewModel.oldConfig);
            int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
            List<Integer> weekDays = new ArrayList<>();
            for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
                int i = integer + (-diff);
                if (i < 0) {
                    i = 6;
                } else if (i > 6) {
                    i = 0;
                }
                weekDays.add(i);
            }
            viewModel.scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);

            binding.submitButton.setVisibility(View.GONE);
            binding.confirmLessonLayout.setVisibility(View.VISIBLE);
            binding.confirmDeleteButton.setClickListener(tkButton -> {
                Dialog dialog = SLDialogUtils.showTwoButton(this, "Delete Lesson?", "Are you sure to delete this lesson?", "Delete", "Go back");
                dialog.findViewById(R.id.left_button).setOnClickListener(v -> {
                    viewModel.deleteLesson();

                    dialog.dismiss();
                });
            });
            binding.confirmConfirmButton.setClickListener(tkButton -> {
//                viewModel.confirmStudentLesson();
                showDialog();
                viewModel.rescheduleAllV2(tkButton);

            });
        }


        //设定初始化折叠，默认展开
        binding.swRec.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                Logger.e("======%s", on);
                if (on) {
                    binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                    binding.layoutEnds.setVisibility(View.VISIBLE);
                    binding.linWeekly.setVisibility(View.VISIBLE);
                    binding.imgWeekly.setVisibility(View.VISIBLE);
                    binding.linBi.setVisibility(View.GONE);
                    binding.imgBi.setVisibility(View.GONE);
                    binding.linMonthly.setVisibility(View.GONE);
                    binding.imgMonthly.setVisibility(View.GONE);
                    viewModel.setRepeatType(1);
                } else {
                    binding.linRecurrenceDetail.setVisibility(View.GONE);
                    binding.layoutEnds.setVisibility(View.GONE);
                    viewModel.setRepeatType(0);
                }
            }
        });
        binding.swEnd.setOnToggleChanged(new SwitchButton.OnToggleChanged() {
            @Override
            public void onToggle(boolean on) {
                if (on) {
                    binding.linEnd.setVisibility(View.VISIBLE);
                    viewModel.scheduleConfigEntity.setEndType(1);
                    binding.rb3.setChecked(true);
                    binding.rb4.setChecked(false);

                } else {
                    binding.linEnd.setVisibility(View.GONE);
                    viewModel.scheduleConfigEntity.setEndType(0);
                }
            }
        });
        AutoInvoicingSetting.TKCurrency currentCurrenciesData = CountriesCurrencies.getLocationCurrencies().toInvoiceSettingData();

        if (SLCacheUtil.getStudioInfo() != null && SLCacheUtil.getStudioInfo().getCurrency() != null && !SLCacheUtil.getStudioInfo().getCurrency().getSymbol().equals("")) {
            currentCurrenciesData = SLCacheUtil.getStudioInfo().getCurrency();
        }
        binding.price.setCurrency(currentCurrenciesData.getSymbol());

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {
            LessonTypeEntity lessonTypeEntity = new LessonTypeEntity();
            lessonTypeEntity = (LessonTypeEntity) data.getSerializableExtra("lessonType");

            selectLessonType(lessonTypeEntity);
        } else {
            Logger.e("lose");
        }
    }

    private void selectLessonType(LessonTypeEntity lessonTypeEntity) {

        lessonMinuteLength = lessonTypeEntity.getTimeLength();
        viewModel.getLessonId(lessonTypeEntity.getId());
        viewModel.scheduleConfigEntity.setLessonType(lessonTypeEntity);
        viewModel.scheduleConfigEntity.setLessonTypeId(lessonTypeEntity.getId());
        if (binding.price.getInputText() != null && !binding.price.getInputText().equals("")) {
            initSpecial(Double.parseDouble(binding.price.getInputText()), Double.parseDouble(viewModel.scheduleConfigEntity.getLessonType().getPrice()));
        }

        binding.linSelectLesson.setVisibility(View.GONE);
        binding.linLessonType.setVisibility(View.VISIBLE);
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            binding.priceLayout.setVisibility(View.VISIBLE);
        }
        binding.tvName.setText(lessonTypeEntity.getName());
        binding.tvInfo.setText(lessonTypeEntity.getInfo());
        RequestOptions placeholder = new RequestOptions()
                .placeholder(R.drawable.def_instrument)
                .error(R.drawable.def_instrument);
        Glide.with(binding.lessonTypeImage.getContext())
                .load(lessonTypeEntity.getInstrumentPath())
                .apply(placeholder)
                .into(binding.lessonTypeImage);
        if (viewModel.studentListEntity != null && viewModel.studentListEntity.getUnConfirmedLessonConfig().size() > 0 && viewModel.oldConfig != null) {
            viewModel.oldConfig.setLessonTypeId(lessonTypeEntity.getId());
            viewModel.oldConfig.setLessonType(lessonTypeEntity);
            setLessonData();
        } else {
            binding.linStartTime.setVisibility(View.VISIBLE);
            if (binding.linRecurrence.getVisibility() == View.VISIBLE) {
                refreshData(true);
            }
        }
        if (lessonTypeEntity.get_package() == 0) {
            binding.endsPackageLayout.setVisibility(View.GONE);
            binding.endsNoneLayout.setVisibility(View.VISIBLE);
            viewModel.scheduleConfigEntity.setEndType(0);
        } else {
            binding.endsPackageLayout.setVisibility(View.VISIBLE);
            binding.endsNoneLayout.setVisibility(View.GONE);
            binding.endsAfterPackage.setText("Ends after " + lessonTypeEntity.get_package() + " lessons");
            viewModel.scheduleConfigEntity.setEndType(2);
            viewModel.scheduleConfigEntity.setEndCount(lessonTypeEntity.get_package());
        }

    }

    private void refreshData(boolean isLessonType) {
        if (isLessonType) {
//            binding.tvStartTime.setText("Tap to select time");
            viewModel.startTimeString.set("Tap to select time");
            viewModel.locationString.set("");
            oldStartTimeFromWebView = 0;
            startTimeFromWebView = 0;
            binding.linRecurrence.setVisibility(View.GONE);
            binding.memoLayout.setVisibility(View.GONE);
            binding.submitButton.setEnabled(false);
            binding.confirmConfirmButton.setEnabled(false);
        }


        viewModel.scheduleConfigEntity.setRepeatType(0);
        viewModel.scheduleConfigEntity.setEndType(0);
        viewModel.scheduleConfigEntity.setStartDateTime(0);
        binding.linRecurrenceDetail.setVisibility(View.GONE);
        binding.swEnd.setToggleOff();
        binding.linWeekly.setVisibility(View.VISIBLE);
        binding.imgWeekly.setVisibility(View.VISIBLE);
        binding.linBi.setVisibility(View.GONE);
        binding.imgBi.setVisibility(View.GONE);
        binding.linMonthly.setVisibility(View.GONE);
        binding.imgMonthly.setVisibility(View.GONE);
        binding.rb3.setChecked(true);
        binding.rb4.setChecked(false);
        binding.swRec.setToggleOff();
        binding.linEnd.setVisibility(View.GONE);
        binding.layoutEnds.setVisibility(View.GONE);
        if (viewModel.scheduleConfigEntity.getLessonType().get_package() == 0) {
//            binding.endsPackageLayout.setVisibility(View.GONE);
//            binding.endsNoneLayout.setVisibility(View.VISIBLE);
            viewModel.scheduleConfigEntity.setEndType(0);
        } else {
//            binding.endsPackageLayout.setVisibility(View.VISIBLE);
//            binding.endsNoneLayout.setVisibility(View.GONE);
            viewModel.scheduleConfigEntity.setEndType(2);
            viewModel.scheduleConfigEntity.setEndCount(viewModel.scheduleConfigEntity.getLessonType().get_package());
        }


    }

    @Override
    public void initView() {
        super.initView();
        binding.groupStudentLayout.setOnClickListener(view -> {
            ArrayList<UserEntity> selectData = new ArrayList<>();
//            viewModel.scheduleConfigEntity.getGroupLessonStudents().forEach(studentListEntity -> selectData.add(studentListEntity));
            List<StudentListEntity> byStudioIdFromList = AppDataBase.getInstance().studentListDao().getByStudioIdFromList(SLCacheUtil.getCurrentStudioId());
            for (StudentListEntity studentListEntity : byStudioIdFromList) {
                if (viewModel.scheduleConfigEntity.getGroupLessonStudents().get(studentListEntity.getStudentId()) != null) {
                    LessonScheduleConfigEntity.GroupLessonStudent groupLessonStudent = SLJsonUtils.toBean(SLJsonUtils.toJsonString(viewModel.scheduleConfigEntity.getGroupLessonStudents().get(studentListEntity.getStudentId())), LessonScheduleConfigEntity.GroupLessonStudent.class);
                    if (groupLessonStudent.getStatus() == LessonScheduleConfigEntity.GroupLessonStudent.Status.active) {
                        selectData.add(studentListEntity.getUserData());
                    }
                }
            }
            Bundle bundle = new Bundle();
            bundle.putBoolean("isShowTeacher", false);
            bundle.putBoolean("isLessonEdit", true);
            bundle.putSerializable("selectData", selectData);
            startActivity(SelectInstructorOrStudentAc.class, bundle);

        });
        binding.memoLayout.setOnClickListener(v -> {
            String memo = "";
            if (viewModel.memoString.get() != null && !viewModel.memoString.get().equals("Optional")) {
                memo = viewModel.memoString.get();
            }
            TKEditeTextDialog dialog = new TKEditeTextDialog(this, memo, "Memo", "Location, zoom link, memo", "CONFIG");
            dialog.showDialog();
            dialog.setClickListener(data -> {
                viewModel.memoString.set(data.equals("") ? "Optional" : data);
            });
        });
        binding.price.editTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable editable) {
                if (editable.toString().equals(".")) {
                    binding.price.editTextView.setText("0.");
                    binding.price.editTextView.setSelection(2);
                }
                if (binding.price.getInputText() == null || binding.price.getInputText().equals("")) {
                    binding.priceSpecial.setText("");
                } else {
                    initSpecial(Double.parseDouble(binding.price.getInputText()), Double.parseDouble(viewModel.scheduleConfigEntity.getLessonType().getPrice()));
                }
            }
        });
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.showTestStudentDialog.observe(this, unused -> {
            Dialog dialog = SLDialogUtils.showTwoButtonSmallButton(this, "Try out as a student", "We have provided a \"test\" student account for you to step in the shoes of one of your students and see what it's like, would you like try out your \"test\" student account?"
                    , "Later", "Re-login\n as student");
            TextView leftButton = (TextView) dialog.findViewById(R.id.left_button);
            TextView rightButton = (TextView) dialog.findViewById(R.id.right_button);
            rightButton.setTextColor(ContextCompat.getColor(this, R.color.main));
            leftButton.setTextColor(ContextCompat.getColor(this, R.color.red));
            leftButton.setOnClickListener(v -> {
                dialog.dismiss();
                Dialog dialog1 = SLDialogUtils.showOneButton(this, "Try Out Later?", "Use \"" + viewModel.studentListEntity.getEmail() + "\" to login as a student", "Got it");
                dialog1.findViewById(R.id.button).setOnClickListener(v1 -> {
                    dialog1.dismiss();
                    finish();
                });
            });
            rightButton.setOnClickListener(v -> {
                dialog.dismiss();
                TKNotificationUtils.closeLessonNotification(AddLessonStepActivity.this);
                SharePreferenceUtils.clear(getApplication());
                FirebaseAuth.getInstance().signOut();
                logOut();

            });
        });
        viewModel.lessonData.observe(this, agendaOnWebViewEntities -> {
            if (startWebView != null) {
                startWebView.evaluateJavascript("getAgenda(" + SLJsonUtils.toJsonString(agendaOnWebViewEntities) + ")", s -> {

                });
            }

        });

        viewModel.lessonTypeEntityMutableLiveData.observe(this, new Observer<LessonTypeEntity>() {
            @Override
            public void onChanged(LessonTypeEntity lessonTypeEntity) {
                selectLessonType(lessonTypeEntity);
//                setLessonData();

            }
        });

        viewModel.liveData.observe(this, lessonScheduleConfigEntity -> {
            Logger.e("=======lessonScheduleConfigEntity======" + lessonScheduleConfigEntity);
//            binding.tvStartTime.setText(TimeUtils.getCurrentTime(lessonScheduleConfigEntity.getStartDateTime()));
            viewModel.startTimeString.set(TimeUtils.getCurrentTime(lessonScheduleConfigEntity.getStartDateTime()));
            if (lessonScheduleConfigEntity.getRepeatType() == 0) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.memoLayout.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.GONE);
                binding.layoutEnds.setVisibility(View.GONE);
            } else if (lessonScheduleConfigEntity.getRepeatType() == 1) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.memoLayout.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.VISIBLE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                for (int i = 0; i < lessonScheduleConfigEntity.getRepeatTypeWeekDay().size(); i++) {
                    switch (lessonScheduleConfigEntity.getRepeatTypeWeekDay().get(i)) {
                        case 0:
                            binding.weekly1.setChecked(true);
                            break;
                        case 1:
                            binding.weekly2.setChecked(true);
                            break;
                        case 2:
                            binding.weekly3.setChecked(true);
                            break;
                        case 3:
                            binding.weekly4.setChecked(true);
                            break;
                        case 4:
                            binding.weekly5.setChecked(true);
                            break;
                        case 5:
                            binding.weekly6.setChecked(true);
                            break;
                        case 6:
                            binding.weekly7.setChecked(true);
                            break;
                    }
                }
            } else if (lessonScheduleConfigEntity.getRepeatType() == 2) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.memoLayout.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linBi.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.VISIBLE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                for (int i = 0; i < lessonScheduleConfigEntity.getRepeatTypeWeekDay().size(); i++) {
                    switch (lessonScheduleConfigEntity.getRepeatTypeWeekDay().get(i)) {
                        case 0:
                            binding.biweekly1.setChecked(true);
                            break;
                        case 1:
                            binding.biweekly2.setChecked(true);
                            break;
                        case 2:
                            binding.biweekly3.setChecked(true);
                            break;
                        case 3:
                            binding.biweekly4.setChecked(true);
                            break;
                        case 4:
                            binding.biweekly5.setChecked(true);
                            break;
                        case 5:
                            binding.biweekly6.setChecked(true);
                            break;
                        case 6:
                            binding.biweekly7.setChecked(true);
                            break;
                    }
                }
            } else if (lessonScheduleConfigEntity.getRepeatType() == 3) {
                binding.swRec.setToggleOn();
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.memoLayout.setVisibility(View.VISIBLE);
                binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
                binding.layoutEnds.setVisibility(View.VISIBLE);
                binding.linMonthly.setVisibility(View.VISIBLE);
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.month1.setText(lessonScheduleConfigEntity.getRepeatTypeMonthDay());
            }
        });

        viewModel.studentInfoEntity.observe(this, new Observer<UserEntity>() {
            @Override
            public void onChanged(UserEntity userEntity) {
                binding.stName.setText(userEntity.getName());
                binding.price.setTransText("Special price for " + viewModel.studentListEntity.getName());

                binding.stEmail.setText(userEntity.getEmail());
            }
        });

        viewModel.uc.currenceTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                showUpPop();
            }
        });


        viewModel.uc.startTime.observe(this, aVoid -> {
            if (viewModel.scheduleConfigEntity.getRepeatTypeWeekDay() == null || viewModel.scheduleConfigEntity.getRepeatTypeWeekDay().size() == 0) {
                binding.weekly4.setChecked(true);
                binding.biweekly4.setChecked(true);
                viewModel.setRepeatType(0);
                viewModel.setRepeatTypeWeekDay(3);
            }
            showStartTimeV2();
        });

        viewModel.uc.endTime.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.linRecurrence.setVisibility(View.VISIBLE);
                binding.memoLayout.setVisibility(View.VISIBLE);
                showEndDialog();
            }
        });

        viewModel.uc.selectLessonType.observe(this, aVoid -> {
            if (viewModel.scheduleConfigEntity == null || viewModel.scheduleConfigEntity.getLessonCategory().equals(LessonTypeEntity.TKLessonCategory.group)) {
                return;
            }
            Intent intent = new Intent(AddLessonStepActivity.this, LessonTypeActivity.class);
            intent.putExtra("selectDataId", viewModel.scheduleConfigEntity.getLessonTypeId());
            intent.putExtra("flag", REQUEST_CODE);
            startActivityForResult(intent, REQUEST_CODE);
        });


        viewModel.uc.recWeekly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.VISIBLE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.VISIBLE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(1);
            }
        });

        viewModel.uc.recBiWeekly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.VISIBLE);
                binding.imgMonthly.setVisibility(View.GONE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.VISIBLE);
                binding.linMonthly.setVisibility(View.GONE);
                viewModel.setRepeatType(2);
            }
        });

        viewModel.uc.recMonthly.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                binding.imgWeekly.setVisibility(View.GONE);
                binding.imgBi.setVisibility(View.GONE);
                binding.imgMonthly.setVisibility(View.VISIBLE);
                binding.linWeekly.setVisibility(View.GONE);
                binding.linBi.setVisibility(View.GONE);
                binding.linMonthly.setVisibility(View.VISIBLE);
                viewModel.setRepeatType(3);


            }
        });
        viewModel.uc.rb1.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
//                if (isLastDayOfMonth(startTime)) {
//                    viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(startTime)));
//                } else {
//                    viewModel.setRepeatTypeMonthType(getWeek(startTime).substring(0, 1) + ":" + TimeUtils.getDay(startTime));
//                }

            }
        });
    }

    private void logOut() {
        ListenerService.shared.deinitListeners();
        Intent intent = new Intent(this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void setLessonData() {
        binding.linSelectLesson.setVisibility(View.GONE);
        binding.linLessonType.setVisibility(View.VISIBLE);
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            binding.priceLayout.setVisibility(View.VISIBLE);
        }
        binding.linStartTime.setVisibility(View.VISIBLE);

//        binding.tvStartTime.setText(TimeUtils.getCurrentTime(viewModel.oldConfig.getStartDateTime()));
        viewModel.startTimeString.set(TimeUtils.getCurrentTime(viewModel.oldConfig.getStartDateTime()));
        viewModel.getStartTime(viewModel.oldConfig.getStartDateTime());
        oldStartTimeFromWebView = viewModel.oldConfig.getStartDateTime();
        startTimeFromWebView = viewModel.oldConfig.getStartDateTime();

        binding.linRecurrence.setVisibility(View.VISIBLE);
        binding.memoLayout.setVisibility(View.VISIBLE);
        binding.confirmConfirmButton.setEnabled(true);
        if (viewModel.oldConfig.getRepeatType() == 0) {
            binding.linRecurrenceDetail.setVisibility(View.GONE);
            binding.swRec.setToggleOff();
        } else if (viewModel.oldConfig.getRepeatType() == 1) {
            binding.layoutEnds.setVisibility(View.VISIBLE);
            binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
            binding.swRec.setToggleOn();
            binding.imgWeekly.setVisibility(View.VISIBLE);
            binding.imgBi.setVisibility(View.GONE);
            binding.imgMonthly.setVisibility(View.GONE);
            binding.linWeekly.setVisibility(View.VISIBLE);
            binding.linBi.setVisibility(View.GONE);
            binding.linMonthly.setVisibility(View.GONE);
            viewModel.setRepeatType(1);
            int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
            for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
                int i = integer + (-diff);
                if (i < 0) {
                    i = 6;
                } else if (i > 6) {
                    i = 0;
                }
                viewModel.setRepeatTypeWeekDay(i);
            }

        } else if (viewModel.oldConfig.getRepeatType() == 2) {
            binding.layoutEnds.setVisibility(View.VISIBLE);
            binding.linRecurrenceDetail.setVisibility(View.VISIBLE);
            binding.swRec.setToggleOn();
            binding.imgWeekly.setVisibility(View.GONE);
            binding.imgBi.setVisibility(View.VISIBLE);
            binding.imgMonthly.setVisibility(View.GONE);
            binding.linWeekly.setVisibility(View.GONE);
            binding.linBi.setVisibility(View.VISIBLE);
            binding.linMonthly.setVisibility(View.GONE);
            viewModel.setRepeatType(2);
            int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
            for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
                int i = integer + (-diff);
                if (i < 0) {
                    i = 6;
                } else if (i > 6) {
                    i = 0;
                }
                viewModel.setRepeatTypeWeekDay(i);
            }
        }
        Logger.e("======%s", viewModel.oldConfig.getEndType());
        if (viewModel.oldConfig.getEndType() == 0) {
            binding.swEnd.setToggleOff();
        } else if (viewModel.oldConfig.getEndType() == 1) {
            binding.swEnd.setToggleOn();
            binding.linEnd.setVisibility(View.VISIBLE);
            binding.rb3.setChecked(true);
            binding.rb4.setChecked(false);
            if (viewModel.oldConfig.getEndCount() == 0) {
                viewModel.oldConfig.setEndCount(10);
            }
            binding.tvCurrenceTime.setText(viewModel.oldConfig.getEndCount() + "");
            binding.tvEndsDate.setText(TimeUtils.timestampToString(viewModel.oldConfig.getEndDate(), "MMM d ，yyyy"));
            oldEndTimeFromWebView = viewModel.oldConfig.getEndDate();
            endTimeFromWebView = viewModel.oldConfig.getEndDate();
        } else if (viewModel.oldConfig.getEndType() == 2) {

            if (viewModel.scheduleConfigEntity.getLessonType().get_package() == 0) {
                binding.swEnd.setToggleOn();
                binding.linEnd.setVisibility(View.VISIBLE);
                binding.rb3.setChecked(false);
                binding.rb4.setChecked(true);
                binding.tvCurrenceTime.setText(viewModel.oldConfig.getEndCount() + "");
                if (viewModel.oldConfig.getEndDate() == 0) {
                    if (viewModel.oldConfig.getStartDateTime() > (System.currentTimeMillis() / 1000)) {
                        viewModel.oldConfig.setEndDate((int) (com.spelist.tunekey.utils.TimeUtils.addMonth(viewModel.oldConfig.getStartDateTime() * 1000L, 1) / 1000L));
                    } else {
                        viewModel.oldConfig.setEndDate((int) (com.spelist.tunekey.utils.TimeUtils.addMonth(System.currentTimeMillis(), 1) / 1000L));
                    }
                }
                binding.tvEndsDate.setText(TimeUtils.timestampToString(viewModel.oldConfig.getEndDate(), "MMM d ，yyyy"));
            }
            oldEndTimeFromWebView = viewModel.oldConfig.getEndDate();
            endTimeFromWebView = viewModel.oldConfig.getEndDate();
        }
        viewModel.scheduleConfigEntity = CloneObjectUtils.cloneObject(viewModel.oldConfig);
        int diff = com.spelist.tunekey.utils.TimeUtils.getUTCWeekdayDiff(viewModel.oldConfig.getStartDateTime() * 1000L);
        List<Integer> weekDays = new ArrayList<>();
        for (Integer integer : viewModel.oldConfig.getRepeatTypeWeekDay()) {
            int i = integer + (-diff);
            if (i < 0) {
                i = 6;
            } else if (i > 6) {
                i = 0;
            }
            weekDays.add(i);
        }
        viewModel.scheduleConfigEntity.setRepeatTypeWeekDay(weekDays);
    }

    private void showEndDialog() {
        endDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        WebView webView1 = contentView.findViewById(R.id.web_view);
        submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.html");
        WebHost webHost1 = new WebHost(this, this);
        webView1.addJavascriptInterface(webHost1, "js");
        String endDate = TimeUtils.timestampToString(endTimeFromWebView, "yyyy/MM/dd");
        String startDate = TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd");
        webView1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView1.evaluateJavascript("getCalendarStartYMD('" + startDate + "','" + endDate + "')", s -> {
                });

            }

        });
        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                submitButton1 = null;
                endDialog.dismiss();
            }
        });
        submitButton1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                endTimeFromWebView = oldEndTimeFromWebView;
                viewModel.scheduleConfigEntity.setEndDate((int) (endTimeFromWebView));
                binding.tvEndsDate.setText(TimeUtils.timestampToString(endTimeFromWebView, "MMM d ，yyyy"));
                submitButton1 = null;
                endDialog.dismiss();
            }
        });
        endDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        endDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        endDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        endDialog.show();//显示弹窗
    }

    public void showStartTimeV2() {
        LessonScheduleConfigEntity lessonScheduleConfigEntity = new LessonScheduleConfigEntity();
        lessonScheduleConfigEntity.setStudentId(viewModel.studentListEntity.studentId);
        lessonScheduleConfigEntity.setTeacherId(viewModel.teacherUserId.get());
        lessonScheduleConfigEntity.setLocation(viewModel.selectLocation);
        lessonScheduleConfigEntity.setStartDateTime(viewModel.startTime1);
        lessonScheduleConfigEntity.setLessonType(viewModel.scheduleConfigEntity.lessonType);

        SelectLessonV2Dialog.Type type;
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            type = SelectLessonV2Dialog.Type.TEACHER_SHOW;
        } else {
            type = SelectLessonV2Dialog.Type.STUDIO_SHOW;
        }


        SelectLessonV2Dialog dialog = new SelectLessonV2Dialog(this, type, this, viewModel, null, lessonScheduleConfigEntity, false);
        dialog.showDialog();
        dialog.setClickConfirm(data -> {
            dialog.getTimeUtils.close();
            dialog.getTimeUtils = null;
            // select location 的地方需要更改
            Logger.e("==>%s", SLJsonUtils.toJsonString(data));
            dialog.dismiss();
//            viewModel.sentRescheduleV2("", lessonScheduleEntities, data);
            startTimeFromWebView = data.getSelectedTimestamp();
            if (!data.getId().equals("SetLater")) {
                viewModel.selectLocation = data.toTKLocation();
                viewModel.locationString.set(viewModel.selectLocation.getTkString());
            } else {
                viewModel.selectLocation = new TKLocation();
                viewModel.locationString.set("No Location");
            }


            viewModel.startTimeString.set(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
            viewModel.getStartTime((int) startTimeFromWebView);
            binding.linRecurrence.setVisibility(View.VISIBLE);
            binding.memoLayout.setVisibility(View.VISIBLE);
            long time = startTimeFromWebView * 1000L;
            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
            endTimeFromWebView = endTim / 1000L;
            oldEndTimeFromWebView = endTim / 1000L;
            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
            binding.tvEndsDate.setText(TimeUtils.getDateForMMMTime(endTim));

            startWebView = null;
            binding.submitButton.setEnabled(true);
            binding.confirmConfirmButton.setEnabled(true);
//            String weekAndDay = "On" + " " + getWeek(time) + " " + TimeUtils.getDate(time);
//            String lastWeek = "On the last " + TimeUtils.getDate(time);
//            //判断是否是本月最后一周
//            if (isLastDayOfMonth(time)) {
//                binding.month1.setText(lastWeek);
//                viewModel.getRepeatTypeMonthDay(2);
//            } else {
//                binding.month1.setText(weekAndDay);
//                viewModel.getRepeatTypeMonthDay(1);
//            }
//            if (isLastDayOfMonth(time)) {
//                viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(time)));
//            } else {
//                viewModel.setRepeatTypeMonthType(getWeek(time).substring(0, 1) + ":" + TimeUtils.getDay(time));
//            }
            refreshData(false);

            return null;
        });
    }

    public void showStartTime() {

        String oldConfigId = "NO";
        if (viewModel.oldConfig != null && viewModel.oldConfig.getId() != null) {
            oldConfigId = viewModel.oldConfig.getId();
        }
        Logger.e("startTimeFromWebView==>%s", startTimeFromWebView);
        long t = 0;
        if (startTimeFromWebView > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
            t = startTimeFromWebView * 1000L;
        }
        SelectLessonDialog.Builder builder = new SelectLessonDialog.Builder(this)
                .create(UserService.getInstance().getCurrentUserId(),
                        t,
                        lessonMinuteLength, oldConfigId);
        builder.clickConfirm(tkButton -> {
//            builder.selectTime;
//            showSendMessage(lessonScheduleEntities, builder.getSelectTime() + "");
            startTimeFromWebView = builder.getSelectTime();
//            binding.tvStartTime.setText(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
            viewModel.startTimeString.set(TimeUtils.timestampToString(startTimeFromWebView, "yyyy/MM/dd hh:mm aaa"));
            viewModel.getStartTime((int) startTimeFromWebView);
            binding.linRecurrence.setVisibility(View.VISIBLE);
            binding.memoLayout.setVisibility(View.VISIBLE);
            long time = startTimeFromWebView * 1000L;
            long endTim = com.spelist.tunekey.utils.TimeUtils.addMonth(time, 1);
            endTimeFromWebView = endTim / 1000L;
            oldEndTimeFromWebView = endTim / 1000L;
            viewModel.scheduleConfigEntity.setEndDate((int) (endTim / 1000L));
            binding.tvEndsDate.setText(TimeUtils.getDateForMMMTime(endTim));

            startWebView = null;
            binding.submitButton.setEnabled(true);
            binding.confirmConfirmButton.setEnabled(true);
//            String weekAndDay = "On" + " " + getWeek(time) + " " + TimeUtils.getDate(time);
//            String lastWeek = "On the last " + TimeUtils.getDate(time);
//            //判断是否是本月最后一周
//            if (isLastDayOfMonth(time)) {
//                binding.month1.setText(lastWeek);
//                viewModel.getRepeatTypeMonthDay(2);
//            } else {
//                binding.month1.setText(weekAndDay);
//                viewModel.getRepeatTypeMonthDay(1);
//            }
//            if (isLastDayOfMonth(time)) {
//                viewModel.setRepeatTypeMonthType(String.valueOf(TimeUtils.getDay(time)));
//            } else {
//                viewModel.setRepeatTypeMonthType(getWeek(time).substring(0, 1) + ":" + TimeUtils.getDay(time));
//            }
            int dayOfWeek = com.spelist.tunekey.utils.TimeUtils.getDayOfWeek(startTimeFromWebView * 1000L) - 1;
            viewModel.clearRepeatTypeWeekDay();
            viewModel.scheduleConfigEntity.getRepeatTypeWeekDay().clear();
            viewModel.weekList.clear();
            viewModel.biWeekList.clear();
            viewModel.setRepeatTypeWeekDay(dayOfWeek);

            refreshData(false);
            builder.dismiss();
        });

    }

    public void getWebViewStartTime(int startTime) {
//        this.runOnUiThread(() -> {
//            if (submitButton != null) {
//                oldStartTimeFromWebView = startTime;
//
//                if (oldStartTimeFromWebView == 0) {
//                    submitButton.setButtonStatus(1);
//                } else {
//                    submitButton.setButtonStatus(0);
//                }
//            }
//        });
    }

    public void changeCalendarTime(long startTime) {
        viewModel.changeCalendarTime(startTime);
    }

    public void getWebViewEndTime(String endTime) {
        Logger.e("======%s", endTime);
        this.runOnUiThread(() -> {
            if (submitButton1 != null) {
                long timeStamp = TimeUtils.getStringToDate(endTime, "yyyy-MM-dd") / 1000L;
                viewModel.scheduleConfigEntity.setEndDate((int) timeStamp);
                oldEndTimeFromWebView = timeStamp;
                if (oldEndTimeFromWebView == 0) {
                    submitButton1.setButtonStatus(1);
                } else {
                    submitButton1.setButtonStatus(0);
                }
            }
//        if (endTimeFromWebView.equals("")) {
//            submitButton1.setButtonStatus(1);
//        } else {
//            submitButton1.setButtonStatus(0);
//        }
        });
    }

    public void showUpPop() {
        bottomDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.schedue_toast, null);
        //获取Dialog的监听

        InputView text = contentView.findViewById(R.id.tv_name);
        TextView confirm = (TextView) contentView.findViewById(R.id.tv_confirm);
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        if (!text.getInputText().equals("10")) {
            text.setInputText((String) binding.tvCurrenceTime.getText());
        } else {
            text.setInputText("10");
        }
        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
                }
            }
        });

        confirm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (text.getInputText().length() > 0) {
                    binding.tvCurrenceTime.setText(text.getInputText());
                    viewModel.scheduleConfigEntity.setEndCount(Integer.parseInt(text.getInputText()));
                    if (bottomDialog.isShowing()) {
                        bottomDialog.dismiss();
                    }
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

    @SuppressLint("SetTextI18n")
    private void initSpecial(double price, double lessonTypePrice) {
        if (price == lessonTypePrice) {
            binding.priceSpecial.setText("Original $" + FuncUtils.doubleTrans(lessonTypePrice) + ", 0% off");
        } else {
            double v = (lessonTypePrice - price) / lessonTypePrice * 100;
            binding.priceSpecial.setText("Original $" + FuncUtils.doubleTrans(lessonTypePrice) + ", " + FuncUtils.doubleTrans(v) + "% off");
        }
        if (price == 0) {
            viewModel.specialPrice = -1;
        } else {
            viewModel.specialPrice = price;
        }

    }

}
