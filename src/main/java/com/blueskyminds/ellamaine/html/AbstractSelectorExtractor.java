package com.blueskyminds.ellamaine.html;

/**
 * Some standard functionality for a SelectorExtractor
 * 
 * Date Started: 30/05/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public abstract class AbstractSelectorExtractor<T> implements SelectorExtractor<T> {

    private Selector selector;

    protected AbstractSelectorExtractor() {
    }

    protected AbstractSelectorExtractor(Selector selector) {
        this.selector = selector;
    }

    public Selector getSelector() {
        return selector;
    }

    public void setSelector(Selector selector) {
        this.selector = selector;
    }

    /**
     * Evaluates whether the document from the given source matches this pattern or criteria
     *
     * @param source
     * @param document
     * @return
     */
    public boolean matches(String source, HTMLDocumentDecorator document) {
        if (selector != null) {
            return selector.matches(source, document);
        } else {
            return false;
        }
    }

}
