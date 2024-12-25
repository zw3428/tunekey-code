package com.spelist.tunekey.ui.teacher.lessons.activity

import android.app.Application
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.core.view.isVisible
import androidx.databinding.DataBindingUtil.setContentView
import androidx.databinding.ViewDataBinding
import androidx.lifecycle.AndroidViewModel
import com.spelist.tools.viewModel.ToolbarViewModel
import com.spelist.tunekey.BR
import com.spelist.tunekey.R
import com.spelist.tunekey.databinding.ActivityLessonDetailsNoteBinding
import com.spelist.tunekey.entity.LessonScheduleEntity
import com.spelist.tunekey.utils.CloneObjectUtils
import com.spelist.tunekey.utils.log
import com.spelist.tunekey.utils.showSmallTwoButtonDialog
import me.goldze.mvvmhabit.base.BaseActivity
import me.goldze.mvvmhabit.base.BaseViewModel
import me.goldze.mvvmhabit.bus.Messenger

class LessonDetailsNoteAc : BaseActivity<ActivityLessonDetailsNoteBinding, LessonDetailsNoteVM>() {

    override fun initContentView(savedInstanceState: Bundle?): Int {
        return R.layout.activity_lesson_details_note
    }

    override fun initVariableId(): Int {
        return BR.viewModel
    }

    override fun initView() {
        super.initView()
        binding.privateNoteItem.switchButton.setOnToggleChanged {
            "onToggleChanged $it".log()
            viewModel.isEnablePrivateNote = it
            binding.privateNoteEt.isVisible = viewModel.isEnablePrivateNote
        }
        binding.saveButton.setClickListener {
            var isShowDialog = !viewModel.isEnablePrivateNote && binding.privateNoteEt.text.toString() != ""

            if (viewModel.isEnablePrivateNote) {
                viewModel.data.teacherToParentNote = binding.privateNoteEt.text.toString()
            } else {
                viewModel.data.teacherToParentNote = ""
            }
            viewModel.data.teacherNote = binding.noteEt.text.toString()
            if (isShowDialog){
                showSmallTwoButtonDialog(this,"Disable Parent’s Private Note?","Disabling and saving will permanently delete the existing private note. Proceed?","Disable & Save","Cancel"){
                    viewModel.save()
                }
            }else{
                viewModel.save()
            }
        }
    }

    override fun initData() {
        super.initData()
        viewModel.data = CloneObjectUtils.cloneObject(intent.getSerializableExtra("data") as LessonScheduleEntity)

        binding.noteEt.setText(viewModel.data.teacherNote)
        binding.privateNoteEt.setText(viewModel.data.teacherToParentNote)

        viewModel.isEnablePrivateNote = viewModel.data.teacherToParentNote != ""

        binding.privateNoteEt.isVisible = viewModel.isEnablePrivateNote
        binding.privateNoteItem.setSwitchButton( viewModel.isEnablePrivateNote)

    }
}

class LessonDetailsNoteVM(application: Application) : ToolbarViewModel<ViewDataBinding, AndroidViewModel>(application) {
    var data = LessonScheduleEntity()
    var isEnablePrivateNote = false
    override fun initToolbar() {
        setNormalToolbar("Notes")
    }
    fun save(){
        Messenger.getDefault().send(data,"updateLessonNote")
        finish()
    }

}