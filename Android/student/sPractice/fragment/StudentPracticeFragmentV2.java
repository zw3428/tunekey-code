package com.spelist.tunekey.ui.student.sPractice.fragment;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Dialog;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.lxj.xpopup.interfaces.XPopupCallback;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SubmitButton;
import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.FragmentStudentPracticeV2Binding;
import com.spelist.tunekey.entity.TKPractice;
import com.spelist.tunekey.entity.TKPracticeAssignment;
import com.spelist.tunekey.ui.student.sPractice.activity.recordVideo.RecordVideoAc;
import com.spelist.tunekey.ui.student.sPractice.dialogs.PracticeDialog;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordHistoryDialog;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;
import com.spelist.tunekey.ui.student.sPractice.vm.StudentPracticeFragmentV2VM;
import com.spelist.tunekey.ui.toolsView.base.BaseFragmentPagerAdapter;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.tatarka.bindingcollectionadapter2.BR;

/**
 * com.spelist.tunekey.ui.sPractice.fragment
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeFragmentV2 extends BaseFragment<FragmentStudentPracticeV2Binding, StudentPracticeFragmentV2VM> {
    private StudentPracticeLogFragment practiceLogFragment = new StudentPracticeLogFragment();
    private StudentPracticeMetronomeFragment metronomeFragment = new StudentPracticeMetronomeFragment();
    private List<Fragment> fragments = new ArrayList<>();
    private List<String> titleList = new ArrayList<>();
    public BaseFragmentPagerAdapter pagerAdapter;
    private String logDate = "";

    /**
     * 初始化根布局
     *
     * @param inflater
     * @param container
     * @param savedInstanceState
     * @return 布局layout的id
     */
    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_practice_v2;
    }

    /**
     * 初始化ViewModel的id
     *
     * @return BR的id
     */
    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
    }

    @Override
    public void initView() {
        super.initView();
        fragments.add(practiceLogFragment);
        fragments.add(metronomeFragment);
        titleList.add("Log Sheet");
        titleList.add("Metronome");
        pagerAdapter = new BaseFragmentPagerAdapter(getChildFragmentManager(), fragments, titleList);
        binding.viewPager.setAdapter(pagerAdapter);
//        binding.viewPager.setScroll(true);
        binding.viewPager.setOffscreenPageLimit(2);
        binding.titleTabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.titleTabs));
        binding.titleTabs.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {

            }
        });
        binding.logPreviousDays.setOnClickListener(v -> {

            selectDate();

        });
        viewModel.uc.logForDay.observe(this, tkPractices -> {
            logForDay(logDate, tkPractices);
        });

    }

    private void selectDate() {
        Dialog endDialog = new Dialog(getContext(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getContext()).inflate(R.layout.dialog_layout_end, null);
        //获取Dialog的监听
        TextView cancel = (TextView) contentView.findViewById(R.id.tv_cancel);

        WebView webView1 = contentView.findViewById(R.id.web_view);
        SubmitButton submitButton1 = contentView.findViewById(R.id.tv_confirm);
        FuncUtils.initWebViewSetting(webView1, "file:///android_asset/web/cal.month.for.popup.v2.html");
        Host webHost1 = new Host();
        webView1.addJavascriptInterface(webHost1, "js");

        logDate = com.spelist.tools.tools.TimeUtils.timestampToString(TimeUtils.addDay(TimeUtils.getCurrentTime() * 1000L, -1) / 1000L, "yyyy/MM/dd");
        String startDate = com.spelist.tools.tools.TimeUtils.timestampToString(0, "yyyy/MM/dd");
        webView1.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                webView1.evaluateJavascript("getCalendarStartYMD('" + startDate + "','" + logDate + "')", s -> {
                });

            }

        });
        cancel.setOnClickListener(v -> endDialog.dismiss());
        submitButton1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                viewModel.specifiedTimeHomeWork(logDate);

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

    private void logForDay(String yyyyMMDD, List<TKPractice> practiceData) {
        Logger.e("选中的日期==>%s", yyyyMMDD);
        if (metronomeFragment != null) {
            metronomeFragment.stop();
        }
        List<TKPractice> oldData = new ArrayList<>();
//        TKPracticeAssignment selectDatePractice = null;
//        for (TKPracticeAssignment item : viewModel.practiceData) {
//            if (TimeUtils.timeFormat(item.getStartTime(), "yyyy/MM/dd").equals(yyyyMMDD)) {
//                selectDatePractice = item;
//                break;
//            }
//        }
//        if (selectDatePractice != null) {
        oldData = practiceData.stream().filter(TKPractice::isAssignment).collect(Collectors.toList());
//        }

        //去除重复名字
        List<TKPractice> data = new ArrayList<>();
        for (TKPractice oldDatum : oldData) {
            boolean isHave = false;
            for (TKPractice datum : data) {
                if (datum.getName().equals(oldDatum.getName())) {
                    isHave = true;
                    break;
                }
            }
            if (!isHave) {
                data.add(oldDatum);
            }

        }


        for (TKPractice item : data) {
            for (int i = viewModel.practiceHistoryData.size() - 1; i >= 0; i--) {
                if (viewModel.practiceHistoryData.get(i).getName().trim().equals(item.getName().trim())) {
                    viewModel.practiceHistoryData.remove(i);
                }
            }
        }
        List<TKPractice> newList = new ArrayList<>();
        for (TKPractice item : viewModel.practiceHistoryData) {
            boolean isHave = false;
            for (TKPractice newItem : newList) {
                if (newItem.getName().trim().equals(item.getName().trim())) {
                    isHave = true;
                }
            }
            if (!isHave) {
                newList.add(item);
            }
        }
        viewModel.practiceHistoryData = newList;

        PracticeDialog practiceDialog = new PracticeDialog(getContext(), data, newList, 0, (TimeUtils.timeToStamp(yyyyMMDD, "yyyy/MM/dd") / 1000L));
        BasePopupView popupView = new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .autoFocusEditText(false)
                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(true)
                .enableDrag(false)
                .asCustom(practiceDialog)
                .show();
        practiceDialog.setOnClickListener((practice, type) -> {
//            Logger.e("????==>%s?==>%s==>%s", type,yyyyMMDD, SLJsonUtils.toJsonString(practice));
            List<TKPractice> list = new ArrayList<>();
            int startTime = (int) (TimeUtils.timeToStamp(yyyyMMDD, "yyyy/MM/dd") / 1000L) + 10;
            practice.setId(IDUtils.getId());
            practice.setStartTime(startTime);
            practice.setDone(true);
            practice.setUpdateTime(TimeUtils.getCurrentTime() + "");
            practice.setManualLog(true);
            list.add(practice);
            viewModel.addPractice(list, true, false, false);

//            if (type == 0) {
//                List<TKPractice> list = new ArrayList<>();
//                int startTime = (int) (TimeUtils.timeToStamp(yyyyMMDD, "yyyy/MM/dd") / 1000L) + 10;
//                Logger.e("startTime==>%s",startTime);
//                practice.setStartTime(startTime);
//                list.add(practice);
//                viewModel.addPractice(list, true, false, false);
//            } else if (type == 1) {
//                Map<String, Object> map = new HashMap<>();
//                map.put("totalTimeLength", practice.getTotalTimeLength());
//                map.put("done", true);
//                map.put("updateTime", TimeUtils.getCurrentTime()+"");
//                map.put("manualLog", true);
//                viewModel.upDataPractice(map, practice.getId());
//            }
        });
    }

    @SuppressLint("CheckResult")
    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.recordVideoDone.observe(this, tkPractice -> {
            if (getActivity() != null) {
                getActivity().runOnUiThread(() -> {
                    RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(getContext(), this, tkPractice, getActivity(), 2, false);
                    recordHistoryDialog.showDialog();
                    recordHistoryDialog.setClickListener(deleteId -> {
                    });
                });
            } else {

                RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(getContext(), this, tkPractice, getActivity(), 2, false);
                recordHistoryDialog.showDialog();
                recordHistoryDialog.setClickListener(deleteId -> {
                });

            }


        });
        viewModel.uc.recordAudioDone.observe(this, tkPractice -> {
            if (getActivity() != null) {
                getActivity().runOnUiThread(() -> {

                    RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(getContext(), this, tkPractice, getActivity(), 1, false);
                    recordHistoryDialog.showDialog();
                    recordHistoryDialog.setClickListener(deleteId -> {
//                if (deleteId.size() > 0) {
//                    viewModel.deleteAudio(deleteId, tkPractice);
//                }
                    });
                });
            } else {
                RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(getContext(), this, tkPractice, getActivity(), 1, false);
                recordHistoryDialog.showDialog();
                recordHistoryDialog.setClickListener(deleteId -> {
//                if (deleteId.size() > 0) {
//                    viewModel.deleteAudio(deleteId, tkPractice);
//                }
                });
            }

        });

        viewModel.uc.refData.observe(this, aVoid -> {

            practiceLogFragment.setData(viewModel, logDate);
            logDate = "";
        });
        viewModel.uc.stopMetronome.observe(this, unused -> {
            if (metronomeFragment != null) {
                metronomeFragment.stop();
            }
        });
        viewModel.uc.clickPlayPractice.observe(this, practice -> {
            if (metronomeFragment != null) {
                metronomeFragment.stop();
            }

            TKPractice data = CloneObjectUtils.cloneObject(practice);
            List<String> notUploadPracticeFileId = SLCacheUtil.getNotUploadPracticeFileId(UserService.getInstance().getCurrentUserId());
            data.getRecordData().removeIf(record -> {
                if (record.isUpload()) {
                    return false;
                } else {
                    return !(notUploadPracticeFileId.contains(record.getId()));
                }
            });


            RecordHistoryDialog recordHistoryDialog = new RecordHistoryDialog(getContext(), this, data, getActivity(), 0, false);
            recordHistoryDialog.showDialog();
            recordHistoryDialog.setClickListener(deleteId -> {
//                if (deleteId.size() > 0) {
//                    viewModel.deleteAudio(deleteId, practice);
//                }
            });
//修改practice
//            new RxPermissions(this)
//                    .request(Manifest.permission.READ_EXTERNAL_STORAGE
//                            , Manifest.permission.WRITE_EXTERNAL_STORAGE)
//                    .subscribe(aBoolean -> {
//                        if (aBoolean) {
//                            PlayPracticeDialog playPracticeDialog = new PlayPracticeDialog(getActivity(), practice, true);
//                            new XPopup.Builder(getContext())
//                                    .isDestroyOnDismiss(true)
//                                    .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
//                                    .dismissOnTouchOutside(false)
//                                    .enableDrag(false)
//                                    .asCustom(playPracticeDialog)
//                                    .show();
//                            playPracticeDialog.setOnClickCloseListener(deleteId -> {
//                                if (deleteId.size() > 0) {
//                                    viewModel.deleteAudio(deleteId, practice);
//                                }
//                            });
//                        } else {
//                            SLToast.warning("Please allow to access your device and try again.");
//                        }
//                    });

        });
        viewModel.uc.recordPractice.observe(this, practice -> {
            if (metronomeFragment != null) {
                metronomeFragment.stop();
            }
            List<String> permissionsList = new ArrayList<>();
            permissionsList.add(Manifest.permission.MODIFY_AUDIO_SETTINGS);
            permissionsList.add(Manifest.permission.RECORD_AUDIO);
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
                permissionsList.add("android.permission.READ_MEDIA_AUDIO");
            } else {
                permissionsList.add(Manifest.permission.READ_EXTERNAL_STORAGE);
                permissionsList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
            }
            String[] permissions = permissionsList.toArray(new String[0]);
            new RxPermissions(this)
                    .request(permissions)
                    .subscribe(aBoolean -> {
                        if (aBoolean) {
                            List<TKPractice> practices = new ArrayList<>();
                            for (TKPracticeAssignment practiceDatum : viewModel.practiceData) {
                                for (TKPractice tkPractice : practiceDatum.getPractice()) {
                                    if (tkPractice.getId().equals(practice.getId())) {
                                        tkPractice.setSelect(true);
                                        practices.addAll(practiceDatum.getPractice());
                                        break;
                                    }
                                }
                            }
                            if (practices.size() == 0) {
                                practice.setSelect(true);
                                practices.add(practice);
                            }

                            //开启屏幕常亮
                            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                            RecordPracticeDialog recordPracticeDialog = new RecordPracticeDialog(getActivity(), practices);
                            BasePopupView popupView = new XPopup.Builder(getContext())
                                    .isDestroyOnDismiss(true)
                                    .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                                    .dismissOnTouchOutside(false)
                                    .enableDrag(false)
                                    .setPopupCallback(new XPopupCallback() {
                                        @Override
                                        public void onCreated(BasePopupView popupView) {

                                        }

                                        @Override
                                        public void beforeShow(BasePopupView popupView) {

                                        }

                                        @Override
                                        public void onShow(BasePopupView popupView) {

                                        }

                                        @Override
                                        public void onDismiss(BasePopupView popupView) {
                                            //关闭屏幕常亮
                                            getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

                                        }

                                        @Override
                                        public void beforeDismiss(BasePopupView popupView) {

                                        }

                                        @Override
                                        public boolean onBackPressed(BasePopupView popupView) {
                                            return false;
                                        }

                                        @Override
                                        public void onKeyBoardStateChanged(BasePopupView popupView, int height) {

                                        }

                                        @Override
                                        public void onDrag(BasePopupView popupView, int value, float percent, boolean upOrLeft) {

                                        }

                                        @Override
                                        public void onClickOutside(BasePopupView popupView) {

                                        }
                                    })
                                    .asCustom(recordPracticeDialog)
                                    .show();
                            recordPracticeDialog.setOnRecordListener((uploadData, totalTime, logId) -> {
//                                viewModel.recordDone(uploadData,totalTime,logId);
                                int pos = 0;
                                for (int i = 0; i < practices.size(); i++) {
                                    if (practices.get(i).getId().equals(logId)) {
                                        pos = i;
                                        break;
                                    }
                                }
                                practices.get(pos).setTotalTimeLength(practices.get(pos).getTotalTimeLength() + totalTime);

                                Logger.e("sdsdsd==>%s",SLJsonUtils.toJsonString(uploadData));
                                if (uploadData.size() > 0) {
                                    for (RecordPracticeDialog.UploadRecode item : uploadData) {
                                        if (!item.getPath().equals("")) {
                                            if (item.getTime() == 0) {
                                                item.setTime(TimeUtils.getCurrentTime());
                                            }
                                            TKPractice.PracticeRecord recordData = new TKPractice.PracticeRecord();
                                            recordData.setId(item.getId())
                                                    .setDuration(item.getDuration())
                                                    .setUpload(false)
                                                    .setStartTime(item.getTime())
                                                    .setOld(false)
                                                    .setFormat(".aac");

                                            practices.get(pos).getRecordData().add(recordData);
                                        }
                                    }

                                }
                                Logger.e("sdsdsd==>%s",SLJsonUtils.toJsonString(practices.get(pos)));

//                                viewModel.uploadPractice(CloneObjectUtils.cloneObject(practices.get(pos)), uploadData);
                                viewModel.uploadPractice(CloneObjectUtils.cloneObject(practices.get(pos)), false);
                            });
                        } else {
                            SLToast.warning("Please allow to access your device and try again.");
                        }
                    });


        });

        viewModel.uc.clickLogAndStartPractice.observe(this, showType -> {
            if (metronomeFragment != null) {
                metronomeFragment.stop();
            }
            List<TKPractice> data = new ArrayList<>();
            data = viewModel.practiceData.get(0).getPractice().stream().filter(TKPractice::isAssignment).collect(Collectors.toList());
            for (TKPractice item : data) {
                for (int i = viewModel.practiceHistoryData.size() - 1; i >= 0; i--) {
                    if (viewModel.practiceHistoryData.get(i).getName().trim().equals(item.getName().trim())) {
                        viewModel.practiceHistoryData.remove(i);
                    }
                }
            }
            List<TKPractice> newList = new ArrayList<>();
            for (TKPractice item : viewModel.practiceHistoryData) {
                boolean isHave = false;


                for (TKPractice newItem : newList) {
                    if (newItem.getName().trim().equals(item.getName().trim())) {
                        isHave = true;
                    }
                }
                if (!isHave) {
                    newList.add(item);
                }
            }
            viewModel.practiceHistoryData = newList;
            if (showType == 0) {
                PracticeDialog practiceDialog = new PracticeDialog(getContext(), data, newList, showType, TimeUtils.getCurrentTime());
                BasePopupView popupView = new XPopup.Builder(getContext())
                        .isDestroyOnDismiss(true)
                        .autoFocusEditText(false)
                        .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                        .dismissOnTouchOutside(true)
                        .enableDrag(false)
                        .asCustom(practiceDialog)
                        .show();
                practiceDialog.setOnClickListener((practice, type) -> {
                    if (type == 0) {
                        List<TKPractice> list = new ArrayList<>();
                        practice.setId(IDUtils.getId());
                        list.add(practice);
                        viewModel.addPractice(list, true, false, false);
                    } else if (type == 1) {
                        Map<String, Object> map = new HashMap<>();
                        map.put("totalTimeLength", practice.getTotalTimeLength());
                        map.put("updateTime", TimeUtils.getCurrentTime() + "");
                        map.put("done", true);
                        map.put("manualLog", true);
                        viewModel.upDataPractice(map, practice.getId());
                    }
                });
            } else {
                BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity())
                        .addMenuItems(new MenuItem("Audio Recording"))
                        .addMenuItems(new MenuItem("Video Recording"));
                bottomMenuFragment.show();
                List<TKPractice> finalData = data;
                bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                    PracticeDialog practiceDialog = new PracticeDialog(getContext(), finalData, newList, showType, TimeUtils.getCurrentTime());
                    BasePopupView popupView = new XPopup.Builder(getContext())
                            .isDestroyOnDismiss(true)
                            .autoFocusEditText(false)
                            .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                            .dismissOnTouchOutside(true)
                            .enableDrag(false)
                            .asCustom(practiceDialog)
                            .show();
                    practiceDialog.setOnClickListener((practice, type) -> {
                        if (position == 0) {

                            if (type == 0) {
                                List<TKPractice> list = new ArrayList<>();
                                practice.setId(IDUtils.getId());
                                list.add(practice);
                                viewModel.addPractice(list, true, true, false);
                            } else {
                                viewModel.uc.recordPractice.setValue(practice);
                            }
                        } else {
                            if (type == 1) {
                                startRecordVideo(practice);
                            } else {
                                List<TKPractice> list = new ArrayList<>();
                                practice.setId(IDUtils.getId());
                                list.add(practice);
                                viewModel.addPractice(list, true, true, true);
                            }

                        }

                    });
                });

            }

//            PracticeDialog practiceDialog = new PracticeDialog(getContext(), data, newList, showType);
//            BasePopupView popupView = new XPopup.Builder(getContext())
//                    .isDestroyOnDismiss(true)
//                    .autoFocusEditText(false)
//                    .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
//                    .dismissOnTouchOutside(true)
//                    .enableDrag(false)
//                    .asCustom(practiceDialog)
//                    .show();
//            practiceDialog.setOnClickListener((practice, type) -> {
//                if (showType == 0) {
//                    if (type == 0) {
//                        List<TKPractice> list = new ArrayList<>();
//                        list.add(practice);
//                        viewModel.addPractice(list, true, false);
//                    } else if (type == 1) {
//                        Map<String, Object> map = new HashMap<>();
//                        map.put("totalTimeLength", practice.getTotalTimeLength());
//                        map.put("done", true);
//                        map.put("manualLog", true);
//                        viewModel.upDataPractice(map, practice.getId());
//                    }
//                } else {
//                    BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity())
//                            .addMenuItems(new MenuItem("Audio Recording"))
//                            .addMenuItems(new MenuItem("Video Recording"));
//                    bottomMenuFragment.show();
//                    bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
//                        if (position == 0) {
//
//                            if (type == 0) {
//                                List<TKPractice> list = new ArrayList<>();
//                                list.add(practice);
//                                viewModel.addPractice(list, true, true);
//                            } else {
//                                viewModel.uc.recordPractice.setValue(practice);
//                            }
//
//                        } else if (position == 1) {
//                            new RxPermissions(this)
//                                    .request(Manifest.permission.RECORD_AUDIO
//                                            , Manifest.permission.CAMERA
//                                            , Manifest.permission.READ_EXTERNAL_STORAGE
//                                            , Manifest.permission.WRITE_EXTERNAL_STORAGE)
//                                    .subscribe(aBoolean -> {
//                                        if (aBoolean) {
//                                            Bundle bundle = new Bundle();
//                                            bundle.putSerializable("data", CloneObjectUtils.cloneObject(practice));
//                                            startActivity(RecordVideoAc.class, bundle);
//                                        } else {
//                                            SLToast.warning("Please allow to access your device and try again.");
//                                        }
//                                    });
//                        }
//
//                    });
//                }
//
//
//            });

        });
        viewModel.uc.recordVideoPractice.observe(this, this::startRecordVideo);
    }

    @SuppressLint("CheckResult")
    private void startRecordVideo(TKPractice practice) {
        List<String> permissionsList = new ArrayList<>();
        permissionsList.add(Manifest.permission.MODIFY_AUDIO_SETTINGS);
        permissionsList.add(Manifest.permission.RECORD_AUDIO);
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
            permissionsList.add("android.permission.READ_MEDIA_AUDIO");
        } else {
            permissionsList.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            permissionsList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }
        String[] permissions = permissionsList.toArray(new String[0]);
        new RxPermissions(this)
                .request(permissions)
                .subscribe(aBoolean -> {
                    if (aBoolean) {
                        Bundle bundle = new Bundle();
                        bundle.putSerializable("data", CloneObjectUtils.cloneObject(practice));
                        startActivity(RecordVideoAc.class, bundle);
                    } else {
                        SLToast.warning("Please allow to access your device and try again.");
                    }
                });
    }

    public class Host {
        @JavascriptInterface
        public void onDatePick(String yymmd) {
            long l = TimeUtils.timeToStamp(yymmd, "yyyy-M-d");
            Logger.e("-*-*-*-*-*-*-*- pick date from js: " + yymmd);
            logDate = TimeUtils.timeFormat(l / 1000, "yyyy/MM/dd");
        }

        @JavascriptInterface
        public void consoleLog(String value) {
            Logger.e("-*-*-*-*-*-*-*- log from webview: " + value);
        }

    }

}
