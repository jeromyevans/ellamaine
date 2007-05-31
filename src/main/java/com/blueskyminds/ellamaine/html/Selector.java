package com.blueskyminds.ellamaine.html;

/**
 * A selector determines whether an HTMLDocument matches a pattern or some other criteria.
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public interface Selector {

    /**
     * Evaluates whether the document from the given source matches this pattern or criteria
     *
     * @param source
     * @param document
     * @return
     */
    boolean matches(String source, HTMLDocumentDecorator document);
}
