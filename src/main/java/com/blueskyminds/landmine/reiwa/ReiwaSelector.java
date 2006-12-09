package com.blueskyminds.landmine.reiwa;

import com.blueskyminds.ellamaine.html.Selector;
import com.blueskyminds.ellamaine.html.HTMLDocumentDecorator;

/**
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class ReiwaSelector implements Selector {

    private static final String REIWA_URL = "reiwa";

    public boolean matches(String sourceUrl, HTMLDocumentDecorator document) {
        return sourceUrl.contains(REIWA_URL);
    }

    // ------------------------------------------------------------------------------------------------------
}
