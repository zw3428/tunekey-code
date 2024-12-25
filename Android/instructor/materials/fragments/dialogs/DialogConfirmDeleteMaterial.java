package com.spelist.tunekey.ui.teacher.materials.fragments.dialogs;

import android.annotation.SuppressLint;
import android.content.Context;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.lxj.xpopup.animator.PopupAnimator;
import com.lxj.xpopup.core.CenterPopupView;
import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.studio.material.materialHome.StudioMaterialFolderFragment;
import com.spelist.tunekey.ui.studio.material.materialHome.StudioMaterialHomeVM;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsFolderFragment;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.student.sMaterials.fragment.StudentMaterialsFolderFragment;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;

import java.util.ArrayList;
import java.util.List;

/**
 * @author zw, Created on 2020-01-15
 */
@SuppressLint("ViewConstructor")
public class DialogConfirmDeleteMaterial extends CenterPopupView {

    private MaterialsViewModel materialsViewModel;
    private StudentMaterialsViewModel studentMaterialsViewModel;
    private StudioMaterialHomeVM studioMaterialHomeVM;

    private Context context;
    private TextView title;
    private TextView prompt;
    private TextView leftBtn;
    private TextView rightBtn;
    private List<MaterialEntity> selectData;
    private boolean isFolder = false;
    private MaterialsFolderFragment folderFragment;
    private StudentMaterialsFolderFragment studentFolderFragment;
    private StudioMaterialFolderFragment studioMaterialFolderFragment;
    public DialogConfirmDeleteMaterial(@NonNull Context context, MaterialsViewModel viewModel
            , List<MaterialEntity> selectData, boolean isFolder, MaterialsFolderFragment folderFragment) {
        super(context);
        this.context = context;
        this.materialsViewModel = viewModel;
        this.selectData = selectData;
        this.isFolder = isFolder;
        this.folderFragment = folderFragment;
//        if (isFolder){
//            this.selectData.addAll(folderFragment.getSelectData()) ;
//            Logger.e("======%s", this.selectData.size());
//        }
    }

    public DialogConfirmDeleteMaterial(@NonNull Context context, StudentMaterialsViewModel studentMaterialsViewModel
            , List<MaterialEntity> selectData, boolean isFolder, StudentMaterialsFolderFragment folderFragment) {
        super(context);
        this.context = context;
        this.studentMaterialsViewModel = studentMaterialsViewModel;
        this.selectData = selectData;
        this.isFolder = isFolder;
//        this.folderFragment = folderFragment;
        this.studentFolderFragment = folderFragment;
//        if (isFolder){
//            this.selectData.addAll(folderFragment.getSelectData()) ;
//            Logger.e("======%s", this.selectData.size());
//        }
    }
    public DialogConfirmDeleteMaterial(@NonNull Context context, StudioMaterialHomeVM studentMaterialsViewModel
            , List<MaterialEntity> selectData, boolean isFolder, StudioMaterialFolderFragment folderFragment) {
        super(context);
        this.context = context;
        this.studioMaterialHomeVM = studentMaterialsViewModel;
        this.selectData = selectData;
        this.isFolder = isFolder;
//        this.folderFragment = folderFragment;
        this.studioMaterialFolderFragment = folderFragment;
        if (isFolder){
            this.selectData.addAll(folderFragment.getSelectData()) ;
            Logger.e("======%s", this.selectData.size());
        }
    }


    // 返回自定义弹窗的布局
    @Override
    protected int getImplLayoutId() {
        return R.layout.dialog_cancel_and_confirm;
    }

    // 执行初始化操作，比如：findView，设置点击，或者任何你弹窗内的业务逻辑
    @SuppressLint({"ResourceAsColor", "NewApi"})
    @Override
    protected void onCreate() {
        super.onCreate();
        title = findViewById(R.id.dialog_title);
        prompt = findViewById(R.id.dialog_prompt);
        leftBtn = findViewById(R.id.dialog_left_btn);
        rightBtn = findViewById(R.id.dialog_right_btn);

        title.setText("Are you sure to delete this material?");
        prompt.setVisibility(GONE);
        leftBtn.setText("DELETE");
        leftBtn.setTextColor(ContextCompat.getColor(getContext(), R.color.red));
        rightBtn.setText("GO BACK");
        rightBtn.setTextColor(ContextCompat.getColor(getContext(), R.color.main));

        rightBtn.setOnClickListener(v -> {
            dismiss(); // 关闭弹窗
        });

        leftBtn.setOnClickListener(v -> {
            List<String> ids = new ArrayList<>();
            Logger.e("======%s", selectData.size());
            for (MaterialEntity selectedMaterial : selectData) {
                ids.add(selectedMaterial.getId());
                if (selectedMaterial.getType() == -2) {
                    for (MaterialEntity material : selectedMaterial.getMaterials()) {
                        ids.add(material.getId());
                    }
                }
            }
            if (isFolder) {
                if (materialsViewModel!=null){
//                    materialsViewModel.deleteInFolderMaterials(folderFragment.getData(), ids);
                    materialsViewModel.deleteMaterials(ids);

                }
                if (studentMaterialsViewModel!=null){
//                    studentMaterialsViewModel.deleteInFolderMaterials(studentFolderFragment.getData(), ids);
                    studentMaterialsViewModel.deleteMaterials(ids);

                }
                if (studioMaterialHomeVM!=null){
//                    studioMaterialHomeVM.deleteInFolderMaterials(studioMaterialFolderFragment.getData(), ids);
                    studioMaterialHomeVM.deleteMaterials(ids);

                }
            } else {
                if (materialsViewModel!=null) {
                    materialsViewModel.deleteMaterials(ids);
                }
                if (studentMaterialsViewModel!=null){
                    studentMaterialsViewModel.deleteMaterials( ids);
                }
                if (studioMaterialHomeVM!=null){
                    studioMaterialHomeVM.deleteMaterials( ids);
                }
            }
            dismiss();
        });
    }

    // 设置最大宽度，看需要而定
    @Override
    protected int getMaxWidth() {
        return super.getMaxWidth();
    }

    // 设置最大高度，看需要而定
    @Override
    protected int getMaxHeight() {
        return super.getMaxHeight();
    }

    // 设置自定义动画器，看需要而定
    @Override
    protected PopupAnimator getPopupAnimator() {
        return super.getPopupAnimator();
    }

    /**
     * 弹窗的宽度，用来动态设定当前弹窗的宽度，受getMaxWidth()限制
     *
     * @return
     */
    protected int getPopupWidth() {
        return 0;
    }

    /**
     * 弹窗的高度，用来动态设定当前弹窗的高度，受getMaxHeight()限制
     *
     * @return
     */
    protected int getPopupHeight() {
        return 0;
    }
}
