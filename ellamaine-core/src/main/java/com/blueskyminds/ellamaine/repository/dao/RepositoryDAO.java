package com.blueskyminds.ellamaine.repository.dao;

import com.blueskyminds.framework.persistence.jpa.dao.AbstractDAO;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;

import javax.persistence.EntityManager;
import javax.persistence.Query;
import java.util.List;

/**
 * The RepositoryDAO can be used to access entries in ellamaines Repository Database
 * The repository database provides an index to the entries in the repository
 *
 * Date Started: 11/06/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class RepositoryDAO extends AbstractDAO<AdvertisementRepository> {

    private static final String QUERY_BY_DATE_YEARMONTHDAY = "advertisementRepository.byYearMonthDay";

    public RepositoryDAO(EntityManager em) {
        super(em, AdvertisementRepository.class);
    }


    /** 
     * List AdvertisementRepository entries for the specified date
     * */
    public List<AdvertisementRepository> listByDate(int year, int month, int day) {
        Query query = em.createNamedQuery(QUERY_BY_DATE_YEARMONTHDAY);
        query.setParameter("year", year);
        query.setParameter("month", month);
        query.setParameter("day", day);
        return query.getResultList();

    }
}
