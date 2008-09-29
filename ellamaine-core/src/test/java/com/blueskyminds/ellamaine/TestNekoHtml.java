package com.blueskyminds.ellamaine;

import com.blueskyminds.homebyfive.framework.core.tools.ResourceTools;
import org.cyberneko.html.parsers.DOMParser;
import org.cyberneko.html.parsers.DOMFragmentParser;
import org.w3c.dom.*;
import org.w3c.dom.html.HTMLDocument;
import org.w3c.dom.html.HTMLCollection;
import org.xml.sax.InputSource;
import org.apache.html.dom.HTMLDocumentImpl;

import java.net.URL;

import junit.framework.TestCase;

/**
 * NekoHTML is a Xerces Native Interface plugin for Xerces2 (an html parser)
 *
 * Date Started: 5/12/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public class TestNekoHtml extends TestCase {

    public TestNekoHtml(String string) {
        super(string);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the TestNekoHtml with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public void testNekoXerces2() throws Exception {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml

        URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("/rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()));
        HTMLDocument document = (HTMLDocument) parser.getDocument();
        assertNotNull(document);
         Element element = document.getElementById("searchStats");
        assertNotNull(element);

        NodeList tableNodes = document.getElementsByTagName("table");
        for (int index = 0; index < tableNodes.getLength(); index++) {
            Node node = tableNodes.item(index);
            if (node.getNodeType() == Node.ELEMENT_NODE) {
                NodeList tableRows = ((Element) node).getElementsByTagName("tr");
                assertNotNull(tableRows);
            }
        }

        NodeList anchorList = document.getElementsByTagName("a");
        assertNotNull(anchorList);

        HTMLCollection anchors = document.getAnchors();
        assertNotNull(anchors);
        
        assertNotNull(document.getBody().getTextContent());
    }

    public void testNeckoHtmlDocument() throws Exception {
        DOMFragmentParser parser = new DOMFragmentParser();
        HTMLDocument document = new HTMLDocumentImpl();
         
        DocumentFragment fragment = document.createDocumentFragment();
        URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("/rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()), fragment);

        assertNotNull(fragment);
//        Element element = ((Element) fragment).getElementById("searchStats");
//        assertNotNull(element);

        //assertTrue(fragment.getAnchors().getLength() != 0);
    }

    public void testHTMLDOMFragment() throws Exception {
        DOMFragmentParser parser = new DOMFragmentParser();
        HTMLDocument document = new HTMLDocumentImpl();

        DocumentFragment fragment = document.createDocumentFragment();
        URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("/rsearch1.htm"));
        parser.parse(new InputSource(fileUrl.openStream()), fragment);
        print(fragment, "");
    }

    public void print(Node node, String indent) {
        System.out.println(indent+node.getClass().getName());
        Node child = node.getFirstChild();
        while (child != null) {
            print(child, indent+" ");
            child = child.getNextSibling();
        }
    }
}

