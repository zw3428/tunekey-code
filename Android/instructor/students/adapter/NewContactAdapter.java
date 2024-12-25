package com.spelist.tunekey.ui.teacher.students.adapter;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.spelist.tunekey.ui.teacher.students.fragments.NewContactFragment;

import java.util.List;

public class NewContactAdapter extends FragmentPagerAdapter{
    private List<NewContactFragment> fragments;//ViewPager要填充的fragment列表


    public NewContactAdapter(@NonNull FragmentManager fm, List<NewContactFragment> fragments) {
        super(fm);
        this.fragments = fragments;
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        //获得position中的fragment来填充
        return fragments.get(position);
    }

    @Override
    public int getCount() {
        return fragments.size();
    }
}
