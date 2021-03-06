package com.blueskyminds.ellamaine;

import com.blueskyminds.homebyfive.framework.core.tools.ResourceTools;
import com.blueskyminds.ellamaine.html.HtmlParser;
import com.blueskyminds.ellamaine.html.TextExtractor;

import java.net.URI;
import java.io.InputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import junit.framework.TestCase;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class TestHtmlParserBasic extends TestCase {

    private static final Log LOG = LogFactory.getLog(TestHtmlParserBasic.class);
    public TestHtmlParserBasic(String string) {
        super(string);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the TestHtmlParserBasic with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public void testHtmlParser() throws Exception {
        URI fileUrl = ResourceTools.locateResource("/rsearch1.htm");
        InputStream inputStream = ResourceTools.openStream(fileUrl);
        HtmlParser parser = new HtmlParser();
        parser.registerExtractor(new TextExtractor());
        String textContent = (String) parser.parseDocument("/rsearch1.htm", inputStream);
        assertNotNull(textContent);
        System.out.println(textContent);
    }


}
