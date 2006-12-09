package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;

/**
 * Determine if a document matches
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public interface Selector {

    boolean matches(String source, HTMLDocumentDecorator document);
}
