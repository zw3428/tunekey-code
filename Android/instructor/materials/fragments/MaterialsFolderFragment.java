package com.spelist.tunekey.ui.teacher.materials.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.GridLayoutManager;

import com.lxj.xpopup.XPopup;
import com.lxj.xpopup.enums.PopupAnimation;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.dialog.MaterialChangeNameDialog;
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment;
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem;
import com.spelist.tunekey.databinding.FragmentMaterialsFolderBinding;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.material.MaterialDetailsDialog;
import com.spelist.tunekey.ui.teacher.materials.MaterialsHelp;
import com.spelist.tunekey.ui.teacher.materials.activity.MaterialsActivity;
import com.spelist.tunekey.ui.student.sMaterials.fragment.StudentMaterialsFragment;
import com.spelist.tunekey.ui.teacher.materials.fragments.dialogs.DialogConfirmDeleteMaterial;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import me.goldze.mvvmhabit.base.BaseFragment;

/**
 * com.spelist.tunekey.ui.materials.fragments
 * 2020/12/28
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MaterialsFolderFragment extends BaseFragment<FragmentMaterialsFolderBinding, MaterialsViewModel> {
    private List<MaterialEntity> data;
    private MaterialEntity folderData;
    private MaterialEntity selectFolderData;
    private MaterialsFragment materialsFragment;
    public MaterialsViewModel.ShowType showType = MaterialsViewModel.ShowType.normal;
    private MaterialsActivity materialsActivity;
    private List<MaterialEntity> selectedMaterials;
    private StudentMaterialsFragment studentMaterialsFragment;
    private MaterialsFolderFragment folderFragment;
    private boolean isSearchStudent = false;

    @Override
    public int initContentView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return R.layout.fragment_materials_folder;
    }

    @Override
    public int initVariableId() {
        return com.spelist.tunekey.BR.viewModel;
    }

    public void setData(List<MaterialEntity> data, MaterialEntity folderData, MaterialsFragment materialsFragment) {
        this.data = data;
        this.folderData = folderData;
        this.materialsFragment = materialsFragment;
        materialsFragment.viewModel.showMaterial = folderData;
        if (viewModel != null) {
            viewModel.folderEntity = folderData;
            Logger.e("viewModel.folderEntity==>%s", viewModel.folderEntity.getId());

            viewModel.setFolderData(data);
        }
    }
    public boolean getSearchIsStudent(){
        if (studentMaterialsFragment != null) {
            return studentMaterialsFragment.searchStudent;
        }else if (materialsFragment != null) {
            return materialsFragment.searchStudent;
        }else if (materialsActivity != null) {
            return materialsActivity.searchStudent;
        }
        return isSearchStudent;
    }

    public void setData(List<MaterialEntity> data, MaterialEntity folderData, StudentMaterialsFragment studentMaterialsFragment) {
        this.data = data;
        this.folderData = folderData;
        this.studentMaterialsFragment = studentMaterialsFragment;

        if (viewModel != null) {
            viewModel.folderEntity = folderData;
            viewModel.setFolderData(data);
        }
    }

    public void setData(List<MaterialEntity> data, MaterialEntity folderData,
                        MaterialsViewModel.ShowType showType, MaterialsActivity materialsActivity,
                        List<MaterialEntity> selectedMaterials) {
        this.data = data;
        this.folderData = folderData;
        this.showType = showType;
        this.materialsActivity = materialsActivity;
        this.selectedMaterials = selectedMaterials;
        materialsActivity.viewModel.showMaterial = folderData;

        if (viewModel != null) {
            if (viewModel.showType == MaterialsViewModel.ShowType.select) {
                viewModel.editStatus.set(true);
                viewModel.selectedMaterials = selectedMaterials;
            }
            viewModel.showType = showType;
            viewModel.folderEntity = folderData;
            viewModel.setFolderData(data);
        }
    }

    public MaterialEntity getData() {
        return folderData;
    }

    public List<MaterialEntity> getSelectData() {
        return viewModel.selectedMaterials;
    }

    @Override
    public void initData() {
        super.initData();
        viewModel.showType = showType;
        if (viewModel.showType == MaterialsViewModel.ShowType.select) {
            viewModel.editStatus.set(true);
            viewModel.selectedMaterials = selectedMaterials;
        }
        viewModel.isFolderViewModel = true;
        viewModel.folderEntity = folderData;
        viewModel.setFolderData(data);

    }

    public void search(String s) {
        if (viewModel != null) {
            viewModel.search(s, getSearchIsStudent());
        }
    }

    public void setIsEdit(boolean isEdit) {
        if (viewModel != null) {
            if (isEdit) {
                viewModel.editStatus.set(true);
                viewModel.cleanSelect();
            } else {
                viewModel.editStatus.set(false);
                viewModel.selectedMaterials.clear();
            }
        }
    }

    @Override
    public void initView() {
        super.initView();
        viewModel.gridLayoutManager.set(new GridLayoutManager(getContext(), 3));
        binding.recyclerView.setItemAnimator(null);
    }

    @Override
    public void initViewObservable() {
        super.initViewObservable();
        viewModel.uc.searchMaterials.observe(this, s -> {
            try {
                if (materialsFragment != null && materialsFragment.viewModel.showMaterial.getId().equals(folderData.getId())) {
                    search(s);
                }
                if (materialsActivity != null && materialsActivity.viewModel.showMaterial.getId().equals(folderData.getId())) {
                    search(s);
                }
            } catch (Throwable e) {

            }

        });
        viewModel.uc.editeFolder.observe(this, isEdit -> {
            try {
                if (materialsFragment != null && materialsFragment.viewModel.showMaterial.getId().equals(folderData.getId())) {
                    setIsEdit(isEdit);
                }
                if (materialsActivity != null && materialsActivity.viewModel.showMaterial.getId().equals(folderData.getId())) {
                    setIsEdit(isEdit);
                }
            } catch (Throwable e) {

            }

        });
        viewModel.uc.closeFolderView.observe(this, integer -> {
            if (folderFragment != null && selectFolderData != null && materialsFragment != null && materialsFragment.viewModel.showMaterial.getId().equals(selectFolderData.getId())) {
                FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
                transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                transaction.setCustomAnimations(
                        R.anim.zoom_in,
                        R.anim.zoom_out);
                transaction.remove(folderFragment);
                transaction.commit();
                folderFragment = null;
                materialsFragment.viewModel.showMaterial = folderData;
                materialsFragment.viewModel.catalogueMaterialsData.remove(materialsFragment.viewModel.catalogueMaterialsData.size() - 1);
                materialsFragment.baseTitleViewModel.title.set(folderData.getName());
                materialsFragment.setCatalogueName();
            }
            if (folderFragment != null && selectFolderData != null && materialsActivity != null && materialsActivity.viewModel.showMaterial.getId().equals(selectFolderData.getId())) {
                FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
                transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                transaction.setCustomAnimations(
                        R.anim.zoom_in,
                        R.anim.zoom_out);
                transaction.remove(folderFragment);
                transaction.commit();
                folderFragment = null;
                materialsActivity.viewModel.showMaterial = folderData;
                materialsActivity.viewModel.catalogueMaterialsData.remove(materialsActivity.viewModel.catalogueMaterialsData.size() - 1);
                materialsActivity.baseTitleViewModel.title.set(folderData.getName());
                materialsActivity.setCatalogueName();
            }
        });
        viewModel.uc.catalogueCloseFolderView.observe(this, data -> {
            if (folderFragment != null) {
                //要去的文件夹的pos
                int showPos = -1;
                //当前文件夹的Pos
                int currentPos = -1;
                if (materialsFragment != null) {
                    for (int i = 0; i < materialsFragment.viewModel.catalogueMaterialsData.size(); i++) {
                        if (materialsFragment.viewModel.catalogueMaterialsData.get(i).getId().equals(data.getId())) {
                            showPos = i;
                        }
                        if (materialsFragment.viewModel.catalogueMaterialsData.get(i).getId().equals(folderData.getId())) {
                            currentPos = i;
                        }
                    }
                }
                if (materialsActivity != null) {
                    for (int i = 0; i < materialsActivity.viewModel.catalogueMaterialsData.size(); i++) {
                        if (materialsActivity.viewModel.catalogueMaterialsData.get(i).getId().equals(data.getId())) {
                            showPos = i;
                        }
                        if (materialsActivity.viewModel.catalogueMaterialsData.get(i).getId().equals(folderData.getId())) {
                            currentPos = i;
                        }
                    }
                }

                if (currentPos < showPos) {
                    return;
                }

                FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
                transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                transaction.setCustomAnimations(
                        R.anim.zoom_in,
                        R.anim.zoom_out);
                transaction.remove(folderFragment);
                transaction.commit();
                folderFragment = null;

            }
        });

        viewModel.uc.clickItem.observe(this, map -> {
            MaterialEntity entity = (MaterialEntity) map.get("data");
            View view = (View) map.get("view");
            if (entity.getType() == -2) {
                if (materialsFragment != null) {
                    FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
                    transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
                    transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                    transaction.setCustomAnimations(R.anim.zoom_in, R.anim.zoom_out);
                    List<MaterialEntity> folderData = materialsFragment.viewModel.allMaterialsData.stream().filter(materialEntity -> materialEntity.getFolder().equals(entity.getId())).collect(Collectors.toList());
                    folderFragment = new MaterialsFolderFragment();
                    Logger.e("?????==>%s", entity.getId());
                    folderFragment.setData(folderData, entity, materialsFragment);
                    transaction.add(R.id.folder_view, folderFragment);
                    transaction.addToBackStack(null);
                    transaction.commit();
                    selectFolderData = entity;
                    materialsFragment.viewModel.catalogueMaterialsData.add(entity);
                    materialsFragment.baseTitleViewModel.title.set(entity.getName());
                    materialsFragment.setCatalogueName();
                }
                if (materialsActivity != null) {
                    FragmentTransaction transaction = getChildFragmentManager().beginTransaction();
                    transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
                    transaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_CLOSE);
                    transaction.setCustomAnimations(R.anim.zoom_in, R.anim.zoom_out);
                    List<MaterialEntity> folderData = materialsActivity.viewModel.allMaterialsData.stream().filter(materialEntity -> materialEntity.getFolder().equals(entity.getId())).collect(Collectors.toList());
                    folderFragment = new MaterialsFolderFragment();
                    folderFragment.setData(folderData, entity, showType, materialsActivity, selectedMaterials);
                    transaction.add(R.id.folder_view, folderFragment);
                    transaction.addToBackStack(null);
                    transaction.commit();
                    selectFolderData = entity;
                    materialsActivity.viewModel.catalogueMaterialsData.add(entity);
                    materialsActivity.baseTitleViewModel.title.set(entity.getName());
                    materialsActivity.setCatalogueName();
                }

            } else {
                MaterialsHelp.clickMaterial(map, getActivity(), this);
            }
        });
        viewModel.uc.materialsObserverData.observe(this, multiItemViewModels ->
                Objects.requireNonNull(viewModel.gridLayoutManager.get()).setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                    @Override
                    public int getSpanSize(int position) {
                        if (multiItemViewModels.get(position).getData().getId().equals("")) {
                            return 3;
                        } else if (viewModel.isListView) {
                            return 3;
                        } else {
                            if ((int) multiItemViewModels.get(position).getData().getType() == 6) {
                                return 3;
                            } else {
                                return 1;
                            }
                        }
                    }
                }));
        viewModel.bottomButtonIsEnable.observe(this, isShow -> {
            if (materialsFragment != null) {
                materialsFragment.setBottomButtonIsEnabled(isShow);
            }
            if (studentMaterialsFragment != null) {
                studentMaterialsFragment.setBottomButtonIsEnabled(isShow);
            }
        });
        viewModel.uc.clickMore.observe(this, data -> {
            BottomMenuFragment bottomMenuFragment = new BottomMenuFragment(getActivity());
            bottomMenuFragment.addMenuItems(new MenuItem("Details"));
            bottomMenuFragment.addMenuItems(new MenuItem("Share In-App"));
//            bottomMenuFragment.addMenuItems(new MenuItem("Share Out-App"));
            bottomMenuFragment.addMenuItems(new MenuItem("Delete", ContextCompat.getColor(getContext(), R.color.red)));
            bottomMenuFragment.show();
            bottomMenuFragment.setOnItemClickListener((menu_item, position) -> {
                CharSequence text = menu_item.getText();
                if (text.equals("Details")) {
                    MaterialDetailsDialog dialog = new MaterialDetailsDialog(getContext(), materialsFragment.viewModel.path, data);
                    dialog.showDialog();
                } else if (text.equals("Share In-App")) {
                    viewModel.clickItemShare(data);

                } else if (text.equals("Share Out-App")) {

                } else if (text.equals("Delete")) {
                    materialsFragment.viewModel.uc.clickDelete.setValue(data);
                }
            });

        });

        viewModel.uc.changeName.observe(this, data -> {
            String id = data.get("id");
            String defaultName = data.get("defaultName");
            MaterialChangeNameDialog.Builder dialog = new MaterialChangeNameDialog.Builder(getContext()).create(defaultName);
            dialog.clickConfirm(tkButton -> {
                dialog.dismiss();
                viewModel.updateMaterialName(id, dialog.getName());
            });
        });
        viewModel.uc.selectData.observe(this, data -> {
            if (materialsActivity != null) {
                boolean isSelect = (boolean) data.get("isSelect");
                MaterialEntity selectData = (MaterialEntity) data.get("data");
                materialsActivity.folderSelectMaterials(isSelect, selectData);
            }
        });


    }
}

