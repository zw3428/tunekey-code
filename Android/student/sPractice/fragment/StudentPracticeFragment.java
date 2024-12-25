package com.spelist.tunekey.ui.student.sPractice.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentManager;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.tablayout.TabLayout;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentPracticeBinding;
import com.spelist.tunekey.ui.student.sPractice.adapter.ViewPagerBindingAdapter;
import com.spelist.tunekey.ui.student.sPractice.dialogs.DialogMetronome;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;


import java.util.Objects;

import me.goldze.mvvmhabit.base.BaseFragment;

public class StudentPracticeFragment extends BaseFragment<FragmentStudentPracticeBinding,
        StudentPracticeViewModel> {

    private BaseTitleViewModel baseTitleViewModel;
    public DialogMetronome dialogMetronome;
    public FragmentManager fragmentManager;
    public ViewPagerBindingAdapter viewPagerBindingAdapter;

    private Animation alphaAnimation = null;
    private boolean animationIsEnd = false;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container,
                               @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_practice;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        baseTitleViewModel = new BaseTitleViewModel(getActivity().getApplication());
        binding.setVariable(BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set("Practice");
        baseTitleViewModel.rightFirstImgVisibility.set(View.VISIBLE);
        binding.titleLayout.titleRightFirstImg.setImageResource(R.mipmap.ic_search_primary);
        viewModel.emptyLayoutVisibility.set(View.GONE);

        // 使用 TabLayout 和 ViewPager 相关联
        binding.secondTitleTabs.setupWithViewPager(binding.viewPager);
        binding.viewPager.addOnPageChangeListener(new TabLayout.TabLayoutOnPageChangeListener(binding.secondTitleTabs));
        //给ViewPager设置adapter
        viewPagerBindingAdapter = new ViewPagerBindingAdapter(this, viewModel);
        binding.setAdapter(viewPagerBindingAdapter);

        // growing tree
        WebHost webHost = new WebHost(this, getContext());
        binding.growingTree.addJavascriptInterface(webHost, "js");
//        binding.growingTree.setOnClickListener(v -> hideGrowingTree());
//        showGrowingTree();
    }

    @Override
    public void initViewObservable() {
        baseTitleViewModel.uc.clickRightFirstImgButton.observe(this, aVoid -> {});

        viewModel.uc.clickLog.observe(this, s -> Toast.makeText(getActivity(), "Click log btn", Toast.LENGTH_SHORT).show());

        viewModel.uc.clickPractice.observe(this, s -> Toast.makeText(getActivity(), "Click practice btn", Toast.LENGTH_SHORT).show());
    }

    public void initMetronomeDialog() {
        if (dialogMetronome == null && fragmentManager == null) {
            dialogMetronome = new DialogMetronome();
            dialogMetronome.initPickerViewData();
            fragmentManager = requireActivity().getSupportFragmentManager();
        }

        assert dialogMetronome != null;
        if (!dialogMetronome.isAdded()) {
            dialogMetronome.show(fragmentManager, "DialogFragment");
        }

//        dialogMetronome.setDialogCallback((count, beat) -> getActivity().runOnUiThread(() -> {
//            viewPagerBindingAdapter.resetCountAndBeat(count, beat);
//            dialogMetronome.dismissDialog();
//        }));
    }

    public void showGrowingTree() {
        Logger.e("-*-*-*-*-*-*-*- show growing tree: ");
        binding.growingTree.setVisibility(View.VISIBLE);
        FuncUtils.initWebViewSetting(binding.growingTree,"file:///android_asset/web/growing.tree.html");
//        binding.growingTree.setWebViewClient(client);
    }

    private void hideGrowingTree() {
        Logger.e("-*-*-*-*-*-*-*- hide growing tree: ");
        binding.growingTree.setVisibility(View.GONE);
    }


}