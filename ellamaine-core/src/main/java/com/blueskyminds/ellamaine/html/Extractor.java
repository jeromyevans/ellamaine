package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;

import java.net.URL;

/**
 * An Extractor is used to extract content from an HTMLDocument.
 *
 * The content can be an object graph, not just a string (eg. a bean)
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public interface Extractor<T> {

    /**
     * Extract the content from the HTMLDocument
     *
     * @param source
     * @param document
     * @return the extracted object graph
     */
    T extractContent(String source, HTMLDocumentDecorator document);
}
