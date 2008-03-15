package com.blueskyminds.ellamaine.html.old;

import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;

import java.util.List;
import java.util.LinkedList;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlElementDelegate implements HtmlElement {

    private Element node;

    private static final String ANCHOR = "a";
    private static final String ID = "id";
    private static final String CSS_CLASS = "class";

    public HtmlElementDelegate(Element node) {
        this.node = node;
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the HtmlElementDelegate with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public String getId() {
        return node.getAttribute(ID);
    }

    public String getCssClass() {
        return node.getAttribute(CSS_CLASS);
    }

    public String getTextContent() {
        return node.getTextContent();
    }

    // ------------------------------------------------------------------------------------------------------

    public List<Anchor> getAnchors() {
        List<Anchor> anchorList = new LinkedList<Anchor>();

        NodeList anchors = node.getElementsByTagName(ANCHOR);
        for (int index = 0; index < anchors.getLength(); index++) {
            Node node = anchors.item(index);
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                anchorList.add(new Anchor((Element) node));
            }
        }
        return anchorList;
    }
}
