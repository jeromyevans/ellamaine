package com.blueskyminds.ellamaine.html.old;

import java.util.List;

/**
 * Interface to access the Anchors contained in an HTML element
 * <p/>
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public interface ContainsAnchors {

    List<Anchor> getAnchors();
    List<Anchor> getAnchorsContaining(String pattern);
    Anchor getAnchorById(String id);
    List<Anchor> getAnchorsByClass(String cssClass);
    List<Anchor> getAnchorsByImageSrc(String src);
    Anchor getNextAnchor();
}
