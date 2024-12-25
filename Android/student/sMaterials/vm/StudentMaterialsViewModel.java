package com.spelist.tunekey.ui.student.sMaterials.vm;

import static com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel.groupAndInsertHeaders;

import android.app.Application;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.databinding.ObservableArrayList;
import androidx.databinding.ObservableField;
import androidx.databinding.ObservableList;
import androidx.lifecycle.MutableLiveData;
import androidx.recyclerview.widget.GridLayoutManager;

import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;
import com.orhanobut.logger.Logger;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tools.tools.SLStringUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.api.CloudFunctions;
import com.spelist.tunekey.api.ListenerService;
import com.spelist.tunekey.api.network.MaterialService;
import com.spelist.tunekey.api.StorageUtils;
import com.spelist.tunekey.api.network.UserService;
import com.spelist.tunekey.app.TApplication;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.customView.TKSelectView;
import com.spelist.tunekey.customView.chooseFolder.MoveFolderDialog;
import com.spelist.tunekey.customView.dialog.googleDrive.SelectGoogleDriveDialog;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.entity.MaterialHashEntity;
import com.spelist.tunekey.entity.StudentListEntity;
import com.spelist.tunekey.ui.material.MaterialsFilterData;
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsFolderViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsGridVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsLinkVMV2;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsListViewModel;
import com.spelist.tunekey.ui.teacher.materials.item.MaterialsMultiItemViewModel;
import com.spelist.tunekey.ui.teacher.students.activity.AddressBookActivity;
import com.spelist.tunekey.utils.CloneObjectUtils;
import com.spelist.tunekey.utils.HashUtils;
import com.spelist.tunekey.utils.IDUtils;
import com.spelist.tunekey.utils.MessengerUtils;
import com.spelist.tunekey.utils.SLCacheUtil;
import com.spelist.tunekey.utils.TimeUtils;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.Serializable;
import java.text.Collator;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;
import me.goldze.mvvmhabit.base.BaseViewModel;
import me.goldze.mvvmhabit.binding.command.BindingCommand;
import me.goldze.mvvmhabit.bus.Messenger;
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent;
import me.tatarka.bindingcollectionadapter2.ItemBinding;


public class StudentMaterialsViewModel extends BaseViewModel {
    public MaterialsFilterData filterData;
    public boolean isListView = false;
    public ObservableField<Boolean> isShowSearchCancel = new ObservableField<Boolean>(false);


    public static final int MULTI_MATERIAL_TYPE_FILE = 0;
    public static final int MULTI_MATERIAL_TYPE_IMG = 1;
    public static final int MULTI_MATERIAL_TYPE_PPT = 2;
    public static final int MULTI_MATERIAL_TYPE_WORD = 3;
    public static final int MULTI_MATERIAL_TYPE_MP3 = 4;
    public static final int MULTI_MATERIAL_TYPE_VIDEO = 5;
    public static final int MULTI_MATERIAL_TYPE_YOUTUBE = 6;
    public static final int MULTI_MATERIAL_TYPE_LINK = 7;
    public static final int MULTI_MATERIAL_TYPE_TXT = 8;
    public static final int MULTI_MATERIAL_TYPE_PDF = 9;
    public static final int MULTI_MATERIAL_TYPE_EXCEL = 10;
    public static final int MULTI_MATERIAL_TYPE_PAGES = 11;
    public static final int MULTI_MATERIAL_TYPE_NUMBERS = 12;
    public static final int MULTI_MATERIAL_TYPE_KEYNOTE = 13;
    public static final int MULTI_MATERIAL_TYPE_GOOGLE_DOC = 14;
    public static final int MULTI_MATERIAL_TYPE_GOOGLE_SHEET = 15;
    public static final int MULTI_MATERIAL_TYPE_GOOGLE_SLIDES = 16;
    public static final int MULTI_MATERIAL_TYPE_GOOGLE_FORMS = 17;
    public static final int MULTI_MATERIAL_TYPE_GOOGLE_DRAWINGS = 18;

    public static final int MULTI_MATERIAL_TYPE_NONE = -1;
    public static final int MULTI_MATERIAL_TYPE_FOLDER = -2;
    //new
    public List<MaterialEntity> allMaterialsData = new ArrayList<>();
    public List<MaterialEntity> catalogueMaterialsData = new ArrayList<>();
    public List<MaterialEntity> teacherMaterialsData = new ArrayList<>();
    //现在显示的materials 如果home页面 为空 文件夹里面则是文件夹
    public MaterialEntity showMaterial;

    public String searchString = "";


    public enum ShowType {
        normal, show, select
    }


    // 0 -> teacher, 1 -> student, 2 -> show
    public MutableLiveData<Integer> roleType = new MutableLiveData<>();
    public MutableLiveData<Integer> emptyLayoutVisibility = new MutableLiveData<>();
    public MutableLiveData<Integer> mainLayoutVisibility = new MutableLiveData<>();
    public MutableLiveData<Integer> promptToBeProLayoutVisibility = new MutableLiveData<>();
    public ObservableField<GridLayoutManager> gridLayoutManager = new ObservableField<>();
    public MutableLiveData<Boolean> bottomButtonIsEnable = new MutableLiveData<>(false);

    //data connection
    public List<MaterialEntity> studentMaterials = new ArrayList<>();
    public String localPath;
    public String storagePathOnline;
    public String downloadUrl = "";
    public String minPictureUrl = "";

    public String creatorId = "";
    public String localFileSuffixName = "";
    public Boolean currentUserIsPro = false;
    public List<MaterialEntity> selectedMaterials = new ArrayList<>();
    public ObservableField<Boolean> editStatus = new ObservableField<>(false);
    public MaterialEntity folderEntity = new MaterialEntity();
    public ObservableField<Boolean> isHaveData = new ObservableField<>();

    public boolean isFolderViewModel = false;

    public boolean isInFolder = false;
    public MaterialEntity inFolderData = new MaterialEntity();
    public int photoDefaultNameCount = 1;
    public int videoDefaultNameCount = 1;
    public int folderDefaultNameCount = 1;
    public int audioDefaultNameCount = 1;

    public ShowType showType = ShowType.normal;
    public Drawable studioColor = ContextCompat.getDrawable(TApplication.getInstance().getBaseContext(), R.drawable.student_material_frame_main);
    public boolean isSearching = false;
    public boolean isEditing = false;

    /**
     * 停止加载的回调 true  成功 false 失败
     */
    public SingleLiveEvent<Boolean> stopLoading = new SingleLiveEvent<>();
    public int materialType;
    public String studentId = "";
    public String path = "Home";

    @Override
    public void onCreate() {
        super.onCreate();
        if (SLCacheUtil.getStudioInfo() != null) {
            studioColor = SLCacheUtil.getStudioInfo().getStudentMaterialsFrame();
        } else if (ListenerService.shared.studentData.getStudioData() != null) {
            studioColor = ListenerService.shared.studentData.getStudioData().getStudentMaterialsFrame();
        }
        studentId = ListenerService.shared.studentData.getUser().getUserId();
        getMaterialsFilterData();

        if (showType == ShowType.normal) {
            emptyLayoutVisibility.setValue(0);
            mainLayoutVisibility.setValue(8);
        }
        promptToBeProLayoutVisibility.setValue(8);
        // data connection
        creatorId = studentId;
        if (showType == ShowType.normal && !isFolderViewModel) {
//            getTeacherMemberLevel();
            initAndListenMaterialData();
        }
        Messenger.getDefault().register(this, "closeFolder", () -> uc.closeFolderView.call());
        Messenger.getDefault().register(this, "catalogueCloseFolderView", MaterialEntity.class, materialEntity -> {
            uc.catalogueCloseFolderView.postValue(materialEntity);
        });
        Messenger.getDefault().register(this, "MATERIALS_EDIT", Boolean.class, isEdit -> {
            uc.editeFolder.postValue(isEdit);
        });
        Messenger.getDefault().send(SLJsonUtils.toJsonString(selectedMaterials), "SELECT_MATERIALS");

        Messenger.getDefault().register(this, "SELECT_MATERIALS", String.class, data -> {
            List<MaterialEntity> materialEntities = SLJsonUtils.toList(data, MaterialEntity.class);
            this.selectedMaterials = materialEntities;
        });
        Messenger.getDefault().register(this, "SEARCH_MATERIALS", String.class, data -> uc.searchMaterials.postValue(data));
        Messenger.getDefault().register(this, MessengerUtils.PARENT_SELECT_KIDS_DONE, () -> {
            studentId = ListenerService.shared.studentData.getUser().getUserId();
        });
        Messenger.getDefault().register(this, "FILTER_CHANGE", this::initFilterData);

    }


    /**
     * 初始化materials 数据
     */
    private void initAndListenMaterialData() {
        Messenger.getDefault().register(this, MessengerUtils.STUDENT_MATERIALS_CHANGED, () -> {
            if (showType == ShowType.normal) {
                if (isFolderViewModel && folderEntity != null && folderEntity.getId() != null) {
                    List<MaterialEntity> materials = new ArrayList<>();
                    for (MaterialEntity homeMaterial : ListenerService.shared.studentData.getMaterials()) {
                        if (folderEntity.getId().equals(homeMaterial.getFolder())) {
                            materials.add(homeMaterial);
                        }
                    }
                    setFolderData(materials);
                } else {
                    setData(CloneObjectUtils.cloneObject(ListenerService.shared.studentData.getMaterials()));
                }
            }
        });

        Messenger.getDefault().register(this, MessengerUtils.STUDENT_GET_STUDIO, () -> {
            Logger.e("======%s", "刷新studio");
            if (ListenerService.shared.studentData.getStudioData() != null) {
                studioColor = ListenerService.shared.studentData.getStudioData().getStudentMaterialsFrame();
            }
        });

        setData(CloneObjectUtils.cloneObject(ListenerService.shared.studentData.getMaterials()));


    }

    /**
     * 设置folder数据
     *
     * @param materials
     */
    public void setFolderData(List<MaterialEntity> materials) {
//        Logger.e("????==>%s", "????" + materials.size());
        allMaterialDataList.clear();
        materialDataList.clear();
        String selfUserId = studentId;
        if (materials == null) {
            return;
        }
        if (materials.size() > 0) {
            materials.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));

            for (MaterialEntity material : materials) {

                MaterialsMultiItemViewModel<StudentMaterialsViewModel> item;
                if (isListView) {
                    item = new MaterialsListViewModel<>(this, material);
                    if (material.getType() == MaterialEntity.Type.folder) {
                        if (material.getCreatorId().equals(selfUserId)) {
                            ((MaterialsListViewModel) item).setHaveFile(allMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        } else {
                            ((MaterialsListViewModel) item).setHaveFile(teacherMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        }
                    }

                }else {
                    if (material.getType() == MaterialEntity.Type.folder) {
                        item = new MaterialsFolderViewModel<>(this, material);
                        MaterialsFolderViewModel<StudentMaterialsViewModel> folderItem = (MaterialsFolderViewModel<StudentMaterialsViewModel>) item;
                        if (material.getCreatorId().equals(selfUserId)) {
                            folderItem.setHaveFile(allMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        } else {
                            folderItem.setHaveFile(teacherMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        }
                    } else if (material.getType() == MaterialEntity.Type.youtube) {
                        item = new MaterialsLinkVMV2<>(this, material);
                    } else {
                        item = new MaterialsGridVMV2<>(this, material);
                    }
                }

                item.setNoSelfShowFrame(selfUserId);
                item.isNotShowShare.set(true);
                item.isShowMoreButton.set(true);
                if (showType == ShowType.show || showType == ShowType.select) {
                    for (MaterialEntity selectedMaterial : selectedMaterials) {
                        if (selectedMaterial.getId().equals(material.getId())) {
                            item.isSelected.set(true);
                        }
                    }
                }
                materialDataList.add(item);
                allMaterialDataList.add(item);
            }
            uc.materialsObserverData.setValue(materialDataList);

            isHaveData.set(materialDataList.size() > 0);
        }
//        if (materials.size() > 0) {
//            materials.sort((o1, o2) -> {
//                int a = Integer.parseInt(o1.getCreateTime());
//                int b = Integer.parseInt(o2.getCreateTime());
//                return b - a;
//            });
//            for (MaterialEntity material : materials) {
//                List<StudentListEntity> shareStudentDatas = new ArrayList<>();
//                for (String studentId : material.getStudentIds()) {
//                    for (StudentListEntity entity : studentList) {
//                        if (studentId.equals(entity.getStudentId())) {
//                            shareStudentDatas.add(entity);
//                            break;
//                        }
//                    }
//                }
//                if (material.getType() == 6) {
//                    MaterialsLinkVMV2<StudentMaterialsViewModel> item = new MaterialsLinkVMV2<>(this,
//                            material);
//                    item.setStudentData(shareStudentDatas);
//                    item.setNoSelfShowFrame(selfUserId);
//                    item.isNotShowShare.set(true);
//                    if (showType == ShowType.show || showType == ShowType.select) {
//                        for (MaterialEntity selectedMaterial : selectedMaterials) {
//                            if (selectedMaterial.getId().equals(material.getId())) {
//                                item.isSelected.set(true);
//                            }
//                        }
//                    }
//                    materialDataList.add(item);
//                    allMaterialDataList.add(item);
//                } else {
//                    MaterialsGridVMV2<StudentMaterialsViewModel> item = new MaterialsGridVMV2<>(this,
//                            material);
//                    item.setStudentData(shareStudentDatas);
//                    item.setNoSelfShowFrame(selfUserId);
//                    item.isNotShowShare.set(true);
//                    if (showType == ShowType.show || showType == ShowType.select) {
//                        for (MaterialEntity selectedMaterial : selectedMaterials) {
//                            if (selectedMaterial.getId().equals(material.getId())) {
//                                item.isSelected.set(true);
//                            }
//                        }
//                    }
//                    materialDataList.add(item);
//                    allMaterialDataList.add(item);
//                }
//
//
//            }
//            uc.materialsObserverData.setValue(materialDataList);
//        }
        initFilterData();
    }

    /**
     * 取消选中
     */
    public void cleanSelect() {
        for (MaterialsMultiItemViewModel materialsMultiItemViewModel : materialDataList) {
            materialsMultiItemViewModel.isSelected.set(false);
        }
    }


    /**
     * 设置数据
     *
     * @param materials
     */
    public void setData(List<MaterialEntity> materials) {
        materialDataList.clear();
        allMaterialDataList.clear();
        int totalMaterialCount = 0;
        videoDefaultNameCount = 1;
        photoDefaultNameCount = 1;
        folderDefaultNameCount = 1;
        audioDefaultNameCount = 1;
        studentMaterials = materials;
        String selfUserId = studentId;
        List<MaterialEntity> teacherMaterials = CloneObjectUtils.cloneObject(ListenerService.shared.studentData.getTeacherMaterials());
        teacherMaterialsData = teacherMaterials;
        Logger.e("teacherMaterials==>%s",teacherMaterials.size());
        Logger.e("materials==>%s",materials.size());

        for (MaterialEntity teacherMaterial : teacherMaterials) {
            if (teacherMaterial.getStudentIds().contains(selfUserId)) {
                materials.add(teacherMaterial);
            }
        }
        List<String> folderIds = new ArrayList<>();
        for (MaterialEntity material : materials) {
            if (material.getType() == -2) {
                folderIds.add(material.getId());
            }
        }
        if (materials.size() > 0) {
            materials.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getName(), o2.getName()));
//            List<MaterialEntity>d = new ArrayList<>();
//            d.addAll(materials.stream().filter(it->it.getFolder().equals("")).collect(Collectors.toList())) ;
//            d.addAll(materials.stream().filter(it->!it.getFolder().equals("")).filter(it->!folderIds.contains(it.getFolder())).collect(Collectors.toList()));
//            Logger.e("d==>%s",SLJsonUtils.toJsonString(d));

            for (MaterialEntity material : materials) {
                totalMaterialCount += material.getMaterials().size();
//                if (material.getFolder().equals("") || (!material.getCreatorId().equals(selfUserId) && !material.getFolder().equals(""))) {
                if (material.getFolder().equals("") || (!material.getFolder().equals("") && !folderIds.contains(material.getFolder()))) {

                    MaterialsMultiItemViewModel<StudentMaterialsViewModel> item;
                    if (isListView) {
                        item = new MaterialsListViewModel<>(this, material);
                        if (material.getType() == MaterialEntity.Type.folder) {
                            if (material.getCreatorId().equals(selfUserId)) {
                                ((MaterialsListViewModel) item).setHaveFile(materials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                            } else {
                                ((MaterialsListViewModel) item).setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                            }
                        }
                    }else {
                        if (material.getType() == MaterialEntity.Type.folder) {
                            item = new MaterialsFolderViewModel<>(this, material);
                            MaterialsFolderViewModel<StudentMaterialsViewModel> folderItem = (MaterialsFolderViewModel<StudentMaterialsViewModel>) item;
                            if (material.getCreatorId().equals(selfUserId)) {
                                folderItem.setHaveFile(materials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                            } else {
                                folderItem.setHaveFile(teacherMaterials.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                            }
                        } else if (material.getType() == MaterialEntity.Type.youtube) {
                            item = new MaterialsLinkVMV2<>(this, material);
                        } else {
                            item = new MaterialsGridVMV2<>(this, material);
                        }
                    }

                    item.setNoSelfShowFrame(selfUserId);
                    item.isNotShowShare.set(true);
                    item.isShowMoreButton.set(true);
                    if (showType == ShowType.select) {
                        for (MaterialEntity selectedMaterial : selectedMaterials) {
                            if (selectedMaterial.getId().equals(material.getId())) {
                                item.isSelected.set(true);
                            }
                        }
                    }
                    if (showType == ShowType.select) {
//                        item.isSelectFileInFolder.set(true);
                        List<String> selectFileId = new ArrayList<>();
                        for (MaterialEntity selectedMaterial : selectedMaterials) {
                            if (selectedMaterial.getId().equals(material.getId())) {
                                item.isSelected.set(true);
                            }
                            for (MaterialEntity materialMaterial : material.getMaterials()) {
                                if (materialMaterial.getId().equals(selectedMaterial.getId())) {
                                    selectFileId.add(materialMaterial.getId());
                                    break;
                                }
                            }
                        }
                        //此处判断 文件夹中的文件是否全部被选中
                        boolean isDontAllSelected = false;
                        if (selectFileId.size() == 0) {
                            isDontAllSelected = false;
                        } else if (selectFileId.size() != material.getMaterials().size()) {
                            isDontAllSelected = true;
                        }
                        if (item.isSelected.get()) {
                            isDontAllSelected = false;
                        }
                        item.isDontAllSelected.set(isDontAllSelected);

                    }
//
                    materialDataList.add(item);
                    allMaterialDataList.add(item);
                    if (material.getType() == 1 && material.getName().toLowerCase().contains("photo")) {
                        photoDefaultNameCount += 1;
                    }
                    if (material.getType() == 5 && material.getName().toLowerCase().contains("video")) {
                        videoDefaultNameCount += 1;
                    }
                    if (material.getType() == 4 && material.getName().toLowerCase().contains("audio")) {
                        audioDefaultNameCount += 1;
                    }
                    if (material.getType() == -2 && material.getName().toLowerCase().contains("new folder")) {
                        folderDefaultNameCount += 1;
                    }
                }
            }
            allMaterialsData = CloneObjectUtils.cloneObject(materials);
            uc.materialsObserverData.setValue(materialDataList);
            emptyLayoutVisibility.setValue(View.GONE);
            mainLayoutVisibility.setValue(0);


//
//List<String> folderIds = new ArrayList<>();
//            for (MaterialEntity material : materials) {
//                if (material.getType() == -2) {
//                    folderIds.add(material.getId());
//                }
//            }
//            for (MaterialEntity material : materials) {
//                List<StudentListEntity> shareStudentDatas = new ArrayList<>();
//                for (String studentId : material.getStudentIds()) {
//                    for (StudentListEntity entity : studentList) {
//                        if (studentId.equals(entity.getStudentId())) {
//                            shareStudentDatas.add(entity);
//                            break;
//                        }
//                    }
//                }
//                if (material.getType() == -2) {
//                    folderDefaultNameCount += 1;
//                    if (material.getMaterials().size() > 0) {
//                        totalMaterialCount += material.getMaterials().size();
//                        material.getMaterials().sort((o1, o2) -> {
//                            int a = Integer.parseInt(o1.getCreateTime());
//                            int b = Integer.parseInt(o2.getCreateTime());
//                            return b - a;
//                        });
//                        MaterialsFolderViewModel<StudentMaterialsViewModel> item = new MaterialsFolderViewModel<>(this, material);
//                        item.setStudentData(shareStudentDatas);
//                        item.setNoSelfShowFrame(selfUserId);
//                        if (showType == ShowType.show || showType == ShowType.select) {
//
//                        }
//                        item.isNotShowShare.set(true);
//                        if (showType == ShowType.select) {
//                            item.isSelectFileInFolder.set(true);
//                            List<String> selectFileId = new ArrayList<>();
//                            for (MaterialEntity selectedMaterial : selectedMaterials) {
//                                if (selectedMaterial.getId().equals(material.getId())) {
//                                    item.isSelected.set(true);
//                                }
//                                for (MaterialEntity materialMaterial : material.getMaterials()) {
//                                    if (materialMaterial.getId().equals(selectedMaterial.getId())) {
//                                        selectFileId.add(materialMaterial.getId());
//                                        break;
//                                    }
//                                }
//                            }
//                            //此处判断 文件夹中的文件是否全部被选中
//                            boolean isDontAllSelected = false;
//                            if (selectFileId.size() == 0) {
//                                isDontAllSelected = false;
//                            } else if (selectFileId.size() != material.getMaterials().size()) {
//                                isDontAllSelected = true;
//                            }
//                            if (item.isSelected.get()) {
//                                isDontAllSelected = false;
//                            }
//                            item.isDontAllSelected.set(isDontAllSelected);
//
//                        }
//                        materialDataList.add(item);
//                        allMaterialDataList.add(item);
//
//                        for (MaterialEntity materialMaterial : material.getMaterials()) {
//                            if (materialMaterial.getType() == 1 && materialMaterial.getName().toLowerCase().contains("photo")) {
//                                photoDefaultNameCount += 1;
//                            }
//                            if (materialMaterial.getType() == 5 && materialMaterial.getName().toLowerCase().contains("video")) {
//                                videoDefaultNameCount += 1;
//                            }
//                            if (material.getType() == 4 && material.getName().toLowerCase().contains("audio")) {
//                                audioDefaultNameCount += 1;
//                            }
//                        }
//
//                    }
//                } else if (material.getType() != -1) {
//                    if (material.getFolder().equals("") || !folderIds.contains(material.getFolder())) {
//                        if (material.getType() == 6) {
//                            totalMaterialCount += 1;
//                            MaterialsLinkVMV2<StudentMaterialsViewModel> item = new MaterialsLinkVMV2<>(this,
//                                    material);
//                            item.setStudentData(shareStudentDatas);
//                            item.setNoSelfShowFrame(selfUserId);
//                            if (showType == ShowType.show || showType == ShowType.select) {
//
//                            }
//                            item.isNotShowShare.set(true);
//                            if (showType == ShowType.select) {
//                                for (MaterialEntity selectedMaterial : selectedMaterials) {
//                                    if (selectedMaterial.getId().equals(material.getId())) {
//                                        item.isSelected.set(true);
//                                    }
//                                }
//                            }
//                            materialDataList.add(item);
//                            allMaterialDataList.add(item);
//
//                        } else {
//                            totalMaterialCount += 1;
//                            MaterialsGridVMV2<StudentMaterialsViewModel> item = new MaterialsGridVMV2<>(this,
//                                    material);
//                            item.setStudentData(shareStudentDatas);
//                            item.setNoSelfShowFrame(selfUserId);
//                            if (showType == ShowType.show || showType == ShowType.select) {
//
//                            }
//                            item.isNotShowShare.set(true);
//                            if (showType == ShowType.select) {
//                                for (MaterialEntity selectedMaterial : selectedMaterials) {
//                                    if (selectedMaterial.getId().equals(material.getId())) {
//                                        item.isSelected.set(true);
//                                    }
//                                }
//                            }
//                            materialDataList.add(item);
//                            allMaterialDataList.add(item);
//                            if (material.getType() == 1 && material.getName().toLowerCase().contains("photo")) {
//                                photoDefaultNameCount += 1;
//                            }
//                            if (material.getType() == 5 && material.getName().toLowerCase().contains("video")) {
//                                videoDefaultNameCount += 1;
//                            }
//                            if (material.getType() == 4 && material.getName().toLowerCase().contains("audio")) {
//                                audioDefaultNameCount += 1;
//                            }
//                        }
//                    }
//                }
//
//            }
//            uc.materialsObserverData.setValue(materialDataList);
//            emptyLayoutVisibility.setValue(View.GONE);
//            mainLayoutVisibility.setValue(0);
        } else {
            if (showType != ShowType.show || showType == ShowType.select) {
                emptyLayoutVisibility.setValue(0);
            }
            mainLayoutVisibility.setValue(8);
        }
        initFilterData();
        promptToBeProLayoutVisibility.setValue(8);

    }

    public StudentMaterialsViewModel(@NonNull Application application) {
        super(application);
    }

    public UIEventObservable uc = new UIEventObservable();

    public void sendUploadLinkToEmail(String link) {
        showDialog();
        addSubscribe(
                CloudFunctions
                        .sendUploadLinkToUser(studentId, link)
                        .subscribe(data -> {
                            SLToast.success("Send Email  Successful!");
                            dismissDialog();
                            Logger.e("======%s", "成功");
                        }, throwable -> {
                            dismissDialog();
                            SLToast.showError();
                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })

        );
    }

    /**
     * 发送已选中的materials
     */
    public void sendSelectMaterials() {
        Messenger.getDefault().send(SLJsonUtils.toJsonString(selectedMaterials), MessengerUtils.SELECT_MATERIALS);
        finish();
    }

    public class UIEventObservable {
        /**
         * 'add materials'按钮 / '+'号
         */
        public SingleLiveEvent<Void> clickAddMaterial = new SingleLiveEvent<>();
        /**
         * materials data (判断 materials 类型)
         */
        public SingleLiveEvent<ObservableList<MaterialsMultiItemViewModel>> materialsObserverData =
                new SingleLiveEvent<>();
        public SingleLiveEvent<ObservableList<MaterialsMultiItemViewModel>> materialsSearchResultObserverData = new SingleLiveEvent<>();
        /**
         * 点击视频 materials
         */
        public SingleLiveEvent<Map<String, Object>> clickVideoItem = new SingleLiveEvent<>();

        /**
         * 点击Item
         */
        public SingleLiveEvent<Map<String, Object>> clickItem = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> clickBackFromSearch = new SingleLiveEvent<>();

        public SingleLiveEvent<Void> dismissDialog = new SingleLiveEvent<>();

        public SingleLiveEvent<Integer> uploadProgress = new SingleLiveEvent<>();
        public SingleLiveEvent<MaterialEntity> closeFolderView = new SingleLiveEvent<>();
        public SingleLiveEvent<MaterialEntity> catalogueCloseFolderView = new SingleLiveEvent<>();
        public SingleLiveEvent<Boolean> editeFolder = new SingleLiveEvent<>();
        public SingleLiveEvent<String> searchMaterials = new SingleLiveEvent<>();
//        public SingleLiveEvent<Integer> closeFolderView = new SingleLiveEvent<>();

        //key:id,defaultName
        public SingleLiveEvent<Map<String, String>> changeName = new SingleLiveEvent<>();

        public SingleLiveEvent<Map<String, Object>> selectData = new SingleLiveEvent<>();
        public SingleLiveEvent<MaterialEntity> clickMore = new SingleLiveEvent<>();
        public SingleLiveEvent<MaterialEntity> clickDelete = new SingleLiveEvent<>();
    }

    //给RecyclerView添加ObservableList
    public ObservableList<MaterialsMultiItemViewModel> materialDataList = new ObservableArrayList<>();
    // search result
    public ObservableList<MaterialsMultiItemViewModel> allMaterialDataList =
            new ObservableArrayList<>();
    //给RecyclerView添加ItemBinding
    public ItemBinding<MaterialsMultiItemViewModel> itemBinding =
            ItemBinding.of((itemBinding, position, item) -> {
                //通过item的类型, 动态设置Item加载的布局
                if (item.getData().getId().equals("") ){
                    itemBinding.set(BR.viewModel, R.layout.item_materilas_group_title);

                }else if (isListView) {
                    itemBinding.set(BR.viewModel, R.layout.item_materilas_list);

                } else {
                    int itemType = (int) item.getData().getType();
                    switch (itemType) {
                        case MULTI_MATERIAL_TYPE_FILE:
                        case MULTI_MATERIAL_TYPE_IMG:
                        case MULTI_MATERIAL_TYPE_PPT:
                        case MULTI_MATERIAL_TYPE_WORD:
                        case MULTI_MATERIAL_TYPE_MP3:
                        case MULTI_MATERIAL_TYPE_VIDEO:
                        case MULTI_MATERIAL_TYPE_LINK:
                        case MULTI_MATERIAL_TYPE_TXT:
                        case MULTI_MATERIAL_TYPE_PDF:
                        case MULTI_MATERIAL_TYPE_EXCEL:
                        case MULTI_MATERIAL_TYPE_GOOGLE_DRAWINGS:
                        case MULTI_MATERIAL_TYPE_GOOGLE_FORMS:
                        case MULTI_MATERIAL_TYPE_GOOGLE_SLIDES:
                        case MULTI_MATERIAL_TYPE_GOOGLE_SHEET:
                        case MULTI_MATERIAL_TYPE_GOOGLE_DOC:
                        case MULTI_MATERIAL_TYPE_KEYNOTE:
                        case MULTI_MATERIAL_TYPE_NUMBERS:
                        case MULTI_MATERIAL_TYPE_PAGES:
                            itemBinding.set(BR.itemGridViewModel, R.layout.item_grid_material);
                            break;
                        case MULTI_MATERIAL_TYPE_YOUTUBE:
                            itemBinding.set(BR.itemLinkViewModel, R.layout.item_link_material);
                            break;
                        case MULTI_MATERIAL_TYPE_FOLDER:
                            itemBinding.set(BR.itemFolderViewModel, R.layout.item_folder_material);
                            break;
                    }
                }
            });

    public void uploadAudio(String name, String selectFolderId, String
            folderName, String uploadPath, String audioId) {

        localFileSuffixName = "aac";
        localPath = uploadPath;
        uploadNewMaterialToStorage(audioId, name, audioId, selectFolderId, folderName);
    }

    public void updateSelectedMaterials(Boolean select, MaterialEntity selectData) {
        if (select) {
            selectedMaterials.add(selectData);
        } else {
            selectedMaterials.removeIf(materialEntity -> selectData.getId().equals(materialEntity.getId()));
        }
        Messenger.getDefault().send(SLJsonUtils.toJsonString(selectedMaterials), "SELECT_MATERIALS");

        bottomButtonIsEnable.setValue(selectedMaterials.size() > 0);
        for (MaterialsMultiItemViewModel item : materialDataList) {
            if (item.getData().getType() == -2 && selectData.getId().equals(item.getData().getId())) {
                item.isDontAllSelected.set(false);
                selectedMaterials.removeIf(materialEntity -> {
                    boolean isHave = false;
                    for (MaterialEntity material : item.getData().getMaterials()) {
                        if (material.getId().equals(materialEntity.getId())) {
                            isHave = true;
                            break;
                        }
                    }
                    return isHave;
                });
            }
        }
        Map<String, Object> map = new HashMap<>();
        map.put("isSelect", select);
        map.put("data", selectData);
        uc.selectData.setValue(map);
    }

    public void search(String s) {
        searchString = s;
        materialDataList.clear();
        String currentUserId = studentId;
        for (int i = 0; i < allMaterialDataList.size(); i++) {

            MaterialsMultiItemViewModel item = allMaterialDataList.get(i);
            String name = item.getData().getName();
            if (name != null) {
                if (name.toLowerCase().contains(s.toLowerCase())) {
                    if (isEditing) {
                        if (allMaterialDataList.get(i).getData().getCreatorId().equals(currentUserId)) {
                            materialDataList.add(item);
                        }
                    } else {
                        materialDataList.add(item);
                    }
                } else if (s.equals("")) {
                    if (isEditing) {
                        if (allMaterialDataList.get(i).getData().getCreatorId().equals(currentUserId)) {
                            materialDataList.add(item);
                        }
                    } else {
                        materialDataList.add(item);
                    }
                }
            }
        }
    }

    /**
     * 点击添加资料按钮（add materials）
     */
    public BindingCommand clickAddMaterial = new BindingCommand(() -> uc.clickAddMaterial.call());

    /**
     * back from search
     */
    public BindingCommand clickBackFromSearch =
            new BindingCommand(() -> uc.clickBackFromSearch.call());


    /**
     * 获取 教师 会员身份 ( free / regular pro )
     */
    public void getTeacherMemberLevel() {
        addSubscribe(
                UserService
                        .getStudioInstance()
                        .getTeacherInfo(false)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread())
                        .subscribe(teacherInfo -> {
                            int level = teacherInfo.getMemberLevelId();
                            if (level == 1) {
                                // free
                                currentUserIsPro = false;
                            } else if (level == 2) {
                                // regular pro
                                currentUserIsPro = true;
                            }
                        }, throwable -> {
                            Logger.e("-**-*-*-*-*-*-*- 获取教师会员身份失败: " + throwable.getMessage());
                        })
        );
    }

    /**
     * 点击Item
     */
    public void clickItem(MaterialEntity entity, View view) {
        Map<String, Object> map = new HashMap<>();
        map.put("data", entity);
        map.put("view", view);
        uc.clickItem.setValue(map);
    }

    /**
     * 点击Item中的Share
     *
     * @param materialEntity
     */
    public void clickItemShare(MaterialEntity materialEntity) {
        if (showType == ShowType.normal) {
            List<MaterialEntity> materialEntities = new ArrayList<>();
            materialEntities.add(materialEntity);
            Bundle bundle = new Bundle();
            bundle.putSerializable("shareMaterials", (Serializable) materialEntities);
            bundle.putBoolean("isInFolder", isFolderViewModel);
            startActivity(AddressBookActivity.class, bundle);
        }
    }

    public void clickEdit(boolean isCancel) {
        materialDataList.clear();
        String currentUserId = studentId;
        isEditing = !isCancel;
        if (isCancel) {
            if (isSearching) {
                for (MaterialsMultiItemViewModel itemViewModel : allMaterialDataList) {
                    String name = itemViewModel.getData().getName();
                    if (name != null) {
                        if (name.toLowerCase().contains(searchString.toLowerCase())) {
                            materialDataList.add(itemViewModel);
                        } else if (searchString.equals("")) {
                            materialDataList.add(itemViewModel);
                        }
                    }
                }
            } else {
                materialDataList.addAll(allMaterialDataList);
            }
        } else {
            for (MaterialsMultiItemViewModel itemViewModel : allMaterialDataList) {

                if (itemViewModel.getData().getCreatorId().equals(currentUserId)) {
                    if (isSearching) {
                        String name = itemViewModel.getData().getName();
                        if (name != null) {
                            if (name.toLowerCase().contains(searchString.toLowerCase())) {
                                materialDataList.add(itemViewModel);
                            } else if (searchString.equals("")) {
                                materialDataList.add(itemViewModel);
                            }
                        }
                    } else {
                        materialDataList.add(itemViewModel);
                    }
                }
            }
        }

    }

    /**
     * 点击Item中的Title
     *
     * @param materialEntity
     */
    public void clickItemTitle(MaterialEntity materialEntity) {
        if (materialEntity.getCreatorId().equals(creatorId)) {
            Map<String, String> map = new HashMap<>();
            map.put("id", materialEntity.getId());
            map.put("defaultName", materialEntity.getName());
            uc.changeName.setValue(map);
        }
    }

    public void dragData(int selectPosition, int toPosition) {
        if (materialDataList.get(selectPosition).getData().getType() == -2 || materialDataList.get(selectPosition) == null
                || materialDataList.get(toPosition) == null) {
            return;
        }
        showDialog();
        List<MaterialEntity> selectData = new ArrayList<>();
        selectData.add(materialDataList.get(selectPosition).getData());
        String id = materialDataList.get(toPosition).getData().getId();
        boolean isShowChangeName = false;
        if (materialDataList.get(toPosition).getData().getType() != -2) {
            isShowChangeName = true;
            id = "0";
            selectData.add(materialDataList.get(toPosition).getData());
        }
        String folderName = "Untitled Folder" + folderDefaultNameCount;
        String folderId = IDUtils.getId();
        boolean finalIsShowChangeName = isShowChangeName;
        addSubscribe(
                MaterialService
                        .getInstance()
                        .moveToFolder(id, folderName, selectData, false, null, folderId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            Logger.e("======%s", "成功");
                            if (finalIsShowChangeName) {
                                Map<String, String> map = new HashMap<>();
                                map.put("id", folderId);
                                map.put("defaultName", folderName);
                                uc.changeName.setValue(map);
                            }
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                            dismissDialog();
                        })
        );
    }


    /**
     * 移动material
     *
     * @param selectId   选择要移动到的文件夹
     * @param folderName 新添加的文件夹名称
     * @param moveData   要移动的文件
     */
    public void moveMaterial(MoveFolderDialog.Builder dialog, String selectId, String folderName, List<MaterialEntity> moveData) {
        addSubscribe(
                MaterialService
                        .getInstance()
                        .moveToFolder(selectId, folderName, moveData, isInFolder, inFolderData, IDUtils.getId())
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            Logger.e("======%s", "成功");
                            dismissDialog();
                            dialog.dismiss();
                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            SLToast.showError();
                            dismissDialog();
                        })
        );
    }


    public void upLoadGooglePhoto(List<MaterialEntity> datas, String selectId, String folderName) {
        AtomicInteger uploadCount = new AtomicInteger();

        for (MaterialEntity data : datas) {
            uploadCount.addAndGet(1);
            newMaterialsByGoogleDrive(selectId, folderName, uploadCount, datas.size(), datas);

        }
    }

    /**
     * 上传从googleDrive中的文件
     *
     * @param files
     * @param selectId
     * @param folderName
     */
    public void uploadGoogleDriveFile(List<SelectGoogleDriveDialog.TKFile> files, String selectId, String folderName) {
        List<MaterialEntity> materialEntities = new ArrayList<>();
        String time = TimeUtils.getCurrentTimeString();
        FirebaseStorage storage = FirebaseStorage.getInstance();
        StorageReference storageRef = storage.getReference();
        Logger.e("======%s", "开始上传");

        for (SelectGoogleDriveDialog.TKFile file : files) {

            if (file.getStatus() != 1 && file.getStatus() != -2) {
                continue;
            }
            String id = IDUtils.getId();
            String storagePathOnline =
                    "materials/" + creatorId + "/" + id + "." + file.getFile().getFullFileExtension();

            MaterialEntity material = new MaterialEntity()
                    .setId(id)
                    .setCreatorId(creatorId)
                    .setStatus(file.getStatus() == -2 ? -1 : 0)
                    .setType(file.getTkType())
                    .setName(file.getFile().getName())
                    .setDesc("")
                    .setSuffixName(file.getFile().getFullFileExtension() != null ? file.getFile().getFullFileExtension() : "")
                    .setOpenType(0)
                    .setGoogleFile(file)
                    .setStudentIds(new ArrayList<>())
                    .setMinPictureUrl((file.getFile().getThumbnailLink() != null && !file.getFile().getThumbnailLink().equals("")) ? file.getFile().getThumbnailLink() : (file.getFile().getIconLink() != null && !file.getFile().getIconLink().equals("")) ? file.getFile().getIconLink() : "")
                    .setCreateTime(time)
                    .setUpdateTime(time);
            if (file.getStatus() == 1) {
                material.setStoragePatch(storagePathOnline);
            } else if (file.getStatus() == -2) {
                material.setUrl(file.getLoadUrl());
            }
            materialEntities.add(material);
        }
        AtomicInteger uploadCount = new AtomicInteger();
        List<MaterialEntity> newMaterial = new ArrayList<>();

        int allCount = materialEntities.size();
        for (int i = 0; i < materialEntities.size(); i++) {
            MaterialEntity materialEntity = materialEntities.get(i);
            Logger.e("此'%s'是否需要上传%s", materialEntity.getId() + materialEntity.getName(), (!materialEntity.getStoragePatch().equals("")));
            if (!materialEntity.getStoragePatch().equals("")) {
                StorageReference spaceRef = storageRef.child(materialEntity.getStoragePatch());
                Uri file = Uri.fromFile(new File(materialEntity.getGoogleFile().getLocalPath()));
                UploadTask uploadTask = spaceRef.putFile(file);
                int finalI = i;
                uploadTask.continueWithTask(task -> {
                    if (!task.isSuccessful()) {
                        throw Objects.requireNonNull(task.getException());
                    }
                    return spaceRef.getDownloadUrl();
                }).addOnCompleteListener(task -> {
                    uploadCount.addAndGet(1);
                    if (task.isSuccessful()) {
                        Logger.e("======上传你文件成功:下载路径" + task.getResult().toString());

                        if (materialEntity.getType() == 1) {
                            materialEntities.get(finalI).setMinPictureUrl(task.getResult().toString());
                        }
                        materialEntities.get(finalI).setUrl(task.getResult().toString());
                        newMaterial.add(materialEntities.get(finalI));
                        newMaterialsByGoogleDrive(selectId, folderName, uploadCount, allCount, newMaterial);
                    } else {
                        Logger.e("上传失败1:" + task.getException());
                    }


                }).addOnFailureListener(exception -> {
                    uploadCount.addAndGet(1);
                    Logger.e("上传失败2:" + exception.getMessage());

                });

            } else {
                Logger.e("此文件不许要上传 直接创建:%s", materialEntity.getId() + materialEntity.getName());

                uploadCount.addAndGet(1);
                newMaterial.add(materialEntities.get(i));
                newMaterialsByGoogleDrive(selectId, folderName, uploadCount, allCount, newMaterial);

            }
        }


    }

    private void newMaterialsByGoogleDrive(String selectId, String folderName, AtomicInteger uploadCount, int allCount, List<MaterialEntity> materialEntity) {
        if (uploadCount.get() == allCount) {
            addSubscribe(MaterialService
                    .getInstance()
                    .createNewMaterialByGoogleDrive(materialEntity, selectId, folderName)
                    .subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe(aBoolean -> {
                        Logger.e("======%s", "创建materials 全部成功");
                        stopLoading.setValue(true);
                        uc.uploadProgress.setValue(100);
                        uc.dismissDialog.call();
                        // 重新获取 material 列表
                    }, throwable ->
                    {
                        Logger.e("-----" + throwable.getMessage());
                        uc.uploadProgress.setValue(-1);
                        stopLoading.setValue(false);
                    }));
        } else {
            int progress = (int) ((double) uploadCount.get() / (double) allCount * 100D);
            if (progress >= 90) {
                progress = 90;
            }
            uc.uploadProgress.setValue(progress);
        }

    }


    /**
     * @param name
     * @param selectFolderId -1为放到home中,0为选择创建新的Folder, id 为选择的id
     * @param folderName     只有selectFolderId为0的时候这个值才有用
     */
    public void getNewMaterialDocId(String name, String selectFolderId, String
            folderName) {
        String id = IDUtils.getId();

        Logger.e("-**-*-*-*-*-*-*- file material");
        Logger.e("-**-*-*-*-*-*-*- localPath: " + localPath);
        String hash = "";
        if (SLStringUtils.isNoNull(localPath)) {
            hash = HashUtils.getFileSHA256(localPath);
            Logger.e("---------- hash 值: " + hash);
//                uploadNewMaterialToStorage(id, name);
        }
        getMaterialHash(hash, id, name, selectFolderId, folderName);


    }

    /**
     * 获取云上是否有相同文件的 hash
     *
     * @param hash
     * @param id
     * @param name
     */
    public void getMaterialHash(String hash, String id, String name, String
            selectFolderId, String folderName) {
        if (materialType == 5) {
            try {
                MediaMetadataRetriever media = new MediaMetadataRetriever();
                media.setDataSource(localPath);
                upLoadVideoMinPicture(id, name, hash, selectFolderId, folderName, media.getFrameAtTime());
            } catch (Exception e) {
                uploadNewMaterialToStorage(id, name, hash, selectFolderId, folderName);
            }
        } else if (materialType == 6 || materialType == 7) {

            setNewMaterialDoc(IDUtils.getId(), name, selectFolderId, folderName);

        } else {
            uploadNewMaterialToStorage(id, name, hash, selectFolderId, folderName);
        }

//        addSubscribe(
//                MaterialService
//                        .getMaterialHashInstance()
//                        .getMaterialHash(hash)
//                        .subscribeOn(Schedulers.io())
//                        .observeOn(AndroidSchedulers.mainThread())
//                        .subscribe(materialHash -> {
//                            Logger.e("------ material hash： " + materialHash);
//                            String url = materialHash.getUrl();
//                            String storagePath = materialHash.getPath();
//                            Logger.e("------ material path: " + storagePath);
//                            boolean isRepeatMaterial = false;
//                            String materialId = id;
//
//                            for (int i = 0; i < materialDataList.size(); i++) {
//                                MaterialsMultiItemViewModel item = materialDataList.get(i);
//                                if (item.getData().getStoragePatch().equals(storagePath)) {
//                                    isRepeatMaterial = true;
//                                    materialId = item.getData().getId();
//                                    break;
//                                }
//                            }
//
//                            if (url.equals("")) {
//                                // material_hash 不存在, 上传 material, 创建 hash
//                                uploadNewMaterialToStorage(id, name, hash);
//                            } else {
//                                // material_hash 存在
//                                if (isRepeatMaterial) {
//                                    // material_hash 存在 并且已经上传过文件
//                                    Logger.e("----- 重复 material");
//                                    updateMaterialDoc(materialId, name);
//                                } else {
//                                    Logger.e("----- 新的 material");
//                                    setMaterialHashDoc(hash, storagePath, id, name);
//                                }
//                            }
//                        }, throwable -> {
//                            Logger.e("-**-*-*-*-*-*-*- 获取 material hash 失败: " + throwable.getMessage());
//                        })

//        );
    }


    public void upLoadVideoMinPicture(String materialId, String name, String hash, String
            selectFolderId, String folderName, Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 70, baos);
        byte[] data = baos.toByteArray();

        String path = "materials/" + creatorId + "/" + IDUtils.getId() + ".jpg";
        StorageReference ref = FirebaseStorage.getInstance().getReference().child(path);
        UploadTask uploadTask = ref.putBytes(data);
        uploadTask.continueWithTask(task -> {
            if (!task.isSuccessful()) {
                throw Objects.requireNonNull(task.getException());
            }
            return ref.getDownloadUrl();
        }).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                Logger.e("==minPictureUrl====上传成功");
                this.minPictureUrl = task.getResult().toString() + "";
                uploadNewMaterialToStorage(materialId, name, hash, selectFolderId, folderName);
            }
        }).addOnFailureListener(exception -> {
            uc.uploadProgress.setValue(-1);
            SLToast.showError();
            Logger.e("minPictureUrl上传失败:" + exception.getMessage());
        });
    }

    /**
     * 上传 material 到 storage
     *
     * @param materialId
     * @param name
     */
    public void uploadNewMaterialToStorage(String materialId, String name, String hash, String
            selectFolderId, String folderName) {
        storagePathOnline =
                "materials/" + creatorId + "/" + materialId + "." + localFileSuffixName;
        Logger.e("-**-*-*-*-*-*-*- storagePathOnline: " + storagePathOnline);
        Logger.e("-**-*-*-*-*-*-*- localPath: " + localPath);
        Logger.e("-**-*-*-*-*-*-*- 上传中 -*-*-*-*-*-*-*-*" + name);


        FirebaseStorage storage = FirebaseStorage.getInstance();
        StorageReference storageRef = storage.getReference();
        StorageReference spaceRef = storageRef.child(storagePathOnline);
        Uri file = Uri.fromFile(new File(localPath));
        UploadTask uploadTask = spaceRef.putFile(file);
        uploadTask.addOnProgressListener(snapshot -> {

            int progress = (int) ((double) snapshot.getBytesTransferred() / (double) snapshot.getTotalByteCount() * 100D);
            if (progress >= 90) {
                progress = 90;
            }
            uc.uploadProgress.setValue(progress);
        });
        uploadTask.continueWithTask(task -> {
            if (!task.isSuccessful()) {
                throw Objects.requireNonNull(task.getException());
            }
            return spaceRef.getDownloadUrl();
        }).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                Logger.e("======上传成功" + task.getResult().toString());
                this.downloadUrl = task.getResult().toString() + "";
                storagePathOnline = "/" + storagePathOnline;
                setMaterialHashDoc(hash, storagePathOnline, materialId, name, selectFolderId, folderName);
            }
        }).addOnFailureListener(exception -> {
            uc.uploadProgress.setValue(-1);
            SLToast.showError();
            Logger.e("上传失败:" + exception.getMessage());
        });

    }

    /**
     * 更新 material name
     *
     * @param id
     * @param name
     */
    public void updateMaterialName(String id, String name) {
        showDialog();
        Map<String, Object> map = new HashMap<>();
        map.put("name", name);

        Logger.e("---- 修改文件名：" + map.toString());

        addSubscribe(MaterialService
                .getInstance()
                .updateMaterialName(id, map, isFolderViewModel, folderEntity)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean -> {
                    dismissDialog();
                    Logger.e("-**-*-*-*-*-*-*- material rename 成功");
                }, throwable -> {
                    dismissDialog();
                    Logger.e("-----" + throwable.getMessage());
                }));
    }

    /**
     * 创建 hash 表
     *
     * @param hash
     * @param storagePathOnline
     * @param materialId
     * @param name
     */
    public void setMaterialHashDoc(String hash, String storagePathOnline, String
            materialId, String name, String selectFolderId, String folderName) {
        MaterialHashEntity materialHash = new MaterialHashEntity()
                .setHash(hash)
                .setPath(storagePathOnline)
                .setPictrueUrl("")
                .setType(materialType)
                .setUrl(downloadUrl);

        addSubscribe(MaterialService
                .getMaterialHashInstance()
                .createNewMaterialHash(materialHash)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean -> {
                    setNewMaterialDoc(materialId, name, selectFolderId, folderName);
                }, throwable -> {
                    Logger.e("-----" + throwable.getMessage());
                    uc.uploadProgress.setValue(-1);
                }));
    }

    /**
     * 上传完成后，新建 material document
     *
     * @param materialId
     * @param name
     */
    public void setNewMaterialDoc(String materialId, String name, String selectFolderId, String
            folderName) {
        String time = (System.currentTimeMillis() / 1000) + "";
        MaterialEntity material = new MaterialEntity()
                .setId(materialId)
                .setCreatorId(creatorId)
                .setType(materialType)
                .setName(name)
                .setDesc("")
                .setStoragePatch(storagePathOnline)
                .setSuffixName(localFileSuffixName)
                .setOpenType(0)
                .setStudentIds(new ArrayList<>())
                .setMinPictureUrl("")
                .setCreateTime(time)
                .setUpdateTime(time);
        if (materialType == 1) {
            material.setUrl(downloadUrl);
        } else if (materialType == 5) {
            material.setUrl(downloadUrl);
            material.setMinPictureUrl(minPictureUrl);
        } else if (materialType == 6 || materialType == 7) {
            material.setUrl(downloadUrl);
            material.setMinPictureUrl(minPictureUrl);
        } else {
            material.setUrl(downloadUrl);
        }

        Logger.e("======%s=%s", selectFolderId, folderName);

        addSubscribe(MaterialService
                .getInstance()
                .createNewMaterial(material, selectFolderId, folderName)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean ->

                {
                    stopLoading.setValue(true);
                    Logger.e("-**-*-*-*-*-*-*- material 新建成功");
                    uc.dismissDialog.call();
                    uc.uploadProgress.setValue(100);
                    // 重新获取 material 列表
                }, throwable ->

                {
                    Logger.e("-----" + throwable.getMessage());
                    uc.uploadProgress.setValue(-1);
                    stopLoading.setValue(false);
                }));
    }

    /**
     * 获取选中的 materialIds
     *
     * @param positions
     */
    public List<String> getSelectedMaterialIds(List<String> positions) {
        Logger.e("-**-*-*-*-*-*-*- positions: " + positions);
        List<String> materialIds = new ArrayList<>();
        for (int i = 0; i < positions.size(); i++) {
            int p = Integer.valueOf(positions.get(i));
            String id = materialDataList.get(p).getData().getId();
            materialIds.add(id);
        }
        Logger.e("-**-*-*-*-*-*-*- materialIds: " + materialIds);
        return materialIds;
    }

    public void deleteInFolderMaterials(MaterialEntity folder, List<String> ids) {
        Logger.e("======%s", ids);
        Logger.e("======%s", folder.getId());

        showDialog("Deleting...");
        addSubscribe(
                MaterialService
                        .getInstance()
                        .deleteInFolderMaterials(folder, ids)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(data -> {
                            dismissDialog();
                            boolean isDeleteAll = true;
                            for (MaterialEntity material : folder.getMaterials()) {
                                if (!ids.contains(material.getId())) {
                                    //判断是否要删除全部
                                    isDeleteAll = false;
                                }
                            }
                            if (isDeleteAll) {
                                uc.closeFolderView.call();
                            }


                        }, throwable -> {
                            Logger.e("失败,失败原因" + throwable.getMessage());
                            dismissDialog();
                            SLToast.showError();
                        })
        );

    }

    /**
     * 删除选中的 material
     *
     * @param materialIds
     */
    public void deleteMaterials(List<String> materialIds) {
//        DeleteMaterialParamEntity deleteMaterialParam = new DeleteMaterialParamEntity();
//        deleteMaterialParam.setCreatorId(creatorId);
//        deleteMaterialParam.setMaterialIds(materialIds);
//        showDialog("Deleting...");
//        CloudFunctions
//                .deleteMaterials(deleteMaterialParam)
//                .addOnCompleteListener(task -> {
//                    dismissDialog();
//                    if (task.isSuccessful()) {
//                        if (task.getResult() != null && task.getResult()) {
//                            Logger.e("====== 删除 material 成功:" + task.getResult());
//                            for (int i = 0; i < deleteMaterialParam.getMaterialIds().size(); i++) {
//                                deleteMaterialsFromStorage(deleteMaterialParam.getMaterialIds().get(i));
//                            }
//                            stopLoading.setValue(true);
//                        }
//                    } else {
//                        Logger.e("====== 删除 material 异常:" + task.getException().getMessage());
//                        stopLoading.setValue(false);
//                    }
//                    // 重新拉取 material
////                    materialsFragment.toggleSelectionStatus(true);
//                    selectedMaterials.clear();
//                });
        showDialog("Deleting...");
        addSubscribe(
                MaterialService.getInstance().deleteMaterials(materialIds)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe(d -> {
                            dismissDialog();
                            selectedMaterials.clear();
                            stopLoading.setValue(true);

                        }, throwable -> {
                            dismissDialog();
                            selectedMaterials.clear();
                            stopLoading.setValue(false);

                            Logger.e("失败,失败原因" + throwable.getMessage());
                        })
        );
    }

    /**
     * 删除 storage 中的 material
     *
     * @param materialId
     */
    public void deleteMaterialsFromStorage(String materialId) {
        addSubscribe(StorageUtils
                .deleteMaterialsFromStorage(materialId)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean -> {
                    Logger.e("-*-*-*-*-*-*-*-*-*-* 删除 storage 中的 material 成功");
                }, throwable -> {
                    Logger.e("-*-*-*-*-*-*-*-*-*-* 删除 storage 中的 material: " + throwable.getMessage());
                })
        );
    }

    public void addFolder(String name, String folderId, MoveFolderDialog.Builder moveDialog) {

        MaterialEntity material = new MaterialEntity()
                .setId(IDUtils.getId())
                .setCreatorId(creatorId)
                .setType(MaterialEntity.Type.folder)
                .setName(name)
                .setDesc("")
                .setOpenType(0)
                .setStudentIds(new ArrayList<>())
                .setCreateTime(TimeUtils.getCurrentTimeString())
                .setUpdateTime(TimeUtils.getCurrentTimeString());

        material.setFolder(folderId);
        showDialog();
        addSubscribe(MaterialService
                .getInstance()
                .createNewMaterial(material, "-1", "")
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean -> {
                    if (moveDialog != null) {
                        moveDialog.addFolderSuccess(material);
                    }
                    dismissDialog();
                }, throwable -> {
                    SLToast.showError();
                    Logger.e("????==>%s", throwable.getMessage());
                    dismissDialog();
                }));
    }

    public void moveMaterials(MoveFolderDialog.Builder moveFolderDialog, String toMaterialsId, List<MaterialEntity> materials) {
        List<String> materialIds = new ArrayList<>();
        for (MaterialEntity material : materials) {
            materialIds.add(material.getId());
        }
        showDialog();
        addSubscribe(MaterialService
                .getInstance()
                .shareMaterials(toMaterialsId, materialIds)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(aBoolean -> {
                    moveFolderDialog.dismiss();
                    dismissDialog();
                }, throwable -> {
                    SLToast.showError();
                    dismissDialog();
                }));
    }

    public void clickMore(MaterialEntity materialEntity) {
        uc.clickMore.setValue(materialEntity);

    }
    public void initFilterData() {
        MaterialsFilterData filterData = getMaterialsFilterData();
        boolean beforeIsListView = false;
        if (this.filterData!=null){
            beforeIsListView = this.filterData.isListView();
        }
        this.filterData = filterData;
        Logger.e("2allMaterialDataList==>%s",allMaterialDataList.size());
        allMaterialDataList.removeIf(materialsMultiItemViewModel -> materialsMultiItemViewModel.getData().getId().equals(""));

        if (beforeIsListView != filterData.isListView()) {
            ObservableList<MaterialsMultiItemViewModel> cloneData =new ObservableArrayList<>();
            cloneData.addAll(allMaterialDataList);
            allMaterialDataList.clear();
            for (MaterialsMultiItemViewModel materialsMultiItemViewModel : cloneData) {
                MaterialsMultiItemViewModel<StudentMaterialsViewModel> item;
                MaterialEntity material  = materialsMultiItemViewModel.getData();
                if (isListView) {
                    item = new MaterialsListViewModel<>(this, material);
                    item.setStudentData((List<StudentListEntity>) materialsMultiItemViewModel.sharedStudentData.get());
                    if (material.getType() == MaterialEntity.Type.folder) {
                        if (material.getCreatorId().equals(studentId)) {
                            ((MaterialsListViewModel) item).setHaveFile(allMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        } else {
                            ((MaterialsListViewModel) item).setHaveFile(teacherMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        }
                    }
                } else {
                    if (material.getType() == MaterialEntity.Type.folder) {
                        item = new MaterialsFolderViewModel<>(this, material);
                        item.setStudentData((List<StudentListEntity>) materialsMultiItemViewModel.sharedStudentData.get());
                        MaterialsFolderViewModel<StudentMaterialsViewModel> folderItem = (MaterialsFolderViewModel<StudentMaterialsViewModel>) item;
                        if (material.getCreatorId().equals(studentId)) {
                            folderItem.setHaveFile(allMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        } else {
                            folderItem.setHaveFile(teacherMaterialsData.stream().anyMatch(materialEntity -> materialEntity.getFolder().equals(material.getId())));
                        }

                    } else if (material.getType() == MaterialEntity.Type.youtube) {
                        item = new MaterialsLinkVMV2<>(this, material);
                        item.setStudentData((List<StudentListEntity>) materialsMultiItemViewModel.sharedStudentData.get());
                    } else {
                        item = new MaterialsGridVMV2<>(this, material);
                        item.setStudentData((List<StudentListEntity>) materialsMultiItemViewModel.sharedStudentData.get());
                    }
                }
                if (studentId!=null){
                    item.setNoSelfShowFrame(studentId);
                }
                item.isNotShowShare.set(true);
                item.isShowMoreButton.set(true);
                if (showType == ShowType.select) {
                    for (MaterialEntity selectedMaterial : selectedMaterials) {
                        if (selectedMaterial.getId().equals(material.getId())) {
                            item.isSelected.set(true);
                        }
                    }
                }
                allMaterialDataList.add(item);

            }
        }
//        if (filterData.isAscending()) {
//            if (filterData.isUpdateDate()) {
//                allMaterialDataList.sort((o1, o2) -> Integer.parseInt(o1.getData().getUpdateTime()) - Integer.parseInt(o2.getData().getUpdateTime()));
//            } else {
//                allMaterialDataList.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o1.getData().getName(), o2.getData().getName()));
//            }
//        } else {
//            if (filterData.isUpdateDate()) {
//                allMaterialDataList.sort((o1, o2) -> Integer.parseInt(o2.getData().getUpdateTime()) - Integer.parseInt(o1.getData().getUpdateTime()));
//            } else {
//                allMaterialDataList.sort((o1, o2) -> Collator.getInstance(Locale.UK).compare(o2.getData().getName(), o1.getData().getName()));
//            }
//        }
        Comparator<MaterialsMultiItemViewModel> comparator = filterData.isUpdateDate() ?
                Comparator.comparingInt(o -> Integer.parseInt(o.getData().getUpdateTime())) :
                Comparator.comparing(o -> o.getData().getName(), Collator.getInstance(Locale.UK));
        if (!filterData.isAscending()) {
            comparator = comparator.reversed();
        }
        allMaterialDataList.sort(comparator);
        Logger.e("allMaterialDataList==>%s",allMaterialDataList.size());
        if (filterData.isAutoGroup()) {
            String group = "";
            for (TKSelectView.TKSelectData tkSelectData : filterData.getAutoGroup()) {
                if (tkSelectData.isSelect()) {
                    group = tkSelectData.getId();
                    break;
                }
            }
            List<MaterialsMultiItemViewModel> day = groupAndInsertHeaders(this, group, allMaterialDataList);
            allMaterialDataList.clear();
            allMaterialDataList.addAll(day);
        }

        materialDataList.clear();
        materialDataList.addAll(allMaterialDataList);
    }

    @NonNull
    public MaterialsFilterData getMaterialsFilterData() {
        List<MaterialsFilterData> materialsFilter = SLCacheUtil.getMaterialsFilter();
        MaterialsFilterData filterData = new MaterialsFilterData();
        if (materialsFilter.size() != 0) {
            for (MaterialsFilterData materialsFilterData : materialsFilter) {
                if (folderEntity == null||folderEntity.getId().equals("")) {
                    if (materialsFilterData.getFolderId().equals("home")) {
                        filterData = materialsFilterData;
                    }
                } else {
                    if (materialsFilterData.getFolderId().equals(folderEntity.getId())) {
                        filterData = materialsFilterData;
                    }
                }
            }
            if (filterData.getFolderId().equals("")){
                for (MaterialsFilterData materialsFilterData : materialsFilter) {
                    if (materialsFilterData.getFolderId().equals("home")) {
                        filterData = materialsFilterData;
                    }
                }
            }
        } else {
            filterData.initData();
            filterData.setFolderId("home");
        }
        isListView = filterData.isListView();

        return filterData;
    }
}
