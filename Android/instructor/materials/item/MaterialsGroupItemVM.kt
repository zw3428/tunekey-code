package com.spelist.tunekey.ui.teacher.materials.item

import androidx.databinding.ObservableField
import com.spelist.tunekey.entity.MaterialEntity
import me.goldze.mvvmhabit.base.BaseViewModel
import me.goldze.mvvmhabit.base.ItemViewModel

/**
 *   com.spelist.tunekey.ui.teacher.materials.item
 *   2024/4/15
 * @author Created on {DATE}
 * 		   Major Function：<b></b>
 * @author mender，Modified Date Modify Content:
 */
open class MaterialsGroupItemVM<VM : BaseViewModel<*, *>?>(viewModel: VM, data: MaterialEntity, title: String, fileSize: String) : MaterialsMultiItemViewModel<VM>(viewModel, data) {
    val titleString = ObservableField("")
    val fileSizeString = ObservableField("")

    init {
        titleString.set(title)
        fileSizeString.set("$fileSize files")
    }
}