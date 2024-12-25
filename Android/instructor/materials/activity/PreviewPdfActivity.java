package com.spelist.tunekey.ui.teacher.materials.activity;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.LinearLayout;

import androidx.core.content.FileProvider;
import androidx.viewpager.widget.ViewPager;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.databinding.ActivityPreviewPdfBinding;
import com.spelist.tunekey.ui.teacher.materials.PreviewPdfVM;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import es.voghdev.pdfviewpager.library.RemotePDFViewPager;
import es.voghdev.pdfviewpager.library.adapter.PDFPagerAdapter;
import es.voghdev.pdfviewpager.library.remote.DownloadFile;
import es.voghdev.pdfviewpager.library.util.FileUtil;
import kotlin.jvm.internal.Intrinsics;
import me.goldze.mvvmhabit.base.BaseActivity;

public class PreviewPdfActivity extends BaseActivity<ActivityPreviewPdfBinding, PreviewPdfVM> implements DownloadFile.Listener {

    private RemotePDFViewPager remotePDFViewPager;
    private PDFPagerAdapter adapter;
    private int totalPage = 0;
    private int currentPage = 1;
    private String url = "";
    private String path = "";


    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_preview_pdf;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initView() {
        super.initView();
        binding.shareButton.setOnClickListener(v -> clickShare());
    }

    @SuppressLint("CheckResult")
    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.clickShare.observe(this, unused -> {
            clickShare();
        });
    }

    @SuppressLint("CheckResult")
    private void clickShare() {
        if (path == null || path.equals("")) {
            return;
        }
        boolean isHave = false;

        File localFile = new File(path);
        if (localFile.exists() || new File(path + ".pdf").exists()) {
            isHave = true;
        }
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
            showDialog();
            File file = renameFile(path, path + ".pdf");
            sharePDF(file);
        } else {
            boolean finalIsHave = isHave;

            new RxPermissions(this)
                    .request(Manifest.permission.READ_EXTERNAL_STORAGE
                            , Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    .subscribe(aBoolean -> {
                        if (aBoolean) {
                            if (finalIsHave) {
                                showDialog();
                                File file = renameFile(path, path + ".pdf");
                                sharePDF(file);

                            }
                        } else {
                            SLToast.warning("Please allow to access your device and try again.");
                        }
                    });
        }



    }

    @Override
    public void initData() {
        super.initData();
        url = getIntent().getStringExtra("url");
        if (url != null) {
            final DownloadFile.Listener listener = PreviewPdfActivity.this;
            showDialog();
            remotePDFViewPager = new RemotePDFViewPager(PreviewPdfActivity.this, this.url, listener);
            remotePDFViewPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
                @Override
                public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

                }

                @Override
                public void onPageSelected(int position) {
                    currentPage = position + 1;
                    setPageString();
                }

                @Override
                public void onPageScrollStateChanged(int state) {

                }
            });
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (adapter != null) {
            adapter.close();
        }
    }

    @Override
    public void onSuccess(String url, String destinationPath) {

        path = destinationPath;
        binding.pdfLayout.addView(remotePDFViewPager,
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        adapter = new PDFPagerAdapter(this, FileUtil.extractFileNameFromURL(url));
        remotePDFViewPager.setAdapter(adapter);
        totalPage = adapter.getCount();
        currentPage = 1;
        viewModel.pageTvVisibility.set(View.VISIBLE);
//        viewModel.setRightButtonVisibility(View.VISIBLE);
        binding.shareButton.setVisibility(View.VISIBLE);
        setPageString();
        dismissDialog();
    }

    @Override
    public void onFailure(Exception e) {
        dismissDialog();
    }


    @Override
    public void onProgressUpdate(int progress, int total) {
    }

    private void setPageString() {
        viewModel.pageTvString.set(currentPage + " / " + totalPage);
    }

    public final void sharePDF(File file) {
        Intent intent = new Intent();
        intent.setAction(Intent.ACTION_SEND);

        intent.setType("application/*");
        ApplicationInfo var8 = this.getApplicationInfo();
        Intrinsics.checkNotNullExpressionValue(var8, "applicationInfo");
        Uri uri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                file
        );

        intent.putExtra(Intent.EXTRA_STREAM, uri);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
        dismissDialog();
    }

    public File renameFile(String file, String toFile) {

        File toBeRenamed = new File(file);
        //检查要重命名的文件是否存在，是否是文件

        File newFile = new File(toFile);
        if (newFile.exists()) {
            Logger.e("已经存在==>");
            return newFile;
        }


        //修改文件名
        if (toBeRenamed.renameTo(newFile)) {
            Logger.e("修改成功==>");
            return newFile;
        } else {
            Logger.e("修改失败==>");
            return toBeRenamed;
        }
    }


}