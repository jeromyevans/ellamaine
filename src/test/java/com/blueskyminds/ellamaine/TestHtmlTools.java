package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.framework.tools.ResourceLocator;
import com.blueskyminds.framework.tools.ResourceTools;
import com.blueskyminds.ellamaine.html.HtmlTools;
import org.cyberneko.html.parsers.DOMParser;
import org.cyberneko.html.filters.Writer;
import org.xml.sax.InputSource;
import org.w3c.dom.html.HTMLDocument;
import org.w3c.dom.html.HTMLElement;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xerces.xni.parser.XMLDocumentFilter;

import java.net.URL;

/**
 * Date Started: 31/05/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class TestHtmlTools extends BaseTestCase {

    private static final Log LOG = LogFactory.getLog(TestHtmlTools.class);

    public TestHtmlTools(String string) {
        super(string);
    }

     public void testPrintOutline() throws Exception {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml

        URL fileUrl = ResourceTools.toURL(ResourceLocator.locateResource("rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()));
        HTMLDocument document = (HTMLDocument) parser.getDocument();

        HTMLElement body = document.getBody();

        HtmlTools.printOutline(body);
    }

    public void testHasDescendant() throws Exception {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml

        URL fileUrl = ResourceTools.toURL(ResourceLocator.locateResource("rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()));
        HTMLDocument document = (HTMLDocument) parser.getDocument();

        HTMLElement body = document.getBody();

        HTMLElement headerDiv = HtmlTools.getFirstElementByTagAndAttribute(body, HtmlTools.DIV, "id", "header");
        assertTrue(HtmlTools.hasDescendant(body, headerDiv));

        HTMLElement anchor = HtmlTools.getFirstElementByTagName(body, HtmlTools.ANCHOR);
        assertTrue(HtmlTools.hasDescendant(headerDiv, anchor));

        HTMLElement content = HtmlTools.getFirstElementByTagAndAttribute(body, HtmlTools.DIV, HtmlTools.ID, "content");
        assertTrue(HtmlTools.hasDescendant(body, content));
        assertFalse(HtmlTools.hasDescendant(headerDiv, content));
    }

    public void testPruneBefore() throws Exception {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml

        URL fileUrl = ResourceTools.toURL(ResourceLocator.locateResource("rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()));
        HTMLDocument document = (HTMLDocument) parser.getDocument();

        HTMLElement body = document.getBody();
        // try to prune out all the nodes before the quickMenu div
        HTMLElement propertyDetails = HtmlTools.getFirstElementByTagAndAttribute(body, HtmlTools.DIV, HtmlTools.ID, "quickMenu");

        HtmlTools.printOutline(body);

        boolean pruned = HtmlTools.pruneBefore(body, propertyDetails);
        assertTrue(pruned);
        
        HtmlTools.printOutline(body);
    }

     public void testPruneAfter() throws Exception {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml

        URL fileUrl = ResourceTools.toURL(ResourceLocator.locateResource("rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()));
        HTMLDocument document = (HTMLDocument) parser.getDocument();

        HTMLElement body = document.getBody();
        // try to prune out all the nodes after the quickmenu div
        HTMLElement propertyDetails = HtmlTools.getFirstElementByTagAndAttribute(body, HtmlTools.DIV, HtmlTools.ID, "quickMenu");

        HtmlTools.printOutline(body);

        boolean pruned = HtmlTools.pruneAfter(body, propertyDetails, false);
        assertTrue(pruned);

        HtmlTools.printOutline(body);
    }
}
