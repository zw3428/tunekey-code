package com.spelist.tunekey.ui.student.sLessons.fragment;

import android.app.Dialog;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.StudentLessonService;
import com.spelist.tunekey.customView.dialog.AddTeacherDialog;
import com.spelist.tunekey.customView.dialog.GroupLessonListDialog;
import com.spelist.tunekey.customView.dialog.JoinGroupLessonDialog;
import com.spelist.tunekey.customView.dialog.NewAnnouncementDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.SLDialogUtilsEx;
import com.spelist.tunekey.customView.dialog.ThreeButtonDialog;
import com.spelist.tunekey.customView.dialog.studioAddLesson.StudioAddLessonDialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.FragmentStudentLessonsBinding;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.ui.chat.activity.ChatActivity;
import com.spelist.tunekey.ui.student.sLessons.activity.SignPoliciesAc;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentAddLessonAc;
import com.spelist.tunekey.ui.student.sLessons.activity.StudentUpcomingAc;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentLessonsViewModelV2;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.SLUiUtils;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseFragment;
import retrofit2.http.HEAD;

public class StudentLessonsFragment extends BaseFragment<FragmentStudentLessonsBinding, StudentLessonsViewModelV2> {
    private BaseTitleViewModel baseTitleViewModel;


    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_lessons;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        binding.lessonRv.setItemAnimator(null);
        binding.refreshLayout.setEnableRefresh(false);//是否启用下拉刷新功能
        binding.refreshLayout.setEnableLoadMore(true);//是否启用上拉加载功能
        binding.refreshLayout.setEnableAutoLoadMore(true);//是否启用列表惯性滑动到底部时自动加载更多
        binding.refreshLayout.setEnableLoadMoreWhenContentNotFull(true);//是否在列表不满一页时候开启上拉加载功能
        binding.refreshLayout.setEnableOverScrollDrag(true);//是否启用越界拖动（仿苹果效果）1.0.4
//        binding.refreshLayout.setEnableFooterFollowWhenLoadFinished(false);//是否在全部加载结束之后Footer跟随内容1.0.4
//        binding.refreshLayout.autoLoadMore();
//        binding.footer.setAccentColorId(R.color.primary);oadMore();
////        binding.footer.setAccentColorId(R.color.primary);
////        binding.footer.setPrimaryColorId(R.color.primary);
//        binding.refreshLayout.setOnLoadMoreListener(refreshLayout -> {
//            viewModel.startTimestamp = (i
//        binding.footer.setPrimaryColorId(R.color.primary);
        binding.refreshLayout.setOnLoadMoreListener(refreshLayout -> {
            viewModel.startTimestamp = (int) (TimeUtils.addMonth(viewModel.startTimestamp * 1000L, -3) / 1000L);
            viewModel.getScheduleConfig();
        });
    }

    @Override
    public void initData() {
        baseTitleViewModel = new BaseTitleViewModel(getActivity().getApplication());
        binding.setVariable(BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set("Lessons");
        baseTitleViewModel.rightButtonVisibility.set(View.GONE);
        baseTitleViewModel.rightButtonText.set("UPCOMING");
//        viewModel.emptyLayoutVisibility.set(View.GONE);
        binding.lessonRv.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.lessonRv.setItemAnimator(null);
        baseTitleViewModel.icon.setValue(R.mipmap.add_primary);
        baseTitleViewModel.leftImgVisibility.set(View.GONE);
        binding.expendLayout.setVisibility(View.GONE);
//SLUiUtils.collapse(binding.expendLayout);

    }


    @Override
    public void initViewObservable() {
        viewModel.uc.showAnnouncementDialog.observe(this, data -> {
            NewAnnouncementDialog dialog = new NewAnnouncementDialog(getContext(), data, viewModel.unReadMessage.size());
            dialog.showDialog();
            dialog.setClickConfirm(aDouble -> {
                Bundle bundle = new Bundle();
                bundle.putSerializable("conversation", viewModel.studioAnnouncementConversation);
                startActivity(ChatActivity.class, bundle);
                return null;

            });

        });

        baseTitleViewModel.uc.clickRightButton.observe(this, aVoid -> {
            if (viewModel.isShowNextLesson.getValue()){
                Bundle bundle = new Bundle();
                bundle.putSerializable("lessonType", (Serializable) viewModel.lessonTypes);
                bundle.putSerializable("teacherData", viewModel.teacherData);
                bundle.putSerializable("policyData", viewModel.policyData);
                startActivity(StudentUpcomingAc.class, bundle);
            }else {
                List<LessonTypeEntity> lessonTypeData = ListenerService.shared.studentData.getLessonTypeData();
                List<LessonScheduleConfigEntity> groupLessonConfig = new ArrayList<>();
                for (LessonScheduleConfigEntity item : viewModel.allScheduleConfigs) {
                    if (!item.isDelete() && item.lessonCategory == LessonTypeEntity.TKLessonCategory.group
                            && (item.groupLessonStudents.get(SLCacheUtil.getCurrentUserId()) == null)) {
                        for (LessonTypeEntity lessonTypeDatum : lessonTypeData) {
                            if (lessonTypeDatum.getId().equals(item.getLessonTypeId())) {
                                item.setLessonType(lessonTypeDatum);
                                break;
                            }
                        }
                        if (item.getLessonType()!=null&&item.getLessonType().getVisibility() != LessonTypeEntity.Visibility.none){
                            groupLessonConfig.add(item);
                        }
                    }
                }

                if (groupLessonConfig.size() > 0){
                    BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity());
                    bottomMenuFragment.addMenuItems(new MenuItem("Join group lesson"));
                    bottomMenuFragment.addMenuItems(new MenuItem("Add private lesson"));
                    bottomMenuFragment.show();
                    bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                        if (position == 0){
                            GroupLessonListDialog dialog = new GroupLessonListDialog(getActivity(),groupLessonConfig);
                            dialog.showDialog();
                            dialog.setClickConfirm(selectData -> {
                                JoinGroupLessonDialog joinGroupLessonDialog = new JoinGroupLessonDialog(getActivity(),selectData.getId(),viewModel);
                                joinGroupLessonDialog.showDialog();
                                joinGroupLessonDialog.setClickConfirm(() -> {
                                    viewModel.joinGroupLesson(selectData.getId());
                                    return null;
                                });
                                return null;
                            });

                        }else {
                            StudioAddLessonDialog dialog = new StudioAddLessonDialog(getActivity(),getActivity(),viewModel,viewModel.studentData,null,true);
                            dialog.showDialog();
                        }
                    });

                }else {
                    StudioAddLessonDialog dialog = new StudioAddLessonDialog(getActivity(),getActivity(),viewModel,viewModel.studentData,null,true);
                    dialog.showDialog();
                }

            }
//                viewModel.pendingCardLayoutVisibility.set(0);
        });
        baseTitleViewModel.uc.clickLeftImgButton.observe(this
                , aVoid -> toAddLesson());


        viewModel.uc.isShowAddButton.observe(this
                , isShow -> {
                    baseTitleViewModel.leftImgVisibility.set(isShow ? View.VISIBLE : View.GONE);
                    binding.nlLeftButton.setText(isShow ? "DELETE LESSON" : "CANCEL LESSON");
                    binding.nlRightButton.setText(isShow ? (viewModel.studentData.getStudentApplyStatus() == 1 ? "RE-INVITE" : "ADD INSTRUCTOR") : "RESCHEDULE");
                });
        viewModel.isShowNextLesson.observe(this,
                isShow -> {
                    Logger.e("isShow==>%s",isShow);
                    if (isShow) {
                        baseTitleViewModel.rightButtonText.set("UPCOMING");
//<<<<<<< HEAD
//                        baseTitleViewModel.rightButtonVisibility.set(View.VISIBLE);
                    } else {
                        baseTitleViewModel.rightButtonText.set("ADD LESSONS");
//                        baseTitleViewModel.rightButtonVisibility.set(View.GONE);

                    }
                    if (viewModel.studentData !=null){
                        baseTitleViewModel.rightButtonVisibility.set((!viewModel.studentData.getStudioId().equals("")) ? View.VISIBLE : View.GONE);
//=======
//                        baseTitleViewModel.rightButtonVisibility.set(View.VISIBLE);
//                    }else {
//                        baseTitleViewModel.rightButtonVisibility.set(View.GONE);
//>>>>>>> studio_event
                    }
//                    if (isShow) {
//                        baseTitleViewModel.rightButtonText.set("UPCOMING");
//                        baseTitleViewModel.rightButtonVisibility.set(View.VISIBLE);
//                    } else {
//                        baseTitleViewModel.rightButtonText.set("ADD LESSONS");
//                        baseTitleViewModel.rightButtonVisibility.set(View.GONE);
//
//                    }
//                    if (viewModel.studentData !=null){
//                        baseTitleViewModel.rightButtonVisibility.set((!viewModel.studentData.getStudioId().equals("")) ? View.VISIBLE : View.GONE);
//                    }

                });
        viewModel.uc.clickAddLesson.observe(this, aVoid -> toAddLesson());
        viewModel.uc.loadingComplete.observe(this, lessonScheduleEntities -> {
            binding.refreshLayout.finishLoadMore();
            binding.refreshLayout.setNoMoreData(lessonScheduleEntities.size() <= 0);
        });

        viewModel.uc.clickNextLeftView.observe(this
                , aVoid -> SLUiUtils.expandAndCollapse(binding.expendLayout, 300));
        viewModel.uc.clickDeleteLesson.observe(this, aVoid -> {
            showDeleteLessonDialog();
            SLUiUtils.expandAndCollapse(binding.expendLayout, 300);
        });
        viewModel.uc.clickInviteTeacher.observe(this, aVoid -> showAddTeacherDialog(""));
        viewModel.uc.clickAddTeacher.observe(this, aVoid -> {
            showAddTeacherDialog("");
            SLUiUtils.expandAndCollapse(binding.expendLayout, 300);
        });
        viewModel.uc.clickReAddTeacher.observe(this, aVoid -> {

            Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Resend the invite?", "Successfully sent invite to" + viewModel.teacherData.getEmail() + ". You will be all set once your instructer confirm your lesson. would you like to resent the invite?", "Go back", "Re-invite");
            dialog.findViewById(R.id.right_button).setOnClickListener(v -> {
                dialog.dismiss();
                showAddTeacherDialog(viewModel.teacherData.getEmail());
            });

            SLUiUtils.expandAndCollapse(binding.expendLayout, 300);
        });
        viewModel.uc.showSignPolicy.observe(this, aVoid -> {
            String name = "U";

            if (ListenerService.shared.studentData.getStudioData() != null) {
                name = ListenerService.shared.studentData.getStudioData().getName() + " u";
            }

//            Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Policies statement released", name + "pdated its policies statement, please sign the new statement.", "Later", "See policies");
//            dialog.findViewById(R.id.right_button).setOnClickListener(v -> {
//                Bundle bundle = new Bundle();
//                bundle.putSerializable("studentData", viewModel.studentData);
//                bundle.putSerializable("policiesData", viewModel.policyData);
//                startActivity(SignPoliciesAc.class,bundle);
//                dialog.dismiss();
//            });
            Dialog dialog = SLDialogUtilsEx.showOneButton(getContext(), "Policies statement released", name + "pdated its policies statement, please sign the new statement.", "See policies");
            dialog.findViewById(R.id.button).setOnClickListener(v -> {
                Bundle bundle = new Bundle();
                bundle.putSerializable("studentData", viewModel.studentData);
                bundle.putSerializable("policiesData", viewModel.policyData);
                startActivity(SignPoliciesAc.class, bundle);
                dialog.dismiss();
            });
        });

        viewModel.uc.clickRetract.observe(this, lessonRescheduleEntity -> {
            Dialog dialog = SLDialogUtils.showTwoButton(getContext(), "Retract request", "Are you sure you want to retract your reschedule request?", "Yes", "No");
            TextView leftButton = dialog.findViewById(R.id.left_button);
            leftButton.setTextColor(ContextCompat.getColor(getContext(), R.color.red));

            leftButton.setOnClickListener(v -> {
                dialog.dismiss();
                viewModel.retractReschedule(lessonRescheduleEntity);
            });
        });
        viewModel.uc.clickNextLessonCancel.observe(this, aVoid -> {
            StudentLessonService.getInstance().cancelLesson(viewModel.policyData, viewModel.studentData, viewModel.nextLessonData, this);
            SLUiUtils.expandAndCollapse(binding.expendLayout, 300);

        });
        viewModel.uc.clickNextLessonReschedule.observe(this, aVoid -> {
            SLUiUtils.expandAndCollapse(binding.expendLayout, 300);
            StudentLessonService.getInstance().toReschedule(this, viewModel.policyData, viewModel.getTeacherData(viewModel.nextLessonData.getTeacherId()), viewModel.nextLessonData, null, viewModel.studentData);
        });
    }

    /**
     * 显示添加老师Dialog
     */
    private void showAddTeacherDialog(String email) {
        AddTeacherDialog dialog = new AddTeacherDialog(getContext(), email);
        BasePopupView popupView = new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(false)
                .asCustom(dialog)
                .show();
        dialog.setClickListener(popupView::dismiss);
    }

    /**
     * 显示删除课程Dialog
     */
    private void showDeleteLessonDialog() {
        ThreeButtonDialog dialog = new ThreeButtonDialog(getContext(), "Warning"
                , "Are you sure you want to delete this lesson?"
                , "This and upcoming lessons", "Only this lesson", "Go back");
        BasePopupView popupView = new XPopup.Builder(getContext())
                .isDestroyOnDismiss(true)
                .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(true)
                .asCustom(dialog)
                .show();
        dialog.setClickListener(new ThreeButtonDialog.OnClickListener() {
            @Override
            public void onClickOne() {
                popupView.dismiss();
                viewModel.studentDeleteLessonWithoutTeacher(true);
            }

            @Override
            public void onClickTwo() {
                popupView.dismiss();
                viewModel.studentDeleteLessonWithoutTeacher(false);
            }

            @Override
            public void onClickThree() {

                popupView.dismiss();
                Logger.e("onClickOne");
            }
        });

    }

    private void toAddLesson() {



        startActivity(StudentAddLessonAc.class);
    }

}
