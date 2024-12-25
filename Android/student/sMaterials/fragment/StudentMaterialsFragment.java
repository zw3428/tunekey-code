package com.spelist.tunekey.ui.student.sMaterials.fragment;

import static android.app.Activity.RESULT_OK;
import static com.shuyu.gsyvideoplayer.GSYVideoADManager.TAG;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.graphics.Rect;
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
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.MimeTypeMap;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.ActivityOptionsCompat;
import androidx.core.content.ContextCompat;
import androidx.core.util.Pair;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.ess.filepicker.FilePicker;
import com.ess.filepicker.model.EssFile;
import com.ess.filepicker.util.Const;
import com.google.android.gms.auth.GoogleAuthException;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.json.JsonFactory;
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
import com.lxj.xpopup.enums.PopupAnimation;
import com.lxj.xpopup.interfaces.XPopupCallback;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tools.viewModel.BaseTitleViewModel;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.chooseFolder.ChooseFolderDialog;
import com.spelist.tunekey.customView.chooseFolder.MoveFolderDialog;
import com.spelist.tunekey.customView.dialog.MaterialAddFolderDialog;
import com.spelist.tunekey.customView.dialog.MaterialChangeNameDialog;
import com.spelist.tunekey.customView.dialog.SLDialogUtils;
import com.spelist.tunekey.customView.dialog.SLMaterialsUploadDialog;
import com.spelist.tunekey.customView.dialog.googleDrive.SelectGoogleDriveDialog;
import com.spelist.tunekey.customView.dialog.googlePhoto.GooglePhotoDialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.FragmentStudentMaterialsBinding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.material.MaterialDetailsDialog;
import com.spelist.tunekey.ui.material.MaterialsFilterAc;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;
import com.spelist.tunekey.ui.student.sPractice.dialogs.RecordPracticeDialog;
import com.spelist.tunekey.ui.teacher.materials.MaterialsHelp;
import com.spelist.tunekey.ui.teacher.materials.MoveCallbackItemTouch;
import com.spelist.tunekey.ui.teacher.materials.MoveItemHelperCallback;
import com.spelist.tunekey.ui.teacher.materials.dialog.TeacherAudioRecodingDialog;
import com.spelist.tunekey.ui.teacher.materials.fragments.dialogs.DialogAddMaterial;
import com.spelist.tunekey.ui.teacher.materials.fragments.dialogs.DialogConfirmDeleteMaterial;
import com.spelist.tunekey.ui.teacher.students.activity.AddressBookActivity;
import com.spelist.tunekey.ui.toolsView.videoPlayer.VideoPlayerActivity;
import com.spelist.tunekey.ui.toolsView.videoPlayer.YouTubeVideoPlayerActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.DriveServiceHelper;
import com.spelist.tunekey.utils.FuncUtils;
import com.spelist.tunekey.utils.GlideEngine;
import com.spelist.tunekey.utils.GooglePhotoServiceHelper;
import com.spelist.tunekey.utils.MediaUtils;
import com.spelist.tunekey.utils.PictureSelectorUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.tbruyelle.rxpermissions2.RxPermissions;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseFragment;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.utils.MaterialDialogUtils;

public class StudentMaterialsFragment extends BaseFragment<FragmentStudentMaterialsBinding, StudentMaterialsViewModel> implements MoveCallbackItemTouch {
    public boolean searchStudent = false;

    private DialogAddMaterial dialogAddMaterial;
    public BaseTitleViewModel baseTitleViewModel;
//    private PictureParameterStyle mPictureParameterStyle;
    private static final int REQUEST_CODE_CHOOSE = 23;
    public Boolean isEdit = false;
    private LinearLayout bottomBtnBar;
    private TextView delete;
    private TextView move;

    private TextView share;
    private StudentMaterialsFolderFragment folderFragment;
    public boolean isFolder;
    private ChooseFolderDialog.Builder chooseDialog;
    private int oldPosition = -1;
    private int newPosition;
    private MoveItemHelperCallback moveItemHelperCallback;
    private static final int REQUEST_CODE_SIGN_IN_BY_DRIVE = 1;
    private static final int REQUEST_CODE_SIGN_IN_BY_PHOTO = 2;
    private DriveServiceHelper mDriveServiceHelper;
    private GooglePhotoServiceHelper googlePhotoServiceHelper;


    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_student_materials;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }

    @Override
    public void initData() {
        baseTitleViewModel = new BaseTitleViewModel(getActivity().getApplication());
        binding.setVariable(com.spelist.tunekey.BR.titleViewModel, baseTitleViewModel);
        baseTitleViewModel.title.set(getActivity().getString(R.string.nav_material_title));
        viewModel.roleType.setValue(0);
        viewModel.gridLayoutManager.set(new GridLayoutManager(getContext(), 3));
        bottomBtnBar = getActivity().findViewById(R.id.bottom_btn_bar);
        bottomBtnBar.setOnClickListener(v -> {
        });
        delete = bottomBtnBar.findViewById(R.id.first);
        share = bottomBtnBar.findViewById(R.id.center);
        move = bottomBtnBar.findViewById(R.id.second);
        share.setVisibility(View.GONE);
        setBottomButtonIsEnabled(false);

        binding.materialsList.setItemAnimator(null);
        share.setOnClickListener(v -> {
            List<MaterialEntity> materialEntities = new ArrayList<>(viewModel.selectedMaterials);
//            if (isFolder) {
//                materialEntities = new ArrayList<>(folderFragment.getSelectData());
//            }
            Bundle bundle = new Bundle();
            bundle.putSerializable("shareMaterials", (Serializable) materialEntities);
            bundle.putBoolean("isInFolder", isFolder);
            startActivity(AddressBookActivity.class, bundle);
            isEdit = false;
            toggleSelectionStatus(false);
            viewModel.bottomButtonIsEnable.setValue(false);
        });
        delete.setOnClickListener(v -> {

            List<MaterialEntity> selectData = new ArrayList<>(viewModel.selectedMaterials);
            Logger.e("selectData==>%s",selectData.size());
            new XPopup.Builder(getContext())
                    .dismissOnTouchOutside(false)
                    .popupAnimation(PopupAnimation.ScaleAlphaFromCenter)
                    .asCustom(new DialogConfirmDeleteMaterial(getContext(), viewModel, selectData, isFolder, folderFragment))
                    .show();
            viewModel.bottomButtonIsEnable.setValue(false);
            isEdit = false;
            toggleSelectionStatus(false);
        });
        move.setOnClickListener(v -> {
            String currentUserId = UserService.getInstance().getCurrentUserId();
            List<MaterialEntity> moveData = new ArrayList<>(viewModel.selectedMaterials);
            List<MaterialEntity> selectData = new ArrayList<>(viewModel.selectedMaterials);

//            if (isFolder) {
//                moveData = new ArrayList<>(folderFragment.getSelectData());
//            }`
            if (moveData.size() == 0) {
                SLToast.showError();
                return;
            }
//            List<MaterialEntity> folderList = new ArrayList<>();
//            for (MaterialsMultiItemViewModel materialsMultiItemViewModel : viewModel.allMaterialDataList) {
//                if (materialsMultiItemViewModel.getData().getType() == -2 && materialsMultiItemViewModel.getData().getMaterials().size() > 0) {
//                    boolean isSelectFolder = false;
//                    for (MaterialEntity materialEntity : moveData) {
//                        //判断选中的是否有文件夹 如果有则在文件夹选择中过滤掉
//                        if (materialEntity.getId().equals(materialsMultiItemViewModel.getData().getId())) {
//                            isSelectFolder = true;
//                        }
//                    }
//                    if (!isSelectFolder && materialsMultiItemViewModel.getData().getCreatorId().equals(currentUserId)) {
//                        folderList.add(materialsMultiItemViewModel.getData());
//                    }
//                }
//            }
//            if (isFolder) {
//                String folder = moveData.get(0).getFolder();
//                folderList.removeIf(materialEntity -> folder.equals(materialEntity.getId()));
//            }

            List<MaterialEntity> folderList = viewModel.allMaterialsData.stream().filter(materialEntity ->
                    materialEntity.getType() == MaterialEntity.Type.folder
                            && materialEntity.getFolder().equals("") && materialEntity.getCreatorId().equals(currentUserId)).collect(Collectors.toList());
            //过滤选中的文件夹
            for (MaterialEntity moveDatum : moveData) {
                if (moveDatum.getType() == MaterialEntity.Type.folder) {
                    for (int i = 0; i < folderList.size(); i++) {
                        if (folderList.get(i).getId().equals(moveDatum.getId())) {
                            folderList.remove(i);
                            break;
                        }
                    }
                }
            }
            List<MaterialEntity> allMaterialsData = CloneObjectUtils.cloneObject(viewModel.allMaterialsData);
            for (MaterialEntity moveDatum : moveData) {
                if (moveDatum.getType() == MaterialEntity.Type.folder ) {
                    for (int i = 0; i < allMaterialsData.size(); i++) {
                        if (allMaterialsData.get(i).getId().equals(moveDatum.getId())|| !allMaterialsData.get(i).getCreatorId().equals(currentUserId)) {
                            allMaterialsData.remove(i);
                            break;
                        }
                    }
                }
            }
            Logger.e("allMaterialsData==>%s",allMaterialsData.size());

            MoveFolderDialog.Builder moveFolderDialog = new MoveFolderDialog.Builder(getContext()).create(folderList, allMaterialsData);
            moveFolderDialog.clickGoBack(tkButton -> {
                if (moveFolderDialog.back()) {
                    moveFolderDialog.isAddFolder = false;
                } else {
                    moveFolderDialog.dismiss();
                }

            });
            moveFolderDialog.clickNext(tkButton -> {
//                if (moveFolderDialog.isUpload) {
//                    showDialog("");
////                    viewModel.getNewMaterialDocId(name, chooseDialog.getSelectId(), chooseDialog.getFolderName());
//                    viewModel.moveMaterial(moveFolderDialog, moveFolderDialog.getSelectId(), moveFolderDialog.getFolderName(), finalMoveData);
//                }
//                moveFolderDialog.next();
                viewModel.moveMaterials(moveFolderDialog, moveFolderDialog.getSelectId(), moveData);

            });
            moveFolderDialog.setOnClickAddFolderListener((folderName, addInFolderId) -> {
                viewModel.addFolder(folderName,addInFolderId,moveFolderDialog);
            });

            viewModel.bottomButtonIsEnable.setValue(false);
            isEdit = false;
            toggleSelectionStatus(false);

        });

        if (viewModel.materialDataList.size() != 0) {
            showFullNavBtn(true);
        }
    }

    public void toggleSelectionStatus(boolean showAnimation) {
        if (!isEdit) {
            binding.titleLayout.titleRightFirstImg.setVisibility(View.VISIBLE);
            binding.titleLayout.titleRightSecondImg.setVisibility(View.VISIBLE);
            // edit
            baseTitleViewModel.leftButtonVisibility.set(View.GONE);
            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);

            bottomBtnBar.setVisibility(View.GONE);

            if (isFolder) {
                folderFragment.setIsEdit(false);
                Messenger.getDefault().send(false, "MATERIALS_EDIT");

            } else {
                viewModel.clickEdit(true);
                viewModel.editStatus.set(false);
                viewModel.selectedMaterials.clear();
            }

        } else {
            binding.titleLayout.titleRightFirstImg.setVisibility(View.GONE);
            binding.titleLayout.titleRightSecondImg.setVisibility(View.GONE);
            // cancel
            baseTitleViewModel.leftButtonVisibility.set(View.VISIBLE);
            baseTitleViewModel.leftImgVisibility.set(View.GONE);
            binding.titleLayout.titleLeftButton.setText("Cancel");
            bottomBtnBar.setVisibility(View.VISIBLE);
            if (isFolder) {
                folderFragment.setIsEdit(true);
                Messenger.getDefault().send(true, "MATERIALS_EDIT");
            } else {
                viewModel.clickEdit(false);
                viewModel.editStatus.set(true);
                viewModel.cleanSelect();
            }
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void initView() {
        super.initView();
        binding.searchCancel.setOnClickListener(view -> {
            if (binding.searchEditText.getText().toString().length() > 0) {
                binding.searchEditText.setText("");
            } else {
                baseTitleViewModel.searchIsVisible.set(false);
                if (moveItemHelperCallback != null) {
                    moveItemHelperCallback.setDragIsEnable(true);
                }
            }
            viewModel.isShowSearchCancel.set(false);

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
                if (isFolder) {
//                    folderFragment.search(s.toString());
                    Messenger.getDefault().send(s.toString(), "SEARCH_MATERIALS");
                } else {
                    viewModel.search(s.toString());
                }
                if (s.toString().length() > 0) {
                    viewModel.isShowSearchCancel.set(true);
                } else {
                    viewModel.isShowSearchCancel.set(false);
                }
            }
        });
        this.moveItemHelperCallback = new MoveItemHelperCallback(this);
        ItemTouchHelper touchHelper = new ItemTouchHelper(moveItemHelperCallback); // Create ItemTouchHelper and pass with parameter the MyItemTouchHelperCallback
        touchHelper.attachToRecyclerView(binding.materialsList);
        String currentUserId = UserService.getInstance().getCurrentUserId();


        binding.materialsList.setOnTouchListener((v, event) -> {
            int type = event.getAction();
            switch (type) {
                case MotionEvent.ACTION_DOWN:
                    break;
                case MotionEvent.ACTION_MOVE:

                    if (oldPosition == -1) {
                        break;
                    }
                    try {

                        viewModel.materialDataList.get(oldPosition).isDragging.set(true);
                        int position = pointToPosition((int) event.getX(), (int) event.getY());

                        if (position == -1) {
                            clearMoveColor();
                            setTypeDrawable(oldPosition, 2);
                        }
                        if (position != -1) {
                            if (viewModel.materialDataList.get(oldPosition).getData().getCreatorId().equals(currentUserId) && viewModel.materialDataList.get(position).getData().getCreatorId().equals(currentUserId)) {
                                setTypeDrawable(oldPosition, 1);
                            } else {
                                clearMoveColor();
                                setTypeDrawable(oldPosition, 2);
                            }
                        }

                        setMoveColor(position);
                    } catch (Exception e) {
                        clearMoveColor();
                        Log.e("======", "失败了");
                    }

                    break;
                case MotionEvent.ACTION_UP:

                    if (oldPosition == -1) {
                        break;
                    }
                    try {
                        viewModel.materialDataList.get(oldPosition).isDragging.set(false);
                        int toPosition = pointToPosition((int) event.getX(), (int) event.getY());
                        Logger.e("======%s===%s", toPosition, oldPosition);
                        if (toPosition != -1 && toPosition != oldPosition && viewModel.materialDataList.get(oldPosition).getData().getCreatorId().equals(currentUserId) && viewModel.materialDataList.get(toPosition).getData().getCreatorId().equals(currentUserId)) {
                            viewModel.dragData(oldPosition, toPosition);
                        }
                        clearMoveColor();
                        oldPosition = -1;
                        this.newPosition = -1;

                    } catch (Exception e) {
                        clearMoveColor();
                        Log.e("======", "失败了" + e.getMessage());
                    }
                    break;
            }

            return false;
        });
    }

    public int pointToPosition(int x, int y) throws Exception {
        Rect frame = new Rect();
        final int count = binding.materialsList.getChildCount(); //显示的子item 数
        for (int i = count - 1; i >= 0; i--) { // 遍历判断当前xy值所在的position
            final View child = binding.materialsList.getChildAt(i);
            if (oldPosition != binding.materialsList.getChildAdapterPosition(child)) { //忽略移动view的坐标
                if (child.getVisibility() != View.GONE) {
                    child.getHitRect(frame);
                    if (frame.contains(x, y)) {
                        return i + viewModel.gridLayoutManager.get().findFirstVisibleItemPosition();
                    }
                }
            }
        }
        return -1;
    }

    @Override
    public void itemTouchOnMove(RecyclerView.ViewHolder holder, int oldP, int newP, RecyclerView.ViewHolder target) {
//        if (viewModel.materialDataList.get(oldP).getData().getType() != -2) {
//            setMoveColor(newP);
//        }
        this.oldPosition = oldP;
        this.newPosition = newP;
    }

    private void setMoveColor(int newP) {
        int count = binding.materialsList.getChildCount();
        for (int i = 0; i < count; i++) {
            if (newP == i) {
                viewModel.materialDataList.get(i).dragIsVisible.set(true);
            } else {
                viewModel.materialDataList.get(i).dragIsVisible.set(false);
            }
        }
    }

    private void clearMoveColor() {
        int count = binding.materialsList.getChildCount();
        for (int i = 0; i < count; i++) {
            viewModel.materialDataList.get(i).dragIsVisible.set(false);
            setTypeDrawable(i, 0);
        }
    }

    /**
     * 设置 item 右上角的加号 禁止
     *
     * @param pos
     * @param type 0 是默认状态,1是拖拽中,2是位置不可用
     */
    private void setTypeDrawable(int pos, int type) {
        int img = R.mipmap.transparent;
        if (type == 1) {
            img = R.mipmap.add;
            if (viewModel.materialDataList.get(pos).getData().getType() == -2) {
                img = R.mipmap.stop;
            }
        } else if (type == 2) {
            img = R.mipmap.stop;
            if (viewModel.materialDataList.get(pos).getData().getType() == -2) {
                img = R.mipmap.stop;
            }
        }

        viewModel.materialDataList.get(pos).typeDrawable.set(ContextCompat.getDrawable(getContext(), img));
    }


    @Override
    public void initViewObservable() {
        //点击folder 中 返回按钮
        baseTitleViewModel.uc.clickLeftBackButton.observe(this, aVoid -> closeFolder());
        //关闭上传Materials dialog
        viewModel.uc.dismissDialog.observe(this, aVoid -> {
            dialogAddMaterial.dismissDialog();
        });


        viewModel.uc.clickAddMaterial.observe(this, aVoid -> {
            initAddMaterialDialog(-1, "");
        });

        baseTitleViewModel.uc.clickLeftButton.observe(this, aVoid -> {
            // isEdit
            Logger.e("------ click to cancel edit");
            isEdit = false;
            toggleSelectionStatus(false);
            viewModel.bottomButtonIsEnable.setValue(false);
        });

        baseTitleViewModel.uc.clickLeftImgButton.observe(this, aVoid -> {
            // not edit
            Logger.e("------ click to edit");
            isEdit = true;
            toggleSelectionStatus(true);
        });

        baseTitleViewModel.uc.clickRightFirstImgButton.observe(this, aVoid -> {
//            startActivity(SearchMaterialsActivity.class);
//            Objects.requireNonNull(getActivity()).overridePendingTransition(android.R.anim.fade_in,
//                    android.R.anim.fade_out);

//            baseTitleViewModel.searchIsVisible.set(true);
//            viewModel.isSearching = true;
//            if (moveItemHelperCallback != null) {
//                moveItemHelperCallback.setDragIsEnable(false);
//            }
//            binding.titleLayout.searchEditText.setFocusable(true);
//            binding.titleLayout.searchEditText.setFocusableInTouchMode(true);//设置触摸聚焦
//            binding.titleLayout.searchEditText.requestFocus();
//            FuncUtils.toggleSoftInput(binding.titleLayout.searchEditText, true);
            Bundle bundle = new Bundle();
            if (viewModel.showMaterial != null) {
                Logger.e("sss==>%s",viewModel.showMaterial.getId());
                bundle.putSerializable("folderId",viewModel.showMaterial.getId());
            }else {
                bundle.putSerializable("folderId","home");
            }
            startActivity(MaterialsFilterAc.class,bundle);
        });

        baseTitleViewModel.uc.clickRightSecondImgButton.observe(this, aVoid -> {
            initAddMaterialDialog(-1, "");

        });
        viewModel.uc.materialsObserverData.observe(this, multiItemViewModels -> {
            if (multiItemViewModels.size() != 0) {
                showFullNavBtn(false);
            }

            Objects.requireNonNull(viewModel.gridLayoutManager.get()).setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                @Override
                public int getSpanSize(int position) {


                    if (multiItemViewModels.get(position).getData().getId().equals("")){
                        return 3;
                    }else  if (viewModel.isListView){
                        return 3;
                    }else{

                        if ((int) multiItemViewModels.get(position).getData().getType() == 6) {
                            return 3;
                        } else {
                            return 1;
                        }
                    }
                }
            });


        });


        viewModel.uc.clickVideoItem.observe(this, map -> {
            Class<?> AimActivity = null;
            String url = (String) map.get("url");
            String minPicUrl = (String) map.get("minPicUrl");
            String name = (String) map.get("name");
            View view = (View) map.get("itemView");
            int type = (int) map.get("type");
            if (type == 6) {
                AimActivity = YouTubeVideoPlayerActivity.class;
            } else if (type == 5) {
                AimActivity = VideoPlayerActivity.class;
            }
            FuncUtils.goToVideoPlayer(getActivity(), view, AimActivity, url, name, minPicUrl);
            Logger.e("???==>%s", "????");

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
        viewModel.uc.clickItem.observe(this, map -> {
            MaterialEntity entity = (MaterialEntity) map.get("data");
            if (entity.getType() == -2) {
                replaceFragment(entity);
                baseTitleViewModel.searchIsVisible.set(false);
                viewModel.isSearching = false;
                viewModel.search("");

                viewModel.searchString = "";
                if (moveItemHelperCallback != null) {
                    moveItemHelperCallback.setDragIsEnable(true);
                }
                binding.titleLayout.searchEditText.setText("");
                if (!entity.getCreatorId().equals(UserService.getInstance().getCurrentUserId())) {
                    baseTitleViewModel.leftImgVisibility.set(View.GONE);
                    baseTitleViewModel.rightSecondImgVisibility.set(View.INVISIBLE);
                }
            } else {
                MaterialsHelp.clickMaterial(map, getActivity(), this);
            }
        });
        viewModel.stopLoading.observe(this, isSuccess -> {
            if (!isSuccess) {
                SLToast.error("Failed, please try again");
            }
        });

//        viewModel.uc.closeFolderView.observe(this, integer -> closeFolder());

        viewModel.uc.changeName.observe(this, data -> {
            String id = data.get("id");
            String defaultName = data.get("defaultName");
            MaterialChangeNameDialog.Builder dialog = new MaterialChangeNameDialog.Builder(getContext()).create(defaultName);
            dialog.clickConfirm(tkButton -> {
                dialog.dismiss();
                viewModel.updateMaterialName(id, dialog.getName());
            });
        });


        baseTitleViewModel.uc.clickCancelSearch.observe(this, aVoid -> {
            if (binding.titleLayout.searchEditText.getText().toString().length() > 0) {
                binding.titleLayout.searchEditText.setText("");
            } else {
                baseTitleViewModel.searchIsVisible.set(false);
                viewModel.isSearching = false;
                viewModel.searchString = "";
                if (moveItemHelperCallback != null) {
                    moveItemHelperCallback.setDragIsEnable(true);
                }
            }
        });
        viewModel.bottomButtonIsEnable.observe(this, this::setBottomButtonIsEnabled);


        binding.titleLayout.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {

            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {

            }

            @Override
            public void afterTextChanged(Editable s) {
                if (isFolder) {
//                    folderFragment.search(s.toString());
                    Messenger.getDefault().send(s.toString(), "SEARCH_MATERIALS");

                } else {
                    viewModel.search(s.toString());
                }
            }
        });

        viewModel.uc.clickMore.observe(this, data -> {
            BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity());
            bottomMenuFragment.addMenuItems(new MenuItem("Details"));
//            bottomMenuFragment.addMenuItems(new MenuItem("Share In-App"));
//            bottomMenuFragment.addMenuItems(new MenuItem("Share Out-App"));
            if (data.creatorId.equals(viewModel.studentId)) {
                bottomMenuFragment.addMenuItems(new MenuItem("Delete", ContextCompat.getColor(getContext(), R.color.red)));
            }
            bottomMenuFragment.show();
            bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                CharSequence text = menu_item.getText();
                if (text.equals("Details")) {
                    MaterialDetailsDialog dialog = new MaterialDetailsDialog(getContext(), viewModel.path,data);
                    dialog.showDialog();
                } else if (text.equals("Share In-App")) {
                    viewModel.clickItemShare(data);

                } else if (text.equals("Share Out-App")) {

                } else if (text.equals("Delete")) {
                    viewModel.uc.clickDelete.setValue(data);
                }
            });
        });
        viewModel.uc.clickDelete.observe(this, data -> {
            List<MaterialEntity> selectData = new ArrayList<>();
            selectData.add(data);
            new XPopup.Builder(getContext())
                    .dismissOnTouchOutside(false)
                    .popupAnimation(PopupAnimation.ScaleAlphaFromCenter)
                    .asCustom(new DialogConfirmDeleteMaterial(requireContext(), viewModel, selectData, isFolder, folderFragment))
                    .show();
        });
    }

    public void showFullNavBtn(boolean showAnimation) {
        //显示顶部导航按钮
        if (isEdit) {
            baseTitleViewModel.leftButtonVisibility.set(View.VISIBLE);
            baseTitleViewModel.leftImgVisibility.set(View.GONE);
        } else {
            baseTitleViewModel.leftButtonVisibility.set(View.GONE);
            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
        }

        baseTitleViewModel.rightFirstImgVisibility.set(0);
        baseTitleViewModel.rightSecondImgVisibility.set(0);
//        baseTitleViewModel.leftButtonText.set(getActivity().getString(R.string.nav_edit));
        binding.titleLayout.titleLeftImg.setImageResource(R.mipmap.ic_multiple_edit);
        binding.titleLayout.titleRightFirstImg.setImageResource(R.mipmap.ic_filter_primary);
        binding.titleLayout.titleRightSecondImg.setImageResource(R.mipmap.ic_add_primary);
    }

    /**
     * 跳转到视频播放
     *
     * @param activity
     * @param view
     */
    public static void goToVideoPlayer(Activity activity, View view, Class<?> aimActivityClass) {
        Intent intent = new Intent(activity, aimActivityClass);
        intent.putExtra(VideoPlayerActivity.TRANSITION, true);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            Pair pair = new Pair<>(view, VideoPlayerActivity.IMG_TRANSITION);
            ActivityOptionsCompat activityOptions =
                    ActivityOptionsCompat.makeSceneTransitionAnimation(
                            activity, pair);
            ActivityCompat.startActivity(activity, intent, activityOptions.toBundle());
        } else {
            activity.startActivity(intent);
            activity.overridePendingTransition(R.anim.abc_fade_in, R.anim.abc_fade_out);
        }
    }

    /**
     * 初始化弹窗
     */
    private void initAddMaterialDialog(int type, String name) {
        viewModel.materialType = type;
        FragmentManager fragmentManager = requireActivity().getSupportFragmentManager();
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
                        .addOnCompleteListener(requireActivity(), new OnCompleteListener<ShortDynamicLink>() {
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
                MaterialAddFolderDialog.Builder dialog = new MaterialAddFolderDialog.Builder(getContext()).create("");
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
                clickOpenFile();
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
                    GoogleSignInClient client = GoogleSignIn.getClient(getActivity(), signInOptions);
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
                    GoogleSignInClient client = GoogleSignIn.getClient(getActivity(), signInOptions);
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
        Dialog dialog = SLDialogUtils.showShowUploadFromCompute(getContext(), link);
        TextView centerButton = dialog.findViewById(R.id.center_button);
        centerButton.setOnClickListener(v -> {
            viewModel.sendUploadLinkToEmail(link);
            dialog.dismiss();
        });

        dialog.findViewById(R.id.left_button).setOnClickListener(v -> {
            if (getActivity() == null) {
                return;
            }
            ClipboardManager cm = (ClipboardManager) getActivity().getSystemService(Context.CLIPBOARD_SERVICE);
            assert cm != null;
            cm.setPrimaryClip(ClipData.newPlainText("copy", link));
            dialog.dismiss();
            SLToast.success("Copy Successful!");
        });
    }

    /**
     * 点击选择文件
     */
    @SuppressLint("CheckResult")
    private void clickOpenFile() {
        final RxPermissions rxPermissions = new RxPermissions(this); // where this is an Activity
        // or Fragment instance
        rxPermissions
                .requestEach(Manifest.permission.READ_EXTERNAL_STORAGE)
                .subscribe(permission -> {
                    if (permission.granted) { // Always true pre-M
                        // I can control the camera now
                        FilePicker
                                .from(this)
                                .chooseForMimeType()
                                .setMaxCount(1)
                                .setFileTypes("pdf", "doc", "ppt", "xls", "txt", "mp3")
                                .requestCode(REQUEST_CODE_CHOOSE)
                                .start();
                    } else if (permission.shouldShowRequestPermissionRationale) {
                        // Denied permission without ask never again
                        SLToast.warning(getString(R.string.no_permission));
                    } else {
                        MaterialDialogUtils
                                .showPermissionDialog(
                                        getContext(),
                                        getString(R.string.permission_settings),
                                        getString(R.string.read_external_storage_permission))
                                .show();
                    }
                });
    }

    /**
     * 选择照片或视频
     */
    private void clickOpenPhotoOrVideo() {
        PictureSelectorUtils.materials(this);
    }


    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (resultCode == RESULT_OK) {
            switch (requestCode) {
                case REQUEST_CODE_SIGN_IN_BY_PHOTO:
                case REQUEST_CODE_SIGN_IN_BY_DRIVE:
                    handleSignInResult(data, requestCode);
                    break;
                case PictureConfig.CHOOSE_REQUEST:
////                    Logger.e("-**-*-*-*-*-*-*- is picture or video -*-*-*-*-*-*-*-*-*");
//                    // 图片选择结果回调
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
                    ArrayList<EssFile> essFileList =
                            data.getParcelableArrayListExtra(Const.EXTRA_RESULT_SELECTION);
                    EssFile file;
                    if (essFileList != null && essFileList.size() != 0) {
                        file = essFileList.get(0);
                        String type = file.getMimeType();
                        String localPath = file.getAbsolutePath();
                        String suffix = MediaUtils.getFileSuffixName(localPath);
                        String name = file.getName().split('.' + suffix)[0];
                        viewModel.localFileSuffixName = suffix;
                        viewModel.localPath = localPath;
                        Logger.e("--*-*-*-*-*-*-*-*-*- file type: " + type);
                        Logger.e("--*-*-*-*-*-*-*-*-*- file path: " + localPath);
                        Logger.e("-**-*-*-*-*-*-*-*-*- suffix: " + suffix);
                        Logger.e("--*-*-*-*-*-*-*-*-*- file name: " + name);
                        assert suffix != null;
                        if (suffix.equals("ppt") || suffix.equals("pptx")) {
//                            initAddMaterialDialog(2, name);
                            viewModel.materialType = 2;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.ppt, "Add ppt", name, "");

                        } else if (suffix.equals("doc") || suffix.equals("docx")) {
//                            initAddMaterialDialog(3, name);
                            viewModel.materialType = 3;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.doc, "Add file", name, "");

                        } else if (suffix.equals("xls") || suffix.equals("xlsx")) {
//                            initAddMaterialDialog(10, name);
                            viewModel.materialType = 10;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.xls, "Add file", name, "");

                        } else if (suffix.equals("txt")) {
//                            initAddMaterialDialog(8, name);
                            viewModel.materialType = 8;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.txt, "Add file", name, "");

                        } else if (suffix.equals("pdf")) {
//                            initAddMaterialDialog(9, name);
                            viewModel.materialType = 9;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.pdf, "Add file", name, "");

                        } else if (suffix.equals("mp3")) {
//                            initAddMaterialDialog(4, name);
                            viewModel.materialType = 4;
                            showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType.mp3, "Add file", name, "");

                        }
                    }
//                    for (EssFile file :
//                            essFileList) {
//                        file.getAbsolutePath();
//                        builder.append(file.getMimeType()).append(" | ").append(file.getName())
//                        .append("\n\n");
//                    }
//                    textView.setText(builder.toString());

                    break;
            }
        } else {
//            SLToast.showError();
        }
    }

    /**
     * 显示 add materials dialog
     *
     * @param type
     * @param title
     * @param name
     * @param info
     */
    private void showAddMaterialsDialog(SLMaterialsUploadDialog.AddMaterialsType type, String title, String name, String info) {

        dialogAddMaterial.dismiss();
        SLMaterialsUploadDialog.Builder dialog = new SLMaterialsUploadDialog
                .Builder(getContext())
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
//
//        data = viewModel.studentMaterials.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0 && entity.getCreatorId().equals(viewModel.creatorId)).collect(Collectors.toList());
//
//
//        chooseDialog = new ChooseFolderDialog.Builder(getContext()).create(data);
//        chooseDialog.clickGoBack(tkButton -> {
//            if (!chooseDialog.back()) {
//                showAddMaterialsDialog(type, title, name, info);
//                chooseDialog.dismiss();
//                chooseDialog = null;
//            } else {
//                chooseDialog.isAddFolder = false;
//            }
//        });
//        chooseDialog.clickNext(tkButton -> {
//            if (chooseDialog.isUpload) {
//                viewModel.getNewMaterialDocId(name, chooseDialog.getSelectId(), chooseDialog.getFolderName());
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
            ContentResolver cr = getActivity().getContentResolver();
            mimeType = cr.getType(uri);
        } else {
            String fileExtension = MimeTypeMap.getFileExtensionFromUrl(uri
                    .toString());
            mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(
                    fileExtension.toLowerCase());
        }
        return mimeType;
    }

    private void replaceFragment(MaterialEntity data) {
//        FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
//        transaction.setCustomAnimations(
//                R.anim.zoom_in,
//                R.anim.zoom_out);
//        isFolder = true;
//        viewModel.isInFolder = true;
//        viewModel.inFolderData = data;
//        List<MaterialEntity> folderData = viewModel.allMaterialsData.stream().filter(materialEntity -> materialEntity.getFolder().equals(data.getId())).collect(Collectors.toList());
//
//        if (folderFragment == null) {
//            folderFragment = new StudentMaterialsFolderFragment();
//            folderFragment.setData(folderData, data, this);
//            transaction.add(R.id.folder_view, folderFragment);
//            transaction.addToBackStack(null);
//        } else {
//            folderFragment.setData(data.getMaterials(), data, this);
//            transaction.show(folderFragment);
//        }
//        baseTitleViewModel.leftBackVisibility.set(View.VISIBLE);
//
//
//        baseTitleViewModel.title.set(data.getName());
//        transaction.commit();
        FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
        transaction.setCustomAnimations(
                R.anim.zoom_in,
                R.anim.zoom_out);
        isFolder = true;
        viewModel.isInFolder = true;
        viewModel.inFolderData = data;
//        List<MaterialEntity> folderData = viewModel.allMaterialsData.stream().filter(materialEntity -> materialEntity.getFolder().equals(data.getId())).collect(Collectors.toList());
        List<MaterialEntity> folderData = new ArrayList<>();
        if (data.getCreatorId().equals(SLCacheUtil.getCurrentUserId())){
            folderData   = viewModel.studentMaterials.stream().filter(material -> material.getFolder().equals(data.getId())).collect(Collectors.toList());
        }else {
            folderData   = viewModel.teacherMaterialsData.stream().filter(material -> material.getFolder().equals(data.getId())).collect(Collectors.toList());
        }

        if (folderFragment == null) {
            folderFragment = new StudentMaterialsFolderFragment();
            folderFragment.setData(folderData, data, this);
            transaction.add(R.id.folder_view, folderFragment);
            transaction.addToBackStack(null);
        } else {
            folderFragment.setData(folderData, data, this);
            transaction.show(folderFragment);
        }
        viewModel.catalogueMaterialsData.add(data);
        baseTitleViewModel.leftBackVisibility.set(View.VISIBLE);
        baseTitleViewModel.title.set(data.getName());
        transaction.commit();
        binding.catalogueLayout.setVisibility(View.VISIBLE);
        binding.catalogueArrow.setVisibility(View.GONE);
        setCatalogueName();

    }

    public void closeFolder() {
//        baseTitleViewModel.title.set(getActivity().getString(R.string.nav_material_title));
//        baseTitleViewModel.leftBackVisibility.set(View.GONE);
//        isFolder = false;
//        viewModel.isInFolder = false;
//        viewModel.inFolderData = null;
//        baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
//        baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
//        isEdit = false;
//        folderFragment.setIsEdit(false);
//        Messenger.getDefault().send(false, "MATERIALS_EDIT");
//        toggleSelectionStatus(false);
//        viewModel.bottomButtonIsEnable.setValue(false);
//        if (baseTitleViewModel.searchIsVisible.get()) {
//            binding.titleLayout.searchEditText.setText("");
//            baseTitleViewModel.searchIsVisible.set(false);
//            viewModel.isSearching = false;
//            viewModel.searchString = "";
//            if (moveItemHelperCallback != null) {
//                moveItemHelperCallback.setDragIsEnable(true);
//            }
//        }
//
//        FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
//        transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
//        transaction.setCustomAnimations(
//                R.anim.zoom_in,
//                R.anim.zoom_out);
//        transaction.hide(folderFragment);
//        transaction.commit();

        if (viewModel.catalogueMaterialsData.size() == 1 || viewModel.catalogueMaterialsData.size() == 0) {
            baseTitleViewModel.title.set(getActivity().getString(R.string.nav_material_title));
            baseTitleViewModel.leftBackVisibility.set(View.GONE);
            isFolder = false;
            viewModel.isInFolder = false;
            viewModel.inFolderData = null;
            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
            baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
            isEdit = false;

            toggleSelectionStatus(false);
            viewModel.bottomButtonIsEnable.setValue(false);
            if (baseTitleViewModel.searchIsVisible.get()) {
                binding.titleLayout.searchEditText.setText("");
                baseTitleViewModel.searchIsVisible.set(false);
                viewModel.isSearching = false;
                viewModel.searchString = "";
                if (moveItemHelperCallback != null) {
                    moveItemHelperCallback.setDragIsEnable(true);
                }
            }
            if (folderFragment != null) {
                folderFragment.setIsEdit(false);
//                Messenger.getDefault().send(false,"MATERIALS_EDIT");
                FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
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
            baseTitleViewModel.leftImgVisibility.set(View.VISIBLE);
            baseTitleViewModel.rightSecondImgVisibility.set(View.VISIBLE);
            isEdit = false;

            toggleSelectionStatus(false);
            if (viewModel.showMaterial!=null&&!viewModel.showMaterial.getCreatorId().equals(SLCacheUtil.getCurrentUserId())) {
                baseTitleViewModel.leftImgVisibility.set(View.GONE);
                baseTitleViewModel.rightSecondImgVisibility.set(View.INVISIBLE);
            }

            viewModel.bottomButtonIsEnable.setValue(false);
            if (baseTitleViewModel.searchIsVisible.get()) {
                binding.titleLayout.searchEditText.setText("");
                baseTitleViewModel.searchIsVisible.set(false);
                if (moveItemHelperCallback != null) {
                    moveItemHelperCallback.setDragIsEnable(true);
                }
            }
            Messenger.getDefault().sendNoMsg("closeFolder");

        }

    }


    public void setBottomButtonIsEnabled(boolean isEnable) {
        delete.setEnabled(isEnable);
        share.setEnabled(isEnable);
        move.setEnabled(isEnable);
        if (isEnable) {
            delete.setTextColor(ContextCompat.getColor(getContext(), R.color.red));
            share.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
            move.setTextColor(ContextCompat.getColor(getContext(), R.color.main));
        } else {
            delete.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            share.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
            move.setTextColor(ContextCompat.getColor(getContext(), R.color.fourth));
        }
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
                        FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
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
                        isEdit = false;

                        toggleSelectionStatus(false);
                        viewModel.bottomButtonIsEnable.setValue(false);
                        if (baseTitleViewModel.searchIsVisible.get()) {
                            binding.titleLayout.searchEditText.setText("");
                            baseTitleViewModel.searchIsVisible.set(false);
                            if (moveItemHelperCallback != null) {
                                moveItemHelperCallback.setDragIsEnable(true);
                            }
                        }
                    }

                }

                @Override
                public void updateDrawState(@NonNull TextPaint ds) {
                    super.updateDrawState(ds);
                    ds.setColor(ContextCompat.getColor(getContext(), R.color.primary));
                    ds.setUnderlineText(false);
                }
            };
            homeSpan.setSpan(clickableSpan, materialsCatalogueIndices.get(i).getStart(), materialsCatalogueIndices.get(i).getEnd(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        binding.catalogueTv.setMovementMethod(LinkMovementMethod.getInstance());
        binding.catalogueTv.setHighlightColor(0);
        viewModel.path = catalogueString;

        binding.catalogueTv.setText(homeSpan);

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
                        getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                        TeacherAudioRecodingDialog recordPracticeDialog = new TeacherAudioRecodingDialog(getActivity(), viewModel.audioDefaultNameCount);
                        BasePopupView popupView = new XPopup.Builder(getContext())
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
                                        getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

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
                    }
                });
    }

    private void showAudioChooseFolderDialog(RecordPracticeDialog.TKAudioModule uploadData, String name) {
        showUploadDialog(MaterialsHelp.UploadType.AUDIO, name, null, null, uploadData);

//        List<MaterialEntity> data = new ArrayList<>();
//        data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0 && entity.getCreatorId().equals(viewModel.creatorId)).collect(Collectors.toList());
//
//        chooseDialog = new ChooseFolderDialog.Builder(getContext()).create(data);
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

    private void handleSignInResult(Intent result, int code) {
        GoogleSignIn.getSignedInAccountFromIntent(result)
                .addOnSuccessListener(googleAccount -> {
                    Log.d(TAG, "Signed in as " + googleAccount.getEmail());

                    if (code == REQUEST_CODE_SIGN_IN_BY_PHOTO) {
                        // Use the authenticated account to sign in to the Drive service.
                        GoogleAccountCredential credential =

                                GoogleAccountCredential.usingOAuth2(
                                        getContext(), Collections.singleton("https://www.googleapis.com/auth/photoslibrary.readonly"));

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

                        Logger.e("======%s", googleAccount.getIdToken());


                    } else if (code == REQUEST_CODE_SIGN_IN_BY_DRIVE) {

                        GoogleAccountCredential credential =
                                GoogleAccountCredential.usingOAuth2(
                                        getContext(), Collections.singleton("https://www.googleapis.com/auth/drive.readonly"));
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

    private void showGooglePhotoDialog() {
        getActivity().runOnUiThread(() -> {
            GooglePhotoDialog dialog = new GooglePhotoDialog(getContext(), googlePhotoServiceHelper);
            BasePopupView popupView = new XPopup.Builder(getContext())
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
//                chooseDialog = new ChooseFolderDialog.Builder(getContext()).create(data);
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

    private void showGoogleDrive() {
        if (getActivity() == null) {
            return;
        }
        getActivity().runOnUiThread(() -> {
            SelectGoogleDriveDialog dialog = new SelectGoogleDriveDialog(mDriveServiceHelper);
            dialog.show(getChildFragmentManager(), "googleDrive");
            dialog.setClickListener(files -> {
                showGoogleDriveChooseFolderDialog(files);
            });
        });

    }

    private void showGoogleDriveChooseFolderDialog(List<SelectGoogleDriveDialog.TKFile> files) {
        showUploadDialog(MaterialsHelp.UploadType.GOOGLE_DRIVE, null, files, null, null);

//        List<MaterialEntity> data = new ArrayList<>();
//
//        data = viewModel.materialsDataListEntity.stream().filter(entity -> entity.getType() == -2 && entity.getMaterials().size() > 0 && entity.getCreatorId().equals(viewModel.creatorId)).collect(Collectors.toList());
//
//
//        chooseDialog = new ChooseFolderDialog.Builder(getContext()).create(data);
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
