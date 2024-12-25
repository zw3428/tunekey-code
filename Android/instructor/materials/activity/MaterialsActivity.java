package com.spelist.tunekey.ui.teacher.materials.activity;

import static com.shuyu.gsyvideoplayer.GSYVideoADManager.TAG;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.text.Editable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextPaint;
import android.text.TextWatcher;
import android.text.method.LinkMovementMethod;
import android.text.style.ClickableSpan;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.webkit.MimeTypeMap;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.GridLayoutManager;

import com.google.android.gms.auth.GoogleAuthException;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.drive.Drive;
import com.google.firebase.dynamiclinks.FirebaseDynamicLinks;
import com.google.firebase.dynamiclinks.ShortDynamicLink;
//import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.basic.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.config.SelectMimeType;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.language.LanguageConfig;
//import com.luck.picture.lib.style.PictureParameterStyle;
import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.core.BasePopupView;
import com.lxj.xpopup.interfaces.XPopupCallback;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.chooseFolder.ChooseFolderDialog;
import com.spelist.tunekey.customView.dialog.MaterialAddFolderDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.SLMaterialsUploadDialog;
import com.spelist.tunekey.customView.dialog.googleDrive.SelectGoogleDriveDialog;
import com.spelist.tunekey.customView.dialog.googlePhoto.GooglePhotoDialog;
import com.spelist.tunekey.databinding.FragmentMaterialsBinding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.teacher.materials.MaterialsHelp;
import com.spelist.tunekey.ui.teacher.materials.dialog.TeacherAudioRecodingDialog;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsFolderFragment;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.fragments.dialogs.DialogAddMaterial;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.DriveServiceHelper;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.GlideEngine;
import com.spelist.tunekey.utils.GooglePhotoServiceHelper;
import com.spelist.tunekey.utils.MediaUtils;
import com.spelist.tunekey.utils.PictureSelectorUtils;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.goldze.mvvmhabit.bus.Messenger;

public class MaterialsActivity extends BaseActivity<FragmentMaterialsBinding, MaterialsViewModel> {
    public BaseTitleViewModel baseTitleViewModel;
    public boolean isFolder;
    private MaterialsFolderFragment folderFragment;
    private DialogAddMaterial dialogAddMaterial;
//    private PictureParameterStyle mPictureParameterStyle;
    private static final int REQUEST_CODE_CHOOSE = 23;
    private static final int REQUEST_CODE_SIGN_IN_BY_DRIVE = 1;
    private static final int REQUEST_CODE_SIGN_IN_BY_PHOTO = 2;
    private DriveServiceHelper mDriveServiceHelper;
    private GooglePhotoServiceHelper googlePhotoServiceHelper;
    private ChooseFolderDialog.Builder chooseDialog;
    private int oldPosition = -1;
    public boolean searchStudent = false;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.fragment_materials;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    @Override
    public void initData() {
        super.initData();
        String type = getIntent().getStringExtra("type");
        if (type.equals("show")) {
            viewModel.showType = MaterialsViewModel.ShowType.show;
//            baseTitleViewModel.rightFirstImgVisibility.set(View.VISIBLE);
            baseTitleViewModel.rightFirstImgVisibility.set(View.GONE);
        }
        if (type.equals("select")) {
            viewModel.showType = MaterialsViewModel.ShowType.select;
            viewModel.editStatus.set(true);
//            baseTitleViewModel.rightButtonVisibility.set(View.VISIBLE);
//            baseTitleViewModel.rightButtonText.set("Confirm");
            baseTitleViewModel.rightFirstImgVisibility.set(View.INVISIBLE);
            baseTitleViewModel.rightSecondImgVisibility.set(0);
//        baseTitleViewModel.leftButtonText.set(getActivity().getString(R.string.nav_edit));
            binding.titleLayout.titleRightFirstImg.setImageResource(R.mipmap.ic_search_primary);
            binding.titleLayout.titleRightSecondImg.setImageResource(R.mipmap.ic_add_primary);
            binding.confirmLayout.setVisibility(View.VISIBLE);
            List<MaterialEntity> selectData = (List<MaterialEntity>) getIntent().getSerializableExtra("selectData");
            if (selectData != null) {
                viewModel.selectedMaterials = selectData;
            }
            binding.confirmButton.setClickListener(tkButton -> {
                viewModel.sendSelectMaterials(true);
            });
            binding.btShareSilently.setOnClickListener(tkButton -> viewModel.sendSelectMaterials(false));
            baseTitleViewModel.uc.clickRightButton.observe(this, aVoid -> {

                viewModel.sendSelectMaterials(true);


            });
            baseTitleViewModel.uc.clickRightSecondImgButton.observe(this, aVoid -> {
                initAddMaterialDialog(-1, "");

            });
        }
        List<MaterialEntity> data = (List<MaterialEntity>) getIntent().getSerializableExtra("data");
        viewModel.setData(data);
        baseTitleViewModel.leftBackVisibility.set(View.VISIBLE);
    }

    @Override
    public void initView() {
        super.initView();
        baseTitleViewModel = new BaseTitleViewModel(this.getApplication());
        binding.setVariable(com.spelist.tunekey.BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set(this.getString(R.string.nav_material_title));
        binding.titleLayout.titleLeftImg.setImageResource(R.mipmap.ic_multiple_edit);
        binding.titleLayout.titleRightFirstImg.setImageResource(R.mipmap.ic_search_primary);
        viewModel.roleType.setValue(0);
        viewModel.gridLayoutManager.set(new GridLayoutManager(this, 3));
        binding.titleLayout.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
//                if (isFolder) {
//                    folderFragment.search(s.toString());
//                } else {
//                    viewModel.search(s.toString());
//                }
                if (isFolder) {
//                    folderFragment.search(s.toString());
                    Messenger.getDefault().send(s.toString(), "SEARCH_MATERIALS");
                } else {
                    viewModel.search(s.toString(),false);
                }
            }
        });
        binding.materialsList.setItemAnimator(null);
        binding.searchCancel.setOnClickListener(view -> {
            if (binding.searchEditText.getText().toString().length() > 0) {
                binding.searchEditText.setText("");
            } else {
                baseTitleViewModel.searchIsVisible.set(false);

            }
            viewModel.isShowSearchCancel.set(false);
            viewModel.isShowSearchLayout.set(false);
        });
        binding.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                if (s.toString().length() > 0) {
                    viewModel.isShowSearchCancel.set(true);
                } else {
                    viewModel.isShowSearchCancel.set(false);
                    if (isFolder) {
                        Messenger.getDefault().send(s.toString(), "SEARCH_MATERIALS");
                    } else {
                        viewModel.search(s.toString(),false);
                    }
                }
                viewModel.isShowSearchLayout.set(s.toString().length() > 0);
                viewModel.searchString.set(s.toString());
            }
        });
        binding.llSearchStudent.setOnClickListener(v -> {
            if (isFolder) {
                Messenger.getDefault().send(viewModel.searchString.get(), "SEARCH_MATERIALS");
            } else {
                viewModel.search(viewModel.searchString.get(),true);
            }
            viewModel.isShowSearchLayout.set(false);
        });
        binding.llSearchMaterials.setOnClickListener(v -> {

            if (isFolder) {
                Messenger.getDefault().send(viewModel.searchString.get(), "SEARCH_MATERIALS");
            } else {
                viewModel.search(viewModel.searchString.get(),false);
            }
            viewModel.isShowSearchLayout.set(false);

        });
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();

        //关闭上传Materials dialog
        viewModel.uc.dismissDialog.observe(this, aVoid -> {
            dialogAddMaterial.dismissDialog();
        });
        viewModel.uc.clickAddMaterial.observe(this, aVoid -> {
            initAddMaterialDialog(-1, "");
        });


        //点击folder 中 返回按钮
        baseTitleViewModel.uc.clickLeftBackButton.observe(this, aVoid -> {
            if (isFolder) {
                closeFolder();
            } else {
                finish();
            }
        });
//        viewModel.uc.closeFolderView.observe(this, integer -> closeFolder());

        baseTitleViewModel.uc.clickRightFirstImgButton.observe(this, aVoid -> {
//            startActivity(SearchMaterialsActivity.class);
//            Objects.requireNonNull(this).overridePendingTransition(android.R.anim.fade_in,
//                    android.R.anim.fade_out);

            baseTitleViewModel.searchIsVisible.set(true);
            binding.titleLayout.searchEditText.setFocusable(true);
            binding.titleLayout.searchEditText.setFocusableInTouchMode(true);//设置触摸聚焦
            binding.titleLayout.searchEditText.requestFocus();
            FuncUtils.toggleSoftInput(binding.titleLayout.searchEditText, true);
        });
        viewModel.uc.uploadProgress.observe(this, progress -> {
//            if (chooseDialog != null) {
//                if (progress == 100) {
//                    chooseDialog.setProgress(100);
//                    chooseDialog.dismiss();
//                } else if (progress == -1) {
//                    chooseDialog.setProgress(0);
//                    chooseDialog.isShowProgressBar(false);
//                } else {
//                    chooseDialog.setProgress(progress);
//                }
//            }
            if (progress == 100) {
                dismissDialog();
            }
        });
        viewModel.stopLoading.observe(this, isSuccess -> {
            if (!isSuccess) {
                SLToast.error("Failed, please try again");
            }
        });
        viewModel.uc.materialsObserverData.observe(this, multiItemViewModels ->
                Objects.requireNonNull(viewModel.gridLayoutManager.get()).setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                    @Override
                    public int getSpanSize(int position) {
                        if (multiItemViewModels.get(position).getData().getId().equals("")){
                            return 3;
                        }else  if (viewModel.isListView){
                            return 3;
                        }else {
                            if ((int) multiItemViewModels.get(position).getData().getType() == 6) {
                                return 3;
                            } else {
                                return 1;
                            }
                        }
                    }
                }));
        viewModel.uc.clickItem.observe(this, map -> {
            Logger.e("?????==>%s", "?????");
//            MaterialEntity entity = (MaterialEntity) map.get("data");
//            if (entity.getType() == -2) {
//                replaceFragment(entity);
//                baseTitleViewModel.searchIsVisible.set(false);
//                binding.titleLayout.searchEditText.setText("");
//            } else {
//                MaterialsHelp.clickMaterial(map, this);
//            }
            MaterialEntity entity = (MaterialEntity) map.get("data");
            if (entity.getType() == -2) {
                replaceFragment(entity);
                baseTitleViewModel.searchIsVisible.set(false);
                viewModel.search("",false);
                binding.titleLayout.searchEditText.setText("");
            } else {
                MaterialsHelp.clickMaterial(map, this);
            }
        });
        baseTitleViewModel.uc.clickCancelSearch.observe(this, aVoid -> {
            if (binding.titleLayout.searchEditText.getText().toString().length() > 0) {
                binding.titleLayout.searchEditText.setText("");
            } else {
                baseTitleViewModel.searchIsVisible.set(false);
            }
        });

    }

    public void folderSelectMaterials(boolean select, MaterialEntity selectData) {
        if (select) {
            viewModel.selectedMaterials.add(selectData);
        } else {
            viewModel.selectedMaterials.removeIf(materialEntity -> selectData.getId().equals(materialEntity.getId()));
        }
        for (MaterialsMultiItemViewModel model : viewModel.materialDataList) {
            if (!model.getData().getId().equals(selectData.getFolder())) {
                continue;
            }
            viewModel.selectedMaterials.removeIf(materialEntity -> selectData.getFolder().equals(materialEntity.getId()));
            List<String> selectFileId = new ArrayList<>();
            for (MaterialEntity selectedMaterial : viewModel.selectedMaterials) {
                if (selectedMaterial.getId().equals(model.getData().getId())) {
                    model.isSelected.set(true);
                }
                for (MaterialEntity materialMaterial : model.getData().getMaterials()) {
                    if (materialMaterial.getId().equals(selectedMaterial.getId())) {
                        selectFileId.add(materialMaterial.getId());
                        break;
                    }
                }
            }
            //此处判断 文件夹中的文件是否全部被选中
            boolean isDontAllSelected = false;
            model.isSelected.set(false);
            if (selectFileId.size() == 0) {
                isDontAllSelected = false;
            } else if (selectFileId.size() != model.getData().getMaterials().size()) {
                isDontAllSelected = true;
            }
            if (selectFileId.size() == model.getData().getMaterials().size()) {
                model.isSelected.set(true);
                for (MaterialsMultiItemViewModel itemViewModel : viewModel.materialDataList) {
                    if (itemViewModel.getData().getId().equals(selectData.getFolder())) {
                        viewModel.selectedMaterials.add(itemViewModel.getData());
                        break;
                    }
                }
            }

            model.isDontAllSelected.set(isDontAllSelected);
        }


    }

    private void replaceFragment(MaterialEntity data) {
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
        transaction.setCustomAnimations(
                R.anim.zoom_in,
                R.anim.zoom_out);
        isFolder = true;
        viewModel.isInFolder = true;
        viewModel.inFolderData = data;
        List<MaterialEntity> folderData = viewModel.allMaterialsData.stream().filter(materialEntity -> materialEntity.getFolder().equals(data.getId())).collect(Collectors.toList());
        if (folderFragment == null) {
            folderFragment = new MaterialsFolderFragment();
            folderFragment.setData(folderData, data, viewModel.showType, this, CloneObjectUtils.cloneObject(viewModel.selectedMaterials));
            transaction.add(R.id.folder_view, folderFragment);
            transaction.addToBackStack(null);
        } else {
            folderFragment.setData(folderData, data, viewModel.showType, this, CloneObjectUtils.cloneObject(viewModel.selectedMaterials));
            transaction.show(folderFragment);
        }
        viewModel.catalogueMaterialsData.add(data);
        baseTitleViewModel.leftBackVisibility.set(View.VISIBLE);
        baseTitleViewModel.title.set(data.getName());
        transaction.commit();
        binding.catalogueLayout.setVisibility(View.VISIBLE);
        binding.catalogueArrow.setVisibility(View.GONE);
        setCatalogueName();

//        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
//        transaction.setCustomAnimations(
//                R.anim.zoom_in,
//                R.anim.zoom_out);
//        isFolder = true;
//        viewModel.isInFolder = true;
//        viewModel.inFolderData = data;
//        if (folderFragment == null) {
//            folderFragment = new MaterialsFolderFragment();
//            folderFragment.setData(data.getMaterials(), data, viewModel.showType, this, CloneObjectUtils.cloneObject(viewModel.selectedMaterials));
//            transaction.add(R.id.folder_view, folderFragment);
//            transaction.addToBackStack(null);
//        } else {
//            folderFragment.setData(data.getMaterials(), data, viewModel.showType, this, CloneObjectUtils.cloneObject(viewModel.selectedMaterials));
//            transaction.show(folderFragment);
//        }
//        baseTitleViewModel.leftBackVisibility.set(View.VISIBLE);
//        baseTitleViewModel.title.set(data.getName());
//        transaction.commit();
    }

    /**
     * 设置目录
     */
    public void setCatalogueName() {
        if (viewModel.catalogueMaterialsData.size() > 0) {
            binding.catalogueLayout.setVisibility(View.VISIBLE);
        } else {
            binding.catalogueLayout.setVisibility(View.GONE);
        }

        String catalogueString = "Home / ";
        List<MaterialsHelp.MaterialsCatalogueIndex> materialsCatalogueIndices = new ArrayList<>();
        MaterialsHelp.MaterialsCatalogueIndex a = new MaterialsHelp.MaterialsCatalogueIndex();
        a.setStart(0);
        a.setEnd(catalogueString.length());
        materialsCatalogueIndices.add(a);
        for (int i = 0; i < viewModel.catalogueMaterialsData.size(); i++) {
            catalogueString += viewModel.catalogueMaterialsData.get(i).getName();
            if (i != viewModel.catalogueMaterialsData.size() - 1) {
                catalogueString += " / ";
                MaterialsHelp.MaterialsCatalogueIndex materialsCatalogueIndex = new MaterialsHelp.MaterialsCatalogueIndex();
                int start = catalogueString.length() - (viewModel.catalogueMaterialsData.get(i).getName().length() + 3);
                materialsCatalogueIndex.setStart(start);
                materialsCatalogueIndex.setEnd(catalogueString.length());
                materialsCatalogueIndices.add(materialsCatalogueIndex);
            }
        }
        SpannableStringBuilder homeSpan = new SpannableStringBuilder();
        homeSpan.append(catalogueString);
        //给不同的目录文字添加点击span
        for (int i = 0; i < materialsCatalogueIndices.size(); i++) {
            int finalI = i;
            ClickableSpan clickableSpan = new ClickableSpan() {
                @Override
                public void onClick(@NonNull View view) {
//                    viewModel.catalogueMaterialsData.clear();
//                    closeFolder();
                    if (finalI == 0) {
                        Messenger.getDefault().send(new MaterialEntity().setId("closeAll"), "catalogueCloseFolderView");
                        //延时300毫秒
                        new Handler().postDelayed(() -> {
                            viewModel.catalogueMaterialsData.clear();
                            closeFolder();
                        }, 300);
                        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
                        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                        transaction.setCustomAnimations(
                                R.anim.zoom_in,
                                R.anim.zoom_out);
                        transaction.hide(folderFragment);
                        transaction.commit();
                        folderFragment = null;
                    } else {
                        MaterialEntity messageMaterial = viewModel.catalogueMaterialsData.get(finalI - 1);
                        //发送消息告诉关闭文件夹
                        Messenger.getDefault().send(messageMaterial, "catalogueCloseFolderView");
                        //延时300毫秒
                        new Handler().postDelayed(() -> {
                            viewModel.showMaterial = messageMaterial;
                            //循环删除大于选择的文件夹
                            for (int j = viewModel.catalogueMaterialsData.size() - 1; j > finalI - 1; j--) {
                                viewModel.catalogueMaterialsData.remove(j);
                            }
                            baseTitleViewModel.title.set(messageMaterial.getName());
                            setCatalogueName();
                        }, 300);
                        baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
                        baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
                    }
                }

                @Override
                public void updateDrawState(@NonNull TextPaint ds) {
                    super.updateDrawState(ds);
                    ds.setColor(ContextCompat.getColor(MaterialsActivity.this, R.color.primary));
                    ds.setUnderlineText(false);
                }
            };
            homeSpan.setSpan(clickableSpan, materialsCatalogueIndices.get(i).getStart(), materialsCatalogueIndices.get(i).getEnd(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        binding.catalogueTv.setMovementMethod(LinkMovementMethod.getInstance());
        binding.catalogueTv.setHighlightColor(0);

        binding.catalogueTv.setText(homeSpan);

    }


    public void closeFolder() {

//        baseTitleViewModel.title.set(this.getString(R.string.nav_material_title));
//        isFolder = false;
//        viewModel.isInFolder = false;
//        viewModel.inFolderData = null;
//        if (baseTitleViewModel.searchIsVisible.get()) {
//            binding.titleLayout.searchEditText.setText("");
//            baseTitleViewModel.searchIsVisible.set(false);
//        }
//        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
//        transaction.setCustomAnimations(
//                R.anim.zoom_in,
//                R.anim.zoom_out);
//        transaction.hide(folderFragment);
//        transaction.commit();
        if (baseTitleViewModel.searchIsVisible.get()) {
            binding.titleLayout.searchEditText.setText("");
            baseTitleViewModel.searchIsVisible.set(false);
        }
        if (viewModel.catalogueMaterialsData.size() == 1 || viewModel.catalogueMaterialsData.size() == 0) {
            baseTitleViewModel.title.set(getString(R.string.nav_material_title));
//            baseTitleViewModel.leftBackVisibility.set(View.GONE);
            isFolder = false;
            viewModel.isInFolder = false;
            viewModel.inFolderData = null;
//            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
            baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
            if (folderFragment != null) {
                folderFragment.setIsEdit(false);
//                Messenger.getDefault().send(false,"MATERIALS_EDIT");
                FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
                transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                transaction.setCustomAnimations(
                        R.anim.zoom_in,
                        R.anim.zoom_out);
                transaction.hide(folderFragment);
                transaction.commit();
                folderFragment = null;
            }

            viewModel.showMaterial = null;
            viewModel.catalogueMaterialsData.clear();
            setCatalogueName();

        } else {
//            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
            baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
            Messenger.getDefault().sendNoMsg("closeFolder");
        }
    }

    private void initAddMaterialDialog(int type, String name) {
        viewModel.materialType = type;
        FragmentManager fragmentManager = getSupportFragmentManager();
        dialogAddMaterial = new DialogAddMaterial();
        Bundle t = new Bundle();
        t.putInt("type", type);
        t.putString("name", name);
        t.putString("from", "MaterialFragment");
        Objects.requireNonNull(dialogAddMaterial).setArguments(t);

        if (!dialogAddMaterial.isAdded()) {
            dialogAddMaterial.show(fragmentManager, "DialogFragments");
        }

        dialogAddMaterial.setDialogCallback(new DialogAddMaterial.DialogCallback() {
            @Override
            public void openUploadViaEmailPopup() {
                Logger.e("------- upload from computer");
//                new XPopup.Builder(getContext())
//                        .dismissOnTouchOutside(false)
//                        .popupAnimation(PopupAnimation.ScaleAlphaFromCenter)
//                        .asCustom(new DialogUploadViaEmail(getContext()))
//                        .show();+
                showDialog("Loading...");
                String link = "https://tunekey.app/d/upload/" + UserService.getInstance().getCurrentUserId();
                Task<ShortDynamicLink> shortLinkTask = FirebaseDynamicLinks.getInstance().createDynamicLink()
                        .setLongLink(Uri.parse("https://tunekey.app/link/?link=" + link))
                        .buildShortDynamicLink()
                        .addOnCompleteListener(MaterialsActivity.this, new OnCompleteListener<ShortDynamicLink>() {
                            @Override
                            public void onComplete(@NonNull Task<ShortDynamicLink> task) {
                                dismissDialog();
                                if (!task.isSuccessful() || task.getResult() == null || task.getResult().getShortLink() == null) {
                                    Logger.e("======获取link失败%s", task.getException());
                                    uploadFromComputer(link);
                                } else {
                                    Uri shortLink = task.getResult().getShortLink();
                                    uploadFromComputer(shortLink.toString());
                                }
                            }
                        });


            }

            @Override
            public void addFolder() {
                MaterialAddFolderDialog.Builder dialog = new MaterialAddFolderDialog.Builder(MaterialsActivity.this).create("");
                dialog.clickConfirm(tkButton -> {
                    dialog.dismiss();
//                    viewModel.updateMaterialName(id, dialog.getName());
                    String id = "";
                    if (viewModel.showMaterial != null) {
                        id = viewModel.showMaterial.getId();
                    }
                    viewModel.addFolder(dialog.getName(), id, null);
                });
            }

            @Override
            public void openPhoto() {

                clickOpenPhotoOrVideo();
            }

            @Override
            public void openFile() {
//                clickOpenFile();
            }

            @Override
            public void openCamera() {

            }

            @Override
            public void openGoogleDrive() {
                if (mDriveServiceHelper != null) {

                    showGoogleDrive();
                } else {
                    GoogleSignInOptions signInOptions =
                            new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                    .requestIdToken(TApplication.getInstance().getApplicationContext().getString(R.string.default_web_client_id))
                                    .requestEmail()
                                    .requestScopes(new Scope("https://www.googleapis.com/auth/drive.readonly"))
                                    .build();
                    GoogleSignInClient client = GoogleSignIn.getClient(MaterialsActivity.this, signInOptions);
                    startActivityForResult(client.getSignInIntent(), REQUEST_CODE_SIGN_IN_BY_DRIVE);
                }
            }

            @Override
            public void openGooglePhoto() {
                if (googlePhotoServiceHelper != null) {
                    showGooglePhotoDialog();
                } else {
                    GoogleSignInOptions signInOptions =
                            new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                    .requestIdToken(TApplication.getInstance().getApplicationContext().getString(R.string.default_web_client_id))
                                    .requestEmail()
                                    .requestScopes(new Scope("https://www.googleapis.com/auth/photoslibrary.readonly"))
                                    .build();
                    GoogleSignInClient client = GoogleSignIn.getClient(MaterialsActivity.this, signInOptions);
                    startActivityForResult(client.getSignInIntent(), REQUEST_CODE_SIGN_IN_BY_PHOTO);
                }
            }

            @Override
            public void openAudioRecord() {
                openRecord();
            }

            @Override
            public void confirmMaterialName(String name) {
//                viewModel.getNewMaterialDocId(name, false);
            }

            @Override
            public void confirmYoutubeLink(String title, CharSequence url) {

            }

            @Override
            public void confirmNormalLink(String title, CharSequence url) {

            }

            @Override
            public void openLink() {
                viewModel.materialType = 1;
                showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.link, "Add Link", "", "");
            }
        });
    }

    private void uploadFromComputer(String link) {
        Dialog dialog = SLDialogUtils.showShowUploadFromCompute(this, link);
        TextView centerButton = dialog.findViewById(R.id.center_button);
        centerButton.setOnClickListener(v -> {
            viewModel.sendUploadLinkToEmail(link);
            dialog.dismiss();
        });

        dialog.findViewById(R.id.left_button).setOnClickListener(v -> {

            ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
            assert cm != null;
            cm.setPrimaryClip(ClipData.newPlainText("copy", link));
            dialog.dismiss();
            SLToast.success("Copy Successful!");
        });
    }


    /**
     * 选择照片或视频
     */
    private void clickOpenPhotoOrVideo() {
        PictureSelectorUtils.materials(this);
//
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {
            switch (requestCode) {
                case REQUEST_CODE_SIGN_IN_BY_PHOTO:
                case REQUEST_CODE_SIGN_IN_BY_DRIVE:
                    handleSignInResult(data, requestCode);
                case PictureConfig.CHOOSE_REQUEST:
//                    Logger.e("-**-*-*-*-*-*-*- is picture or video -*-*-*-*-*-*-*-*-*");
                    // 图片选择结果回调
                    List<LocalMedia> localMedia = PictureSelector.obtainSelectorList(data);
                    // 例如 LocalMedia 里面返回五种path
                    // 1.media.getPath(); 为原图path
                    // 2.media.getCutPath();为裁剪后path，需判断media.isCut();是否为true
                    // 3.media.getCompressPath();为压缩后path，需判断media.isCompressed();是否为true
                    // 4.media.getOriginalPath()); media.isOriginal());为true时此字段才有值
                    // 5.media.getAndroidQToPath();为Android Q版本特有返回的字段，此字段有值就用来做上传使用
                    // 如果同时开启裁剪和压缩，则取压缩路径为准因为是先裁剪后压缩
                    for (LocalMedia media : localMedia) {
                        Log.e(TAG, "-*-*-*-*-*-*-*-*-*-*-*-* local media -*-*-*-*-*-*-*-*-*-*-*-*-*");
                        Log.e(TAG, "压缩::" + media.getCompressPath());
                        Log.e(TAG, "原图::" + media.getPath());
                        Log.e(TAG, "裁剪::" + media.getCutPath());
                        Log.e(TAG, "是否开启原图::" + media.isOriginal());
                        Log.e(TAG, "原图路径::" + media.getOriginalPath());
                        Log.e(TAG, "-*-*-*-*-*-*-*-*-*-*-*-* local media -*-*-*-*-*-*-*-*-*-*-*-*-*");
                        int type = PictureMimeType.getMimeType(media.getMimeType());

                        if (SelectMimeType.TYPE_IMAGE == type) {
                            Logger.e("-**-*-*-*-*-*-*- image");
                            if (SLStringUtils.isNoNull(media.getCompressPath())) {
                                viewModel.localPath = media.getCompressPath();
//                            viewModel.localPicVideoPaths.add(media.getCompressPath());
                            } else if (SLStringUtils.isNoNull(media.getCutPath())) {
                                viewModel.localPath = media.getCutPath();
//                            viewModel.localPicVideoPaths.add(media.getCutPath());
                            } else if (SLStringUtils.isNoNull(media.getPath())) {
                                viewModel.localPath = media.getPath();
//                            viewModel.localPicVideoPaths.add(media.getPath());
                            }
//                            initAddMaterialDialog(1, "Photo "+viewModel.photoDefaultNameCount);
                            viewModel.materialType = 1;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.photo, "Add photo", "Photo " + viewModel.photoDefaultNameCount, "");
                        } else {
                            if (SLStringUtils.isNoNull(media.getRealPath())) {
                                viewModel.localPath = media.getRealPath();
                            }

                            if (SelectMimeType.TYPE_VIDEO == type) {

                                Logger.e("-**-*-*-*-*-*-*- video");
                                dialogAddMaterial.dismiss();
                                viewModel.materialType = 5;
//                                initAddMaterialDialog(5, "Video " + viewModel.videoDefaultNameCount);
                                showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.video, "Add video", "Video " + viewModel.videoDefaultNameCount, "");

                            } else {
                                Logger.e("-**-*-*-*-*-*-*- audio");
//                                initAddMaterialDialog(4, "");
                            }
                        }
                        viewModel.localFileSuffixName = MediaUtils.getFileSuffixName(viewModel.localPath);

                    }
                    break;
                case REQUEST_CODE_CHOOSE:
                    Logger.e("-**-*-*-*-*-*-*- is file -*-*-*-*-*-*-*-*-*");
                    //如果是文件选择模式，需要获取选择的所有文件的路径集合
//                    List<String> list = data.getStringArrayListExtra(Constant.RESULT_INFO);
// Constant.RESULT_INFO == "paths"
//                    for (String s : list) {
//                        Logger.e("====ss" + s);
//                    }
////                    List<String> list = data.getStringArrayListExtra("paths");
//                    //如果是文件夹选择模式，需要获取选择的文件夹路径
//                    String path = data.getStringExtra("path");
//                    File file = new File(list.get(0));
//                    Uri uri = null;
//                    if(file.exists()) {
//                        uri = Uri.fromFile(file);
//                    }
                    //todo 判断文件大小如果过大取消上传
//                    Logger.e("====" + file.getPath()+"==="+getMimeType(uri));
//                    ArrayList<EssFile> essFileList =
//                            data.getParcelableArrayListExtra(Const.EXTRA_RESULT_SELECTION);
//                    EssFile file;
//                    if (essFileList != null && essFileList.size() != 0) {
//                        file = essFileList.get(0);
//                        String type = file.getMimeType();
//                        String localPath = file.getAbsolutePath();
//                        String suffix = MediaUtils.getFileSuffixName(localPath);
//                        String name = file.getName().split('.' + suffix)[0];
//                        viewModel.localFileSuffixName = suffix;
//                        viewModel.localPath = localPath;
//                        Logger.e("--*-*-*-*-*-*-*-*-*- file type: " + type);
//                        Logger.e("--*-*-*-*-*-*-*-*-*- file path: " + localPath);
//                        Logger.e("-**-*-*-*-*-*-*-*-*- suffix: " + suffix);
//                        Logger.e("--*-*-*-*-*-*-*-*-*- file name: " + name);
//                        assert suffix != null;
//                        if (suffix.equals("ppt") || suffix.equals("pptx")) {
////                            initAddMaterialDialog(2, name);
//                            viewModel.materialType = 2;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.ppt, "Add ppt", name, "");
//
//                        } else if (suffix.equals("doc") || suffix.equals("docx")) {
////                            initAddMaterialDialog(3, name);
//                            viewModel.materialType = 3;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.doc, "Add file", name, "");
//
//                        } else if (suffix.equals("xls") || suffix.equals("xlsx")) {
////                            initAddMaterialDialog(10, name);
//                            viewModel.materialType = 10;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.xls, "Add file", name, "");
//
//                        } else if (suffix.equals("txt")) {
////                            initAddMaterialDialog(8, name);
//                            viewModel.materialType = 8;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.txt, "Add file", name, "");
//
//                        } else if (suffix.equals("pdf")) {
////                            initAddMaterialDialog(9, name);
//                            viewModel.materialType = 9;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.pdf, "Add file", name, "");
//
//                        } else if (suffix.equals("mp3")) {
////                            initAddMaterialDialog(4, name);
//                            viewModel.materialType = 4;
//                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.mp3, "Add file", name, "");
//
//                        }
//                    }
//                    for (EssFile file :
//                            essFileList) {
//                        file.getAbsolutePath();
//                        builder.append(file.getMimeType()).append(" | ").append(file.getName())
//                        .append("\n\n");
//                    }
//                    textView.setText(builder.toString());

                    break;
            }
        }
    }

    private void showGoogleDrive() {
        SelectGoogleDriveDialog dialog = new SelectGoogleDriveDialog(mDriveServiceHelper);
        dialog.show(getSupportFragmentManager(), "googleDrive");
        dialog.setClickListener(files -> {
            showGoogleDriveChooseFolderDialog(files);
        });
    }

    private void showGoogleDriveChooseFolderDialog(List<SelectGoogleDriveDialog.TKFile> files) {
        showUploadDialog(MaterialsHelp.UploadType.GOOGLE_DRIVE, null, files, null, null);

//        List<MaterialEntity> data = new ArrayList<>();
//
//        data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0 && entity.getCreatorId().equals(viewModel.creatorId)).collect(Collectors.toList());
//
//
//        chooseDialog = new ChooseFolderDialog.Builder(this).create(data);
//        chooseDialog.clickGoBack(tkButton -> {
//            if (!chooseDialog.back()) {
//                chooseDialog.dismiss();
//                chooseDialog = null;
//            } else {
//                chooseDialog.isAddFolder = false;
//            }
//        });
//        chooseDialog.clickNext(tkButton -> {
//            if (chooseDialog.isUpload) {
//                viewModel.uploadGoogleDriveFile(files, chooseDialog.getSelectId(), chooseDialog.getFolderName());
//
//            }
//            chooseDialog.next();
//        });
    }

    private void showGooglePhotoDialog() {
        runOnUiThread(() -> {
            GooglePhotoDialog dialog = new GooglePhotoDialog(this, googlePhotoServiceHelper);
            BasePopupView popupView = new XPopup.Builder(this)
                    .isDestroyOnDismiss(true)
                    .enableDrag(false)
                    .dismissOnBackPressed(true) // 按返回键是否关闭弹窗，默认为true
                    .dismissOnTouchOutside(false)
                    .asCustom(dialog)
                    .show();
            dialog.setClickListener((photoDatas) -> {
                showUploadDialog(MaterialsHelp.UploadType.GOOGLE_PHOTO, null, null, photoDatas, null);

//                List<MaterialEntity> data = new ArrayList<>();
//
//                data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0 && entity.getCreatorId().equals(viewModel.creatorId)).collect(Collectors.toList());
//
//
//                chooseDialog = new ChooseFolderDialog.Builder(this).create(data);
//                chooseDialog.clickGoBack(tkButton -> {
//                    if (!chooseDialog.back()) {
//                        chooseDialog.dismiss();
//                        chooseDialog = null;
//                    } else {
//                        chooseDialog.isAddFolder = false;
//                    }
//                });
//                chooseDialog.clickNext(tkButton -> {
//                    if (chooseDialog.isUpload) {
//                        viewModel.upLoadGooglePhoto(photoDatas, chooseDialog.getSelectId(), chooseDialog.getFolderName());
//                    }
//                    chooseDialog.next();
//                });
            });
        });
    }

    @SuppressLint("CheckResult")
    private void openRecord() {
        List<String> permissionsList = new ArrayList<>();
        permissionsList.add(Manifest.permission.MODIFY_AUDIO_SETTINGS);
        permissionsList.add(Manifest.permission.RECORD_AUDIO);
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S_V2) {
            permissionsList.add("android.permission.READ_MEDIA_AUDIO");
        } else {
            permissionsList.add(Manifest.permission.READ_EXTERNAL_STORAGE);
            permissionsList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }
        String[] permissions = permissionsList.toArray(new String[0]);
        new RxPermissions(this)
                .request(permissions)
                .subscribe(aBoolean -> {
                    if (aBoolean) {

                        //开启屏幕常亮
                        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                        TeacherAudioRecodingDialog recordPracticeDialog = new TeacherAudioRecodingDialog(this, viewModel.audioDefaultNameCount);
                        BasePopupView popupView = new XPopup.Builder(this)
                                .isDestroyOnDismiss(true)
                                .dismissOnBackPressed(false) // 按返回键是否关闭弹窗，默认为true
                                .dismissOnTouchOutside(false)
                                .enableDrag(false)
                                .setPopupCallback(new XPopupCallback() {
                                    @Override
                                    public void onCreated(BasePopupView popupView) {

                                    }

                                    @Override
                                    public void beforeShow(BasePopupView popupView) {

                                    }

                                    @Override
                                    public void onShow(BasePopupView popupView) {

                                    }

                                    @Override
                                    public void onDismiss(BasePopupView popupView) {
                                        //关闭屏幕常亮
                                        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

                                    }

                                    @Override
                                    public void beforeDismiss(BasePopupView popupView) {

                                    }

                                    @Override
                                    public boolean onBackPressed(BasePopupView popupView) {
                                        return false;
                                    }

                                    @Override
                                    public void onKeyBoardStateChanged(BasePopupView popupView, int height) {

                                    }

                                    @Override
                                    public void onDrag(BasePopupView popupView, int value, float percent, boolean upOrLeft) {

                                    }

                                    @Override
                                    public void onClickOutside(BasePopupView popupView) {

                                    }
                                })
                                .asCustom(recordPracticeDialog)
                                .show();
                        recordPracticeDialog.setOnRecordListener((uploadData, name) -> {
                            viewModel.materialType = 4;
                            showAudioChooseFolderDialog(uploadData, name);

                        });
                    } else {
                        SLToast.warning("Please allow to access your device and try again.");
                    }
                });
    }

    private void showAudioChooseFolderDialog(RecordPracticeDialog.TKAudioModule uploadData, String name) {
        showUploadDialog(MaterialsHelp.UploadType.AUDIO, name, null, null, uploadData);

//        List<MaterialEntity> data = new ArrayList<>();
//        data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0).collect(Collectors.toList());
//
//        chooseDialog = new ChooseFolderDialog.Builder(this).create(data);
//        chooseDialog.clickGoBack(tkButton -> {
//            if (!chooseDialog.back()) {
//
//
//                chooseDialog.dismiss();
//                chooseDialog = null;
//            } else {
//                chooseDialog.isAddFolder = false;
//            }
//        });
//        chooseDialog.clickNext(tkButton -> {
//            if (chooseDialog.isUpload) {
//                viewModel.uploadAudio(name, chooseDialog.getSelectId(), chooseDialog.getFolderName(), uploadData.getAudioPath(), uploadData.getId());
//
//            }
//            chooseDialog.next();
//        });
    }

    /**
     * 获取文件类型
     *
     * @param uri
     * @return
     */
    public String getMimeType(Uri uri) {
        String mimeType = null;
        if (uri.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
            ContentResolver cr = getContentResolver();
            mimeType = cr.getType(uri);
        } else {
            String fileExtension = MimeTypeMap.getFileExtensionFromUrl(uri
                    .toString());
            mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(
                    fileExtension.toLowerCase());
        }
        return mimeType;
    }

    private void showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType type, String title, String name, String info) {

        dialogAddMaterial.dismiss();
        SLMaterialsUploadDialog.Builder dialog = new SLMaterialsUploadDialog
                .Builder(this)
                .create(title,
                        name,
                        viewModel.localPath,
                        type);
        dialog.clickConfirm(tkButton -> {
            if (dialog.getType() == SLMaterialsUploadDialog.AddMaterialsType.link || dialog.getType() == SLMaterialsUploadDialog.AddMaterialsType.youtube) {
                if (dialog.getType() == SLMaterialsUploadDialog.AddMaterialsType.link) {
                    viewModel.materialType = 7;
                } else {
                    viewModel.materialType = 6;
                }
                viewModel.minPictureUrl = dialog.getMinImgUrl();
                viewModel.downloadUrl = dialog.getUrl();
                showChooseFolderDialog(dialog.getType(), title, dialog.getName(), info);

            } else {
                showChooseFolderDialog(type, title, dialog.getName(), info);

            }
            dialog.dismiss();
        });
        dialog.setInfo(info);

    }

    private void showChooseFolderDialog(SLMaterialsUploadDialog.AddMaterialsType type, String title, String name, String info) {
        showUploadDialog(MaterialsHelp.UploadType.NONE, name, null, null, null);

//        List<MaterialEntity> data = new ArrayList<>();
//        data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0).collect(Collectors.toList());
//
//
//        chooseDialog = new ChooseFolderDialog.Builder(this).create(data);
//        chooseDialog.clickGoBack(tkButton -> {
//            if (!chooseDialog.back()) {
//                showAddMaterialsDialog(type, title, name, info);
//
//                chooseDialog.dismiss();
//                chooseDialog = null;
//            } else {
//                chooseDialog.isAddFolder = false;
//            }
//        });
//        chooseDialog.clickNext(tkButton -> {
//            if (chooseDialog.isUpload) {
//                viewModel.getNewMaterialDocId(name, chooseDialog.getSelectId(), chooseDialog.getFolderName());
//
//            }
//            chooseDialog.next();
//        });
    }

    private void handleSignInResult(Intent result, int code) {
        GoogleSignIn.getSignedInAccountFromIntent(result)
                .addOnSuccessListener(googleAccount -> {
                    Log.d(TAG, "Signed in as " + googleAccount.getEmail());

                    if (code == REQUEST_CODE_SIGN_IN_BY_PHOTO) {
                        // Use the authenticated account to sign in to the Drive service.
                        GoogleAccountCredential credential =

                                GoogleAccountCredential.usingOAuth2(
                                        this, Collections.singleton("https://www.googleapis.com/auth/photoslibrary.readonly"));

                        credential.setSelectedAccount(googleAccount.getAccount());
                        new Thread(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    googlePhotoServiceHelper = new GooglePhotoServiceHelper(credential.getToken());

                                    showGooglePhotoDialog();

                                } catch (IOException e) {
                                    Logger.e("1======%s", e.getMessage());
                                    e.printStackTrace();
                                } catch (GoogleAuthException e) {
                                    Logger.e("2======%s", e.getMessage());

                                    e.printStackTrace();
                                }
                            }
                        }).start();


                    } else if (code == REQUEST_CODE_SIGN_IN_BY_DRIVE) {

                        GoogleAccountCredential credential =
                                GoogleAccountCredential.usingOAuth2(
                                        this, Collections.singleton("https://www.googleapis.com/auth/drive.readonly"));
                        credential.setSelectedAccount(googleAccount.getAccount());
                        Drive googleDriveService =
                                new Drive.Builder(
                                        AndroidHttp.newCompatibleTransport(),
                                        new GsonFactory(),
                                        credential)
                                        .setApplicationName("Tunekey")
                                        .build();

                        mDriveServiceHelper = new DriveServiceHelper(googleDriveService);

                        showGoogleDrive();
                    }

                })
                .addOnFailureListener(exception -> {
                    Logger.e("======失败%s", exception);
                    SLToast.showError();
                });
    }

    @Override
    public void onBackPressed() {
        if (isFolder) {
            closeFolder();
        } else {
            finish();
            overridePendingTransition(me.goldze.mvvmhabit.R.anim.push_right_in, me.goldze.mvvmhabit.R.anim.push_right_out);
        }
    }

    public void showUploadDialog(MaterialsHelp.UploadType type, String name, List<SelectGoogleDriveDialog.TKFile> driveDatas, List<MaterialEntity> photoDatas, RecordPracticeDialog.TKAudioModule audioData) {
        showDialog("Uploading...");
        String selectFolderId = "-1";
        if (viewModel.showMaterial != null) {
            selectFolderId = viewModel.showMaterial.getId();
        }
        switch (type) {
            case GOOGLE_PHOTO:
                viewModel.upLoadGooglePhoto(photoDatas, selectFolderId, "");
                break;
            case GOOGLE_DRIVE:
                viewModel.uploadGoogleDriveFile(driveDatas, selectFolderId, "");
                break;
            case NONE:
                viewModel.getNewMaterialDocId(name, selectFolderId, "");
                break;
            case AUDIO:
                viewModel.uploadAudio(name, selectFolderId, "", audioData.getAudioPath(), audioData.getId());

                break;
        }
    }
}