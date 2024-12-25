package com.spelist.tunekey.ui.student.sLessons.activity

import android.app.Application
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.databinding.ObservableArrayList
import androidx.databinding.ObservableField
import androidx.databinding.ObservableList
import androidx.databinding.ViewDataBinding
import androidx.lifecycle.AndroidViewModel
import com.google.firebase.functions.FirebaseFunctions
import com.spelist.tools.viewModel.ToolbarViewModel
import com.spelist.tunekey.BR
import com.spelist.tunekey.R
import com.spelist.tunekey.api.ListenerService
import com.spelist.tunekey.app.TApplication
import com.spelist.tunekey.customView.SLToast
import com.spelist.tunekey.databinding.ActivityStudentAddLessonStatusListBinding
import com.spelist.tunekey.entity.TKStudentLessonConfigRequests
import com.spelist.tunekey.ui.credit.CreditListItemVM
import com.spelist.tunekey.ui.credit.CreditListVM
import com.spelist.tunekey.utils.TimeUtils
import com.spelist.tunekey.utils.showTwoButtonLeftRedDialog
import me.goldze.mvvmhabit.base.BaseActivity
import me.goldze.mvvmhabit.base.ItemViewModel
import me.goldze.mvvmhabit.binding.command.BindingCommand
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent
import me.tatarka.bindingcollectionadapter2.ItemBinding

class StudentAddLessonStatusListAc : BaseActivity<ActivityStudentAddLessonStatusListBinding, StudentAddLessonStatusListVM>() {


    override fun initContentView(savedInstanceState: Bundle?): Int {
        return R.layout.activity_student_add_lesson_status_list
    }

    override fun initVariableId(): Int {
        return BR.viewModel
    }

    override fun initView() {

        binding.recyclerView.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)

    }


    override fun initData() {
        super.initData()

        val data = intent.getSerializableExtra("data") as MutableList<TKStudentLessonConfigRequests>
        viewModel.initData(data)
    }

    override fun initViewObservable() {
        super.initViewObservable()
        viewModel.uc.clickCancel.observe(this) {
            showTwoButtonLeftRedDialog(this,"Cancel lesson?","The instructor hasn't confirmed your lesson yet. Are you sure you want to cancel? You can reapply after cancellation.","Cancel","Go back"){
                viewModel.cancel(it)
            }
        }
    }
}

class StudentAddLessonStatusListVM(application: Application) : ToolbarViewModel<ViewDataBinding, AndroidViewModel>(application) {
    lateinit var data: MutableList<TKStudentLessonConfigRequests>
    var observableList: ObservableList<StudentAddLessonStatusListItemVM> = ObservableArrayList()

    //RecyclerView多布局添加ItemBinding
    var itemBinding: ItemBinding<StudentAddLessonStatusListItemVM?> = ItemBinding.of { itemBinding: ItemBinding<*>, _: Int, _: StudentAddLessonStatusListItemVM? -> itemBinding[BR.viewModel] = R.layout.item_new_lesson }
    var uc = UIClickObservable()

    class UIClickObservable {
        var clickCancel = SingleLiveEvent<String>()
    }

    override fun initToolbar() {
        setNormalToolbar("New lesson")
    }

    fun initData(data: MutableList<TKStudentLessonConfigRequests>) {
        this.data = data
        val lessonMap = ListenerService.shared.studentData.lessonTypeData.associateBy { it.id }
        val teacherMap = ListenerService.shared.studentData.teacherDatas.associateBy { it.userId }

        data.forEach {
            it.config.lessonType = lessonMap[it.config.lessonTypeId]
            it.config.teacherName = teacherMap[it.config.teacherId]?.userData?.name
            observableList.add(StudentAddLessonStatusListItemVM(this, it))
        }
    }

    fun cancel(id: String) {
        showDialog()
        FirebaseFunctions.getInstance()
                .getHttpsCallable("scheduleService-studentCancelRequestedLesson")
                .call(mapOf("id" to id))
                .addOnCompleteListener {
                    dismissDialog()
                    if (it.exception == null){
                        observableList.remove(observableList.find { it.data!!.id == id })
                        SLToast.success("Cancel successfully!")
                    }else{
                        SLToast.showError()

                    }
                }
    }
}

class StudentAddLessonStatusListItemVM(viewModel: StudentAddLessonStatusListVM) : ItemViewModel<StudentAddLessonStatusListVM>(viewModel) {
    var data: TKStudentLessonConfigRequests? = null
    var day = ObservableField("")
    var month = ObservableField("")
    var time = ObservableField("")
    var info = ObservableField("")
    var from = ObservableField("")
    var status = ObservableField("")
    var statusColor = ObservableField(ContextCompat.getColor(TApplication.getInstance().baseContext, R.color.primary))

    constructor(viewModel: StudentAddLessonStatusListVM, data: TKStudentLessonConfigRequests) : this(viewModel) {
        this.data = data
        initData(data)
    }


    private fun initData(data: TKStudentLessonConfigRequests) {
        day.set(TimeUtils.timeFormat(data.config.startDateTime.toLong(), "d"))
        month.set(TimeUtils.timeFormat(data.config.startDateTime.toLong(), "MMM"))
        time.set(TimeUtils.timeFormat(data.config.startDateTime.toLong(), "EEE, hh:mm a"))
        var infoString = ""
        if (data.config.lessonType != null) {
            infoString = data.config.lessonType.name + ", "
        }
        infoString += data.config.lessonInfoStringByShare
        if (data.config.teacherName != "") {
            infoString += "\n" + data.config.teacherName
        }
        info.set(infoString)
        if (data.status == TKStudentLessonConfigRequests.Status.PENDING) {
            from.set("Pending")
        } else {
            from.set("")
        }
        status.set("Cancel")
        statusColor.set(ContextCompat.getColor(TApplication.getInstance().baseContext, R.color.main))
    }

    var onClickReschedule = BindingCommand { _: View? ->
//        creditData!!.updateHistory.sortByDescending { it.updateTimestamp }
//        if (creditData!!.updateHistory.size > 0) {
//            if (creditData!!.updateHistory[0].updateType == TKLessonCredit.UpdateType.create || creditData!!.updateHistory[0].updateType == TKLessonCredit.UpdateType.decline) {
//                viewModel.clickToReschedule(creditData!!)
//            }
//        }
        viewModel.uc.clickCancel.value = data!!.id

    }

}