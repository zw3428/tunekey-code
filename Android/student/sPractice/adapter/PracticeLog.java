package com.spelist.tunekey.ui.student.sPractice.adapter;

public class PracticeLog {
    private String date;
    private String timeLength;

    public PracticeLog(String date, String timeLength) {
        this.date = date;
        this.timeLength = timeLength;
    }

    public String getDate() {
        return date;
    }

    public String getTimeLength() {
        return timeLength;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public void setTimeLength(String timeLength) {
        this.timeLength = timeLength;
    }
}
