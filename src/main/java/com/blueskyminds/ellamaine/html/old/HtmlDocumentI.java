package com.blueskyminds.ellamaine.html.old;


import java.util.List;

/**
 * Wraps a DOM Document with methods to quickly access common html elements
 * <p/>
 * Date Started: 7/12/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public interface HtmlDocumentI {

    List<Anchor> getAnchors();
    List<Anchor> getAnchorsContaining(String pattern);
    Anchor getAnchorById(String id);
    List<Anchor> getAnchorsByClass(String cssClass);
    List<Anchor> getAnchorsByImageSrc(String src);
    Anchor getNextAnchor();

    // ------------------------------------------------------------------------------------------------------

    String getNextText();
    String getNextTextContaining(String pattern);
    String getNextTextAfterTag(String tagName);
    
    // ------------------------------------------------------------------------------------------------------

    List<Table> getTables();
    Table getNextTable();
    Table getTableById(String id);
    List<Table> getTablesByClass(String cssClass);

    // ------------------------------------------------------------------------------------------------------


    List<Frame> getFrames();
    boolean hasFrames();
    
    // ------------------------------------------------------------------------------------------------------

    Form getForm(String name);

    // ------------------------------------------------------------------------------------------------------

    String getContent();
}
