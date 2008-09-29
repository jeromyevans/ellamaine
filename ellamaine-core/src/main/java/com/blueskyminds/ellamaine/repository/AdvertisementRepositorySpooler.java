package com.blueskyminds.ellamaine.repository;

import com.blueskyminds.homebyfive.framework.core.persistence.paging.QueryPager;
import com.blueskyminds.homebyfive.framework.core.persistence.query.QueryFactory;
import com.blueskyminds.homebyfive.framework.core.persistence.spooler.EntitySpooler;
import com.blueskyminds.homebyfive.framework.core.persistence.spooler.SpoolerTask;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import javax.persistence.EntityManager;

/**
 * Spools entries from the AdvertisementRepository for processing
 *
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementRepositorySpooler extends EntitySpooler<AdvertisementRepository> {

    private static final Log LOG = LogFactory.getLog(AdvertisementRepositorySpooler.class);

    public AdvertisementRepositorySpooler(EntityManager entityManager, QueryPager pager, SpoolerTask<AdvertisementRepository> spoolerTask) {
        super(pager, QueryFactory.createFindAllQuery(entityManager, AdvertisementRepository.class), spoolerTask);
        init();
    }

    public AdvertisementRepositorySpooler(EntityManager entityManager, QueryPager pager) {
        super(pager, QueryFactory.createFindAllQuery(entityManager, AdvertisementRepository.class), null);
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AdvertisementRepositorySpooler with default attributes
     */
    private void init() {
        setPageSize(1000);
    }

    // ------------------------------------------------------------------------------------------------------

}