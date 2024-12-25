package com.spelist.tunekey.ui.teacher.lessons.fragments;

import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;
import androidx.databinding.DataBindingUtil;
import androidx.fragment.app.FragmentManager;

import com.bumptech.glide.Glide;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.countDownView.CountDownInterface;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.selectCalendarDate.SelectCalendarDateDialog;
import com.spelist.tunekey.customView.dialog.selectLesson.SelectLessonDialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.DialogRescheduleSendMessageBinding;
import com.spelist.tunekey.databinding.FragmentLessonsBinding;
import com.spelist.tunekey.entity.BlockEntity;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.ui.teacher.lessons.LessonWebHost;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonCountDownActivity;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsAc;
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonSearchAc;
import com.spelist.tunekey.ui.teacher.lessons.activity.SelectStudentActivity;
import com.spelist.tunekey.ui.teacher.lessons.dialog.DialogAddLesson;
import com.spelist.tunekey.ui.teacher.lessons.dialog.rescheduleBox.RescheduleBox;
import com.spelist.tunekey.ui.teacher.lessons.dialog.rescheduleBox.RescheduleBoxAdapter;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonsViewModel;
import com.spelist.tunekey.ui.teacher.lessonsFilter.LessonsFilterActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import org.jetbrains.annotations.NotNull;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * Author WHT
 * Description:
 * Date :2019-10-07
 */
public class LessonsFragment extends BaseFragment<FragmentLessonsBinding, LessonsViewModel> {
    private DialogAddLesson dialogAddLesson;
    private Dialog bottomDialog;
    private FragmentManager fragmentManager;
    public int lessonDisplayType = 4; //1: day, 2: 3-day, 3: week, 4: month
    public LessonWebHost webHost;
    private int clickLessonTapCount = 0;

    private final Animation lessonFilterScaleAnimationShow = new
            ScaleAnimation(0f, 1f, 1f, 1f, Animation.RELATIVE_TO_SELF, 0f, Animation.RELATIVE_TO_SELF, 0.5f);
    private final Animation lessonFilterScaleAnimationHide = new
            ScaleAnimation(1f, 0f, 1f, 1f, Animation.RELATIVE_TO_SELF, 0f, Animation.RELATIVE_TO_SELF, 0.5f);

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_lessons;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }


    @Override
    public void initData() {
        viewModel.currentSelectTimestamp = TimeUtils.getCurrentTime() * 1000L;

        if (getActivity() != null && webHost == null) {
            webHost = new LessonWebHost(getContext(), this);
            FuncUtils.initWebViewSetting(binding.lessonMonthWeb, "file:///android_asset/web/cal.month.v2.html");
            binding.lessonMonthWeb.addJavascriptInterface(webHost, "js");
            binding.lesson.addJavascriptInterface(webHost, "js");
            lessonDisplayType = SLCacheUtil.getTeacherLookCalendarType(UserService.getInstance().getCurrentUserId()) + 1;
            initLessonFilter();
        }


        clickLessonTapCount = SLCacheUtil.getClickLessonTapCount();
        if (clickLessonTapCount >= 3) {
            binding.tipView.setVisibility(View.GONE);
        } else {
            binding.tipView.setVisibility(View.VISIBLE);
        }
    }

    @Override
    public void initView() {
        super.initView();
        binding.titleLeftImg.setOnClickListener(v -> {
            hideLessonFilter();
        });
        binding.countDownView.setTypeFace(ResourcesCompat.getFont(getContext(), R.font.helvetica_neue_bold));
        binding.countDownLayout.setOnClickListener(v -> {
            if (viewModel.nowLesson == null) {
                return;
            }
            clickLessonTapCount = clickLessonTapCount + 1;
            SLCacheUtil.setClickLessonTapCount(clickLessonTapCount);
            Intent intent = new Intent(getActivity(), LessonCountDownActivity.class);
            intent.putExtra("data", viewModel.nowLesson);
            startActivity(intent);
            getActivity().overridePendingTransition(R.anim.zoom_in, R.anim.zoom_out);
            viewModel.isShowCountDownView.set(false);
        });
//        Calendar calendar = Calendar.getInstance();
//        calendar.add(Calendar.SECOND, 10);
//        binding.countDownView.startTimer(calendar);
        binding.countDownView.setOnTick(new CountDownInterface() {
            @Override
            public void onTick(long time) {
                if (time == 0) {
                    getActivity().runOnUiThread(() -> {
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
        Glide.with(this).load(R.mipmap.tap).into(binding.tipView);
        binding.tipView.setRotation(-45);
    }


    @SuppressLint("ResourceAsColor")
    @Override
    public void initViewObservable() {
        viewModel.uc.nowLesson.observe(this, lessonScheduleEntity -> {
            long endTime = lessonScheduleEntity.getTKShouldDateTime() + (lessonScheduleEntity.getShouldTimeLength() * 60);
            Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.SECOND, (int) (endTime - TimeUtils.getCurrentTime()));
            binding.countDownView.startTimer(calendar);
            if (clickLessonTapCount >= 3) {
                binding.tipView.setVisibility(View.GONE);
            } else {
                binding.tipView.setVisibility(View.VISIBLE);
            }
        });

        viewModel.uc.clickAddLesson.observe(this, aVoid ->
                initAddLessonDialog());
        viewModel.uc.clickFilter.observe(this, aVoid -> {
            Intent intent = new Intent();
            intent.setClass(getActivity(), LessonsFilterActivity.class);
            intent.putExtra("lessonDisplayType", lessonDisplayType);
            startActivityForResult(intent, 100);
        });
        viewModel.uc.clickSearch.observe(this, aVoid -> {

            startActivity(new Intent(getContext(), LessonSearchAc.class));
        });

        viewModel.uc.clickView.observe(this, aVoid -> {
            showLessonFilter();
        });

        viewModel.uc.clickDay.observe(this, aVoid -> {
            if (lessonDisplayType != 1) {
                lessonDisplayType = 1;
                initLessonFilter();
            }
        });

        viewModel.uc.click3Day.observe(this, aVoid -> {
            if (lessonDisplayType != 2) {
                lessonDisplayType = 2;
                initLessonFilter();
            }
        });

        viewModel.uc.clickWeek.observe(this, aVoid -> {
            if (lessonDisplayType != 3) {
                lessonDisplayType = 3;
                initLessonFilter();
            }
        });

        viewModel.uc.clickMonth.observe(this, aVoid -> {
            if (lessonDisplayType != 4) {
                lessonDisplayType = 4;
                initLessonFilter();
            }
        });

        /**
         * 刷新日历数据
         */
        viewModel.uc.refreshData.observe(this, aVoid -> {
            List<LessonScheduleEntity> lessonScheduleEntities = CloneObjectUtils.cloneObject(viewModel.lessonScheduleList);
            for (LessonScheduleEntity lessonScheduleEntity : lessonScheduleEntities) {
                lessonScheduleEntity.setShouldDateTime(lessonScheduleEntity.getTKShouldDateTime());
            }
            String agendaJson = SLJsonUtils.toJsonString(lessonScheduleEntities);

            String promptData = SLJsonUtils.toJsonString(viewModel.undoneRescheduleData);

            if (!SLCacheUtil.getHaveLesson()) {
                viewModel.haveLesson = viewModel.lessonScheduleList.size() > 0;
                SLCacheUtil.setHaveLesson(viewModel.lessonScheduleList.size() > 0);
                viewModel.initHaveData();
            }
            Logger.e("个数==>%s",lessonScheduleEntities.size());
            if (lessonDisplayType < 4) {
                binding.lesson.evaluateJavascript("initLessonList(" + (viewModel.currentSelectTimestamp) + "," + agendaJson + "," + promptData + ")", s -> {
                });
            } else {
                binding.lessonMonthWeb.evaluateJavascript("getAgenda(" + agendaJson + "," + promptData + "," + viewModel.currentSelectTimestamp + ")", ss -> {
                });
            }


        });

        viewModel.uc.clickRetract.observe(this, data -> {
            Dialog dialog = SLDialogUtils.showTwoButton(getActivity(), "Retract request", "Are you sure you want to retract your reschedule request?", "Yes", "No");
            TextView leftButton = dialog.findViewById(R.id.left_button);
            leftButton.setTextColor(ContextCompat.getColor(getContext().getApplicationContext(), R.color.red));
            leftButton.setOnClickListener(v -> {
                dialog.dismiss();
                viewModel.retractReschedule(data);
            });
        });

        viewModel.uc.clickDeclined.observe(this, data -> {
            Dialog bottomDialog = new Dialog(getActivity(), R.style.BottomDialog);
            DialogRescheduleSendMessageBinding binding = DataBindingUtil.inflate(LayoutInflater.from(getActivity()), R.layout.dialog_reschedule_send_message, null, false);
            View contentView = binding.getRoot();
            //获取Dialog的监听
            binding.closeButton.setOnClickListener(v -> {
                bottomDialog.dismiss();
            });
            binding.sendButton.setText("DECLINED");
            binding.sendButton.setClickListener(tkButton -> {
                String s = binding.message.getText().toString();
                viewModel.declinedReschedule(s, data);
//                viewModel.sendReschedule(s, afterTime, lessonScheduleEntities);
                bottomDialog.dismiss();
            });
            binding.message.setFocusable(true);
            binding.message.setFocusableInTouchMode(true);//设置触摸聚焦
            binding.message.requestFocus();
            FuncUtils.toggleSoftInput(binding.message, true);

            bottomDialog.setContentView(contentView);
            ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
            layoutParams.width = getResources().getDisplayMetrics().widthPixels;
            contentView.setLayoutParams(layoutParams);
            bottomDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
            bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
            bottomDialog.show();//显示弹窗
        });


        viewModel.uc.showErrorDialog.observe(this, s -> {
            String title = s.get("title");
            String content = s.get("content");
            Dialog dialog = SLDialogUtils.showOneButton(getActivity(),
                    title,
                    content,
                    "SEE UPDATE");
            TextView button = dialog.findViewById(R.id.button);
            button.setOnClickListener(v -> {
                dialog.dismiss();
                clickRescheduleBox();
            });
        });
    }

    /**
     * 日历翻页
     *
     * @param time 日历的翻页月的起始时间戳
     */
    public void changeCalendarPage(long time) {
        if (lessonDisplayType != 4) {
            viewModel.currentSelectTimestamp = time * 1000;
        }

        if (getActivity() != null) {
            getActivity().runOnUiThread(() -> viewModel.changeCalendarPage(time));
        }
    }

    /**
     * 日历翻页
     *
     * @param time 日历的翻页月的起始时间戳
     */
    public void changeSelectTime(long time) {
        viewModel.currentSelectTimestamp = time;
    }

    /**
     * 点击reschedule消息盒子
     */
    public void clickRescheduleBox() {
        RescheduleBox.Builder dialog = new RescheduleBox.Builder(getContext())
                .create(viewModel.undoneRescheduleData);
        dialog.clickButton(new RescheduleBoxAdapter.clickItem() {
            //confirm retract close
            @Override
            public void clickConfirm(int pos) {
                dialog.dismiss();
                Logger.e("clickConfirm");
                getActivity().runOnUiThread(() -> viewModel.clickBoxConfirm(viewModel.undoneRescheduleData.get(pos)));
            }

            @Override
            public void clickReschedule(int pos) {
                Logger.e("clickReschedule");
                getActivity().runOnUiThread(() -> {
                    dialog.dismiss();
                    long t = 0;
                    try {
                        int after = Integer.parseInt(viewModel.undoneRescheduleData.get(pos).getTimeAfter());
                        if (after != 0 && after > com.spelist.tunekey.utils.TimeUtils.getCurrentTime()) {
                            t = after * 1000L;
                        }
                    } catch (Throwable e) {
                        Logger.e("转换时间失败==>%s",e.getMessage());
                    }

                    SelectLessonDialog.Builder selectLessonDialog = new SelectLessonDialog.Builder(getContext())
                            .createByReschedule(UserService.getInstance().getCurrentUserId(),
                                    t,
                                    viewModel.undoneRescheduleData.get(pos).getShouldTimeLength(), viewModel.undoneRescheduleData.get(pos).getId(), viewModel.undoneRescheduleData.get(pos).getId());
                    selectLessonDialog.clickConfirm(tkButton -> {
//            builder.selectTime;
                        int selectTime = selectLessonDialog.getSelectTime();
                        int diff = 0;
                        LessonScheduleEntity lessonData = SLCacheUtil.getLessonData(viewModel.undoneRescheduleData.get(pos).getScheduleId());
                        if (lessonData != null) {
                            if (lessonData.getLessonScheduleData() != null) {
                                diff = TimeUtils.getRescheduleDiff(lessonData.getLessonScheduleData().getStartDateTime(), selectTime);
                            } else {
                                List<LessonScheduleConfigEntity> collect = new ArrayList<>();
                                if (ListenerService.shared.user.getRoleIds().contains("1")) {
                                    collect = ListenerService.shared.teacherData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(lessonData.getLessonScheduleConfigId())).collect(Collectors.toList());
                                } else {
                                    collect = ListenerService.shared.studentData.getScheduleConfigs().stream().filter(entity -> entity.getId().equals(lessonData.getLessonScheduleConfigId())).collect(Collectors.toList());
                                }
                                if (collect.size() > 0) {
                                    diff = TimeUtils.getRescheduleDiff(collect.get(0).getStartDateTime(), selectTime);
                                }
                            }
                        }

                        selectTime = selectTime + (diff * 3600);

                        viewModel.clickBoxReschedule(viewModel.undoneRescheduleData.get(pos), selectTime);

                        selectLessonDialog.dismiss();
                    });

                });


            }

            @Override
            public void clickDeclined(int pos) {
                Logger.e("clickDeclined");
                dialog.dismiss();
                getActivity().runOnUiThread(() -> viewModel.clickBoxDeclined(viewModel.undoneRescheduleData.get(pos)));

            }

            @Override
            public void clickRetract(int pos) {
                Logger.e("clickRetract");
                dialog.dismiss();
                getActivity().runOnUiThread(() -> viewModel.clickRetract(viewModel.undoneRescheduleData.get(pos)));
            }

            @Override
            public void clickClose(int pos) {
                Logger.e("clickClose");
                dialog.dismiss();
                getActivity().runOnUiThread(() -> viewModel.clickBoxClose(viewModel.undoneRescheduleData.get(pos)));
            }
        });
    }

    public void hideLessonFilter() {
        binding.titleLeftImg.setVisibility(View.GONE);
        lessonFilterScaleAnimationHide.setDuration(200);//动画持续时间
        binding.lessonFilter.setAnimation(lessonFilterScaleAnimationHide);//设置动画
        lessonFilterScaleAnimationHide.startNow();
        binding.lessonFilter.setVisibility(View.GONE);
        viewModel.viewBtnVisibility.set(View.VISIBLE);
        viewModel.viewDisplayType = 0;
        handler.removeCallbacksAndMessages(null);
//        initLessonFilter();
    }

    Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull @NotNull Message msg) {
            hideLessonFilter();
            return false;
        }
    });


    public void showLessonFilter() {
        viewModel.viewBtnVisibility.set(View.GONE);
        binding.titleLeftImg.setVisibility(View.VISIBLE);
        lessonFilterScaleAnimationShow.setDuration(200);//动画持续时间
        binding.lessonFilter.setVisibility(View.VISIBLE);
        binding.lessonFilter.setAnimation(lessonFilterScaleAnimationShow);//设置动画
        lessonFilterScaleAnimationShow.startNow();
        viewModel.viewDisplayType = 1;
        handler.removeCallbacksAndMessages(null);
        handler.sendEmptyMessageDelayed(1, 5000);

//        initLessonFilter();
    }

    /**
     * 选择日历显示方式
     */
    public void initLessonFilter() {
        if (getContext() == null || getActivity() == null) {
            return;
        }
        getActivity().runOnUiThread(() -> {
            binding.filterBtDay.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            binding.filterBtDay.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_corner2));
            binding.filterBt3day.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            binding.filterBt3day.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_corner2));
            binding.filterBtWeek.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            binding.filterBtWeek.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_corner2));
            binding.filterBtMonth.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            binding.filterBtMonth.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_corner2));
            List<LessonScheduleEntity> lessonScheduleEntities = CloneObjectUtils.cloneObject(viewModel.lessonScheduleList);
            for (LessonScheduleEntity lessonScheduleEntity : lessonScheduleEntities) {
                lessonScheduleEntity.setShouldDateTime(lessonScheduleEntity.getTKShouldDateTime());
            }
            String agendaJson = SLJsonUtils.toJsonString(lessonScheduleEntities);
            String promptData = SLJsonUtils.toJsonString(viewModel.undoneRescheduleData);
            switch (lessonDisplayType) {
                case 1:
                    SLCacheUtil.setTeacherLookCalendarType(UserService.getInstance().getCurrentUserId(), 0);
                    binding.filterBtDay.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
                    binding.filterBtDay.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_green_corner2));
                    binding.titleLeftButton.setImageResource(R.mipmap.ic_calendar_1day);
                    viewModel.lessonDaysVisibility.set(View.VISIBLE);
                    viewModel.lessonMonthVisibility.set(View.GONE);
                    FuncUtils.initWebViewSetting(binding.lesson, "file:///android_asset/web/1-day-lesson.v2.html");
                    new Handler().postDelayed(() -> binding.lesson.evaluateJavascript("initLessonList(" + (viewModel.currentSelectTimestamp) + "," + agendaJson + "," + promptData + ")", s -> {
                    }), 300);
                    handler.removeCallbacksAndMessages(null);
                    handler.sendEmptyMessageDelayed(1, 5000);
                    break;
                case 2:
                    SLCacheUtil.setTeacherLookCalendarType(UserService.getInstance().getCurrentUserId(), 1);
                    binding.filterBt3day.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
                    binding.filterBt3day.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_green_corner2));
                    viewModel.lessonDaysVisibility.set(View.VISIBLE);
                    viewModel.lessonMonthVisibility.set(View.GONE);
                    binding.titleLeftButton.setImageResource(R.mipmap.ic_calendar_3day);
                    FuncUtils.initWebViewSetting(binding.lesson, "file:///android_asset/web/3-day-lesson.v2.html");
                    new Handler().postDelayed(() -> binding.lesson.evaluateJavascript("initLessonList(" + (viewModel.currentSelectTimestamp) + "," + agendaJson + "," + promptData + ")", s -> {
                    }), 300);
                    handler.removeCallbacksAndMessages(null);
                    handler.sendEmptyMessageDelayed(1, 5000);
                    break;
                case 3:
                    SLCacheUtil.setTeacherLookCalendarType(UserService.getInstance().getCurrentUserId(), 2);
                    binding.filterBtWeek.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
                    binding.filterBtWeek.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_green_corner2));
                    viewModel.lessonDaysVisibility.set(View.VISIBLE);
                    viewModel.lessonMonthVisibility.set(View.GONE);
                    binding.titleLeftButton.setImageResource(R.mipmap.ic_calendar_7day);
                    FuncUtils.initWebViewSetting(binding.lesson, "file:///android_asset/web/7-day-lesson.v2.html");
                    new Handler().postDelayed(() -> binding.lesson.evaluateJavascript("initLessonList(" + (viewModel.currentSelectTimestamp) + "," + agendaJson + "," + promptData + ")", s -> {
                    }), 300);
                    handler.removeCallbacksAndMessages(null);
                    handler.sendEmptyMessageDelayed(1, 5000);
                    break;
                case 4:
                    binding.titleLeftButton.setImageResource(R.mipmap.ic_calendar_30day);
                    SLCacheUtil.setTeacherLookCalendarType(UserService.getInstance().getCurrentUserId(), 3);
                    viewModel.lessonDaysVisibility.set(View.GONE);
                    viewModel.lessonMonthVisibility.set(View.VISIBLE);
                    binding.filterBtMonth.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
                    binding.filterBtMonth.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.bg_with_border1_green_corner2));
                    binding.lessonMonthWeb.evaluateJavascript("getAgenda(" + agendaJson + "," + promptData + ")", ss -> {
                    });
                    handler.removeCallbacksAndMessages(null);
                    handler.sendEmptyMessageDelayed(1, 5000);
                    break;
            }
        });

    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

    }

    private void initAddLessonDialog() {
        boolean isShowAddTakeDayOff = true;
        for (BlockEntity blockEntity : viewModel.blockList) {
            if (TimeUtils.timeFormat(blockEntity.getStartDateTime(), "yyyy-MM-dd").equals(TimeUtils.timeFormat(viewModel.currentSelectTimestamp / 1000, "yyyy-MM-dd"))) {
                isShowAddTakeDayOff = false;
            }
        }
        if (lessonDisplayType != 4) {
            isShowAddTakeDayOff = true;
        }
//        dialogAddLesson = new DialogAddLesson(this, isShowAddTakeDayOff);
//        fragmentManager = getActivity().getSupportFragmentManager();
//        dialogAddLesson.show(fragmentManager, "DialogFragments");
//
//
//        dialogAddLesson.setDialogCallback(new DialogAddLesson.DialogCallback() {
//            @Override
//            public void addLesson() {
//
//            }
//
//            @Override
//            public void addEvent() {
//
//            }
//
//            @Override
//            public void addBlock() {
//
//            }
//        });
        BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity())
                .addMenuItems(new MenuItem("Lesson"));
        if (isShowAddTakeDayOff) {
            bottomMenuFragment.addMenuItems(new MenuItem("Take Day Off"));
        }
        bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
            if (position == 0) {
                startActivity(SelectStudentActivity.class);
            } else {
                if (lessonDisplayType == 4 && SLCacheUtil.getHaveLesson()) {
                    takeDayOffDialog();
                } else {
                    showSelectTakeDayOffDialog(null);
                }
            }
        }).show();


    }

    /**
     * 进入课程详情页
     *
     * @param selectedLesson
     * @param selectedIndexOfDay
     * @param allLessonOfDay
     */
    public void toLessonDetail(String selectedLesson, int selectedIndexOfDay, String allLessonOfDay) {
        if (getActivity() == null) {
            return;
        }
        Logger.e("点击的是%s", selectedIndexOfDay);
        getActivity().runOnUiThread(() -> {
            Gson gson = new Gson();
            Logger.e("???==>%s", allLessonOfDay);
            List<LessonScheduleEntity> data = gson.fromJson(allLessonOfDay, new TypeToken<List<LessonScheduleEntity>>() {
            }.getType());
            for (LessonScheduleEntity webDatum : data) {
                for (LessonScheduleEntity lessonScheduleEntity : viewModel.lessonScheduleList) {
                    if (webDatum.getId().equals(lessonScheduleEntity.getId())) {
                        webDatum.setShouldDateTime(lessonScheduleEntity.getShouldDateTime());
                        break;
                    }

                }
            }

            if (data.get(selectedIndexOfDay) == null) {
                return;
            }
            String selectId = data.get(selectedIndexOfDay).getId();
//            for (int i = 0; i < data.size(); i++) {
//                data.get(i).setShouldDateTime(data.get(i).getShouldDateTime() / 1000);
//            }
            Logger.e("data.get(selectedIndexOfDay).getType()%s", data.get(selectedIndexOfDay).getType());
            if (data.get(selectedIndexOfDay).getType() == 0 || data.get(selectedIndexOfDay).getType() == 1) {
                data.removeIf(lessonScheduleEntity -> (lessonScheduleEntity.getType() != 0 && lessonScheduleEntity.getType() != 1));
                int index = 0;
                for (int i = 0; i < data.size(); i++) {
                    if (data.get(i).getId().equals(selectId)) {
                        index = i;
                    }
                }
                Intent intent = new Intent(getActivity(), LessonDetailsAc.class);
                intent.putExtra("data", (Serializable) data);
                intent.putExtra("nowLesson", (Serializable) viewModel.nowLesson);
                intent.putExtra("selectIndex", index);
                intent.putExtra("selectTime", data.get(index).getShouldDateTime());
                startActivity(intent);
            } else if (data.get(selectedIndexOfDay).getType() == 3) {
                clickBlock(data.get(selectedIndexOfDay));
            }
        });

    }

    private void clickBlock(LessonScheduleEntity lessonScheduleEntity) {
        BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity())
                .addMenuItems(new MenuItem("Edit"))
                .addMenuItems(new MenuItem("Delete"));

        bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
            Logger.e("postion%s", position);
            if (position == 0) {
                showSelectTakeDayOffDialog(lessonScheduleEntity);
            } else if (position == 1) {
                viewModel.deleteBlock(lessonScheduleEntity.getId());
            }
        }).show();
    }

    public void showSelectTakeDayOffDialog(LessonScheduleEntity lessonScheduleEntity) {
        List<String> block = new ArrayList<>();
        for (BlockEntity blockEntity : viewModel.blockList) {
            block.add(TimeUtils.timeFormat(blockEntity.getStartDateTime(), "yyyy-M-d"));
        }


        SelectCalendarDateDialog dialog = new SelectCalendarDateDialog(getContext(), block);
        BasePopupView popupView = new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .enableDrag(false)
                .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(false)
                .asCustom(dialog)
                .show();
        dialog.setListener(time -> {
            if (lessonScheduleEntity != null) {
                viewModel.updateBlock(time, lessonScheduleEntity.getId());
            } else {
                viewModel.setupBlock(time);
            }
        });
    }

    public void takeDayOffDialog() {

        bottomDialog = new Dialog(getContext(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getContext()).inflate(R.layout.take_day_off_toast, null);
        TextView no = contentView.findViewById(R.id.cancel);
        TextView save = contentView.findViewById(R.id.save);
        TextView date = contentView.findViewById(R.id.date);
        Logger.e("当前选中的天%s", viewModel.currentSelectTimestamp);
        date.setText(TimeUtils.timeFormat(viewModel.currentSelectTimestamp / 1000, "MMMM d"));
        no.setOnClickListener(v -> bottomDialog.dismiss());
        save.setOnClickListener(v -> {
            bottomDialog.dismiss();
            viewModel.setupBlock((int) (viewModel.currentSelectTimestamp / 1000));
        });

        bottomDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        bottomDialog.getWindow().setGravity(Gravity.CENTER);//弹窗位置
        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        bottomDialog.show();//显示弹窗

    }


}
