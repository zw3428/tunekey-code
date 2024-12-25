package com.spelist.tunekey.ui.teacher.materials.item;

import android.view.View;

import androidx.annotation.NonNull;
import androidx.databinding.ObservableField;

import com.orhanobut.logger.Logger;
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
 * com.spelist.tunekey.ui.materials.fragments
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MaterialsFolderViewModel<VM extends BaseViewModel> extends MaterialsMultiItemViewModel<VM> {

    public MaterialsViewModel materialsViewModel;
    public ObservableField<FileImg> file1Data = new ObservableField<>(new FileImg());
    public ObservableField<FileImg> file2Data = new ObservableField<>(new FileImg());
    public ObservableField<FileImg> file3Data = new ObservableField<>(new FileImg());
    public ObservableField<FileImg> file4Data = new ObservableField<>(new FileImg());
    public ObservableField<Integer> fileImg = new ObservableField<Integer>(R.mipmap.folder_empty);

    public StudentDetailV2VM studentVM;
    public LessonDetailsVM lessonDetailsVM;
    public ObservableField<Boolean> isSelectFileInFolder = new ObservableField<>(true);
    public StudentMaterialsViewModel studentMaterialsViewModel;
    public StudioMaterialHomeVM studioMaterialVM;
    public StudioStudentDetailVM studioStudentDetailVM;

    public boolean sharePage = false;


    public MaterialsFolderViewModel(@NonNull VM viewModel, MaterialEntity data) {
        super(viewModel, data);
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
            isNotShowShare.set(true);
            isShowMoreButton.set(true);
            this.studentMaterialsViewModel = (StudentMaterialsViewModel) viewModel;
        }

//        for (int i = 0; i < data.getMaterials().size(); i++) {
//            if (i > 3) {
//                break;
//            }
//            String url = "";
//            int placeholder = 0;
//            MaterialEntity materialEntity = data.getMaterials().get(i);
//            switch (materialEntity.getType()) {
//                case -2:
//                    placeholder = R.mipmap.ic_materials;
//                    break;
//                case 0:
//                    placeholder = R.mipmap.img_other_file;
//                    break;
//                case 1:
//                    url = materialEntity.getUrl();
//                    placeholder = R.mipmap.img_jpg;
//                    break;
//
//
//                case 2:
//                    placeholder = R.mipmap.img_ppt;
//                    break;
//                case 3:
//                    placeholder = R.mipmap.img_doc;
//                    break;
//                case 4:
//                    placeholder = R.mipmap.img_mp3;
//                    break;
//                case 5:
//                    url = materialEntity.getMinPictureUrl();
//                    placeholder = R.mipmap.img_video;
//                    break;
//                case 6:
//                case 7:
//                    url = materialEntity.getMinPictureUrl();
//                    placeholder = R.mipmap.img_link;
//                    break;
//                case 8:
//                    placeholder = R.mipmap.img_txt;
//                    break;
//                case 9:
//                    placeholder = R.mipmap.img_pdf;
//                    break;
//                case 10:
//                    placeholder = R.mipmap.img_excel;
//                    break;
//                case 11:
//                    placeholder = R.mipmap.img_pages;
//                    break;
//                case 12:
//                    placeholder = R.mipmap.img_numbers;
//                    break;
//                case 13:
//                    placeholder = R.mipmap.img_keynotes;
//                    break;
//                case 14:
//                    placeholder = R.mipmap.img_docs;
//                    break;
//                case 15:
//                    placeholder = R.mipmap.img_sheets;
//                    break;
//                case 16:
//                    placeholder = R.mipmap.img_slides;
//                    break;
//                case 17:
//                    placeholder = R.mipmap.img_forms;
//                    break;
//                case 18:
//                    placeholder = R.mipmap.img_drawing;
//                    break;
//            }
//            if (i == 0) {
//                file1Data.set(new FileImg(url, placeholder));
//
//            } else if (i == 1) {
//                file2Data.set(new FileImg(url, placeholder));
//            } else if (i == 2) {
//                file3Data.set(new FileImg(url, placeholder));
//            } else {
//                file4Data.set(new FileImg(url, placeholder));
//            }
//
//        }


    }

    //条目的点击事件
    public BindingCommand<View> clickItem = new BindingCommand<>(view -> {
        if (materialsViewModel !=null) {
            materialsViewModel.clickItem(materialData.get(), view);
        }
        if (studioMaterialVM !=null) {
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
            studentMaterialsViewModel.clickItem(materialData.get(), view);
        }
    });
    public BindingCommand<View> selectItem = new BindingCommand<>(new BindingConsumer<View>() {
        @Override
        public void call(View view) {
            if (isSelectFileInFolder.get()) {
                if (materialsViewModel !=null) {
                    materialsViewModel.clickItem(materialData.get(), view);
                }
                if (studioMaterialVM !=null) {
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
                    studentMaterialsViewModel.clickItem(materialData.get(), view);
                }
                return;
            }
            isSelected.set(!isSelected.get());
            if (materialsViewModel !=null){
                materialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studioMaterialVM !=null){
                studioMaterialVM.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studentMaterialsViewModel!=null){
                studentMaterialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
        }
    });

    public BindingCommand<View> selectFolder = new BindingCommand<>(new BindingConsumer<View>() {
        @Override
        public void call(View view) {
            if (!isSelectFileInFolder.get()) {
                return;
            }
            isSelected.set(!isSelected.get());
            if (materialsViewModel !=null){
                materialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studioMaterialVM !=null){
                studioMaterialVM.updateSelectedMaterials(isSelected.get(), materialData.get());
            }
            if (studentMaterialsViewModel!=null){
                studentMaterialsViewModel.updateSelectedMaterials(isSelected.get(), materialData.get());

            }
        }
    });
    public void setHaveFile(boolean isHave){
        if (isHave){
            fileImg.set(R.mipmap.folder);
        }else {
            fileImg.set(R.mipmap.folder_empty);
        }
    }



    public static class FileImg {
        public String url = "";
        public int placeholder;

        public FileImg(String url, int placeholder) {
            this.url = url;
            this.placeholder = placeholder;
        }

        public FileImg() {
        }

        public String getUrl() {
            return url;
        }

        public FileImg setUrl(String url) {
            this.url = url;
            return this;
        }

        public int getPlaceholder() {
            return placeholder;
        }

        public FileImg setPlaceholder(int placeholder) {
            this.placeholder = placeholder;
            return this;
        }
    }
}
