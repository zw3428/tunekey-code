package com.spelist.tunekey.ui.teacher.lessons.adapter;

public class DialogLessonTypeData {
    private String title;
    private String id;
    private String imgUrl;
    private int type; // 0: group, 1: private
    private String price;
    private int timeLength;

    public void setTitle(String title) {
        this.title = title;
    }

    public void setImgUrl(String imgUrl) {
        this.imgUrl = imgUrl;
    }

    public void setPrice(String price) {
        this.price = price;
    }

    public void setTimeLength(int timeLength) {
        this.timeLength = timeLength;
    }

    public void setType(int type) {
        this.type = type;
    }

    public int getTimeLength() {
        return timeLength;
    }

    public String getType() {
        if (type == 0){
            return "Group";
        }else if(type == 1) {
            return "Private";
        }
        return "";
    }

    public String getImgUrl() {
        return imgUrl;
    }

    public String getTitle() {
        return title;
    }

    public String getPrice() {
        return price;
    }

    public String getId() {
        return id;
    }

    public DialogLessonTypeData setId(String id) {
        this.id = id;
        return this;
    }
}
