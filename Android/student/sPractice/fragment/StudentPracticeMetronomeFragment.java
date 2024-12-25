package com.spelist.tunekey.ui.student.sPractice.fragment;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentManager;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.databinding.FragmentStudentPracticeMetronomeBinding;
import com.spelist.tunekey.ui.student.sPractice.dialogs.DialogMetronome;
import com.spelist.tunekey.ui.student.sPractice.host.MetronomeHost;
import com.spelist.tunekey.utils.FuncUtils;
import com.tencent.mmkv.MMKV;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.base.BaseViewModel;

/**
 * com.spelist.tunekey.ui.sPractice.fragment
 * 2021/4/16
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class StudentPracticeMetronomeFragment extends BaseFragment<FragmentStudentPracticeMetronomeBinding, BaseViewModel> {
    public DialogMetronome dialogMetronome;
    public FragmentManager fragmentManager;
    private int defCount = 4;
    private int defBeat = 4;

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
        return R.layout.fragment_student_practice_metronome;
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

        FuncUtils.initWebViewSetting(binding.webView, "file:///android_asset/web/metronome.html");
        MetronomeHost webHost = new MetronomeHost(this);
        binding.webView.addJavascriptInterface(webHost, "js");
        binding.webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                String data = MMKV.defaultMMKV().getString("metronomeData:" + UserService.getInstance().getCurrentUserId(), "");
                if (data == null ||data.equals("")){
                    binding.webView.evaluateJavascript("recover()", s -> {
                    });
                }else {
                    binding.webView.evaluateJavascript("recover('"+data+"')", s -> {
                    });
                }
            }
        });

    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
    }

    public void showBeatPickerDialog() {
        if (getActivity() == null) {
            return;
        }
        getActivity().runOnUiThread(() -> {
            if (dialogMetronome == null && fragmentManager == null) {
                dialogMetronome = new DialogMetronome();
                fragmentManager = requireActivity().getSupportFragmentManager();
            }

            assert dialogMetronome != null;
            if (!dialogMetronome.isAdded()) {
                dialogMetronome.show(fragmentManager, "DialogFragment");
            }
            dialogMetronome.setDialogCallback(defCount, defBeat, (count, beat) -> {
                defCount = Integer.parseInt(count);
                defBeat = Integer.parseInt(beat);
                binding.webView.evaluateJavascript("setBPMFromNative(" + defCount + "," + defBeat + ")", s -> {
                });
                dialogMetronome.dismissDialog();
            });
        });
    }
    public void stop(){
        if (binding!=null){
            binding.webView.evaluateJavascript("stopPlay()", s -> {
            });
        }
        stopMetronome();
    }

    public void startMetronome() {
        try {
            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        }catch (Exception e){

        }

    }

    public void stopMetronome() {
        try {
            getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        }catch (Exception e){

        }
    }
}
