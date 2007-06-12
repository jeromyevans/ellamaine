package com.blueskyminds.ellamaine.html.old;

import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.apache.xerces.dom.ElementImpl;

/**
 * Specialisation of an Element
 *
 * Date Started: 7/12/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public class Anchor extends ElementImpl implements Element {

    private Element element;

    private static final String HREF = "href";
    
    public Anchor(Element element) {
        this.element = element;        
    }

    public String getHref() {
        return element.getAttribute(HREF);
    }

}
