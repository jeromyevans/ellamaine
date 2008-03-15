package com.blueskyminds.ellamaine.html.old;

import org.w3c.dom.Element;

import java.util.List;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlNode<N extends Element> implements HtmlElement {

    protected N node;
    private HtmlElementDelegate htmlElement;

    public HtmlNode(N node) {
        this.node = node;
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the HtmlNode with default attributes
     */
    private void init() {
        htmlElement = new HtmlElementDelegate(node);
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
