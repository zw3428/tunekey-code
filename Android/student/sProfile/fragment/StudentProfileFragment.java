package com.spelist.tunekey.ui.student.sProfile.fragment;

import android.app.Dialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.PagerSnapHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.google.firebase.auth.FirebaseAuth;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.SwitchAccountDialog;
import com.spelist.tunekey.customView.dialog.AddTeacherDialog;
import com.spelist.tunekey.customView.dialog.FollowUsDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.TKSelectTimeDialog;
import com.spelist.tunekey.customView.dialog.TKSelectTimeDialogNew;
import com.spelist.tunekey.customView.dialog.addStudent.AddStudentDialog;
import com.spelist.tunekey.databinding.FragmentStudentProfileBinding;
import com.spelist.tunekey.databinding.ItemStudentProfileStudentBinding;
import com.spelist.tunekey.entity.NotificationEntity;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.notification.TKNotificationUtils;
import com.spelist.tunekey.ui.loginAndOnboard.login.LoginActivity;
import com.spelist.tunekey.ui.loginAndOnboard.login.vm.LoginHistoryItemVM;
import com.spelist.tunekey.ui.main.index.MainActivity;
import com.spelist.tunekey.ui.main.sIndex.StudentMainActivity;
import com.spelist.tunekey.ui.toolsView.FaqActivity;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerAdapter;
import com.spelist.tunekey.utils.BaseViewBindingRecyclerHolder;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SharePreferenceUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.utils.DeviceInfoUtils;
import me.goldze.mvvmhabit.utils.UIUtils;
import me.jessyan.autosize.utils.AutoSizeUtils;

public class StudentProfileFragment extends BaseFragment<FragmentStudentProfileBinding, StudentProfileViewModel> {
    private int startTime;
    private LinearLayoutManager linearLayoutManager;
    private BaseViewBindingRecyclerAdapter<UserEntity> adapter;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_profile;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
    }

    @Override
    public void initView() {
        super.initView();

        try {
            if (!TKNotificationUtils.areNotificationsEnabled(getContext())) {
                // 创建一个 Handler 对象
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    // 这里放置你想要在 5 秒后执行的代码
                    // 例如：检查通知权限并引导用户去设置
                    Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Notification permission", "We need notification access to provide you with timely updates and alerts. Would you like to enable notifications now?", "To setting", "Not now");
                    TextView leftButton1 = dialog.findViewById(R.id.left_button);
                    leftButton1.setOnClickListener(v -> {
                        dialog.dismiss();
                        TKNotificationUtils.openNotificationSettingsForApp(getContext());
                    });
                }, 1500); // 延时时间设置为 5000 毫秒（即 5 秒）
            }
        }catch (Exception e){
            Logger.e("检查订阅失败==>%s",e.getMessage());
        }


        binding.versionTv.setOnClickListener(v -> {
            if (!viewModel.isLatestVersion){
                DeviceInfoUtils.openGooglePlay(getContext());
            }
        });
        linearLayoutManager = new LinearLayoutManager(getContext());
        linearLayoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);
        binding.studentRecyclerview.setLayoutManager(linearLayoutManager);

        initRecyclerView();

        binding.linReminder.setVisibility(View.GONE);
        binding.swNotes.setToggleOn(false);
        binding.swAchievement.setToggleOn(false);
        binding.swShare.setToggleOn(false);
        binding.swReschedule.setToggleOn(false);
        binding.swReminder.setToggleOff(false);
        binding.swNotes.setOnToggleChanged(on -> {
            Map<String, Object> map = new HashMap<>();
            map.put("notesNotificationOpened", on);
            viewModel.updateNotification(map);
        });
        binding.swAchievement.setOnToggleChanged(on -> {
            Map<String, Object> map = new HashMap<>();
            map.put("newAchievementNotificationOpened", on);
            viewModel.updateNotification(map);
        });
        binding.swShare.setOnToggleChanged(on -> {
            Map<String, Object> map = new HashMap<>();
            map.put("fileSharedNotificationOpened", on);
            viewModel.updateNotification(map);
        });
        binding.swReschedule.setOnToggleChanged(on -> {
            Map<String, Object> map = new HashMap<>();
            map.put("rescheduleConfirmedNotificationOpened", on);
            viewModel.updateNotification(map);
        });

        binding.swReminder.setOnToggleChanged(on -> {
            Map<String, Object> map = new HashMap<>();
            if (on) {
                binding.linReminder.setVisibility(View.VISIBLE);
                map.put("reminderOpened", true);
            } else {
                binding.linReminder.setVisibility(View.GONE);
                map.put("reminderOpened", false);
            }
            viewModel.updateNotification(map);
        });
        binding.checkMin15.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityMin15.set(isChecked);
                viewModel.getReminderTime(5);
            }

        });
        binding.checkMin30.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityMin30.set(isChecked);
                viewModel.getReminderTime(10);
            }
        });
        binding.checkHour1.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour1.set(isChecked);
                viewModel.getReminderTime(15);
            }
        });
        binding.checkHours2.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour2.set(isChecked);
                viewModel.getReminderTime(30);
            }
        });
        binding.checkHour3.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour3.set(isChecked);
                viewModel.getReminderTime(60);
            }
        });
        binding.checkHour4.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour4.set(isChecked);
                viewModel.getReminderTime(120);
            }
        });
        binding.checkHour5.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityHour5.set(isChecked);
                viewModel.getReminderTime(180);
            }
        });
        binding.checkDay1.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                viewModel.visibilityDay1.set(isChecked);
                viewModel.getReminderTime(1440);
            }
        });
        initPracticeReminderView();

    }

    private void initRecyclerView() {
        PagerSnapHelper snapHelper = new PagerSnapHelper();
        snapHelper.attachToRecyclerView(binding.studentRecyclerview);
        binding.studentRecyclerview.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                if (newState == RecyclerView.SCROLL_STATE_IDLE) { //如果滚动结束
                    if (snapHelper.findSnapView(linearLayoutManager) == null) {
                        return;
                    }
                    View snapView = snapHelper.findSnapView(linearLayoutManager);
                    int currentPageIndex = linearLayoutManager.getPosition(snapView);
                    if (viewModel.selectIndex != currentPageIndex) { //防止重复提示
                        viewModel.selectIndex = currentPageIndex;
                        viewModel.selectStudent = viewModel.studentListData.get(currentPageIndex);
                        ListenerService.shared.parentUserData.selectStudentData = viewModel.selectStudent;
                        Messenger.getDefault().sendNoMsg(MessengerUtils.PARENT_SELECT_KIDS);
                        viewModel.isAddStudent.set(viewModel.studentListData.get(currentPageIndex).getUserId().equals("ADD"));
                        Logger.e("11==>%s", 22);
                    }
                }
            }
        });
        binding.dotView.attachToRecyclerView(binding.studentRecyclerview, snapHelper);
        adapter = new BaseViewBindingRecyclerAdapter<UserEntity>(getContext(), viewModel.studentListData, R.layout.item_student_profile_student) {
            @Override
            public void convert(BaseViewBindingRecyclerHolder holder, UserEntity item, int position, boolean isScrolling) {
                if (holder.getBinding() instanceof ItemStudentProfileStudentBinding) {
                    ItemStudentProfileStudentBinding binding = (ItemStudentProfileStudentBinding) holder.getBinding();

                    if (item.getUserId().equals("ADD")) {
                        binding.addLayout.setVisibility(View.VISIBLE);
                        binding.totalLayout.setVisibility(View.GONE);
                    } else {
                        binding.addLayout.setVisibility(View.GONE);
                        binding.totalLayout.setVisibility(View.VISIBLE);
                        binding.avatarView.loadAvatar(item.getUserId(), item.getName(), 0);
                        binding.title.setText(item.getName());
                        binding.info.setText(item.getEmail());
                    }
                    if (viewModel.studentListData != null) {
                        FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) binding.mainLayout.getLayoutParams();
                        if (viewModel.studentListData.size() == 1) {
                            int screenWidth = UIUtils.getScreenWidth(getActivity());
                            layoutParams.width = screenWidth - AutoSizeUtils.pt2px(getActivity(), 40f);
                            binding.mainLayout.setPadding(0, 0, 0, AutoSizeUtils.pt2px(getActivity(), 10f));
                        } else {
                            layoutParams.width = AutoSizeUtils.pt2px(getActivity(), 295f);
                            if (position == 0) {
                                binding.mainLayout.setPadding(0, 0, AutoSizeUtils.pt2px(getActivity(), 10f), AutoSizeUtils.pt2px(getActivity(), 10f));
                            } else if (position == viewModel.studentListData.size() - 1) {
                                binding.mainLayout.setPadding(AutoSizeUtils.pt2px(getActivity(), 10f), 0, 0, AutoSizeUtils.pt2px(getActivity(), 10f));
                            } else {
                                binding.mainLayout.setPadding(AutoSizeUtils.pt2px(getActivity(), 10f), 0, AutoSizeUtils.pt2px(getActivity(), 10f), AutoSizeUtils.pt2px(getActivity(), 10f));
                            }
                        }
                        binding.mainLayout.setLayoutParams(layoutParams);
                    }
                }
            }
        };
        binding.studentRecyclerview.setAdapter(adapter);
        adapter.registerAdapterDataObserver(binding.dotView.getAdapterDataObserver());
        adapter.setOnItemClickListener((parent, view, position) -> {
            if (position == viewModel.studentListData.size() - 1) {
                AddStudentDialog dialog = new AddStudentDialog(getContext(), AddStudentDialog.Source.PARENT_PROFILE, ListenerService.shared.parentUserData.parentUserData);
                dialog.showDialog();
                dialog.setClickConfirm(user -> {
//                    viewModel.studentListData.add(viewModel.studentListData.size()-1,user);
//                    adapter.refreshData(viewModel.studentListData);
                    int currentPageIndex = viewModel.studentListData.size() - 1;
                    adapter.add(user, viewModel.studentListData.size() - 1);
//                    if (viewModel.selectIndex != currentPageIndex) { //防止重复提示
//                        viewModel.selectIndex = currentPageIndex;
//                        viewModel.selectStudent = viewModel.studentListData.get(currentPageIndex);
                    viewModel.selectStudent = user;
                    ListenerService.shared.parentUserData.selectStudentData = viewModel.selectStudent;
                    Messenger.getDefault().sendNoMsg(MessengerUtils.PARENT_SELECT_KIDS);
                    viewModel.isAddStudent.set(false);
//                    }
                    return null;
                });
            }


        });
    }

    private void initPracticeReminderView() {


//        Logger.e("????==>%s",SLJsonUtils.toJsonString(viewModel.notificationData.getValue().getWorkdayPracticeReminder()));
//        Logger.e("????==>%s",SLJsonUtils.toJsonString(viewModel.notificationData.getValue().getWeekendPracticeReminder()));
////
//        initPracticeReminder(workData, weekData);

        binding.swPractice.setOnToggleChanged(on -> {
            binding.practiceWorkLayout.setVisibility(on ? View.VISIBLE : View.GONE);
            binding.practiceWeekLayout.setVisibility(on ? View.VISIBLE : View.GONE);
            Map<String, Object> map = new HashMap<>();
            map.put("practiceReminderOpened", on);
            if (on) {
                map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                initPracticeReminder(viewModel.notificationData.getValue().getWorkdayPracticeReminder(), viewModel.notificationData.getValue().getWeekendPracticeReminder());
            }


            viewModel.updateNotification(map);

        });
        binding.practiceWork1.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWorkdayPracticeReminder().size() > 0) {
                time = viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(0).getTime();
            }
            showSelectTimeDialog(time, 1);
        });
        binding.practiceWork2.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWorkdayPracticeReminder().size() > 1) {
                time = viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(1).getTime();
            }
            showSelectTimeDialog(time, 2);
        });
        binding.practiceWork3.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWorkdayPracticeReminder().size() > 2) {
                time = viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(2).getTime();
            }
            showSelectTimeDialog(time, 3);
        });
        binding.practiceWeek1.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWeekendPracticeReminder().size() > 0) {
                time = viewModel.notificationData.getValue().getWeekendPracticeReminder().get(0).getTime();
            }
            showSelectTimeDialog(time, 4);
        });
        binding.practiceWeek2.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWeekendPracticeReminder().size() > 1) {
                time = viewModel.notificationData.getValue().getWeekendPracticeReminder().get(1).getTime();
            }
            showSelectTimeDialog(time, 5);
        });
        binding.practiceWeek3.setOnClickListener(v -> {
            int time = -1;
            if (viewModel.notificationData.getValue() != null && viewModel.notificationData.getValue().getWeekendPracticeReminder().size() > 2) {
                time = viewModel.notificationData.getValue().getWeekendPracticeReminder().get(2).getTime();
            }
            showSelectTimeDialog(time, 6);
        });
    }

    private void showSelectTimeDialog(int time, int type) {
        boolean isHaveDelete = time != -1;
        int startTime = (int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L);

        if (time == -1) {
            time = TimeUtils.getCurrentTime();
        } else {
            time = time + startTime;
        }
        int hour = Integer.parseInt(TimeUtils.getFormatHour(time * 1000L));
        int min = Integer.parseInt(TimeUtils.getFormatMinute(time * 1000L));

        TKSelectTimeDialog dialog = new TKSelectTimeDialog(getContext(), hour, min, isHaveDelete);
        dialog.showDialog();
        dialog.setClickListener(new TKSelectTimeDialog.OnClickListener() {
            @Override
            public void onClickConfirm(int time) {
                Logger.e("type==>%s=>%s", type, time);
                try {
                    NotificationEntity.PracticeReminder reminder = new NotificationEntity.PracticeReminder();
                    reminder.setTime(time);
                    reminder.setEnable(true);
                    Map<String, Object> map = new HashMap<>();
                    switch (type) {
                        case 1:
                            viewModel.notificationData.getValue().getWorkdayPracticeReminder().set(0, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWorkdayPracticeReminder().add(reminder);
//                            }
                            map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                            break;
                        case 2:
                            viewModel.notificationData.getValue().getWorkdayPracticeReminder().set(1, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWorkdayPracticeReminder().add(reminder);
//                            }
                            map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                            break;
                        case 3:
                            viewModel.notificationData.getValue().getWorkdayPracticeReminder().set(2, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWorkdayPracticeReminder().add(reminder);
//                            }
                            map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                            break;
                        case 4:
                            viewModel.notificationData.getValue().getWeekendPracticeReminder().set(0, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWeekendPracticeReminder().add(reminder);
//                            }
                            map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                            break;
                        case 5:
                            viewModel.notificationData.getValue().getWeekendPracticeReminder().set(1, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWeekendPracticeReminder().add(reminder);
//                            }
                            map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                            break;
                        case 6:
                            viewModel.notificationData.getValue().getWeekendPracticeReminder().set(2, reminder);
//                            if (isHaveDelete) {
//                            } else {
//                                viewModel.notificationData.getValue().getWeekendPracticeReminder().add(reminder);
//                            }
                            map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                            break;
                    }

                    viewModel.updateNotification(map);
                    initPracticeReminder(viewModel.notificationData.getValue().getWorkdayPracticeReminder(), viewModel.notificationData.getValue().getWeekendPracticeReminder());
                } catch (Throwable e) {
                    Logger.e("失败==>%s", e.getMessage());
                }

            }

            @Override
            public void onClickDelete() {
                Map<String, Object> map = new HashMap<>();
                switch (type) {
                    case 1:

                        viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(0).setTime(-1).setEnable(false);
                        map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                        break;
                    case 2:
                        viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(1).setTime(-1).setEnable(false);
                        map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                        break;
                    case 3:
                        viewModel.notificationData.getValue().getWorkdayPracticeReminder().get(2).setTime(-1).setEnable(false);
                        map.put("workdayPracticeReminder", viewModel.notificationData.getValue().getWorkdayPracticeReminder());
                        break;
                    case 4:
                        viewModel.notificationData.getValue().getWeekendPracticeReminder().get(0).setTime(-1).setEnable(false);
                        map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                        break;
                    case 5:
                        viewModel.notificationData.getValue().getWeekendPracticeReminder().get(1).setTime(-1).setEnable(false);
                        map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                        break;
                    case 6:
                        viewModel.notificationData.getValue().getWeekendPracticeReminder().get(2).setTime(-1).setEnable(false);
                        map.put("weekendPracticeReminder", viewModel.notificationData.getValue().getWeekendPracticeReminder());
                        break;
                }

                initPracticeReminder(viewModel.notificationData.getValue().getWorkdayPracticeReminder(), viewModel.notificationData.getValue().getWeekendPracticeReminder());
                viewModel.updateNotification(map);
            }
        });
    }

    private String initPracticeTime(int time) {
        if (startTime == 0) {
            startTime = (int) (TimeUtils.getStartDay(TimeUtils.getCurrentTime()).getTimeInMillis() / 1000L);
        }
        return TimeUtils.timeFormat(startTime + time, "h:mm aa");
    }

    private void initPracticeReminder(List<NotificationEntity.PracticeReminder> workData, List<NotificationEntity.PracticeReminder> weekData) {
        if (viewModel.notificationData.getValue() == null) {
            return;
        }

        binding.practiceWork1.setText("");
        binding.practiceWorkImage1.setVisibility(View.INVISIBLE);
        binding.practiceWorkAdd1.setVisibility(View.VISIBLE);
        binding.practiceWork1.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWork1.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));

        binding.practiceWork2.setText("");
        binding.practiceWorkImage2.setVisibility(View.INVISIBLE);
        binding.practiceWorkAdd2.setVisibility(View.VISIBLE);
        binding.practiceWork2.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWork2.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));

        binding.practiceWork3.setText("");
        binding.practiceWorkImage3.setVisibility(View.INVISIBLE);
        binding.practiceWorkAdd3.setVisibility(View.VISIBLE);
        binding.practiceWork3.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWork3.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));

        binding.practiceWeek1.setText("");
        binding.practiceWeekImage1.setVisibility(View.INVISIBLE);
        binding.practiceWeekAdd1.setVisibility(View.VISIBLE);
        binding.practiceWeek1.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWeek1.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));

        binding.practiceWeek2.setText("");
        binding.practiceWeekImage2.setVisibility(View.INVISIBLE);
        binding.practiceWeekAdd2.setVisibility(View.VISIBLE);
        binding.practiceWeek2.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWeek2.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));

        binding.practiceWeek3.setText("");
        binding.practiceWeekImage3.setVisibility(View.INVISIBLE);
        binding.practiceWeekAdd3.setVisibility(View.VISIBLE);
        binding.practiceWeek3.setBackground(ContextCompat.getDrawable(getContext(), R.drawable.textview_border));
        binding.practiceWeek3.setTextColor(ContextCompat.getColor(getContext(), R.color.primary));


        for (int i = 0; i < workData.size(); i++) {
            if (i == 0) {
                if (workData.get(i).getTime() != -1) {
                    binding.practiceWork1.setText(initPracticeTime(workData.get(i).getTime()));
                    binding.practiceWorkAdd1.setVisibility(View.GONE);
                    binding.practiceWorkImage1.setVisibility(workData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWork1.setBackground(ContextCompat.getDrawable(getContext(), workData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWork1.setTextColor(ContextCompat.getColor(getContext(), workData.get(i).isEnable() ? R.color.main : R.color.primary));
                }

            }
            if (i == 1) {
                if (workData.get(i).getTime() != -1) {
                    binding.practiceWork2.setText(initPracticeTime(workData.get(i).getTime()));
                    binding.practiceWorkAdd2.setVisibility(View.GONE);
                    binding.practiceWorkImage2.setVisibility(workData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWork2.setBackground(ContextCompat.getDrawable(getContext(), workData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWork2.setTextColor(ContextCompat.getColor(getContext(), workData.get(i).isEnable() ? R.color.main : R.color.primary));
                }

            }
            if (i == 2) {
                if (workData.get(i).getTime() != -1) {
                    binding.practiceWork3.setText(initPracticeTime(workData.get(i).getTime()));
                    binding.practiceWorkAdd3.setVisibility(View.GONE);
                    binding.practiceWorkImage3.setVisibility(workData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWork3.setBackground(ContextCompat.getDrawable(getContext(), workData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWork3.setTextColor(ContextCompat.getColor(getContext(), workData.get(i).isEnable() ? R.color.main : R.color.primary));
                }

            }
        }
        for (int i = 0; i < weekData.size(); i++) {
            if (i == 0) {
                if (weekData.get(i).getTime() != -1) {
                    binding.practiceWeek1.setText(initPracticeTime(weekData.get(i).getTime()));
                    binding.practiceWeekAdd1.setVisibility(View.GONE);
                    binding.practiceWeekImage1.setVisibility(weekData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWeek1.setBackground(ContextCompat.getDrawable(getContext(), weekData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWeek1.setTextColor(ContextCompat.getColor(getContext(), weekData.get(i).isEnable() ? R.color.main : R.color.primary));
                }
            }
            if (i == 1) {
                if (weekData.get(i).getTime() != -1) {
                    binding.practiceWeek2.setText(initPracticeTime(weekData.get(i).getTime()));
                    binding.practiceWeekAdd2.setVisibility(View.GONE);
                    binding.practiceWeekImage2.setVisibility(weekData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWeek2.setBackground(ContextCompat.getDrawable(getContext(), weekData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWeek2.setTextColor(ContextCompat.getColor(getContext(), weekData.get(i).isEnable() ? R.color.main : R.color.primary));
                }
            }
            if (i == 2) {
                if (weekData.get(i).getTime() != -1) {
                    binding.practiceWeek3.setText(initPracticeTime(weekData.get(i).getTime()));
                    binding.practiceWeekAdd3.setVisibility(View.GONE);
                    binding.practiceWeekImage3.setVisibility(weekData.get(i).isEnable() ? View.VISIBLE : View.INVISIBLE);
                    binding.practiceWeek3.setBackground(ContextCompat.getDrawable(getContext(), weekData.get(i).isEnable() ? R.drawable.main_border : R.drawable.textview_border));
                    binding.practiceWeek3.setTextColor(ContextCompat.getColor(getContext(), weekData.get(i).isEnable() ? R.color.main : R.color.primary));
                }
            }
        }


    }

    @Override
    public void initViewObservable() {

        viewModel.uc.refreshStudentList.observe(this, unused -> {
            if (viewModel.studentListData.size() == 1) {
                binding.dotView.setVisibility(View.GONE);
                //                binding.studioRecyclerview.setPadding(AutoSizeUtils.pt2px(getActivity(), 20), 0, AutoSizeUtils.pt2px(getActivity(), 10), 0);
            } else {
                binding.dotView.setVisibility(View.VISIBLE);
                //                binding.studioRecyclerview.setPadding(AutoSizeUtils.pt2px(getActivity(), 20), 0, AutoSizeUtils.pt2px(getActivity(), 10), 0);
            }
            adapter.refreshData(viewModel.studentListData);
        });

        viewModel.uc.toMainActivity.observe(this, integer -> {
            Intent intent;
            if (integer == 1) {
                intent = new Intent(getContext(), MainActivity.class);
            } else if (integer == 2) {
                intent = new Intent(getContext(), StudentMainActivity.class);
            } else {
                intent = new Intent(getActivity(), LoginActivity.class);
            }

            intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getActivity().startActivity(intent);
            getActivity().overridePendingTransition(me.goldze.mvvmhabit.R.anim.anim_navigation_show, me.goldze.mvvmhabit.R.anim.anim_navigation_hidden_1);

        });
        viewModel.uc.clickSwitchAccount.observe(this, unused -> {
            List<LoginHistoryItemVM.TKLoginHistory> loginHistory = SLCacheUtil.getLoginHistory().stream().filter(it -> !it.getPassword().equals("")).collect(Collectors.toList());
            loginHistory.removeIf(it -> (it.getUserId().equals(UserService.getInstance().getCurrentUserId()) || it.getUserData() == null));
            SwitchAccountDialog dialog = new SwitchAccountDialog(getContext(), loginHistory);
            dialog.showDialog();
            dialog.setClickSignOut(() -> {
                SharePreferenceUtils.clear(getContext());
                FirebaseAuth.getInstance().signOut();
                viewModel.logout.setValue(true);
                return null;
            });
            dialog.setSelectUser(pos -> {
                SharePreferenceUtils.clear(getContext());
                TKNotificationUtils.closeLessonNotification(getActivity());
                FirebaseAuth.getInstance().signOut();

                LoginHistoryItemVM.TKLoginHistory data = loginHistory.get(pos);
                viewModel.switchAccount(data);

                return null;
            });


        });

        viewModel.uc.clickFAQ.observe(this, unused -> startActivity(FaqActivity.class));

        viewModel.logout.observe(this, aBoolean -> {
            TKNotificationUtils.closeLessonNotification(getActivity());
            Intent intent = new Intent(getActivity(), LoginActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        });
        viewModel.teacherId.observe(this, s -> {
            if (!s.equals("")) {
                viewModel.initChatData();
            }
        });
        viewModel.uc.clickContact.observe(this, unused -> {
            Dialog dialog = new Dialog(getActivity(), R.style.BottomDialog);

            View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.dialog_contact, null);
            contentView.findViewById(R.id.messageLayout).setOnClickListener(v -> {
                viewModel.getSupportGroupConversation();
                dialog.dismiss();
            });
            contentView.findViewById(R.id.textLayout).setOnClickListener(v -> {
                try {
                    Intent intent = new Intent(Intent.ACTION_SENDTO);
                    intent.setData(Uri.parse("smsto:14088688371"));           //设置发送的号码
                    intent.putExtra("sms_body", "");
                    startActivity(intent);
                    dialog.dismiss();
                } catch (Throwable e) {
                    SLToast.error("Failed to open SMS, please try again!");
                }

            });
            contentView.findViewById(R.id.emailLayout).setOnClickListener(v -> {
                String[] TO = {"support@tunekey.app"};
                Intent emailIntent = new Intent(Intent.ACTION_SEND);
                emailIntent.setData(Uri.parse("mailto:"));
                emailIntent.setType("text/plain");
                emailIntent.putExtra(Intent.EXTRA_EMAIL, TO);

                try {
                    startActivity(emailIntent);
                } catch (android.content.ActivityNotFoundException ex) {
                    SLToast.error("Failed to open email, please try again!");
                }
                dialog.dismiss();
            });
            contentView.findViewById(R.id.followLayout).setOnClickListener(v -> {

                viewModel.getFollowUsData();
                //youtube
//                toApp("https://www.youtube.com/channel/UCxpG0ByYyvLadNKrukECAgw","https://www.youtube.com/channel/UCxpG0ByYyvLadNKrukECAgw","com.google.android.youtube");
                //instagram
//                toApp("https://www.instagram.com/tunekeyapp/","https://www.instagram.com/tunekeyapp/","com.instagram.android");
                //facebook
//                toApp("fb://page/105654964705036","com.facebook.katana");
                //Twitter
//                toApp("https://twitter.com/TunekeyA","twitter://user?screen_name=TunekeyA","com.twitter.android");
                // Tik tok
//                toApp("https://www.tiktok.com/@tunekeyapp","https://www.tiktok.com/@tunekeyapp","com.zhiliaoapp.musically");
//               toApp("https://tunekey.app","https://tunekey.app","");

                dialog.dismiss();
            });

            contentView.findViewById(R.id.cancel).setOnClickListener(v -> {
                dialog.dismiss();
            });
            dialog.setContentView(contentView);
            ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
            layoutParams.width = getResources().getDisplayMetrics().widthPixels;
            contentView.setLayoutParams(layoutParams);
            dialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
            dialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
            dialog.show();//显示弹窗
        });
        viewModel.uc.showFollow.observe(this, followUs -> {
            FollowUsDialog dialog = new FollowUsDialog(getActivity(), followUs.getResources());
            BasePopupView popupView = new XPopup.Builder(getActivity())
                    .isDestroyOnDismiss(true)
                    .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(false)
                    .asCustom(dialog)
                    .show();
            dialog.setClickListener(data -> {
                popupView.dismiss();
                toApp(data.getFailedUrl(), data.getAndroidIntentUrl(), data.getAndroidPackageName());
            });

        });
        viewModel.uc.refreshAvatar.observe(this, time -> {
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    binding.avatarView.refreshAvatar(time);
                }
            });
        });
        viewModel.uc.clickInviteInstructor.observe(this, unused -> {
            //点击邀请老师
            AddTeacherDialog dialog = new AddTeacherDialog(getContext(), "");
            BasePopupView popupView = new XPopup.Builder(getContext())
                    .isDestroyOnDismiss(true)
                    .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(false)
                    .asCustom(dialog)
                    .show();
            dialog.setClickListener(popupView::dismiss);
        });

        viewModel.isReminderOpened.observe(this, isReminderOpened -> {
            if (isReminderOpened) {
                binding.swReminder.setToggleOn(false);
            } else {
                binding.swReminder.setToggleOff(false);
            }
            binding.linReminder.setVisibility(isReminderOpened ? View.VISIBLE : View.GONE);
        });
        viewModel.notificationData.observe(this, notificationEntity -> {
            if (notificationEntity.isPracticeReminderOpened()) {
                binding.swPractice.setToggleOn(false);
                binding.practiceWorkLayout.setVisibility(View.VISIBLE);
                binding.practiceWeekLayout.setVisibility(View.VISIBLE);
            } else {
                binding.swPractice.setToggleOff(false);
                binding.practiceWorkLayout.setVisibility(View.GONE);
                binding.practiceWeekLayout.setVisibility(View.GONE);
            }
            initPracticeReminder(notificationEntity.getWorkdayPracticeReminder(), notificationEntity.getWeekendPracticeReminder());

            if (notificationEntity.isNotesNotificationOpened()) {
                binding.swNotes.setToggleOn(false);
            } else {
                binding.swNotes.setToggleOff(false);
            }
            if (notificationEntity.isNewAchievementNotificationOpened()) {
                binding.swAchievement.setToggleOn(false);
            } else {
                binding.swAchievement.setToggleOff(false);
            }
            if (notificationEntity.isFileSharedNotificationOpened()) {
                binding.swShare.setToggleOn(false);
            } else {
                binding.swShare.setToggleOff(false);
            }
            if (notificationEntity.isRescheduleConfirmedNotificationOpened()) {
                binding.swReschedule.setToggleOn(false);
            } else {
                binding.swShare.setToggleOff(false);
            }
        });

        viewModel.userName.observe(this, s -> {
            binding.avatarView.loadAvatar(viewModel.userId.getValue(), viewModel.userName.getValue(), 0);
        });
    }

    public void toApp(String url, String intentUrl, String packageName) {
        Intent intent = null;
        if (!packageName.equals("")) {
            try {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setPackage(packageName);
                intent.setData(Uri.parse(intentUrl));
                startActivity(intent);
            } catch (Throwable e) {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                startActivity(intent);
            }
        } else {
            try {
                intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                startActivity(intent);
            } catch (Throwable e) {
                SLToast.error("Failed to open app, please try again!");
            }
        }
    }
}
