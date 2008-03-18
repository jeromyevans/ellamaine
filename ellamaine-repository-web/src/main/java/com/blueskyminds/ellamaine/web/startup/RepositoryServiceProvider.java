package com.blueskyminds.ellamaine.web.startup;

import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.ellamaine.repository.service.LocalRepositoryService;
import com.google.inject.Inject;
import com.google.inject.Provider;

import javax.persistence.EntityManager;

/**
 * Date Started: 15/03/2008
 * <p/>
 * History:
 */
public class RepositoryServiceProvider implements Provider<RepositoryService> {

    private Provider<EntityManager> em;

    public RepositoryService get() {
        return new LocalRepositoryService(em.get());
    }

    @Inject
    public void setEm(Provider<EntityManager> em) {
        this.em = em;
    }
}
