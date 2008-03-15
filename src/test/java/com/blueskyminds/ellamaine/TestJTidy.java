package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.framework.tools.ResourceTools;
import com.blueskyminds.framework.tools.ResourceTools;
import org.w3c.tidy.Tidy;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import java.io.*;
import java.net.URL;

/**
 * Test use of the JTidy library
 *
 * Date Started: 26/11/2006
 * <p/>
 * History:
 * <p/>
 * ---[ Blue Sky Minds Pty Ltd ]------------------------------------------------------------------------------
 */
public class TestJTidy extends BaseTestCase {

    public TestJTidy(String string) {
        super(string);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the TestJTidy with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public void testJTidySetup() throws Exception {
        Tidy tidy = new Tidy();

        URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("rsearch1.htm"));

        tidy.parse(fileUrl.openStream(), System.out);
    }

    // ------------------------------------------------------------------------------------------------------

    public void testJTidyDOM() throws Exception {
        Tidy tidy = new Tidy();
        tidy.setShowWarnings(false);
        tidy.setQuiet(true);        
        URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("rsearch1.htm"));

        Document document = tidy.parseDOM(fileUrl.openStream(), System.out);
        assertNotNull(document);
        Element element = document.getElementById("searchStats");
        assertNotNull(element);
    }


    public void testStreamToXerces() throws Exception {
        final Tidy tidy = new Tidy();

        tidy.setShowWarnings(false);
        final URL fileUrl = ResourceTools.toURL(ResourceTools.locateResource("rsearch1.htm"));

        final PipedInputStream intoXerces = new PipedInputStream();
        final PipedOutputStream out = new PipedOutputStream(intoXerces);
        new Thread(
            new Runnable() {
                public void run() {
                    try {
                        tidy.parse(fileUrl.openStream(),  out);
                    } catch (IOException e) {
                        //
                    }
                }
            }
        ).start();


        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document document = builder.parse(intoXerces);

        assertNotNull(document);
    }
        
}
