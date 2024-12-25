package com.spelist.tunekey.ui.teacher.lessons.activity

import android.app.Application
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.databinding.DataBindingUtil.setContentView
import androidx.databinding.ViewDataBinding
import androidx.lifecycle.AndroidViewModel
import com.spelist.tools.viewModel.ToolbarViewModel
import com.spelist.tunekey.BR
import com.spelist.tunekey.R
import com.spelist.tunekey.databinding.ActivityLessonDetailsHistoryBinding
import com.spelist.tunekey.databinding.ItemItemLessonHistoryBinding
import com.spelist.tunekey.databinding.ItemLessonHistoryBinding
import com.spelist.tunekey.utils.BaseViewBindingRecyclerAdapter
import com.spelist.tunekey.utils.BaseViewBindingRecyclerHolder
import com.spelist.tunekey.utils.TimeUtils
import me.goldze.mvvmhabit.base.BaseActivity
import me.goldze.mvvmhabit.bus.Messenger
import java.io.Serializable

class LessonDetailsHistoryAc : BaseActivity<ActivityLessonDetailsHistoryBinding, LessonDetailsHistoryVM>() {
    lateinit var adapter: BaseViewBindingRecyclerAdapter<LessonDetailsHistoryVM.Data>
    override fun initContentView(savedInstanceState: Bundle?): Int {
        return R.layout.activity_lesson_details_history
    }

    override fun initVariableId(): Int {
        return BR.viewModel
    }

    override fun initData() {
        super.initData()
        val data = intent.getSerializableExtra("data") as MutableList<LessonDetailsHistoryVM.Data>
        viewModel.type = intent.getStringExtra("type")!!
        data.sortByDescending { it.timeStamp }

        viewModel.data = data
//        viewModel.initData()
        adapter.refreshData(viewModel.data)

    }

    override fun initView() {
        binding.btSave.isEnabled = false
        binding.recyclerView.itemAnimator = null
        binding.recyclerView.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)
        adapter = object : BaseViewBindingRecyclerAdapter<LessonDetailsHistoryVM.Data>(this, viewModel.data, R.layout.item_lesson_history) {
            override fun convert(holder: BaseViewBindingRecyclerHolder, item: LessonDetailsHistoryVM.Data, position: Int, isScrolling: Boolean) {
                if (holder.binding !is ItemLessonHistoryBinding) {
                    return
                }
                val binding = holder.binding as ItemLessonHistoryBinding
                binding.tVTime.text = item.time
                binding.recyclerView.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this@LessonDetailsHistoryAc)
                binding.recyclerView.itemAnimator = null
                val adapter = object : BaseViewBindingRecyclerAdapter<LessonDetailsHistoryVM.Data.Content>(this@LessonDetailsHistoryAc, item.contentList, R.layout.item_item_lesson_history) {
                    override fun convert(holder: BaseViewBindingRecyclerHolder, item: LessonDetailsHistoryVM.Data.Content, position: Int, isScrolling: Boolean) {
                        if (holder.binding !is ItemItemLessonHistoryBinding) {
                            return
                        }
                        val binding = holder.binding as ItemItemLessonHistoryBinding
                        binding.tVContent.text = item.content
                        if (item.isSelect) {
                            binding.imageView.setImageResource(R.mipmap.check)
                        } else {
                            binding.imageView.setImageResource(R.mipmap.checkbox_off)
                        }
                    }
                }
                binding.recyclerView.adapter = adapter
                adapter.setOnItemClickListener { parent, view, position ->
                    item.contentList[position].isSelect = !item.contentList[position].isSelect
                    adapter.notifyDataSetChanged()
                    this@LessonDetailsHistoryAc.binding.btSave.isEnabled = getSelectData().size > 0
                }
            }
        }
        binding.recyclerView.adapter = adapter
        binding.btSave.setClickListener {
            Messenger.getDefault().send(getSelectData(),viewModel.type)
            finish()
        }
    }
    private fun getSelectData():MutableList<String>{
        val data = mutableListOf<String>()
        viewModel.data.forEach { it ->
            it.contentList.forEach {
                if (it.isSelect) {
                    data.add(it.content)
                }
            }
        }
        return data
    }
}

class LessonDetailsHistoryVM(application: Application) : ToolbarViewModel<ViewDataBinding, AndroidViewModel>(application) {
    var data = mutableListOf<Data>()
    //historyLessonPlan,historyNextLessonPlan,historyHomework
    var type = "historyLessonPlan"

    override fun initToolbar() {
       setNormalToolbar("History")
    }

    fun initData() {


    }

    class Data() : Serializable {
        var time = ""
        var timeStamp = 0

        var contentList = mutableListOf<Content>()

        class Content : Serializable {
            var content = ""
            var isSelect = false
        }
    }
}