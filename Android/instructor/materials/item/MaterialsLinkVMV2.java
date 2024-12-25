package com.spelist.tunekey.ui.teacher.materials.item;

import android.view.View;

import androidx.annotation.NonNull;

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
public class MaterialsLinkVMV2 <VM extends BaseViewModel> extends MaterialsMultiItemViewModel<VM> {
    public MaterialsViewModel materialsViewModel;
    public StudentDetailV2VM studentVM;
    public LessonDetailsVM lessonDetailsVM;
    public StudentMaterialsViewModel studentMaterialsViewModel;
    public StudioMaterialHomeVM studioMaterialVM;
    public StudioStudentDetailVM studioStudentDetailVM;
    public MaterialsLinkVMV2(@NonNull VM viewModel, MaterialEntity data) {
        super(viewModel, data);
        if (viewModel instanceof MaterialsViewModel){
            materialsViewModel = (MaterialsViewModel)viewModel;
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
            isNotShowShare.set(true);
            isShowMoreButton.set(false);
            this.studentMaterialsViewModel = (StudentMaterialsViewModel) viewModel;
        }
        if (viewModel instanceof  StudioMaterialHomeVM){
            studioMaterialVM = (StudioMaterialHomeVM)viewModel;
        }
    }
    //条目的点击事件
    public BindingCommand<View> clickItem = new BindingCommand<>(view -> {
//        ToastUtils.showShort("I'm youtube video");
//        Map<String, Object> map = new HashMap<>();
//        map.put("itemView", view);
//        map.put("url", materialData.get().getUrl());
//        map.put("type", materialData.get().getType());
//        map.put("name", materialData.get().getName());
//        materialsViewModel.uc.clickVideoItem.setValue(map);
        if (materialsViewModel!=null){
            materialsViewModel.clickItem(materialData.get(),view);
        }
        if (studioMaterialVM!=null){
            studioMaterialVM.clickItem(materialData.get(),view);
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
            studentMaterialsViewModel.clickItem(materialData.get(),view);
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