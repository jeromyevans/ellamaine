package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;
import com.blueskyminds.framework.persistence.paging.Page;
import com.blueskyminds.framework.persistence.paging.Pager;

import java.io.InputStream;
import java.util.List;

/**
 * Accesses Ellamaine's advertisement repository
 *
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public interface RepositoryService extends Pager {

    /**
     * Get an input stream to the specified Repository entry
     *
     * @param repositoryEntryId
     * @return
     **/
    InputStream getInputStream(Integer repositoryEntryId) throws RepositoryServiceException;

    /**
     * Returns the content of the specified Repository entry
     *
     * @param repositoryEntryId
     * @return RepositoryContent containing all content of the entry
     **/
    RepositoryContent getContent(Integer repositoryEntryId) throws RepositoryServiceException;
    
    /**
     * Lookup a page of AdvertisementRepository entries
     **/
    Page findPage(int pageNo, int pageSize);

    /**
     * List entries created on the specified date
     *
     * @param year
     * @param month
     * @param day
     * @return
     */
    List<AdvertisementRepository> listByDate(int year, int month, int day);

}
