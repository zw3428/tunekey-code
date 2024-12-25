package com.spelist.tunekey.ui.teacher.lessons.activity;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.os.Bundle;

import com.orhanobut.logger.Logger;
import com.scwang.smart.refresh.footer.ClassicsFooter;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.scwang.smart.refresh.layout.listener.OnLoadMoreListener;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivitySearchStudentLessonDetailBinding;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.teacher.lessons.vm.SearchStudentLessonDetailVM;
import com.spelist.tunekey.utils.TimeUtils;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BR;

public class SearchStudentLessonDetailAc extends BaseActivity<ActivitySearchStudentLessonDetailBinding, SearchStudentLessonDetailVM> {
    static {
        ClassicsFooter.REFRESH_FOOTER_PULLING = "";
        ClassicsFooter.REFRESH_FOOTER_RELEASE = "Loading more...";
        ClassicsFooter.REFRESH_FOOTER_REFRESHING = "Loading more...";
        ClassicsFooter.REFRESH_FOOTER_LOADING = "Loading more...";
        ClassicsFooter.REFRESH_FOOTER_FINISH = "";
        ClassicsFooter.REFRESH_FOOTER_FAILED = "";
        ClassicsFooter.REFRESH_FOOTER_NOTHING = "No more lessons";
    }

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_search_student_lesson_detail;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        StudentListEntity studentData = (StudentListEntity) getIntent().getSerializableExtra("studentData");
        Logger.e("======%s", studentData.getName());
        viewModel.setNormalToolbar(studentData.getName());
        viewModel.userData = studentData;
        viewModel.email.set(studentData.getEmail());
        viewModel.name.set(studentData.getName());
        viewModel.userId.set(studentData.getStudentId());
        viewModel.getData();
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
//        binding.footer.setAccentColorId(R.color.primary);
//        binding.footer.setPrimaryColorId(R.color.primary);
        binding.refreshLayout.setOnLoadMoreListener(refreshLayout -> {
            viewModel.startTime = viewModel.endTime;
            viewModel.endTime = (int) (TimeUtils.addMonth(viewModel.startTime * 1000L, 1) / 1000L);
            viewModel.getData();
        });

    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.loadingComplete.observe(this,lessonScheduleEntities -> {
            binding.refreshLayout.finishLoadMore();
            if (lessonScheduleEntities.size() == 0 ){
                binding.refreshLayout.setNoMoreData(true);
            }
        });
    }
}