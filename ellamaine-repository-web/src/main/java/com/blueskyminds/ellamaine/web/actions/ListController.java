package com.blueskyminds.ellamaine.web.actions;

import com.opensymphony.xwork2.ActionSupport;
import com.opensymphony.xwork2.ModelDriven;
import com.blueskyminds.homebyfive.framework.core.persistence.paging.Page;
import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;
import com.google.inject.Inject;
import com.wideplay.warp.persist.Transactional;
import com.wideplay.warp.persist.TransactionType;
import org.apache.struts2.rest.HttpHeaders;
import org.apache.struts2.rest.DefaultHttpHeaders;
import org.apache.commons.collections.map.LinkedMap;

import java.util.List;
import java.util.Calendar;
import java.util.LinkedList;

/**
 * List advertisements entered on a specified date
 *
 * Date Started: 21/08/2008
 * <p/>
 * Copyright (c) 2008 Blue Sky Minds Pty Ltd
 */
public class ListController extends ActionSupport implements ModelDriven<List<AdvertisementRepository>> {

    private RepositoryService repositoryService;

    private List<AdvertisementRepository> page;
    private int year;
    private int month;
    private int day;

    public void setYear(int year) {
        this.year = year;
    }

    public void setMonth(int month) {
        this.month = month;
    }

    public void setDay(int day) {
        this.day = day;
    }

    public int getYear() {
        return year;
    }

    public int getMonth() {
        return month;
    }

    public int getDay() {
        return day;
    }

    @Transactional(type = TransactionType.READ_ONLY)
    public HttpHeaders index() {

        if (year <= 2004) {
            year = 2004;
        }
        
        page = repositoryService.listByDate(year, month, day);        

        return new DefaultHttpHeaders("index");
    }

    public List<AdvertisementRepository> getModel() {
        return page;
    }

    public List<String> getYears() {
        List<String> years = new LinkedList<String>();
        Calendar now = Calendar.getInstance();
        int endYear = now.get(Calendar.YEAR);
        for (int year = 2004; year <= endYear; year++) {
            years.add(Integer.toString(year));
        }
        return years;
    }

    public List<String> getMonths() {
        List<String> months = new LinkedList<String>();
        for (int month = 1; month <= 12; month++) {
            months.add(Integer.toString(month));
        }
        return months;
    }

    public List<String> getDays() {
        List<String> days = new LinkedList<String>();
        for (int day = 1; day <= 31; day++) {
            days.add(Integer.toString(day));
        }
        return days;
    }

    @Inject
    public void setRepositoryService(RepositoryService repositoryService) {
        this.repositoryService = repositoryService;
    }
}
