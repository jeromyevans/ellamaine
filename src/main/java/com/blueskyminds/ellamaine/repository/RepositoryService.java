package com.blueskyminds.ellamaine.repository;

import com.blueskyminds.framework.persistence.PersistenceService;

import java.io.InputStream;

/**
 * Accesses Ellamaine's advertisement repository
 *
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public interface RepositoryService {

//    /**
//     * Create a spooler for paging entries from the AdvertisementRepository
//     *
//     * @param spoolerListener
//     * @return
//     */
//    AdvertisementRepositorySpooler createSpooler(SpoolerListener<AdvertisementRepository> spoolerListener);

    /**
     * Get the PersistenceService used to access the AdvertisementRepository
     * @return
     */
    PersistenceService getPersistenceService();

    /**
     * Get an input stream to the specified Repository entry
     *
     * @param repositoryEntryId
     * @return
     **/
    InputStream getInputStream(Integer repositoryEntryId) throws RepositoryServiceException ;
}