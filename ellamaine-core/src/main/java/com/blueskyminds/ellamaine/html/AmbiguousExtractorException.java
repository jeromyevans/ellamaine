package com.blueskyminds.ellamaine.html;

import org.apache.commons.lang.StringUtils;

import java.util.List;

/**
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class AmbiguousExtractorException extends Exception {

    private static final String DEFAULT_MESSAGE = "Unable to resolve which Extractor to use.  Multiple selectors match the document";

    public AmbiguousExtractorException(List<Selector> selectorsThatMatch) {
        this(DEFAULT_MESSAGE, selectorsThatMatch);
    }

    public AmbiguousExtractorException(String message, List<Selector> selectorsThatMatch) {
        super(message+" ("+ StringUtils.join(selectorsThatMatch.iterator(), ", "));
    }

    public AmbiguousExtractorException(String message, Throwable cause) {
        super(message, cause);
    }

    public AmbiguousExtractorException(Throwable cause) {
        super(cause);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AmbiguousExtractorException with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------
}
