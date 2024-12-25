package com.spelist.tunekey.ui.teacher.students.fragments;

import static com.spelist.tools.tools.SLStringUtils.isEmail;
import static com.spelist.tools.tools.SLStringUtils.isNoNull;

import android.Manifest;
import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.InputFilter;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.dynamiclinks.DynamicLink;
import com.google.firebase.dynamiclinks.FirebaseDynamicLinks;
import com.google.firebase.dynamiclinks.ShortDynamicLink;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.InputView;
import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.databinding.FragmentStudentBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.loginAndOnboard.login.vm.LoginHistoryItemVM;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.ui.teacher.students.activity.AddressBookActivity;
import com.spelist.tunekey.ui.toolsView.base.BaseFragmentPagerAdapter;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.goldze.mvvmhabit.base.BaseFragment;
import retrofit2.http.HEAD;

/**
 * Author WHT
 * Description:
 * Date :2019-10-07
 */
public class StudentsFragment extends BaseFragment<FragmentStudentBinding, StudentViewModel> {
    List<Fragment> fragments = new ArrayList<>();
    List<String> titleList = new ArrayList<>();
    private Dialog bottomDialog;
    private Dialog newContactDialog;
    public BaseFragmentPagerAdapter pagerAdapter;
    private StudentsItemFragment activeFragment;
    private StudentsItemFragment inactiveFragment;
    private StudentsItemFragment archivedFragment;
    private String sendMessageString = "";

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student;

    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {

        // viewModel.emptyLayoutVisibility.set(View.GONE);
        viewModel.getTeacherMemberLevel();
        viewModel.getStudentList();


    }

    @Override
    public void initView() {
        super.initView();
        activeFragment = new StudentsItemFragment();
        inactiveFragment = new StudentsItemFragment();
        archivedFragment = new StudentsItemFragment();
        fragments.add(inactiveFragment);
        fragments.add(activeFragment);
        fragments.add(archivedFragment);
        titleList.add("Inactive");
        titleList.add("Active");
        titleList.add("Archived");
        pagerAdapter = new BaseFragmentPagerAdapter(getChildFragmentManager(), fragments, titleList);
        binding.viewPager.setAdapter(pagerAdapter);
        binding.viewPager.setOffscreenPageLimit(3);
        binding.tabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.tabs));

        binding.tabs.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                viewModel.getPosition(tab.getPosition());

            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {

            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {

            }
        });

    }

    @Override
    public void initViewObservable() {
        viewModel.uc.showAddStudentError.observe(this,role -> {
            if (role ==1){
                SLDialogUtils.showOneButton(getContext(),"Not a student","This email has been associated with a instructor account. Please confirm the e-mail with your student.","Got it");
            }else {
                SLDialogUtils.showOneButton(getContext(),"Not your student","This student has been connected to another instructor. Please confirm with your student.","Got it");
            }
        });


        viewModel.addStudent.observe(this, value -> {
            if (value) {
                addStudent();
            }
        });

        viewModel.currentUserIsPro.observe(this, value -> {
            if (value) {
                binding.pro.setVisibility(View.VISIBLE);
            } else {
                binding.pro.setVisibility(View.GONE);
            }
        });
        viewModel.addNewStudent.observe(this, value -> {
            if (value) {
                pagerAdapter.notifyDataSetChanged();
                Logger.e("notifyDataSetChanged");
            }
        });
        viewModel.refreshStudent.observe(this, new Observer<Integer>() {
            @Override
            public void onChanged(Integer pos) {
                try {
                    pagerAdapter.notifyDataSetChanged();
                    binding.tabs.pageScroll(pos);
                    binding.viewPager.setCurrentItem(pos);
                }catch (Throwable e){

                }
            }
        });

        viewModel.mutInactiveList.observe(this, value -> {
            inactiveFragment.getList(value, 0);
        });
        viewModel.mutActiveList.observe(this, value -> {
            activeFragment.getList(value, 1);
        });

        viewModel.mutArchivedList.observe(this, value -> {
            archivedFragment.getList(value, 2);
        });

        viewModel.uc.showAddStudent.observe(this, new Observer<Void>() {
            @Override
            public void onChanged(Void aVoid) {
                addStudent();
            }
        });


        viewModel.uc.showAddTestStudent.observe(this, aVoid -> {

            newContact(true);
        });

        viewModel.uc.testStudentAutoAddLesson.observe(this, aVoid -> {
            if (!viewModel.isTestStudent) {
                return;
            }






            viewModel.isTestStudent = false;
            String testEmail = "test-" + viewModel.userEntity.getEmail();
            StudentListEntity data = null;
            for (StudentListEntity studentListEntity : viewModel.mutInactiveList.getValue()) {
                if (studentListEntity.getEmail().equals(testEmail)) {
                    data = studentListEntity;
                }
            }
            Logger.e("data:%s",data != null);
            if (data != null) {

                List<LoginHistoryItemVM.TKLoginHistory> loginHistory = SLCacheUtil.getLoginHistory();
                LoginHistoryItemVM.TKLoginHistory  tkLoginHistory = new LoginHistoryItemVM.TKLoginHistory();
                tkLoginHistory.setEmail(data.getEmail());
                tkLoginHistory.setUserId(data.getStudentId());
                tkLoginHistory.setName(data.getName());
                loginHistory.add(tkLoginHistory);
                SLCacheUtil.setLoginHistory(loginHistory);


                Intent intent = new Intent(getActivity(), AddLessonStepActivity.class);
                intent.putExtra("list", data);
                intent.putExtra("isTest", true);
                startActivity(intent);
            }

        });

    }

    public void addStudent() {
        bottomDialog = new Dialog(getActivity(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.addstudent_toast, null);
        //获取Dialog的监听
        TextView newStudent = (TextView) contentView.findViewById(R.id.new_student);
        TextView googleContact = (TextView) contentView.findViewById(R.id.google_contact);
        TextView addressBook = (TextView) contentView.findViewById(R.id.address_book);
        TextView inviteLink = (TextView) contentView.findViewById(R.id.invite_link);

        TextView tvCancel = (TextView) contentView.findViewById(R.id.tv_cancle);


        tvCancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (bottomDialog.isShowing()) {
                    bottomDialog.dismiss();
                }
            }
        });

        newStudent.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                bottomDialog.dismiss();
                newContact(false);
            }
        });

        googleContact.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(getActivity(), AddressBookActivity.class);
                intent.putExtra("googleContact", "0");
                startActivity(intent);
                bottomDialog.dismiss();
            }
        });

        addressBook.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                bottomDialog.dismiss();

                toAddressBook(false);
            }
        });

        inviteLink.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                bottomDialog.dismiss();
                getInviteLink();
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

    /**
     * get student Link
     */
    private void getInviteLink() {
        showDialog("Loading...");
        String link = "https://tunekey.app/invitation?tId=" + UserService.getInstance().getCurrentUserId();
        DynamicLink.IosParameters iosParameters = new DynamicLink.IosParameters.Builder("com.spelist.tunekey")
                .setCustomScheme("com.spelist.tunekey")
                .setAppStoreId("1479006791")
                .build();
        DynamicLink.AndroidParameters androidParameters = new DynamicLink.AndroidParameters.Builder().build();

        DynamicLink.NavigationInfoParameters navigationInfoParameters = new DynamicLink.NavigationInfoParameters.Builder().setForcedRedirectEnabled(true).build();
        Task<ShortDynamicLink> shortLinkTask = FirebaseDynamicLinks.getInstance().createDynamicLink()
                .setLongLink(Uri.parse("https://tunekey.app/invite/?link=" + link))
                .setIosParameters(iosParameters)
                .setAndroidParameters(androidParameters)
                .setNavigationInfoParameters(navigationInfoParameters)
                .buildShortDynamicLink()
                .addOnCompleteListener(getActivity(), new OnCompleteListener<ShortDynamicLink>() {
                    @Override
                    public void onComplete(@NonNull Task<ShortDynamicLink> task) {
                        dismissDialog();
                        if (!task.isSuccessful() || task.getResult() == null || task.getResult().getShortLink() == null) {
                            Logger.e("======获取link失败%s", task.getException());
                            showInviteLink(link);
                        } else {
                            Uri shortLink = task.getResult().getShortLink();
                            showInviteLink(shortLink.toString());
                        }
                    }
                });
    }

    private void showInviteLink(String link) {
//        SLDialogUtils.showTwoButton()
        Dialog dialog = SLDialogUtils.showInviteDialog(getContext(), link);
        Logger.e("link==>%s",link);
        sendMessageString = "Hey, check out TuneKey, great app to learn music. \n" + link;

        TextView centerButton = dialog.findViewById(R.id.center_button);
        centerButton.setOnClickListener(v -> {
            viewModel.sendEmail(link);
            dialog.dismiss();
        });
        dialog.findViewById(R.id.right_button).setOnClickListener(v -> {
            if (getActivity() == null) {
                return;
            }
            toAddressBook(true);

            dialog.dismiss();
        });
        dialog.findViewById(R.id.left_button).setOnClickListener(v -> {
            if (getActivity() == null) {
                return;
            }
            ClipboardManager cm = (ClipboardManager) getActivity().getSystemService(Context.CLIPBOARD_SERVICE);
            assert cm != null;
            cm.setPrimaryClip(ClipData.newPlainText("copy", link));
            dialog.dismiss();
            SLToast.success("Copy Successful!");
        });
    }


    public void newContact(boolean isTestStudent) {
        if (getActivity() == null) {
            return;
        }
        newContactDialog = new Dialog(getActivity(), R.style.BottomDialog);
        View contentView = LayoutInflater.from(getActivity()).inflate(R.layout.new_contact_toast, null);
        //获取Dialog的监听

        InputView name = contentView.findViewById(R.id.tv_name);
        InputView email = contentView.findViewById(R.id.tv_email);
        InputView phone = contentView.findViewById(R.id.tv_phone);
        phone.editTextView.setFilters(new InputFilter[]{new InputFilter.LengthFilter(20)});



        TextView cancel = (TextView) contentView.findViewById(R.id.tx_cancel);
        TextView save = (TextView) contentView.findViewById(R.id.tx_save);


        cancel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (newContactDialog.isShowing()) {
                    newContactDialog.dismiss();
                }
            }
        });
        if (isTestStudent) {
            name.setInputText("Example Student");
            email.setInputText("test-" + viewModel.userEntity.getEmail());
            name.prohibitInput();
            email.prohibitInput();
            save.setText("Next");
        } else {
            name.setFocus();
        }

        save.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //验证名字不为空且邮箱格式正确
                if (!isNoNull(name.getInputText())) {
                    SLToast.error("Please check the name you entered!");
                } else if (!isEmail(email.getInputText().trim())){
                    SLToast.error("Please check the email you entered!");
                }else {
                    Map<String, Object> list = new HashMap<>();
                    list.put("email", email.getInputText().trim());
                    list.put("name", name.getInputText());
                    list.put("invitedStatus", "-1");
                    list.put("lessonTypeId", "");
                    if (isNoNull(phone.getInputText())) {
                        list.put("phone", phone.getInputText());
                    } else {
                        list.put("phone", "");
                    }
                    List<Map<String, Object>> studentList = new ArrayList<>();
                    studentList.add(list);
                    viewModel.checkEmail(studentList, isTestStudent);
                    newContactDialog.dismiss();
                }
            }
        });

        newContactDialog.setContentView(contentView);
        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
        contentView.setLayoutParams(layoutParams);
        newContactDialog.getWindow().setGravity(Gravity.BOTTOM);//弹窗位置
        newContactDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
        newContactDialog.show();//显示弹窗
    }

    /**
     * 检查权限
     */
    private void toAddressBook(boolean isSendMessage) {
        //判断是否有权限
//        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.READ_CONTACTS)
//                != PackageManager.PERMISSION_GRANTED) {
//
//            ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.READ_CONTACTS}, isSendMessage ? 220 : 200);
//        } else {
//            Intent intent = new Intent(getActivity(), AddressBookActivity.class);
//            if (isSendMessage) {
//                intent.putExtra("sendMessage", sendMessageString);
//            } else {
//                intent.putExtra("toAddressBook", "0");
//            }
//            startActivity(intent);
//        }
        new RxPermissions(this)
                .request(Manifest.permission.READ_CONTACTS)
                .subscribe(aBoolean -> {
                    if (aBoolean) {
                        Intent intent = new Intent(getActivity(), AddressBookActivity.class);
                        if (isSendMessage) {
                            intent.putExtra("sendMessage", sendMessageString);
                        } else {
                            intent.putExtra("toAddressBook", "0");
                        }
                        startActivity(intent);
                    }else{
                        SLToast.warning("Please allow to access your device and try again.");
                    }
                });

    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        Logger.e("======%s", "权限申请成功");
        if (requestCode == 200) {
            Intent intent = new Intent(getActivity(), AddressBookActivity.class);
            intent.putExtra("sendMessage", sendMessageString);
            startActivity(intent);
        } else if (requestCode == 220) {
            Intent intent = new Intent(getActivity(), AddressBookActivity.class);
            intent.putExtra("toAddressBook", "0");
            startActivity(intent);
        } else {

        }
    }

}
