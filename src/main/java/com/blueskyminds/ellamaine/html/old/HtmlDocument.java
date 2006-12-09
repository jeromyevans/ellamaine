package com.blueskyminds.html.old;

import org.w3c.dom.Element;

import java.util.List;

import com.blueskyminds.html.old.Anchor;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlDocument extends HtmlNode<Element> {

    private HtmlElementDelegate htmlElement;

    public HtmlDocument(Element node) {
        super(node);
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the HtmlDocument with default attributes
     */
    private void init() {
        htmlElement = new HtmlElementDelegate((Element) node);
    }

    // ------------------------------------------------------------------------------------------------------


    public String getId() {
        return htmlElement.getId();
    }

    public String getCssClass() {
        return htmlElement.getCssClass();
    }

    public String getTextContent() {
        return htmlElement.getTextContent();
    }

    public List<Anchor> getAnchors() {
        return htmlElement.getAnchors();
    }
}
