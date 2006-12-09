package com.blueskyminds.landmine.reiwa;

import com.blueskyminds.ellamaine.html.Selector;
import com.blueskyminds.ellamaine.html.HTMLDocumentDecorator;

/**
 * Identifies a legacy REIWA webpage
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class ReiwaLegacySelector implements Selector {

    private static final String SEARCH_DETAILS_PATTERN = "searchdetails.cfm";
    private static final String SUBURB_PROFILE_PATTERN = "Suburb Profile";
    private static final String SAVE_PATTERN = "Save";
    private static final String PRINT_PATTERN = "Print";
    private static final String MAP_PATTERN = "Map";

    // ------------------------------------------------------------------------------------------------------

    public boolean matches(String sourceUrl, HTMLDocumentDecorator document) {
        if ((sourceUrl.contains(SEARCH_DETAILS_PATTERN)) && (document.containsText(SAVE_PATTERN))) {
            if (document.containsAnyText(SUBURB_PROFILE_PATTERN, PRINT_PATTERN, MAP_PATTERN)) {
                return true;
            }
        }
        return false;
    }


    // ------------------------------------------------------------------------------------------------------
}
