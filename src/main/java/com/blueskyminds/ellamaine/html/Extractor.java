package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;

import java.net.URL;

/**
 * An Extractor is used to extract content from an HTMLDocument
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public interface Extractor<T> {

    // ------------------------------------------------------------------------------------------------------   
    // ------------------------------------------------------------------------------------------------------

    /**
     * Evaluate whether this extractor supports the specified document
     *
     * @param source - a string identifying the orgin (eg. a url)
     * @param document
     * @return enumeration of the Extractor that supports the given document, otherwise null
     */
    public Enum isSupported(String source, HTMLDocumentDecorator document);

    // ------------------------------------------------------------------------------------------------------

    /** Extract the content from the HTMLDocument
     *
     * @param version, as specifed by isSupported
     * @param source
     * @param document
     * @return the extracted object graph
     */
    T extractContent(Enum version, String source, HTMLDocumentDecorator document);
}
