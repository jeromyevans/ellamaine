package com.blueskyminds.ellamaine.web.startup;

import com.google.inject.Inject;
import com.wideplay.warp.persist.PersistenceService;

/**
 *
 * Starts the persistence service when constructed
 *
 * Date Started: 17/03/2008
 * <p/>
 * History:
 */
public class PersistenceServiceInitializer {

    @Inject
    public PersistenceServiceInitializer(PersistenceService service) {
        service.start();
    }
}
