package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.ellamaine.repository.RepositoryServiceException;

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

    /**
     * Get an input stream to the specified Repository entry
     *
     * @param repositoryEntryId
     * @return
     **/
    InputStream getInputStream(Integer repositoryEntryId) throws RepositoryServiceException;
}
