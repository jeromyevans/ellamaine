package com.blueskyminds.ellamaine.repository.dao;

import com.blueskyminds.framework.persistence.jpa.dao.AbstractDAO;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;

import javax.persistence.EntityManager;

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

    public RepositoryDAO(EntityManager em) {
        super(em, AdvertisementRepository.class);
    }
    
}
