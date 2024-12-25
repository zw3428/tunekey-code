package com.spelist.tunekey.ui.teacher.materials.item

import android.app.Application
import android.view.View
import androidx.core.content.ContextCompat
import androidx.databinding.ObservableField
import com.orhanobut.logger.Logger
import com.spelist.tunekey.entity.MaterialEntity
import com.spelist.tunekey.entity.StudentListEntity
import com.spelist.tunekey.ui.student.sMaterials.vm.StudentMaterialsViewModel
import com.spelist.tunekey.ui.studio.material.materialHome.StudioMaterialHomeVM
import com.spelist.tunekey.ui.studio.team.teamHome.student.detail.StudioStudentDetailVM
import com.spelist.tunekey.ui.teacher.lessons.vm.LessonDetailsVM
import com.spelist.tunekey.ui.teacher.materials.fragments.MaterialsViewModel
import com.spelist.tunekey.ui.teacher.students.vm.StudentDetailV2VM
import com.spelist.tunekey.utils.TimeUtils
import me.goldze.mvvmhabit.base.BaseViewModel
import me.goldze.mvvmhabit.binding.command.BindingAction
import me.goldze.mvvmhabit.binding.command.BindingCommand
import me.goldze.mvvmhabit.binding.command.BindingConsumer


/**
 * com.spelist.tunekey.ui.materials.item
 * 2020/12/24
 *
 * @author wu.haitao ,Created on {DATE}
 * Major Function：****
 * @author mender，Modified Date Modify Content:
 */
class MaterialsListViewModel<VM : BaseViewModel<*, *>?>(viewModel: VM, data: MaterialEntity) : MaterialsMultiItemViewModel<VM>(viewModel, data) {
    private var mType = 0
    var lessonDetailsVM: LessonDetailsVM? = null
    var studentMaterialsViewModel: StudentMaterialsViewModel? = null
    var studioStudentDetailVM: StudioStudentDetailVM? = null
    var materialsViewModel: MaterialsViewModel? = null
    var studentVM: StudentDetailV2VM? = null
    var studioMaterialVM: StudioMaterialHomeVM? = null


    var picBgVisibility = ObservableField(false)
    var showImgUrl = ObservableField("")
    var showScaleType = ObservableField(6)

    /**
     * material type img
     */
    var typeImg = ObservableField(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.ic_launcher))

    /**
     * 分类图片是否显示, default: 8
     */
    var typeImgVisibility = ObservableField(false)



    override fun setStudentData(sharedStudentData: List<StudentListEntity>) {
        this.sharedStudentData.set(sharedStudentData)
        for (i in sharedStudentData.indices) {
            when (i) {
                0 -> {
                    sharedStudent1.set(sharedStudentData[i])
                }
                1 -> {
                    sharedStudent2.set(sharedStudentData[i])
                }
                2 -> {
                    sharedStudent3.set(sharedStudentData[i])
                }
            }
        }
    }

    /**
     * 设置不是自己显示边框
     */
//    override fun setNoSelfShowFrame(userId: String) {
//        if (viewModel is StudentMaterialsViewModel) {
//            val viewModel = viewModel as StudentMaterialsViewModel
//            val studioColor = viewModel.studioColor
//            studentFrame.value = studioColor
//        }
//        isNotSelfFrame.set(data.getCreatorId() != userId)
//    }

    //    public MaterialsListViewModel(@NonNull VM viewModel, MaterialEntity data) {
    //        super(viewModel);
    //        this.materialData.set(data);
    //    }
    override fun getData(): MaterialEntity {
        return materialData.get()!!
    }

    var clickShare: BindingCommand<*> = BindingCommand<Any?>(BindingAction {
        if (viewModel is MaterialsViewModel) {
            val mVM = viewModel as MaterialsViewModel
            mVM.clickItemShare(materialData.get())
        }
        if (viewModel is StudioMaterialHomeVM) {
            val mVM = viewModel as StudioMaterialHomeVM
            mVM.clickItemShare(materialData.get())
        }
    })
    var clickTitle: BindingCommand<*> = BindingCommand<Any?>(BindingAction {
        if (viewModel is MaterialsViewModel) {
            val mVM = viewModel as MaterialsViewModel
            mVM.clickItemTitle(materialData.get())
        } else if (viewModel is StudentMaterialsViewModel) {
            val mVM = viewModel as StudentMaterialsViewModel
            mVM.clickItemTitle(materialData.get())
        } else if (viewModel is StudioMaterialHomeVM) {
            val mVM = viewModel as StudioMaterialHomeVM
            mVM.clickItemTitle(materialData.get())
        }
    })
    var clickMore: BindingCommand<*> = BindingCommand<Any?>(BindingAction {
        if (viewModel is MaterialsViewModel) {
            val mVM = viewModel as MaterialsViewModel
            mVM.clickMore(materialData.get())
        }
        if (viewModel is StudioMaterialHomeVM) {
            val mVM = viewModel as StudioMaterialHomeVM
            mVM.clickMore(materialData.get())
        }
        if (viewModel is StudentMaterialsViewModel) {
            val mVM = viewModel as StudentMaterialsViewModel
            mVM.clickMore(materialData.get())
        }
    })

    //    private Class<VM> clazz;
    //
    //    public ObservableField<MaterialEntity> materialData = new ObservableField<MaterialEntity>(new MaterialEntity());
    //
    //    public ObservableField<Boolean> isShowPlayButton = new ObservableField<>(false);
    //
    //    public ObservableField<String> timeString = new ObservableField<>("");
    //
    //    public ObservableField<List<StudentListEntity>> sharedStudentData = new ObservableField<>(new ArrayList<>());
    //
    //    public ObservableField<StudentListEntity> sharedStudent1 = new ObservableField<>(new StudentListEntity());
    //    public ObservableField<StudentListEntity> sharedStudent2 = new ObservableField<>(new StudentListEntity());
    //    public ObservableField<StudentListEntity> sharedStudent3 = new ObservableField<>(new StudentListEntity());
    //    public ObservableField<Boolean> isSelected = new ObservableField<>(false);
    //    public ObservableField<Boolean> isDontAllSelected = new ObservableField<>(false);
    //
    //    //是否正在拖拽中 ,拖拽中的不显示title 等
    //    public ObservableField<Boolean> isDragging = new ObservableField<>(false);
    //    public ObservableField<Boolean> isNotShowShare = new ObservableField<>(false);
    //
    //    //是否显示拖拽选中绿框
    //    public ObservableField<Boolean> dragIsVisible = new ObservableField<>(false);
    //    //显示add,stop,透明
    //    public ObservableField<Drawable> typeDrawable = new ObservableField<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.mipmap.transparent));
    //
    //    //是否显示不是自己创建的边框
    //    public ObservableField<Boolean> isNotSelfFrame = new ObservableField<>(false);
    //    public MutableLiveData<Drawable> studentFrame = new MutableLiveData<>(ContextCompat.getDrawable(TApplication.getInstance().getApplicationContext(), R.drawable.student_material_frame_main));
    //    public ObservableField<Boolean> isShowMoreButton = new ObservableField<>(true);
    init {
        timeString.set(TimeUtils.getStrOfTimeTillNow(data.getCreateTime()))
//        when (data.getType()) {
//            -2, -1, 0, 1, 2, 3, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7 -> isShowPlayButton.set(false)
//            4, 6, 5 -> isShowPlayButton.set(true)
//        }
        mType = data.getType()
        if (viewModel is MaterialsViewModel) {
            this.materialsViewModel = viewModel
        }
        if (viewModel is StudioMaterialHomeVM) {
            this.studioMaterialVM = viewModel as StudioMaterialHomeVM
        }
        if (viewModel is StudentDetailV2VM) {
            this.studentVM = viewModel as StudentDetailV2VM
        }
        if (viewModel is StudioStudentDetailVM) {
            this.studioStudentDetailVM = viewModel as StudioStudentDetailVM
        }
        if (viewModel is LessonDetailsVM) {
            this.lessonDetailsVM = viewModel as LessonDetailsVM
        }
        if (viewModel is StudentMaterialsViewModel) {
            this.studentMaterialsViewModel = viewModel as StudentMaterialsViewModel
        }
        showScaleType.set(6)
        when (mType) {
            -2 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.folder_empty))
            }

            0 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_other_file))
            }

            1 -> {
                setGridMaterialItemDisplay(true, true)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_jpg))
                showImgUrl.set(data.getUrl())
            }

            5 -> {
                setGridMaterialItemDisplay(true, true)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_video))
                showImgUrl.set(data.getMinPictureUrl())
            }
            6 -> {
                setGridMaterialItemDisplay(true, true)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_video))
                showImgUrl.set(data.getMinPictureUrl())
            }
            2 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_ppt))
            }

            3 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_doc))
            }

            4 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.img_mp3))
            }

            7 -> {
                showScaleType.set(3)
                if (data.getMinPictureUrl() == "") {
                    setGridMaterialItemDisplay(true, false)
                } else {
                    setGridMaterialItemDisplay(true, true)
                }
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_link))
                showImgUrl.set(data.getMinPictureUrl())
            }

            8 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_txt))
            }

            9 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_pdf))
            }

            10 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_excel))
            }

            11 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_pages))
            }

            12 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_numbers))
            }

            13 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_keynotes))
            }

            14 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_docs))
            }

            15 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_sheets))
            }

            16 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_slides))
            }

            17 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_forms))
            }

            18 -> {
                setGridMaterialItemDisplay(true, false)
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication(), com.spelist.tunekey.R.mipmap.img_drawing))
            }
        }
    }

    /**
     * 设置 material item 显示
     *
     * @param typeImg
     * @param picBg
     */
    private fun setGridMaterialItemDisplay(typeImg: Boolean, picBg: Boolean) {
        typeImgVisibility.set(typeImg)
        picBgVisibility.set(picBg)
    }
    fun setHaveFile(isHave: Boolean) {
        setGridMaterialItemDisplay(true, false)
        if (isHave) {
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.folder))
            } else {
                this.typeImg.set(ContextCompat.getDrawable(viewModel!!.getApplication<Application>(), com.spelist.tunekey.R.mipmap.folder_empty))
            }

    }

    // 条目的点击事件
    var clickItem = BindingCommand<View>(BindingConsumer<View> {
        var view = it
        if (mType == 1) {
            view = view.findViewById<View>(com.spelist.tunekey.R.id.material_item_bg)
        }
        if (materialsViewModel != null) {
            materialsViewModel!!.clickItem(materialData.get(), view)
        }
        if (studioMaterialVM != null) {
            studioMaterialVM!!.clickItem(materialData.get(), view)
        }
        if (studentVM != null) {
            studentVM!!.clickItem(materialData.get(), view)
        }
        if (studioStudentDetailVM != null) {
            studioStudentDetailVM!!.clickItem(materialData.get(), view)
        }
        if (lessonDetailsVM != null) {
            lessonDetailsVM!!.clickMaterialsItem(materialData.get(), view)
        }
        if (studentMaterialsViewModel != null) {
            isNotShowShare.set(true)
            isShowMoreButton.set(false)
            studentMaterialsViewModel!!.clickItem(materialData.get(), view)
        }
    })

    var selectItem = BindingCommand(object : BindingConsumer<View> {
        override fun call(t: View) {
            isSelected.set(!isSelected.get()!!)
            if (materialsViewModel != null) {
                materialsViewModel!!.updateSelectedMaterials(isSelected.get(), materialData.get())
            }
            if (studioMaterialVM != null) {
                studioMaterialVM!!.updateSelectedMaterials(isSelected.get(), materialData.get())
            }
            if (studentMaterialsViewModel != null) {
                studentMaterialsViewModel!!.updateSelectedMaterials(isSelected.get(), materialData.get())
            }
        }
    })
}