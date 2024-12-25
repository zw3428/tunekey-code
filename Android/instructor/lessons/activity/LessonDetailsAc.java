package com.spelist.tunekey.ui.teacher.lessons.activity;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.FragmentManager;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.PagerSnapHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.lihang.ShadowLayout;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.countDownView.CountDownInterface;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKButton;
import com.spelist.tunekey.customView.TextEnlargementDialog;
import com.spelist.tunekey.customView.dialog.AttendanceDoneDialog;
import com.spelist.tunekey.customView.dialog.LessonDetailsMoreDialog;
import com.spelist.tunekey.customView.dialog.NoShowDialog;
import com.spelist.tunekey.customView.dialog.ReportNoShowDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.ThreeButtonDialog;
import com.spelist.tunekey.customView.dialog.selectLessonV2.SelectLessonV2Dialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.dao.AppDataBase;
import com.spelist.tunekey.databinding.ActivityLessonDetailsBinding;
import com.spelist.tunekey.databinding.ItemLessonBeforeBinding;
import com.spelist.tunekey.databinding.ItemLessonBeforeV2Binding;
import com.spelist.tunekey.entity.AchievementEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonSchedulePlanEntity;
import com.spelist.tunekey.entity.LessonScheduleExEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKRoleAndAccess;
import com.spelist.tunekey.entity.TeacherInfoEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.studio.calendar.calendarHome.dialog.LessonToEmailDialog;
import com.spelist.tunekey.ui.studio.calendar.followUp.StudioFollowUpAc;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonAchievementItemViewModel;

import com.spelist.tunekey.ui.teacher.lessons.dialog.reschedule.RescheduleAllAndUpcomingDialog;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonDetailsVM;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonHomeworkItemViewModel;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonPlanItemViewModel;
import com.spelist.tunekey.ui.teacher.materials.MaterialsHelp;
import com.spelist.tunekey.ui.teacher.materials.activity.MaterialsActivity;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerAdapter;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerHolder;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TKUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function2;
import me.goldze.mvvmhabit.base.BaseActivity;
import me.goldze.mvvmhabit.utils.UIUtils;
import me.jessyan.autosize.utils.AutoSizeUtils;

public class LessonDetailsAc extends BaseActivity<ActivityLessonDetailsBinding, LessonDetailsVM> {
    private LinearLayoutManager linearLayoutManager;
    private BaseViewBindingRecyclerAdapter<LessonScheduleEntity> adapter;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_lesson_details;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        List<LessonScheduleEntity> data = (List<LessonScheduleEntity>) getIntent().getSerializableExtra("data");
        viewModel.nowLesson = (LessonScheduleEntity) getIntent().getSerializableExtra("nowLesson");
        viewModel.checkClassNow();

        long nowTime = System.currentTimeMillis() / 1000L;
        String teacherName = "";
        if (!TKUtils.INSTANCE.currentUserIsStudio()) {
            UserEntity currentUserData = SLCacheUtil.getCurrentUserData(UserService.getInstance().getCurrentUserId());
            if (currentUserData != null) {
                teacherName = currentUserData.getName();
            }
        }
        List<LessonTypeEntity> lessonTypeData = new ArrayList<>();
        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            lessonTypeData = ListenerService.shared.teacherData.getLessonTypes();
        } else {
            lessonTypeData = ListenerService.shared.studioData.lessonTypesData;
        }
        for (LessonScheduleEntity lessonScheduleEntity : data) {
            long timeLength = lessonScheduleEntity.getShouldTimeLength() * 60L;
            long entTime = lessonScheduleEntity.getTKShouldDateTime() + timeLength;
            if ((nowTime > lessonScheduleEntity.getTKShouldDateTime() && entTime > nowTime) && lessonScheduleEntity.getLessonStatus() == 0) {
                lessonScheduleEntity.setLessonStatus(1);
            } else if (nowTime > entTime) {
                lessonScheduleEntity.setLessonStatus(2);
            }
            if (TKUtils.INSTANCE.currentUserIsStudio()) {
                String teacherId = lessonScheduleEntity.getTeacherId();
                TeacherInfoEntity teacher = AppDataBase.getInstance().teacherInfoDao().getByUserId(teacherId);
                if (teacher.getUserData() != null) {
                    lessonScheduleEntity.setTeacherName(teacher.getUserData().getName());
                }
            } else {
                lessonScheduleEntity.setTeacherName(teacherName);
            }
            if (lessonScheduleEntity.getLessonType().getId() == null) {
                continue;
            }
            if (lessonScheduleEntity.getLessonType() == null || lessonScheduleEntity.getLessonType().getId().equals("")) {
                for (LessonTypeEntity lessonTypeDatum : lessonTypeData) {
                    if (lessonTypeDatum.getId().equals(lessonScheduleEntity.getLessonTypeId())) {
                        lessonScheduleEntity.setLessonType(lessonTypeDatum);
                        break;
                    }
                }
            }
        }
        viewModel.data.set(data);
        adapter.refreshData(data);
        viewModel.selectIndex.setValue(getIntent().getIntExtra("selectIndex", 0));
        viewModel.titleString.setValue(TimeUtils.timeFormat(getIntent().getLongExtra("selectTime", 0), "hh:mm a, MMM d"));
        viewModel.initData();
        linearLayoutManager.findFirstCompletelyVisibleItemPosition();
        linearLayoutManager.scrollToPosition(viewModel.selectIndex.getValue());
//        linearLayoutManager.scrollToPositionWithOffset(viewModel.selectIndex.getValue(), 10);
    }

    @Override
    public void initView() {
        super.initView();

        binding.recordAttendance.setOnClickListener(view -> {
            BottomMenuFragment dialog = new BottomMenuFragment(this);
            dialog.addMenuItems(new MenuItem("Present"));
            dialog.addMenuItems(new MenuItem("Excused"));
            dialog.addMenuItems(new MenuItem("Unexcused"));
            dialog.addMenuItems(new MenuItem("Late"));
            dialog.show();
            dialog.setOnItemClickListener((menu_item, position) -> {
                int type = LessonScheduleExEntity.Type.PRESENT;
                switch (position) {
                    case 0:
                        type = LessonScheduleExEntity.Type.PRESENT;
                        break;
                    case 1:
                        type = LessonScheduleExEntity.Type.EXCUSED;
                        break;
                    case 2:
                        type = LessonScheduleExEntity.Type.UNEXCUSED;
                        break;
                    case 3:
                        type = LessonScheduleExEntity.Type.LATE;
                        break;
                }

                viewModel.updateAttendance(type);
            });
        });
        linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
        binding.rvStudentInfo.setLayoutManager(linearLayoutManager);
        binding.rvLessonPlan.setLayoutManager(new LinearLayoutManager(this));
        viewModel.gridLayoutManager.set(new GridLayoutManager(this, 3));
        binding.rvAchievement.setLayoutManager(new LinearLayoutManager(this));
        binding.rvHomework.setLayoutManager(new LinearLayoutManager(this));
        binding.rvNextPlan.setLayoutManager(new LinearLayoutManager(this));


        binding.rvStudentInfo.setItemAnimator(null);
        binding.rvLessonPlan.setItemAnimator(null);
        binding.rvAddMaterials.setItemAnimator(null);
        binding.rvAchievement.setItemAnimator(null);
        binding.rvHomework.setItemAnimator(null);
        binding.rvNextPlan.setItemAnimator(null);


        PagerSnapHelper snapHelper = new PagerSnapHelper();
        snapHelper.attachToRecyclerView(binding.rvStudentInfo);
        binding.dotView.attachToRecyclerView(binding.rvStudentInfo, snapHelper);
        binding.rvStudentInfo.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                if (newState == RecyclerView.SCROLL_STATE_IDLE) {//如果滚动结束
                    View snapView = snapHelper.findSnapView(linearLayoutManager);
                    int currentPageIndex = linearLayoutManager.getPosition(snapView);
                    if (viewModel.selectIndex.getValue() != currentPageIndex) {//防止重复提示
                        viewModel.selectIndex.setValue(currentPageIndex);
                    }
                }
            }
        });
//        binding.rvStudentInfo.getAdapter().registerAdapterDataObserver(binding.dotView.getAdapterDataObserver());

        binding.countDownView.setTypeFace(ResourcesCompat.getFont(this, R.font.helvetica_neue_bold));
        binding.countDownLayout.setOnClickListener(v -> {
            if (viewModel.nowLesson == null) {
                return;
            }

            Intent intent = new Intent(this, LessonCountDownActivity.class);
            intent.putExtra("data", viewModel.nowLesson);
            startActivity(intent);
            overridePendingTransition(R.anim.zoom_in, R.anim.zoom_out);
            viewModel.isShowCountDownView.set(false);
        });

        binding.countDownView.setOnTick(new CountDownInterface() {
            @Override
            public void onTick(long time) {
                if (time == 0) {
                    Logger.e("======%s", "时间到了1");
                    runOnUiThread(() -> {
                        viewModel.isShowCountDownView.set(false);
                        viewModel.nowLesson = null;
                        viewModel.checkClassNow();
                    });
                }
            }

            @Override
            public void onFinish() {
                //时间到了
                Logger.e("======%s", "时间到了" + TimeUtils.getCurrentTime());
                new Handler().postDelayed(() -> {
                    viewModel.isShowCountDownView.set(false);
                    viewModel.nowLesson = null;
                    viewModel.checkClassNow();
                }, 1000);


            }
        });
        binding.studentNoteLayout.setOnClickListener(v -> {
            if (viewModel.selectData != null && viewModel.selectData.getValue() != null) {
                TextEnlargementDialog dialogFragment = TextEnlargementDialog.newInstance(viewModel.selectData.getValue().getStudentNote());
                FragmentManager fragmentManager = getSupportFragmentManager();
                dialogFragment.show(fragmentManager, "1234");
            }
        });
        adapter = new BaseViewBindingRecyclerAdapter<LessonScheduleEntity>(this, viewModel.data.get(), R.layout.item_lesson_before_v2) {
            @Override
            public void convert(BaseViewBindingRecyclerHolder holder, LessonScheduleEntity data, int position, boolean isScrolling) {
                if (holder.getBinding() instanceof ItemLessonBeforeV2Binding) {
                    ItemLessonBeforeV2Binding binding = (ItemLessonBeforeV2Binding) holder.getBinding();
                    if (data.getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
                        binding.avatarView.setLessonTypeImg(data.getLessonType().getInstrumentUrl());
                        binding.name.setText(data.getLessonType().getName());
                        binding.info.setText(data.getDetailedInfo());
                        binding.studentSize.setVisibility(View.VISIBLE);
                        List<String> ids = new ArrayList<>();
                        for (Map.Entry<String, LessonScheduleConfigEntity.GroupLessonStudent> entry : data.getGroupLessonStudents().entrySet()) {
                            LessonScheduleConfigEntity.GroupLessonStudent value = SLJsonUtils.toBean(SLJsonUtils.toJsonString(entry.getValue()), LessonScheduleConfigEntity.GroupLessonStudent.class);
                            if (value.getRegistrationTimestamp() <= data.getShouldDateTime()) {
                                ids.add(entry.getKey());
                            }
                        }


                        binding.studentSize.setText(ids.size() + " students");
                    } else {
                        binding.avatarView.loadAvatar(data.getStudentId(), data.getStudentName(), 0);
                        binding.name.setText(data.getStudentName());
                        binding.info.setText(data.getDetailedInfo());
                        binding.studentSize.setVisibility(View.GONE);
                    }

                    binding.teacherLayout.setVisibility(View.GONE);
                    binding.locationView.setVisibility(View.GONE);
                    try {
                        if (data.getLocation() != null && !data.getLocation().getId().equals("")) {
                            binding.locationView.setVisibility(View.VISIBLE);
                            binding.locationView.setText(data.getLocation().getTkString());
                        } else {
//                            binding.locationView.setVisibility(View.VISIBLE);
//                            binding.locationView.setText("Add Location");
                        }

                        if (data.getTeacherName().equals("")) {
                            if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                                UserEntity currentUserData = SLCacheUtil.getCurrentUserData(SLCacheUtil.getCurrentUserId());
                                if (currentUserData != null) {
                                    binding.teacherLayout.setVisibility(View.VISIBLE);
                                    binding.teacherName.setText(currentUserData.getName());
                                    binding.teacherAvatarView.loadAvatar(currentUserData.getUserId(), currentUserData.getName(), 1);
                                }
                            } else {
                                TeacherInfoEntity teacherInfo = AppDataBase.getInstance().teacherInfoDao().getByUserId(data.getTeacherId());
                                if (teacherInfo != null && teacherInfo.getUserData() != null) {
                                    binding.teacherLayout.setVisibility(View.VISIBLE);
                                    binding.teacherName.setText(teacherInfo.getUserData().getName());
                                    binding.teacherAvatarView.loadAvatar(teacherInfo.getUserData().getUserId(), teacherInfo.getUserData().getName(), 1);
                                }
                            }
                        } else {
                            binding.teacherLayout.setVisibility(View.VISIBLE);
                            binding.teacherName.setText(data.getTeacherName());
                            binding.teacherAvatarView.loadAvatar(data.getTeacherId(), data.getTeacherName(), 1);
                        }
                    } catch (Throwable e) {

                    }


                    ShadowLayout mainLayout = holder.getView(R.id.mainLayout);
                    if (viewModel.data.get() != null) {
                        FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) mainLayout.getLayoutParams();
                        if (viewModel.data.get().size() == 1) {
                            int screenWidth = UIUtils.getScreenWidth(LessonDetailsAc.this);
                            layoutParams.width = screenWidth - AutoSizeUtils.pt2px(LessonDetailsAc.this, 40f);
                            mainLayout.setPadding(0, 0, 0, AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f));
                        } else {
                            layoutParams.width = AutoSizeUtils.pt2px(LessonDetailsAc.this, 295f);
                            if (position == 0) {
                                mainLayout.setPadding(0, 0, AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f), AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f));
                            } else if (position == viewModel.data.get().size() - 1) {
                                mainLayout.setPadding(AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f), 0, 0, AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f));
                            } else {
                                mainLayout.setPadding(AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f), 0, AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f), AutoSizeUtils.pt2px(LessonDetailsAc.this, 10f));
                            }

                        }
                        mainLayout.setLayoutParams(layoutParams);
                    }
                }
            }
        }

        ;
        binding.rvStudentInfo.setAdapter(adapter);
        adapter.setOnItemClickListener(new BaseViewBindingRecyclerAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(RecyclerView parent, View view, int position) {

                if (viewModel.selectData == null || viewModel.selectData.getValue() == null) {
                    return;
                }
                if (viewModel.selectData.getValue().getLessonCategory() == LessonTypeEntity.TKLessonCategory.group) {
                    viewModel.clickGroupStudent();
                } else {
                    viewModel.clickStudent();
                }
            }
        });
        adapter.registerAdapterDataObserver(binding.dotView.getAdapterDataObserver());

    }


    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.showShareLesson.observe(this, link -> {
            Intent sendIntent = new Intent();
            sendIntent.setAction(Intent.ACTION_SEND);
            sendIntent.putExtra(Intent.EXTRA_TEXT, link);
            sendIntent.setType("text/plain");
            Intent shareIntent = Intent.createChooser(sendIntent, null);
            startActivity(shareIntent);
        });
        viewModel.uc.attendanceDone.observe(this, unused -> {
            AttendanceDoneDialog dialog = new AttendanceDoneDialog(this);
            dialog.showDialog();
            dialog.setClickFollowUp(() -> {
                Bundle bundle = new Bundle();
                bundle.putInt("pos", 1);
                startActivity(StudioFollowUpAc.class, bundle);
                finish();
                return null;
            });
        });
        viewModel.uc.clickNoShow.observe(this, unused -> {
//            NoShowDialog dialog = new NoShowDialog(this, false, false);
//            dialog.showDialog();
//            dialog.setClickConfirm((aBoolean, s) -> {
//                viewModel.retractNoShow(s);
//                return null;
//            });


            BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(this);
            bottomMenuFragment.addMenuItems(new MenuItem("No-Show"));
            bottomMenuFragment.addMenuItems(new MenuItem("Late"));
            bottomMenuFragment.addMenuItems(new MenuItem("Present"));
            bottomMenuFragment.show();

            bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                if (menu_item.getText().equals("Present")) {
                    viewModel.retractLateAndPresent("Present");
                } else if (menu_item.getText().equals("Late")) {
                    viewModel.retractLateAndPresent("Late");
                } else if (menu_item.getText().equals("No-Show")) {
                    ReportNoShowDialog dialog = new ReportNoShowDialog(this);
                    dialog.showDialog();
                    dialog.setClickConfirm(s -> {
                        viewModel.retractNoShow(s);
                        return null;
                    });
                }

            });


        });

        viewModel.uc.clickMore.observe(this, unused -> {
//            if (viewModel.selectData.getValue().lessonCategory == LessonTypeEntity.TKLessonCategory.group) {
//                BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(this);
//                bottomMenuFragment.addMenuItems(new MenuItem("Share group lesson"));
//                bottomMenuFragment.show();
//                bottomMenuFragment.setOnItemClickListener((menu_item, position) -> viewModel.getShareLink(viewModel.selectData.getValue().getLessonScheduleConfigId()));
//               return;
//            }
            boolean isCanReschedule = false;
            boolean isCanCancelLesson = false;
            if (viewModel.isSureRescheduleAndCancel) {
                if (viewModel.isCanReschedule) {
                    isCanReschedule = true;
                }
                if (viewModel.isCanCancelLesson) {
                    isCanCancelLesson = true;
                }
            }
            if (!isCanCancelLesson && !isCanReschedule) {
                return;
            }

            LessonDetailsMoreDialog bottomDialog = new LessonDetailsMoreDialog(this, isCanReschedule, isCanCancelLesson,viewModel.selectData.getValue().lessonCategory == LessonTypeEntity.TKLessonCategory.group);
            bottomDialog.showDialog();
            bottomDialog.setClickShareGroupLesson((Function0<Unit>) () -> {
                viewModel.getShareLink(viewModel.selectData.getValue().getLessonScheduleConfigId());
                return null;
            });
            bottomDialog.setClickReschedule(() -> {
                BottomMenuFragment rescheduleMenu = new BottomMenuFragment(this)
                        .addMenuItems(new MenuItem("This lesson"));
                if (viewModel.selectData.getValue() != null && viewModel.selectData.getValue().getConfigEntity() != null && viewModel.selectData.getValue().getConfigEntity().getRepeatType() != 0) {
                    rescheduleMenu.addMenuItems(new MenuItem("This & following lessons"));
                    rescheduleMenu.addMenuItems(new MenuItem("All lessons"));
                }
                rescheduleMenu.show();
                rescheduleMenu.setOnItemClickListener((rescheduleMenu_item, rescheduleMenuPosition) -> {
                    if (rescheduleMenu_item.getText().toString().equals("This lesson")) {
//                        viewModel.clickReschedule();
                        clickThisReschedule();
                    } else if (rescheduleMenu_item.getText().toString().equals("This & following lessons") || rescheduleMenu_item.getText().toString().equals("All lessons")) {
                        showRescheduleAllAndUpcomingDialog(rescheduleMenu_item.getText().toString());
                    }
                });
                return null;
            });
            bottomDialog.setClickCancelLesson(() -> {
                BottomMenuFragment rescheduleMenu = new BottomMenuFragment(this)
                        .addMenuItems(new MenuItem("This lesson"));
                if (viewModel.selectData.getValue() != null && viewModel.selectData.getValue().getConfigEntity() != null && viewModel.selectData.getValue().getConfigEntity().getRepeatType() != 0) {
                    rescheduleMenu.addMenuItems(new MenuItem("This & following lessons"));
                    rescheduleMenu.addMenuItems(new MenuItem("All lessons"));
                }
                rescheduleMenu.show();
                rescheduleMenu.setOnItemClickListener((rescheduleMenu_item, rescheduleMenuPosition) -> {

                    if (rescheduleMenu_item.getText().toString().equals("This lesson")) {
                        Logger.e("Sdsdsdsd==>%s","sdsdsd");
                        Dialog dialog = SLDialogUtils.showTwoButton(this, "Cancel lesson?", "Are you sure to cancel this lesson?", "Go back", "I’m sure");
                        TextView rightButton = (TextView) dialog.findViewById(R.id.right_button);
                        rightButton.setOnClickListener(v -> {
                            if (viewModel.selectData.getValue().lessonCategory == LessonTypeEntity.TKLessonCategory.group){
                                viewModel.clickGroupCancelLesson(rescheduleMenu_item.getText().toString());
                            }else {
                                viewModel.clickThisCancelLessonV2();
                            }


                            dialog.dismiss();

                        });

                    } else if (rescheduleMenu_item.getText().toString().equals("This & following lessons") || rescheduleMenu_item.getText().toString().equals("All lessons")) {
                        if (viewModel.selectData.getValue() == null) {
                            return;
                        }
                        LessonScheduleConfigEntity configEntity = viewModel.selectData.getValue().getConfigEntity();
                        if (configEntity == null && ListenerService.shared.teacherData != null && ListenerService.shared.teacherData.getScheduleConfigs() != null) {
                            for (LessonScheduleConfigEntity scheduleConfig : ListenerService.shared.teacherData.getScheduleConfigs()) {
                                if (viewModel.selectData.getValue().getLessonScheduleConfigId().equals(scheduleConfig.getId())) {
                                    configEntity = scheduleConfig;
                                    break;
                                }
                            }
                        }
                        String info = "Are you sure to cancel all lessons?";
                        if (rescheduleMenu_item.getText().toString().equals("This & following lessons")) {
                            info = "Are you sure to cancel this and following lessons?";
                        }

                        LessonScheduleConfigEntity finalConfigEntity = configEntity;

                        Dialog dialog = SLDialogUtils.showTwoButton(this, "Cancel lesson?", info, "Go back", "I’m sure");
                        TextView rightButton = (TextView) dialog.findViewById(R.id.right_button);
                        rightButton.setOnClickListener(v -> {
                            if (viewModel.selectData.getValue().lessonCategory == LessonTypeEntity.TKLessonCategory.group){
                                viewModel.clickGroupCancelLesson(rescheduleMenu_item.getText().toString());
                            }else {
                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLesson(rescheduleMenu_item.getText().toString(), finalConfigEntity, viewModel.selectData.getValue());
                            }

                            dialog.dismiss();
                        });
                    }
                });

                return null;
            });
            bottomDialog.setClickTimer(() -> {
                return null;
            });
            bottomDialog.setClickMetronome(() -> {
                return null;
            });
            bottomDialog.setClickTuner(() -> {
                return null;
            });
            bottomDialog.setClickWhiteboard(() -> {
                return null;
            });

//
//            BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(this)
////                    .addMenuItems(new MenuItem("Share"))
//                    .addMenuItems(new MenuItem("Student Balance"));
//            if (viewModel.isSureRescheduleAndCancel) {
//                if (viewModel.isCanReschedule) {
//                    bottomMenuFragment.addMenuItems(new MenuItem("Reschedule"));
//                }
//                if (viewModel.isCanCancelLesson) {
//                    bottomMenuFragment.addMenuItems(new MenuItem("Cancel Lesson", ContextCompat.getColor(this, R.color.red)));
//                }
//            }
//
//            bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
//                if (menu_item.getText().equals("Reschedule")) {
//                    BottomMenuFragment rescheduleMenu = new BottomMenuFragment(this)
//                            .addMenuItems(new MenuItem("This lesson"));
//                    if (viewModel.selectData.getValue() != null && viewModel.selectData.getValue().getConfigEntity() != null && viewModel.selectData.getValue().getConfigEntity().getRepeatType() != 0) {
//                        rescheduleMenu.addMenuItems(new MenuItem("This & following lessons"));
//                        rescheduleMenu.addMenuItems(new MenuItem("All lessons"));
//                    }
//                    rescheduleMenu.show();
//                    rescheduleMenu.setOnItemClickListener((rescheduleMenu_item, rescheduleMenuPosition) -> {
//                        if (rescheduleMenu_item.getText().toString().equals("This lesson")) {
//                            viewModel.clickReschedule();
//                        } else if (rescheduleMenu_item.getText().toString().equals("This & following lessons") || rescheduleMenu_item.getText().toString().equals("All lessons")) {
//                            showRescheduleAllAndUpcomingDialog(rescheduleMenu_item.getText().toString());
//                        }
//                    });
//
//                } else if (menu_item.getText().equals("Cancel Lesson")) {
//                    BottomMenuFragment rescheduleMenu = new BottomMenuFragment(this)
//                            .addMenuItems(new MenuItem("This lesson"));
//                    if (viewModel.selectData.getValue() != null && viewModel.selectData.getValue().getConfigEntity() != null && viewModel.selectData.getValue().getConfigEntity().getRepeatType() != 0) {
//                        rescheduleMenu.addMenuItems(new MenuItem("This & following lessons"));
//                        rescheduleMenu.addMenuItems(new MenuItem("All lessons"));
//                    }
//                    rescheduleMenu.show();
//                    rescheduleMenu.setOnItemClickListener((rescheduleMenu_item, rescheduleMenuPosition) -> {
//                        if (rescheduleMenu_item.getText().toString().equals("This lesson")) {
////<<<<<<< HEAD
////                            Dialog dialog = SLDialogUtils.showTwoButtonSmallButton(this, "Cancel lesson?", "Are you sure to cancel this lesson?", "Cancel\nanyways", "Go back");
////                            TextView leftButton = dialog.findViewById(R.id.left_button);
////                            leftButton.setTextColor(ContextCompat.getColor(this, R.color.red));
////                            leftButton.setOnClickListener(view -> {
//////                                viewModel.clickCancelLesson();
////                                viewModel.clickThisCancelLessonV2();
////=======
//////                            Dialog dialog = SLDialogUtils.showTwoButtonSmallButton(this, "Cancel lesson?", "Are you sure to cancel this lesson?", "Cancel\nanyways", "Go back");
//////                            TextView leftButton = dialog.findViewById(R.id.left_button);
//////                            leftButton.setTextColor(ContextCompat.getColor(this, R.color.red));
//////                            leftButton.setOnClickListener(view -> {
//////                                viewModel.clickCancelLesson();
//////                                dialog.dismiss();
//////                            });
//////                            dialog.show();
//                            Dialog dialog = SLDialogUtils.showTwoButton(this, "Cancel lesson?", "Are you sure to cancel this lesson?", "Go back", "I’m sure");
//                            TextView rightButton = (TextView) dialog.findViewById(R.id.right_button);
//                            rightButton.setOnClickListener(v -> {
////                                viewModel.clickCancelLesson();
//                                viewModel.clickThisCancelLessonV2();
//                                dialog.dismiss();
//
//                            });
//
//                        } else if (rescheduleMenu_item.getText().toString().equals("This & following lessons") || rescheduleMenu_item.getText().toString().equals("All lessons")) {
////                            showRescheduleAllAndUpcomingDialog(rescheduleMenu_item.getText().toString());
//                            if (viewModel.selectData.getValue() == null) {
//                                return;
//                            }
//                            LessonScheduleConfigEntity configEntity = viewModel.selectData.getValue().getConfigEntity();
//                            if (configEntity == null && ListenerService.shared.teacherData != null && ListenerService.shared.teacherData.getScheduleConfigs() != null) {
//                                for (LessonScheduleConfigEntity scheduleConfig : ListenerService.shared.teacherData.getScheduleConfigs()) {
//                                    if (viewModel.selectData.getValue().getLessonScheduleConfigId().equals(scheduleConfig.getId())) {
//                                        configEntity = scheduleConfig;
//                                        break;
//                                    }
//                                }
//                            }
//                            String info = "Are you sure to cancel all upcoming lessons?";
//                            if (rescheduleMenu_item.getText().toString().equals("This & following lessons")) {
//                                info = "Are you sure to cancel this and following lessons?";
//                            }
//
//
////                            Dialog dialog = SLDialogUtils.showTwoButtonSmallButton(this, "Cancel lesson?", info, "Cancel\nanyways", "Go back");
////                            TextView leftButton = dialog.findViewById(R.id.left_button);
////                            leftButton.setTextColor(ContextCompat.getColor(this, R.color.red));
////                            LessonScheduleConfigEntity finalConfigEntity = configEntity;
////                            leftButton.setOnClickListener(view -> {
////                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLesson(rescheduleMenu_item.getText().toString(), finalConfigEntity,viewModel.selectData.getValue());
////                                dialog.dismiss();
////                            });
////                            dialog.show();
//
//                            LessonScheduleConfigEntity finalConfigEntity = configEntity;
////<<<<<<< HEAD
////                            leftButton.setOnClickListener(view -> {
//////                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLesson(rescheduleMenu_item.getText().toString(), finalConfigEntity, viewModel.selectData.getValue());
////                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLessonV2(rescheduleMenu_item.getText().toString(),viewModel.selectData.getValue());
////=======
//                            Dialog dialog = SLDialogUtils.showTwoButton(this, "Cancel lesson?", info, "Go back", "I’m sure");
//                            TextView rightButton = (TextView) dialog.findViewById(R.id.right_button);
////                    leftButton.setTextColor(ContextCompat.getColor(fragment.getContext(), R.color.red));
//                            rightButton.setOnClickListener(v -> {
//                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLesson(rescheduleMenu_item.getText().toString(), finalConfigEntity, viewModel.selectData.getValue());
////                                viewModel.clickCancelLessonByAllLessonAndThisAndUpcomingLessonV2(rescheduleMenu_item.getText().toString(), viewModel.selectData.getValue());
//
//                                dialog.dismiss();
//                            });
//
//
//                        }
//                    });
//
//                }
////                else if (menu_item.getText().equals("Student Balance")) {
////                    viewModel.toStudentBalance();
////                }
//                else if (menu_item.getText().equals("Share")) {
//                    shareLesson();
//                }
//
//            }).show();
        });

        viewModel.uc.nowLesson.observe(this, lessonScheduleEntity ->

        {
            long endTime = lessonScheduleEntity.getTKShouldDateTime() + (lessonScheduleEntity.getShouldTimeLength() * 60);
            Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.SECOND, (int) (endTime - TimeUtils.getCurrentTime()));
            binding.countDownView.startTimer(calendar);
        });

        //title 更改
        viewModel.titleString.observe(this, s -> viewModel.setTitleString(s));

        //页数更改
        viewModel.selectIndex.observe(this, index -> viewModel.changePage());

        //点击添加lessonPlan
        viewModel.uc.clickAddLessonPlan.observe(this, aVoid ->

                showUpPop(1, "", "", false));

        //点击修改lessonPlan
        viewModel.uc.clickEditLessonPlan.observe(this, map ->

                showUpPop((Integer) map.get("type"), (String) map.get("plan"), (String) map.get("id"), true));

        //点击添加notes
        viewModel.uc.clickAddNotes.observe(this, aVoid ->{
//            showUpPop(2, "", "", false));
            Bundle bundle = new Bundle();
            bundle.putSerializable("data", viewModel.selectData.getValue());
            startActivity(LessonDetailsNoteAc.class, bundle);

        });


        //点击修改notes
        viewModel.uc.clickEditNotes.observe(this, aVoid ->{
//            if (viewModel.selectData != null) {
//                showUpPop(2, viewModel.selectData.getValue().getTeacherNote(), "", true);
//            }
            Bundle bundle = new Bundle();
            bundle.putSerializable("data", viewModel.selectData.getValue());
            startActivity(LessonDetailsNoteAc.class, bundle);
        });


        // materials 数据更新
        viewModel.materialsData.observe(this, multiItemViewModels ->
                viewModel.gridLayoutManager.get().

                        setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                            @Override
                            public int getSpanSize(int position) {
                                if (multiItemViewModels.size() > position) {
                                    if ((int) multiItemViewModels.get(position).getType() == 6) {
                                        return 3;
                                    } else {
                                        return 1;
                                    }
                                }
                                return 1;
                            }
                        }));

        //点击添加AddMaterials
        viewModel.uc.clickAddMaterials.observe(this, aVoid ->

        {
            List<MaterialEntity> materialsData = new ArrayList<>();

             if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
                 materialsData = ListenerService.shared.teacherData.getHomeMaterials();
             } else {
                 materialsData = AppDataBase.getInstance().materialDao().getByCreatorIdFromList(SLCacheUtil.getCurrentUserId());
             }

            Intent intent = new Intent(LessonDetailsAc.this, MaterialsActivity.class);
            intent.putExtra("type", "select");
            intent.putExtra("data", (Serializable) new ArrayList<MaterialEntity>());
            intent.putExtra("selectData", (Serializable) CloneObjectUtils.cloneObject(viewModel.materialsData.getValue()));

            startActivity(intent);
        });

        //点击查看materialsItem
        viewModel.uc.clickMaterialItem.observe(this, map ->

        {
            MaterialEntity entity = (MaterialEntity) map.get("data");
            if (entity.getType() == -2) {
//                replaceFragment(entity);
//                baseTitleViewModel.searchIsVisible.set(false);
//                if (moveItemHelperCallback != null) {
//                    moveItemHelperCallback.setDragIsEnable(true);
//                }
//                binding.titleLayout.searchEditText.setText("");
            } else {
                MaterialsHelp.clickMaterial(map, LessonDetailsAc.this);
            }
        });

        //添加Achievement
        viewModel.uc.clickAddAchievement.observe(this, aVoid ->

                showAchievement(null));
        //修改Achievement
        viewModel.uc.clickAchievementItem.observe(this, this::showAchievement);
        //添加homework
        viewModel.uc.clickAddHomework.observe(this, aVoid ->

        {
            showUpPop(4, "", "", false);
        });
        //修改homework
        viewModel.uc.clickEditHomework.observe(this, data ->

        {
            showUpPop(4, data.getName(), data.getId(), true);

        });
        //添加NextLessonPlan
        viewModel.uc.clickAddNextPlan.observe(this, aVoid ->

        {
            showUpPop(3, "", "", false);
        });

    }

    private void clickThisReschedule() {
        LessonScheduleEntity data = viewModel.selectData.getValue();
        SelectLessonV2Dialog.Type type = SelectLessonV2Dialog.Type.STUDIO_SHOW;
        boolean isShowSelectSelectTeacher = true;

        if (SLCacheUtil.getUserRole().equals(UserEntity.UserRole.teacher) && (TKRoleAndAccess.getData() != null && TKRoleAndAccess.getData().getRoleType() != TKRoleAndAccess.RoleType.MANAGER)) {
            type = SelectLessonV2Dialog.Type.TEACHER_SHOW;
            isShowSelectSelectTeacher = false;
        }

        SelectLessonV2Dialog dialog = new SelectLessonV2Dialog(this, type, this, viewModel, data, null, isShowSelectSelectTeacher, true);
        dialog.showDialog();
        dialog.setClickConfirm(locationData -> {
//            Logger.e("==>%s", SLJsonUtils.toJsonString(locationData));
//            dialog.dismiss();
//            viewModel.sentRescheduleV2("", data, locationData);
            if (data.lessonCategory.equals(LessonTypeEntity.TKLessonCategory.group)||data.getStudentId().equals("")){
                viewModel.sentRescheduleByGroup("", data, locationData);
                dialog.dismiss();
            }else {
                ThreeButtonDialog threeButtonDialog = new ThreeButtonDialog(LessonDetailsAc.this, "Confirm Reschedule", "Send reschedule request or confirm immediately, your student will receive request or confirmation.", "Send Request", "Immediately Confirm", "Go Back");
                threeButtonDialog.showDialog();
                threeButtonDialog.setClickListener(new ThreeButtonDialog.OnClickListener() {
                    @Override
                    public void onClickOne() {
                        dialog.dismiss();
                        threeButtonDialog.dismiss();
                        dialog.getTimeUtils.close();
                        viewModel.sentRescheduleV2("", data, locationData, false);
                    }

                    @Override
                    public void onClickTwo() {
                        viewModel.sentRescheduleV2("", data, locationData, true);
                        threeButtonDialog.dismiss();
                        dialog.getTimeUtils.close();
                        dialog.getTimeUtils = null;
                        dialog.dismiss();
                    }

                    @Override
                    public void onClickThree() {
                        threeButtonDialog.dismiss();
                    }
                });
            }



            return null;
        });


    }

    private void shareLesson() {
        List<LessonSchedulePlanEntity> planEntityList = new ArrayList<>();
        List<MaterialEntity> materialEntityList = new ArrayList<>();
        List<TKPractice> practiceList = new ArrayList<>();
        List<AchievementEntity> achievementEntityList = new ArrayList<>();
        List<LessonSchedulePlanEntity> nextLessonPlan = new ArrayList<>();

        //设置lessonPlan
        if (viewModel.lessonPlanList != null) {
            for (LessonPlanItemViewModel item : viewModel.lessonPlanList) {
                if (item.lessonPlanData != null) {
                    planEntityList.add(item.lessonPlanData);
                }
            }
        }
        //设置materials
        if (viewModel.materialsList != null) {
            for (MaterialsMultiItemViewModel item : viewModel.materialsList) {
                if (item.getData() != null) {
                    materialEntityList.add(item.getData());
                }
            }
        }
        //设置Homework
        if (viewModel.homeworkList != null) {
            for (LessonHomeworkItemViewModel item : viewModel.homeworkList) {
                if (item.practice != null) {
                    practiceList.add(item.practice);
                }
            }
        }
        //设置achievement
        if (viewModel.achievementList != null) {
            for (LessonAchievementItemViewModel item : viewModel.achievementList) {
                if (item.achievementEntity != null) {
                    achievementEntityList.add(item.achievementEntity);
                }
            }
        }
        //设置nextLessonPlan
        if (viewModel.nextLessonPlanList != null) {
            for (LessonPlanItemViewModel item : viewModel.nextLessonPlanList) {
                if (item.lessonPlanData != null) {
                    nextLessonPlan.add(item.lessonPlanData);
                }
            }
        }
        LessonToEmailDialog dialog = new LessonToEmailDialog(this, viewModel.selectData.getValue(), planEntityList, materialEntityList, practiceList, achievementEntityList, nextLessonPlan);
        dialog.showDialog();
    }

    private void showRescheduleAllAndUpcomingDialog(String text) {
        if (viewModel.selectData.getValue() == null) {
            return;
        }
        LessonScheduleConfigEntity configEntity = viewModel.selectData.getValue().getConfigEntity();
        if (configEntity == null && ListenerService.shared.teacherData != null && ListenerService.shared.teacherData.getScheduleConfigs() != null) {
            for (LessonScheduleConfigEntity scheduleConfig : ListenerService.shared.teacherData.getScheduleConfigs()) {
                if (viewModel.selectData.getValue().getLessonScheduleConfigId().equals(scheduleConfig.getId())) {
                    configEntity = scheduleConfig;
                    break;
                }
            }
        }

        RescheduleAllAndUpcomingDialog dialog = new RescheduleAllAndUpcomingDialog(this, this, viewModel, configEntity, viewModel.selectData.getValue(), text);
        dialog.showDialog();
    }

    public void showAchievement(AchievementEntity achievementEntity) {
        Dialog bottomDialog = new Dialog(this, R.style.BottomDialog);
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
        TKButton retract = contentView.findViewById(R.id.retract_button);
        View leftP = contentView.findViewById(R.id.p_view_left);
        View rightP = contentView.findViewById(R.id.p_view_right);


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
        if (achievementEntity != null) {
            retract.setVisibility(View.VISIBLE);
            leftP.setVisibility(View.GONE);
            rightP.setVisibility(View.GONE);
            check8.setVisibility(View.GONE);
            switch (achievementEntity.getType()) {
                case 1:
                    check1.setVisibility(View.VISIBLE);
                    break;
                case 2:
                    check2.setVisibility(View.VISIBLE);
                    break;
                case 3:
                    check3.setVisibility(View.VISIBLE);
                    break;
                case 4:
                    check6.setVisibility(View.VISIBLE);
                    break;
                case 5:
                    check5.setVisibility(View.VISIBLE);
                    break;
                case 6:
                    check4.setVisibility(View.VISIBLE);
                    break;
                case 7:
                    check7.setVisibility(View.VISIBLE);
                    break;
                case 8:
                    check8.setVisibility(View.VISIBLE);
                    break;
                case 9:
                    check9.setVisibility(View.VISIBLE);
                    break;
                case 10:
                    check10.setVisibility(View.VISIBLE);
                    break;
            }
        }

        Technique.setOnClickListener(v -> {
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
        });
        Notation.setOnClickListener(v -> {
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
        });
        Song.setOnClickListener(v -> {
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
        });
        Improv.setOnClickListener(v -> {
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
        });
        GroupPlay.setOnClickListener(v -> {
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
        });

        Dedication.setOnClickListener(v -> {
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
        });
        listening.setOnClickListener(v -> {
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
        });
        reading.setOnClickListener(v -> {
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
        });

        creativity.setOnClickListener(v -> {
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
            showAchievementEdit(achievementType[0], achievementEntity);
            if (bottomDialog.isShowing()) {
                bottomDialog.dismiss();
            }
        });
        retract.setClickListener(tkButton -> {
            if (achievementEntity != null) {
                viewModel.deleteAchievement(achievementEntity.getId());
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

    public void showAchievementEdit(int type, AchievementEntity achievementEntity) {

        Dialog achievementDialog = new Dialog(this, R.style.BottomDialog);
        View contentView = LayoutInflater.from(this).inflate(R.layout.dialog_add_achievement_edit, null);

        TKButton create = contentView.findViewById(R.id.create);
        create.setEnabled(false);
        TKButton retract = contentView.findViewById(R.id.retract_button);
        View leftP = contentView.findViewById(R.id.p_view_left);
        View rightP = contentView.findViewById(R.id.p_view_right);


        InputView title = contentView.findViewById(R.id.input_title);
        title.setFocus();
        title.editTextView.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        InputView description = contentView.findViewById(R.id.input_des);
        description.editTextView.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
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
                } else {
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
                } else {
                    create.setEnabled(false);
                }
            }
        });
        if (achievementEntity != null) {
            retract.setVisibility(View.VISIBLE);
            leftP.setVisibility(View.GONE);
            rightP.setVisibility(View.GONE);
            create.setText("UPDATE");
            title.setInputText(achievementEntity.getName());
            description.setInputText(achievementEntity.getDesc());
        }
        create.setClickListener(v -> {
            if (achievementEntity == null) {
                viewModel.addAchievement(type, title.getInputText(), description.getInputText());
            } else {
                viewModel.editAchievement(achievementEntity.getId(), type, title.getInputText(), description.getInputText());
            }
            if (achievementDialog.isShowing()) {
                achievementDialog.dismiss();
            }
        });
        retract.setClickListener(tkButton -> {
            if (achievementEntity != null) {
                viewModel.deleteAchievement(achievementEntity.getId());
                if (achievementDialog.isShowing()) {
                    achievementDialog.dismiss();
                }
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


    /**
     * 显示添加事件弹窗
     *
     * @param type 1:lesson type,2:note, 3:next lesson plan, 4: homework
     */
    @SuppressLint("SetTextI18n")
    public void showUpPop(int type, String defaultText, String defaultId, boolean isEdit) {
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
        if (type == 1) {
            addText.setHint("Add lesson plan here");
            title.setText(topicString + " Plan");
        } else if (type == 2) {
            addText.setHint("Add notes here");
            title.setText(topicString + " Note");
        } else if (type == 3) {
            addText.setHint("Add plan here for next lesson");
            title.setText(topicString + " Plan");
        } else if (type == 4) {
            addText.setHint("Add assignment here");
            title.setText(topicString + " Homework");
        }
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
                if (type == 1) {
                    viewModel.deletePlan(defaultId, 1);
                } else if (type == 2) {
//                    viewModel.upDateNotes("");
                } else if (type == 3) {
                    viewModel.deletePlan(defaultId, 3);
                } else if (type == 4) {
                    viewModel.deleteHomework(defaultId);
                }
            }
            bottomDialog.dismiss();
        });
        create.setClickListener(tkButton -> {
            String text = String.valueOf(addText.getText());
            if (type == 1) {
                if (isEdit) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("plan", text);
                    viewModel.upDateLessonPlan(map, defaultId, 1);
                } else {
                    viewModel.addLessonPlan(1, text);
                }
            } else if (type == 2) {
//                viewModel.upDateNotes(text);
            } else if (type == 3) {
                if (isEdit) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("plan", text);
                    viewModel.upDateLessonPlan(map, defaultId, 3);
                } else {
                    viewModel.addLessonPlan(3, text);
                }
            } else if (type == 4) {
                if (isEdit) {
                    viewModel.editHomework(defaultId, text);
                } else {
                    viewModel.addHomework(text);
                }
            }
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