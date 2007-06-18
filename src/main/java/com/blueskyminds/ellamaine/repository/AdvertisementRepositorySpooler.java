package com.blueskyminds.ellamaine.repository;

import com.blueskyminds.framework.persistence.spooler.DomainObjectSpooler;
import com.blueskyminds.framework.persistence.spooler.SpoolerTask;
import com.blueskyminds.framework.persistence.spooler.SpoolerException;
import com.blueskyminds.framework.persistence.PersistenceServiceException;
import com.blueskyminds.framework.persistence.query.QueryFactory;
import com.blueskyminds.framework.persistence.paging.QueryPager;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import javax.persistence.EntityManager;
import java.util.List;

/**
 * Spools entries from the AdvertisementRepository for processing
 *
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementRepositorySpooler extends DomainObjectSpooler<AdvertisementRepository> {

    private static final Log LOG = LogFactory.getLog(AdvertisementRepositorySpooler.class);

    private SpoolerTask<AdvertisementRepository> spoolerTask;

//    public AdvertisementRepositorySpooler(EntityManager entityManager, Pager pager, Query query) {
//        super(entityManager, pager, AdvertisementRepository.class, query);
//        init();
//    }

    public AdvertisementRepositorySpooler(EntityManager entityManager, QueryPager pager, SpoolerTask<AdvertisementRepository> spoolerTask) {
        super(entityManager, pager, QueryFactory.createFindAllQuery(entityManager, AdvertisementRepository.class));
        this.spoolerTask = spoolerTask;
        init();
    }

    public AdvertisementRepositorySpooler(EntityManager entityManager, QueryPager pager) {
        super(entityManager, pager, QueryFactory.createFindAllQuery(entityManager, AdvertisementRepository.class));
        this.spoolerTask = null;
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the ExtractorLogSpooler with default attributes
     */
    private void init() {
        setPageSize(1000);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Process the collection of domain objects that have been paged out of persistence
     * The persistence session is open
     */
    protected void process(List<AdvertisementRepository> queryResults) throws SpoolerException {
        try {
            if (spoolerTask != null) {
                spoolerTask.process(queryResults);
            }
        } catch(PersistenceServiceException e) {
            throw new SpoolerException("Failed while processing a page of AdvertisementRepository entries", e);
        }
    }

}