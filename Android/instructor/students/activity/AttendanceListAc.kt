package com.spelist.tunekey.ui.teacher.students.activity

import android.app.Application
import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.databinding.ViewDataBinding
import androidx.lifecycle.AndroidViewModel
import androidx.recyclerview.widget.LinearLayoutManager
import com.orhanobut.logger.Logger
import com.spelist.tools.viewModel.ToolbarViewModel
import com.spelist.tunekey.BR
import com.spelist.tunekey.R
import com.spelist.tunekey.api.network.TKApi
import com.spelist.tunekey.customView.SLToast
import com.spelist.tunekey.customView.dialog.ReportNoShowDialog
import com.spelist.tunekey.customView.sLBottomMenu.BottomMenuFragment
import com.spelist.tunekey.customView.sLBottomMenu.MenuItem
import com.spelist.tunekey.databinding.ActivityAttendanceListBinding
import com.spelist.tunekey.entity.LessonScheduleEntity
import com.spelist.tunekey.entity.LessonScheduleExEntity
import com.spelist.tunekey.entity.LessonScheduleExEntity.Type.EXCUSED
import com.spelist.tunekey.entity.LessonScheduleExEntity.Type.LATE
import com.spelist.tunekey.entity.LessonScheduleExEntity.Type.PRESENT
import com.spelist.tunekey.entity.LessonScheduleExEntity.Type.UNEXCUSED
import com.spelist.tunekey.ui.teacher.lessons.activity.LessonDetailsAc
import com.spelist.tunekey.utils.BaseRecyclerAdapter
import com.spelist.tunekey.utils.BaseRecyclerHolder
import com.spelist.tunekey.utils.TimeUtils
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import me.goldze.mvvmhabit.base.BaseActivity
import me.goldze.mvvmhabit.bus.event.SingleLiveEvent
import java.io.Serializable

class AttendanceListAc : BaseActivity<ActivityAttendanceListBinding, AttendanceListVM>() {
    private lateinit var adapter:BaseRecyclerAdapter<LessonScheduleEntity>
    override fun initContentView(savedInstanceState: Bundle?): Int {
        return R.layout.activity_attendance_list
    }

    override fun initVariableId(): Int {
        return BR.viewModel
    }

    override fun initView() {

        super.initView()
        try {
            viewModel.lessonScheduleEntities = intent.getSerializableExtra("data") as MutableList<LessonScheduleEntity>
        }catch (e:Throwable){
            Logger.e("==>%s",e.message);
        }
        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        val self = this
        adapter = object :BaseRecyclerAdapter<LessonScheduleEntity>(this, viewModel.lessonScheduleEntities,R.layout.item_attendance){
            override fun convert(
                    holder: BaseRecyclerHolder,
                    item: LessonScheduleEntity,
                    position: Int,
                    isScrolling: Boolean
            ) {
                holder.setText(R.id.monthTv,TimeUtils.timeFormat(item.tkShouldDateTime,"MMM"))
                holder.setText(R.id.dayTv,TimeUtils.timeFormat(item.tkShouldDateTime,"dd"))
                holder.setText(R.id.timeTv,TimeUtils.timeFormat(item.tkShouldDateTime,"EEE hh:mma"))
                val attendanceLayout = holder.getView<LinearLayout>(R.id.attendanceLayout)
                val normalTv = holder.getView<TextView>(R.id.normalTv)
                if (item.attendance.size==0){
                    normalTv.isVisible = true
                    attendanceLayout.isVisible = false
                }else{
                    normalTv.isVisible = false
                    attendanceLayout.isVisible = true
                    val typeTv = holder.getView<TextView>(R.id.typeTv)
                    val attendanceTimeTv = holder.getView<TextView>(R.id.attendanceTimeTv)
                    holder.setText(R.id.typeTv, item.attendance[0].typeString())
                    holder.setText(R.id.attendanceTimeTv,TimeUtils.timeFormat( item.attendance[0].createTime.toLong(),"hh:mma, MM/dd/yyyy"))
                    when (item.type) {
                        LessonScheduleExEntity.Type.PRESENT -> {
                            typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
                        }
                        LessonScheduleExEntity.Type.EXCUSED -> {
                            typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
                        }
                        LessonScheduleExEntity.Type.UNEXCUSED -> {
                            typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_red))
                        }
                        LessonScheduleExEntity.Type.LATE -> {
                            typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
                        }
                    }



//                    itRecyclerView.layoutManager = LinearLayoutManager(self)
//                    itRecyclerView.adapter = object:BaseRecyclerAdapter<LessonScheduleExEntity.LessonAttendanceEntity>(self,item.attendance,R.layout.item_attendance_type){
//                        override fun convert(
//                            holder: BaseRecyclerHolder,
//                            item: LessonScheduleExEntity.LessonAttendanceEntity,
//                            position: Int,
//                            isScrolling: Boolean
//                        ) {
//                            holder.setText(R.id.typeTv,item.typeString())
//                            holder.setText(R.id.timeTv,TimeUtils.timeFormat(item.createTime.toLong(),"hh:mma, MM/dd/yyyy"))
//                            val typeTv = holder.getView<TextView>(R.id.typeTv)
//                            when (item.type) {
//                                LessonScheduleExEntity.Type.PRESENT -> {
//                                    typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
//                                }
//                                LessonScheduleExEntity.Type.EXCUSED -> {
//                                    typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
//                                }
//                                LessonScheduleExEntity.Type.UNEXCUSED -> {
//                                    typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_red))
//                                }
//                                LessonScheduleExEntity.Type.LATE -> {
//                                    typeTv.setTextColor(ContextCompat.getColor(self,R.color.attendance_yellow))
//                                }
//                            }
//
//                        }
//
//                    }
                }

            }

        }
        binding.recyclerView.adapter = adapter
        adapter.setOnItemClickListener { parent, view, p ->

            val data = mutableListOf<LessonScheduleEntity>()
            data.add(viewModel.lessonScheduleEntities[p])
            val intent = Intent(this, LessonDetailsAc::class.java)
            intent.putExtra("data", data as Serializable)
//            intent.putExtra("nowLesson", viewModel!!.nowLesson as Serializable?)
            intent.putExtra("selectIndex", 0)
            intent.putExtra("selectTime", data[0].getShouldDateTime())
            startActivity(intent)

//            val bottomMenuFragment = BottomMenuFragment(this)
//            bottomMenuFragment.addMenuItems(MenuItem("No-Show"))
//            bottomMenuFragment.addMenuItems(MenuItem("Late"))
//            bottomMenuFragment.addMenuItems(MenuItem("Present"))
//            bottomMenuFragment.show()
//
//            bottomMenuFragment.setOnItemClickListener { menu_item: TextView, position: Int ->
//                when (menu_item.text) {
//                    "Present" -> {
//                        viewModel.retractLateAndPresent(p, viewModel.lessonScheduleEntities[p].getId(),"Present")
//                    }
//                    "Late" -> {
//                        viewModel.retractLateAndPresent(p, viewModel.lessonScheduleEntities[p].getId(),"Late")
//                    }
//                    "No-Show" -> {
//                        val dialog = ReportNoShowDialog(this)
//                        dialog.showDialog()
//                        dialog.clickConfirm = { s: String? ->
//                            viewModel.retractNoShow(p, viewModel.lessonScheduleEntities[p].getId(), viewModel.lessonScheduleEntities[p].getStudentId(),s)
//                        }
//                    }
//                }
//            }


        }
    }

    override fun initViewObservable() {
        super.initViewObservable()
        viewModel.uc.refreshData.observe(this){
            adapter.notifyItemChanged(it)
        }
    }

}
class AttendanceListVM(application: Application) :ToolbarViewModel<ViewDataBinding,AndroidViewModel>(
        application
){
    var lessonScheduleEntities = mutableListOf<LessonScheduleEntity>()
    var uc = UIClickObservable()
    class UIClickObservable {
        var refreshData = SingleLiveEvent<Int>()
    }
    override fun initToolbar() {
        setNormalToolbar("Lesson History")
    }
    fun retractNoShow(pos:Int,lessonId:String,studentId:String,note: String?) {
        showDialog()
        addSubscribe(
                TKApi.retractNoShow(note!!, lessonId,studentId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe({ d: Boolean? ->
                            dismissDialog()
                            SLToast.showSuccess()
                            val attendance = LessonScheduleExEntity.LessonAttendanceEntity ()
                            attendance.id= ""
                            attendance.type = UNEXCUSED
                            attendance.note = note
                            lessonScheduleEntities[pos].setAttendance(mutableListOf<LessonScheduleExEntity.LessonAttendanceEntity>(attendance))
                            uc.refreshData.postValue(pos)
//                            val attendanceS = StringBuilder()
//                            attendanceS.append("Attendance: ")
//                            attendanceS.append(note)
//                            attendanceString.set(attendanceS.toString() + " " + TimeUtils.timeFormat(TimeUtils.getCurrentTime().toLong(), "hh:mma, MM/dd/yyyy"))
//                            attendanceButtonString.set("Report Attendance")
//                            isShowAttendance.set(true)
//                            uc.attendanceDone.call()
//                            isHaveNoshow = true
                        }) { throwable: Throwable ->
                            dismissDialog()
                            SLToast.showError()
                            Logger.e("失败,失败原因" + throwable.message)
                        }
        )
    }

    fun retractLateAndPresent(pos:Int,lessonId:String,note: String?) {
        showDialog()
        addSubscribe(
                TKApi.retractLateAndPresent(note!!, lessonId)
                        .subscribeOn(Schedulers.io())
                        .observeOn(AndroidSchedulers.mainThread(), true)
                        .subscribe({ d: Boolean? ->
                            dismissDialog()
                            SLToast.showSuccess()
//                            Logger.e("selectData.getValue().getId()==>%s", selectData.getValue().getId())
                            val attendance = LessonScheduleExEntity.LessonAttendanceEntity ()
                            attendance.id= ""
                            attendance.type = if (note == "Present"){
                                PRESENT
                            }else{
                                LATE
                            }
                            attendance.note = note
                            lessonScheduleEntities[pos].setAttendance(mutableListOf<LessonScheduleExEntity.LessonAttendanceEntity>(attendance))
                            uc.refreshData.postValue(pos)
//                            attendanceString.set(attendanceS.toString() + " " + TimeUtils.timeFormat(TimeUtils.getCurrentTime().toLong(), "hh:mma, MM/dd/yyyy"))
//                            attendanceButtonString.set("Report Attendance")
//                            isShowAttendance.set(true)
//                            isHaveNoshow = true
                        }) { throwable: Throwable ->
//                            if (selectData.getValue().getAttendance().size > 0) {
//                                if (selectData.getValue().getAttendance().get(0).note == "Present") {
//                                    return@subscribe
//                                }
//                            }
                            dismissDialog()
                            SLToast.showError()
                            Logger.e("失败,失败原因" + throwable.message)
                        }
        )
    }
}