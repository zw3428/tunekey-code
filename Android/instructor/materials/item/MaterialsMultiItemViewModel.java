package com.spelist.tunekey.ui.teacher.materials.item;

import android.graphics.drawable.Drawable;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableField;
import androidx.lifecycle.MutableLiveData;

import com.orhanobut.logger.Logger;
import com.spelist.tunekey.R;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel;
import com.spelist.tunekey.ui.studio.material.materialHome.StudioMaterialHomeVM;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.utils.TimeUtils;

import java.util.ArrayList;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.base.ItemViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;

/**
 * com.spelist.tunekey.ui.materials.item
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
public class MaterialsMultiItemViewModel<VM extends BaseViewModel> extends ItemViewModel<VM> {

    private Class<VM> clazz;

    public ObservableField<MaterialEntity> materialData = new ObservableField<MaterialEntity>(new MaterialEntity());

    public ObservableField<Boolean> isShowPlayButton = new ObservableField<>(false);

    public ObservableField<String> timeString = new ObservableField<>("");

    public ObservableField<List<StudentListEntity>> sharedStudentData = new ObservableField<>(new ArrayList<>());
    public List<StudentListEntity> sharedStudent =new ArrayList<>();

    public ObservableField<StudentListEntity> sharedStudent1 = new ObservableField<>(new StudentListEntity());
    public ObservableField<StudentListEntity> sharedStudent2 = new ObservableField<>(new StudentListEntity());
    public ObservableField<StudentListEntity> sharedStudent3 = new ObservableField<>(new StudentListEntity());
    public ObservableField<Boolean> isSelected = new ObservableField<>(false);
    public ObservableField<Boolean> isDontAllSelected = new ObservableField<>(false);

    //是否正在拖拽中 ,拖拽中的不显示title 等
    public ObservableField<Boolean> isDragging = new ObservableField<>(false);
    public ObservableField<Boolean> isNotShowShare = new ObservableField<>(false);

    //是否显示拖拽选中绿框
    public ObservableField<Boolean> dragIsVisible = new ObservableField<>(false);
    //显示add,stop,透明
    public ObservableField<Drawable> typeDrawable = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.mipmap.transparent));

    //是否显示不是自己创建的边框
    public ObservableField<Boolean> isNotSelfFrame = new ObservableField<>(false);
    public MutableLiveData<Drawable> studentFrame = new MutableLiveData<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.student_material_frame_main));
    public ObservableField<Boolean> isShowMoreButton = new ObservableField<>(true);


    public void setStudentData(List<StudentListEntity> sharedStudentData) {
        this.sharedStudentData.set(sharedStudentData);
        sharedStudent = sharedStudentData;
        for (int i = 0; i < sharedStudentData.size(); i++) {
            if (i == 0) {
                sharedStudent1.set(sharedStudentData.get(i));
            } else if (i == 1) {
                sharedStudent2.set(sharedStudentData.get(i));
            } else if (i == 2) {
                sharedStudent3.set(sharedStudentData.get(i));
            }
        }
    }


    /**
     * 设置不是自己显示边框
     */
    public void setNoSelfShowFrame(String userId){
        if (viewModel instanceof StudentMaterialsViewModel){
            StudentMaterialsViewModel viewModel = (StudentMaterialsViewModel) this.viewModel;
            Drawable studioColor = viewModel.studioColor;
            studentFrame.setValue(studioColor);
        }
        isNotSelfFrame.set(!getData().getCreatorId().equals(userId));

    }

    public MaterialsMultiItemViewModel(@NonNull VM viewModel, MaterialEntity data) {
        super(viewModel);
        this.materialData.set(data);
        timeString.set(TimeUtils.getStrOfTimeTillNow(data.getCreateTime()));
        switch (data.getType()) {
            case -2:
            case -1:
            case 0:
            case 1:
            case 2:
            case 3:
            case 18:
            case 17:
            case 16:
            case 15:
            case 14:
            case 13:
            case 12:
            case 11:
            case 10:
            case 9:
            case 8:
            case 7:
                isShowPlayButton.set(false);
                break;
            case 4:
            case 6:
            case 5:
                isShowPlayButton.set(true);

                break;
        }
    }

    public MaterialEntity getData() {
        return materialData.get();
    }

    public BindingCommand clickShare = new BindingCommand(() -> {
        if (viewModel instanceof MaterialsViewModel) {
            MaterialsViewModel mVM = (MaterialsViewModel) viewModel;
            mVM.clickItemShare(materialData.get());
        }
        if (viewModel instanceof StudioMaterialHomeVM) {
            StudioMaterialHomeVM mVM = (StudioMaterialHomeVM) viewModel;
            mVM.clickItemShare(materialData.get());
        }
    });
    public BindingCommand clickTitle = new BindingCommand(() -> {
        if (viewModel instanceof MaterialsViewModel) {
            MaterialsViewModel mVM = (MaterialsViewModel) viewModel;
            mVM.clickItemTitle(materialData.get());
        } else if (viewModel instanceof StudentMaterialsViewModel) {
            StudentMaterialsViewModel mVM = (StudentMaterialsViewModel) viewModel;
            mVM.clickItemTitle(materialData.get());
        } else if (viewModel instanceof StudioMaterialHomeVM) {
            StudioMaterialHomeVM mVM = (StudioMaterialHomeVM) viewModel;
            mVM.clickItemTitle(materialData.get());
        }
    });

    public BindingCommand clickMore = new BindingCommand(() -> {
        if (viewModel instanceof MaterialsViewModel) {
            MaterialsViewModel mVM = (MaterialsViewModel) viewModel;
            mVM.clickMore(materialData.get());
        }
        if (viewModel instanceof StudioMaterialHomeVM) {
            StudioMaterialHomeVM mVM = (StudioMaterialHomeVM) viewModel;
            mVM.clickMore(materialData.get());
        }
        if (viewModel instanceof StudentMaterialsViewModel) {
            StudentMaterialsViewModel mVM = (StudentMaterialsViewModel) viewModel;
            mVM.clickMore(materialData.get());
        }
    });

}
