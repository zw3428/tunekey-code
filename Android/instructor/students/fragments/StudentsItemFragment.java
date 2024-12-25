package com.spelist.tunekey.ui.teacher.students.fragments;

import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.ThreeButtonDialog;
import com.spelist.tunekey.databinding.FragmentActiveBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.activity.AddLessonStepActivity;
import com.spelist.tunekey.ui.teacher.students.vm.StudentsItemFragmentVM;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * com.spelist.tunekey.ui.students.fragments
 * 2020/11/23
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentsItemFragment extends BaseFragment<FragmentActiveBinding, StudentsItemFragmentVM> {
    public int type = 0;
    public List<StudentListEntity> data = new ArrayList<>();

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_active;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getActivity().getApplication());
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvActive.setLayoutManager(linearLayoutManager);
        binding.rvActive.setItemAnimator(null);
        if (data != null && viewModel != null) {
            viewModel.setData(data);
            viewModel.type = type;
        }
    }
    public void getList(List<StudentListEntity> studentListEntities,int type) {
        this.data = studentListEntities;
        this.type = type;
        if (studentListEntities != null && viewModel != null) {
            viewModel.setData(studentListEntities);
            viewModel.type = type;
        }
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.invite.observe(this, value -> {
            if (value.getStudentApplyStatus() == 1){
                String content = "Tap ACCEPT, you will accept to add a new student.\n" +"("+value.getEmail()+")";
                ThreeButtonDialog threeButtonDialog = new ThreeButtonDialog(getContext(),"New student?",content
                        ,"Accept","Not my student","Go Back");
                BasePopupView popupView = new XPopup.Builder(getContext())
                        .isDestroyOnDismiss(true)
                        .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                        .dismissOnTouchOutside(true)
                        .asCustom(threeButtonDialog)
                        .show();
                threeButtonDialog.setClickListener(new ThreeButtonDialog.OnClickListener() {
                    @Override
                    public void onClickOne() {
                        threeButtonDialog.dismiss();
                        viewModel.acceptStudent(value);
                    }

                    @Override
                    public void onClickTwo() {
                        threeButtonDialog.dismiss();
                        viewModel.rejectStudent(value);
                    }

                    @Override
                    public void onClickThree() {
                        threeButtonDialog.dismiss();
                    }
                });
            }else {
                if (value.getInvitedStatus().equals("0")){
                    showUpPop(value);
                }else {
                    Intent intent = new Intent(getActivity(), AddLessonStepActivity.class);
                    intent.putExtra("list", value);
                    startActivity(intent);
                }
            }

        });
//        viewModel.uc.clickAccept.observe(this,studentListEntity -> {
//
//        });
//        viewModel.uc.clickReject.observe(this,studentListEntity -> {
//
        //获取屏幕宽度
//            DisplayMetrics dm = new DisplayMetrics();
//            getActivity().getWindowManager().getDefaultDisplay().getMetrics(dm);
//            int width = dm.widthPixels;
//            int height = dm.heightPixels;
        //获取用户id
//            String userId = studentListEntity.getUserId();
    }
    public void showUpPop(StudentListEntity studentListEntity) {
        String content = "Your student account has been created, an invite email with download link will be sent to your student.\n" +
                " \n" +
                "The next steps for your student:\n" +
                "\n" +
                "1. Install Tunekey app\n" +
                "2. Sign in with \n" +
                "    "+studentListEntity.getEmail()+"\n" +
                "3. Create a password\n" +
                "4. All set!";

        Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Invite", content, "LATER","SEND INVITE");

        dialog.show();
        TextView dContent = dialog.findViewById(R.id.content);
        dContent.setGravity(Gravity.START);
        dialog.findViewById(R.id.right_button).setOnClickListener(v1 -> {
            viewModel.resendInvitation(studentListEntity);
            dialog.dismiss();
        });


//        Dialog  bottomDialog = new Dialog(getContext(), R.style.BottomDialog);
//        View contentView = LayoutInflater.from(getContext()).inflate(R.layout.resend_toast, null);
//        TextView resend = contentView.findViewById(R.id.resend);
//
//        resend.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View v) {
//                viewModel.resendInvitation(studentListEntity);
//                bottomDialog.dismiss();
//            }
//        });
//        bottomDialog.setContentView(contentView);
//        ViewGroup.LayoutParams layoutParams = contentView.getLayoutParams();
//        layoutParams.width = getResources().getDisplayMetrics().widthPixels;
//        contentView.setLayoutParams(layoutParams);
//        bottomDialog.getWindow().setGravity(Gravity.CENTER);//弹窗位置
//        bottomDialog.getWindow().setWindowAnimations(R.style.BottomDialog_Animation);//弹窗样式
//        bottomDialog.show();//显示弹窗
    }


}
