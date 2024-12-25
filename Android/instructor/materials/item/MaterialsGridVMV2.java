package com.spelist.tunekey.ui.teacher.materials.item;

import android.annotation.SuppressLint;
import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;

import com.spelist.tunekey.R;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;
import com.spelist.tunekey.ui.studio.material.materialHome.StudioMaterialHomeVM;
import com.spelist.tunekey.ui.studio.team.teamHome.student.detail.StudioStudentDetailVM;
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonDetailsVM;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailV2VM;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.binding.command.BindingConsumer;

/**
 * com.spelist.tunekey.ui.materials.item
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MaterialsGridVMV2 <VM extends BaseViewModel> extends MaterialsMultiItemViewModel<VM> {
    private int mType;


    /**
     * material type img
     */
    public ObservableField<Drawable> typeImg = new ObservableField<>(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.ic_launcher));
    /**
     * 分类图片是否显示, default: 8
     */
    public ObservableField<Boolean> typeImgVisibility = new ObservableField<>(false);
    /**
     * 视频背景图片是否显示, default: 8
     */
    public ObservableField<Boolean> picBgVisibility = new ObservableField<>(false);
    public ObservableField<String> showImgUrl = new ObservableField<>("");
    public ObservableField<Integer> showScaleType = new ObservableField<>(6);
    public LessonDetailsVM lessonDetailsVM;
    public StudentMaterialsViewModel studentMaterialsViewModel;
    public StudioStudentDetailVM studioStudentDetailVM;
    public MaterialsViewModel materialsViewModel;
    public StudentDetailV2VM studentVM;
    public StudioMaterialHomeVM studioMaterialVM;



    public MaterialsGridVMV2(@NonNull VM viewModel, MaterialEntity data) {
        super(viewModel, data);
        mType = data.getType();
        if (viewModel instanceof MaterialsViewModel){
            this.materialsViewModel = (MaterialsViewModel)viewModel;
        }
        if (viewModel instanceof StudioMaterialHomeVM){
            this.studioMaterialVM = (StudioMaterialHomeVM)viewModel;
        }
        if (viewModel instanceof StudentDetailV2VM){
            this.studentVM = (StudentDetailV2VM)viewModel;
        }
        if (viewModel instanceof StudioStudentDetailVM){
            this.studioStudentDetailVM = (StudioStudentDetailVM)viewModel;
        }
        if (viewModel instanceof LessonDetailsVM){
            this.lessonDetailsVM = (LessonDetailsVM)viewModel;
        }
        if (viewModel instanceof StudentMaterialsViewModel){
            this.studentMaterialsViewModel = (StudentMaterialsViewModel) viewModel;
        }
        showScaleType.set(6);
        switch (mType) {
            case -2:
                setGridMaterialItemDisplay(false, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.ic_materials));
                break;
            case 0:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_other_file));
                break;
            case 1:
                setGridMaterialItemDisplay(true, true);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_jpg));
                showImgUrl.set(data.getUrl());
                break;
            case 5:
                setGridMaterialItemDisplay(true, true);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_video));
                showImgUrl.set(data.getMinPictureUrl());
                break;
            case 2:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_ppt));
                break;
            case 3:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_doc));
                break;
            case 4:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_mp3));
                break;
//            case 6:
//                setGridMaterialItemDisplay(true, true);
//                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_link));
//                showImgUrl.set(data.getMinPictureUrl());
//                break;
            case 7:
                showScaleType.set(3);
                if (data.getMinPictureUrl() .equals("")){
                    setGridMaterialItemDisplay(true, false);
                }else {
                    setGridMaterialItemDisplay(true, true);
                }
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_link));
                showImgUrl.set(data.getMinPictureUrl());

                break;
            case 8:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_txt));
                break;
            case 9:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_pdf));
                break;
            case 10:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_excel));
                break;
            case 11:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_pages));
                break;
            case 12:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_numbers));
                break;
            case 13:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_keynotes));
                break;
            case 14:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_docs));
                break;
            case 15:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_sheets));
                break;
            case 16:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_slides));
                break;
            case 17:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_forms));
                break;
            case 18:
                setGridMaterialItemDisplay(true, false);
                this.typeImg.set(ContextCompat.getDrawable(viewModel.getApplication(), R.mipmap.img_drawing));
                break;

        }
    }

    /**
     * 设置 material item 显示
     *
     * @param typeImg
     * @param picBg
     */
    private void setGridMaterialItemDisplay(boolean typeImg, boolean picBg) {
        this.typeImgVisibility.set(typeImg);
        this.picBgVisibility.set(picBg);
    }

    // 条目的点击事件
    public BindingCommand<View> clickItem = new BindingCommand<View>(new BindingConsumer<View>() {
        @SuppressLint("CheckResult")
        @Override
        public void call(View view) {
            if (mType == 1) {
                view = view.findViewById(R.id.material_item_bg);
            }
            if (materialsViewModel!=null){
                materialsViewModel.clickItem(materialData.get(), view);
            }
            if (studioMaterialVM!=null){
                studioMaterialVM.clickItem(materialData.get(), view);
            }
            if (studentVM !=null){
                studentVM.clickItem(materialData.get(), view);
            }
            if (studioStudentDetailVM !=null){
                studioStudentDetailVM.clickItem(materialData.get(), view);
            }
            if (lessonDetailsVM !=null){
                lessonDetailsVM.clickMaterialsItem(materialData.get(), view);
            }
            if (studentMaterialsViewModel!=null){
                isNotShowShare.set(true);
                isShowMoreButton.set(false);
                studentMaterialsViewModel.clickItem(materialData.get(), view);
            }
        }
    });
    public BindingCommand<View> selectItem = new BindingCommand<>(new BindingConsumer<View>() {
        @Override
        public void call(View view) {
            isSelected.set(!isSelected.get());
            if (materialsViewModel!=null){
                materialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studioMaterialVM!=null){
                studioMaterialVM.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studentMaterialsViewModel!=null){
                studentMaterialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
        }
    });

}