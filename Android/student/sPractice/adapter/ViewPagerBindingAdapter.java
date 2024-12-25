package com.spelist.tunekey.ui.student.sPractice.adapter;

import android.annotation.SuppressLint;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.webkit.JavascriptInterface;

import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.databinding.ViewDataBinding;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.SLWebView;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.FragmentStudentPracticeItem1Binding;
import com.spelist.tunekey.databinding.FragmentStudentPracticeItem2Binding;
import com.spelist.tunekey.ui.student.sPractice.fragment.StudentPracticeFragment;
import com.spelist.tunekey.ui.student.sPractice.fragment.StudentPracticeItemViewModel;
import com.spelist.tunekey.ui.student.sPractice.fragment.StudentPracticeViewModel;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.WebHost;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import me.tatarka.bindingcollectionadapter2.BindingViewPagerAdapter;

public class ViewPagerBindingAdapter extends BindingViewPagerAdapter<StudentPracticeItemViewModel> {

    public StudentPracticeFragment studentPracticeFragment;
    public StudentPracticeViewModel studentPracticeViewModel;
    public SLWebView metronome;
    public RecyclerView practiceLogListRV;
    private ConstraintLayout practicePopup;
    private int scrollState = 0;
    private boolean btnIn = true;
    private Animation mIntoSlide;
    private Animation mOutSlide;
    private View view;
    private List<PracticeLog> list = new ArrayList<>();

    public ViewPagerBindingAdapter(StudentPracticeFragment studentPracticeFragment,
                                   StudentPracticeViewModel viewModel) {
        this.studentPracticeFragment = studentPracticeFragment;
        this.studentPracticeViewModel = viewModel;
    }

    @Override
    public void onBindBinding(final ViewDataBinding binding, int variableId, int layoutRes, final int position, StudentPracticeItemViewModel item) {
        super.onBindBinding(binding, variableId, layoutRes, position, item);
        //这里可以强转成ViewPagerItemViewModel对应的ViewDataBinding
        if (position == 0) {
            FragmentStudentPracticeItem1Binding _binding = (FragmentStudentPracticeItem1Binding) binding;
            practiceLogListRV = _binding.practiceList;
            view = _binding.practiceLogBtn;
            initPracticeLogData(_binding);
            initPracticeLogRVListener();
            practicePopup = studentPracticeFragment.getActivity().findViewById(R.id.practice_popup);

            // click listener
            _binding.logBtn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {

                }
            });

            _binding.startPracticeBtn.setOnClickListener(v -> FuncUtils.enterFromBottom(practicePopup));

        } else if (position == 1) {
            FragmentStudentPracticeItem2Binding _binding = (FragmentStudentPracticeItem2Binding) binding;
            metronome = _binding.metronome;
            initMetronome(metronome);
        }
    }

    private void initPracticeLogRVListener() {
        practiceLogListRV.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                scrollState = newState;
            }

            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                if (dy > 0) {
                    if (btnIn && scrollState != 1) {
                        FuncUtils.initBottomDialogAnimationOut(mOutSlide, view);
                        btnIn = false;
                    }
                }else if (dy < 0){
                    if (!btnIn && scrollState != 1) {
                        FuncUtils.initBottomDialogAnimationIn(mIntoSlide, view);
                        btnIn = true;
                    }
                }
            }
        });
    }

    public void initPracticeLogData(FragmentStudentPracticeItem1Binding _binding) {
        for (int i = 0; i < 10; i++) {
            list.add(new PracticeLog("July " + (31 - i * 3), "1.5 hrs"));
        }

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(studentPracticeFragment.getActivity().getApplication());
        _binding.practiceList.setLayoutManager(linearLayoutManager);
        PracticeLogAdapter adapter = new PracticeLogAdapter(studentPracticeFragment.getActivity(), list);
        _binding.practiceList.setAdapter(adapter);
    }

    @SuppressLint("JavascriptInterface")
    @JavascriptInterface
    private void initMetronome(SLWebView metronome) {
        FuncUtils.initWebViewSetting(metronome, "file:///android_asset/web/metronome.html");
        //JS映射
        WebHost webHost = new WebHost(this, studentPracticeFragment.getContext());
        metronome.addJavascriptInterface(webHost, "js");
    }

    public void resetCountAndBeat(String count, String beat) {
        metronome.post(() -> metronome.evaluateJavascript("resetCountAndBeat(" + Integer.valueOf(count) + "," + Integer.valueOf(beat) + ")", s -> {}));
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        super.destroyItem(container, position, object);
    }

    public void init() {
        Objects.requireNonNull(studentPracticeFragment.getActivity()).runOnUiThread(() -> {
            Logger.e("metronome1 url -> ", metronome.getUrl());
            studentPracticeFragment.initMetronomeDialog();
        });
    }
}

