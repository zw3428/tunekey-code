package com.spelist.tunekey.ui.student.sLessons.activity;


import androidx.annotation.LayoutRes;
import androidx.databinding.ViewDataBinding;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.app.Dialog;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.ShapeDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.StudentLessonService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.dialog.AddTeacherDialog;
import com.spelist.tunekey.customView.dialog.GroupLessonListDialog;
import com.spelist.tunekey.customView.dialog.JoinGroupLessonDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.ThreeButtonDialog;
import com.spelist.tunekey.customView.dialog.studioAddLesson.StudioAddLessonDialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.ActivityStudentUpComingBinding;
import com.spelist.tunekey.databinding.ItemStudentUpcomingBinding;
import com.spelist.tunekey.databinding.ItemStudioEventListByStudentUpcomingBinding;
import com.spelist.tunekey.entity.LessonScheduleConfigEntity;
import com.spelist.tunekey.entity.LessonScheduleEntity;
import com.spelist.tunekey.entity.LessonTypeEntity;
import com.spelist.tunekey.entity.PolicyEntity;
import com.spelist.tunekey.entity.TKStudioEvent;
import com.spelist.tunekey.entity.UserEntity;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentUpcomingEventItemVM;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentUpcomingItemVM;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentUpcomingMultiItemViewModel;
import com.spelist.tunekey.ui.student.sLessons.vm.StudentUpcomingVM;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function1;
import me.goldze.mvvmhabit.base.BaseActivity;
import me.jessyan.autosize.utils.AutoSizeUtils;
import me.tatarka.bindingcollectionadapter2.BR;
import me.tatarka.bindingcollectionadapter2.BindingRecyclerViewAdapter;
import retrofit2.http.HEAD;

public class StudentUpcomingAc extends BaseActivity<ActivityStudentUpComingBinding, StudentUpcomingVM> {
    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_student_up_coming;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        viewModel.lessonTypes = (List<LessonTypeEntity>) getIntent().getSerializableExtra("lessonType");
        viewModel.teacherData = (UserEntity) getIntent().getSerializableExtra("teacherData");
        viewModel.policyData = (PolicyEntity) getIntent().getSerializableExtra("policyData");
        viewModel.context = this;
        viewModel.initData();
    }

    @Override
    public void initView() {
        super.initView();
        binding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        binding.recyclerView.setItemAnimator(null);
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
            viewModel.endTimestamp = (int) (TimeUtils.addMonth(viewModel.endTimestamp * 1000L, +3) / 1000L);
            viewModel.initScheduleData();
        });


    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickAddLesson.observe(this,unused -> {


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
                BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(this);
                bottomMenuFragment.addMenuItems(new MenuItem("Join group lesson"));
                bottomMenuFragment.addMenuItems(new MenuItem("Add private lesson"));
                bottomMenuFragment.show();
                bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                    if (position == 0){
                        GroupLessonListDialog dialog = new GroupLessonListDialog(this,groupLessonConfig);
                        dialog.showDialog();
                        dialog.setClickConfirm(selectData -> {
                            JoinGroupLessonDialog joinGroupLessonDialog = new JoinGroupLessonDialog(this,selectData.getId(),viewModel);
                            joinGroupLessonDialog.showDialog();
                            joinGroupLessonDialog.setClickConfirm(() -> {
                                viewModel.joinGroupLesson(selectData.getId());
                                return null;
                            });
                            return null;
                        });

                    }else {
                        StudioAddLessonDialog dialog = new StudioAddLessonDialog(this,this,viewModel,viewModel.studentData,null,true);
                        dialog.showDialog();
                    }
                });

            }else {
                StudioAddLessonDialog dialog = new StudioAddLessonDialog(this,this,viewModel,viewModel.studentData,null,true);
                dialog.showDialog();
            }

        });
        viewModel.uc.addComplete.observe(this, t -> {


        });
        viewModel.uc.loadingComplete.observe(this, t -> {
            binding.refreshLayout.finishLoadMore();
//            binding.refreshLayout.setNoMoreData(lessonScheduleEntities.size() <= 0);
        });


        viewModel.uc.clickDeleteLesson.observe(this, this::showDeleteLessonDialog);
        viewModel.uc.clickLessonCancel.observe(this, data -> {
            StudentLessonService.getInstance().cancelLesson(viewModel.policyData, viewModel.studentData, data, this);
        });
        viewModel.uc.clickAddTeacher.observe(this, data -> {
            showAddTeacherDialog("");
        });
        viewModel.uc.clickReAddTeacher.observe(this, aVoid -> {
            Dialog dialog = SLDialogUtils.showTwoButton(this, "Resend the invite?", "Successfully sent invite to" + viewModel.teacherData.getEmail() + ". You will be all set once your instructor confirm your lesson. would you like to resent the invite?", "Go back", "Re-invite");
            dialog.findViewById(R.id.right_button).setOnClickListener(v -> {
                dialog.dismiss();
                showAddTeacherDialog(viewModel.teacherData.getEmail());
            });
        });
        viewModel.uc.clickReschedule.observe(this,lesson -> {
            StudentLessonService.getInstance().toReschedule(this,viewModel.policyData,viewModel.getTeacherData(lesson.getTeacherId()),lesson,null,viewModel.studentData);
        });
    }

    private void showAddTeacherDialog(String email) {
        AddTeacherDialog dialog = new AddTeacherDialog(this, email);
        BasePopupView popupView = new XPopup.Builder(this)
                .isDestroyOnDismiss(true)
                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(false)
                .asCustom(dialog)
                .show();
        dialog.setClickListener(popupView::dismiss);
    }

    private void showDeleteLessonDialog(LessonScheduleEntity data) {
        ThreeButtonDialog dialog = new ThreeButtonDialog(this, "Warning"
                , "Are you sure you want to delete this lesson?"
                , "This and upcoming lessons", "Only this lesson", "Go Back");
        BasePopupView popupView = new XPopup.Builder(this)
                .isDestroyOnDismiss(true)
                .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                .dismissOnTouchOutside(true)
                .asCustom(dialog)
                .show();
        dialog.setClickListener(new ThreeButtonDialog.OnClickListener() {
            @Override
            public void onClickOne() {
                popupView.dismiss();
                viewModel.studentDeleteLessonWithoutTeacher(data, true);
            }

            @Override
            public void onClickTwo() {
                popupView.dismiss();
                viewModel.studentDeleteLessonWithoutTeacher(data, false);
            }

            @Override
            public void onClickThree() {

                popupView.dismiss();
                Logger.e("onClickOne");
            }
        });

    }

    public static class MyRecyclerViewAdapter<T> extends BindingRecyclerViewAdapter<T> {

        @Override
        public ViewDataBinding onCreateBinding(LayoutInflater inflater, @LayoutRes int layoutId, ViewGroup viewGroup) {
            ViewDataBinding binding = super.onCreateBinding(inflater, layoutId, viewGroup);
            return binding;
        }

        @Override
        public void onBindBinding(ViewDataBinding binding, int bindingVariable, @LayoutRes int layoutId, int position, T item) {
            super.onBindBinding(binding, bindingVariable, layoutId, position, item);
            if (binding instanceof ItemStudioEventListByStudentUpcomingBinding) {
                ItemStudioEventListByStudentUpcomingBinding bd = (ItemStudioEventListByStudentUpcomingBinding) binding;
                bd.descriptionTv.post(() -> {
                    if (bd.descriptionTv.getLineCount() >= 3) {
                        bd.downArrowButton.setVisibility(View.VISIBLE);
                    } else {
                        bd.downArrowButton.setVisibility(View.GONE);
                    }
                });
                if (item instanceof StudentUpcomingEventItemVM){
                    StudentUpcomingEventItemVM vm = (StudentUpcomingEventItemVM) item;
                    GradientDrawable drawable = new GradientDrawable();
                    drawable.setCornerRadius(AutoSizeUtils.pt2px(TApplication.getInstance().getBaseContext(),5));
                    drawable.setColor(Color.parseColor("#"+vm.color));
                    bd.mainLayout.setBackground(drawable);
                    if (vm.data.isOpen()) {
                        bd.downArrowButton.setImageResource(R.mipmap.ic_arrow_primary_up);
                        bd.descriptionTv.setMaxLines(1000);
                    }else {
                        bd.downArrowButton.setImageResource(R.mipmap.ic_arrow_primary_down);
                        bd.descriptionTv.setMaxLines(3);
                    }
                }
                bd.downArrowButton.setOnClickListener(view -> {
                    if (bd.descriptionTv.getLineCount() >= 3&&item instanceof StudentUpcomingEventItemVM) {
                        ((StudentUpcomingEventItemVM) item).data.setOpen(!((StudentUpcomingEventItemVM) item).data.isOpen());
                        notifyItemChanged(position);
                    }
                });
                bd.descriptionTv.setOnClickListener(view -> {
                    if (bd.descriptionTv.getLineCount() >= 3&&item instanceof StudentUpcomingEventItemVM) {
                        ((StudentUpcomingEventItemVM) item).data.setOpen(!((StudentUpcomingEventItemVM) item).data.isOpen());
                        notifyItemChanged(position);
                    }
                });
            }
        }
    }
}
