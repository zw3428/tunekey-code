package com.spelist.tunekey.ui.teacher.lessons.activity

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Message
import com.spelist.tools.custom.countDownView.CountDownInterface
import com.spelist.tunekey.R
import com.spelist.tunekey.databinding.ActivityLessonCountDownBinding
import com.spelist.tunekey.entity.LessonScheduleEntity
import com.spelist.tunekey.utils.MessengerUtils
import com.spelist.tunekey.utils.TimeUtils
import me.goldze.mvvmhabit.bus.Messenger
import java.util.*


class LessonCountDownActivity : Activity() {
    private lateinit var binding: ActivityLessonCountDownBinding;
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLessonCountDownBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.mainLayout.setOnClickListener {
            finish()
        }
        initData()
    }

    private fun initData() {
        val lessonScheduleEntity = intent.getSerializableExtra("data") as LessonScheduleEntity?
            ?: return
        val endTime =
            lessonScheduleEntity.tkShouldDateTime + lessonScheduleEntity.shouldTimeLength * 60
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.SECOND, (endTime - TimeUtils.getCurrentTime()).toInt()-1)
        binding.countDownView.startTimer(calendar)
        binding.currentTime.text = "Current time ${TimeUtils.timeFormat(TimeUtils.getCurrentTime().toLong(), "hh:mm aa")}"
        binding.endTimeTv.text = "End time ${TimeUtils.timeFormat(endTime, "hh:mm aa")}"

        binding.countDownView.setOnTick(object : CountDownInterface{
            override fun onTick(time: Long) {

            }

            override fun onFinish() {
                //倒计时结束
                finish()
            }
        })
        postHandler()
    }

    private fun postHandler() {

        Handler(Looper.getMainLooper()).postDelayed({ handler.sendEmptyMessage(1) },1000)

    }

    private val handler = object :Handler(Looper.getMainLooper()){
        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            binding.currentTime.text = "Current time ${TimeUtils.timeFormat(TimeUtils.getCurrentTime().toLong(), "hh:mm aa")}"
            postHandler()
        }
    }

    override fun finish() {
        super.finish()
        Messenger.getDefault().sendNoMsg(MessengerUtils.SHOW_COUNT_DOWN_VIEW)
        overridePendingTransition(R.anim.zoom_in, R.anim.zoom_out)

    }
}