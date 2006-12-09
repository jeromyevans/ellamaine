package com.blueskyminds.ellamaine.html;

/**
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class AmbiguousExtractorException extends Exception {

    private static final String DEFAULT_MESSAGE = "Unable to resolve which Extractor to use.  Multiple extractors support the document";

    public AmbiguousExtractorException(Extractor extractor1, Enum version1, Extractor extractor2, Enum version2) {
        this(DEFAULT_MESSAGE, extractor1, version1, extractor2, version2);
    }

    public AmbiguousExtractorException(String message, Extractor extractor1, Enum version1, Extractor extractor2, Enum version2) {
        super(message+" ("+extractor1.getClass().getSimpleName()+" Version "+version1+","+extractor2.getClass().getSimpleName()+" Version "+version2+")");
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
