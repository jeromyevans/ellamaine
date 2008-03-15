package com.blueskyminds.ellamaine.html;

/**
 * A simple selector that always returns true or false
 *
 * Date Started: 30/05/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class DefaultSelector implements Selector {

    private boolean result;

    public DefaultSelector(boolean result) {
        this.result = result;
    }

    public boolean matches(String source, HTMLDocumentDecorator document) {
        return result;
    }

}
