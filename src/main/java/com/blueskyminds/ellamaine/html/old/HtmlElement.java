package com.blueskyminds.html.old;


import org.w3c.dom.Element;

import java.util.List;

import com.blueskyminds.html.old.Anchor;

/**
 * Wraps a DOM Element and provides methods to access common HTML attributes/properties
 * <p/>
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public interface HtmlElement {


    public String getId();

    String getCssClass();

    String getTextContent();

    List<Anchor> getAnchors();

}
