package com.spelist.tunekey.ui.teacher.materials.activity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;

import androidx.recyclerview.widget.GridLayoutManager;

import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.databinding.ActivitySearchMaterialsBinding;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;

import java.util.Timer;
import java.util.TimerTask;

import me.goldze.mvvmhabit.base.BaseActivity;

public class SearchMaterialsActivity extends BaseActivity<ActivitySearchMaterialsBinding,
        MaterialsViewModel> {

    private TimerTask task;
    private Timer timer;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_search_materials;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.clickBackFromSearch.observe(this, aVoid -> {
            finish();
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        });
//        viewModel.uc.clickCancelSearch.observe(this, aVoid -> {
//            binding.searchEditText.setText("");
//        });
        viewModel.uc.materialsSearchResultObserverData.observe(this, multiItemViewModels ->
                viewModel.gridLayoutManager.get().setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                    @Override
                    public int getSpanSize(int position) {
                        if ((int) multiItemViewModels.get(position).getData().getType() == 6) {
                            return 3;
                        } else {
                            return 1;
                        }
                    }
                }));
    }

    @SuppressLint("ResourceAsColor")
    @Override
    public void initData() {
        binding.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                int length = s.length();

                if (timer != null) {
                    timer.cancel();
                }

                if (task != null) {
                    task.cancel();
                }
                task = new TimerTask() {
                    @Override
                    public void run() {
                        binding.materialsList.post(() -> {
                            if (length > 0) {
                            } else {
                            }
                        });
                    }
                };

                timer = new Timer();
                timer.schedule(task, 300);

                /*if (length > 0) {
                    viewModel.cancelSearchLayoutVisibility.setValue(0);
                    viewModel.initMaterialSearchResult(s);
                }else {
                    viewModel.cancelSearchLayoutVisibility.setValue(8);
                    viewModel.materialSearchResultList.clear();
                }*/
            }
        });
//        binding.searchEditText.setHintTextColor(ContextCompat.getColor(getContext(),R.color.primary));
        binding.searchEditText.setHintTextColor(getResources().getColor(R.color.primary));
        viewModel.roleType.setValue(2);
        viewModel.gridLayoutManager.set(new GridLayoutManager(this, 3));
    }
}
