package com.blueskyminds.ellamaine.html.filters;

import org.w3c.dom.html.HTMLElement;
import com.blueskyminds.homebyfive.framework.core.tools.filters.Filter;

/**
 * A filter that accepts an HTMLElement with a specified attribute and value
 *
 * Date Started: 31/05/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AttrValueFilter implements Filter<HTMLElement> {

    private String attrName;
    private String attrValue;

    public AttrValueFilter(String attrName, String attrValue) {
        this.attrName = attrName;
        this.attrValue = attrValue;
    }

    /**
     * Accepts an HTMLElement with the specified attribute name and value (exact match)
     *
     * @param element   HTMLElement to check
     * @return true if the object is accepted by the filter
     */
    public boolean accept(HTMLElement element) {
        boolean accepted = false;

        if (element != null) {
            String attr = element.getAttribute(attrName);
            if (attr != null) {
                if (attr.equals(attrValue)) {
                    accepted = true;
                }
            }
        }
        return accepted;
    }
}
