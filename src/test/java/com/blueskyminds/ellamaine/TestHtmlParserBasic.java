package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.tools.ResourceLocator;
import com.blueskyminds.ellamaine.html.HtmlParser;
import com.blueskyminds.ellamaine.html.TextExtractor;
import java.net.URL;
import java.io.InputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class TestHtmlParserBasic extends BaseTestCase {

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
        URL fileUrl = ResourceLocator.locateResource("rsearch1.htm");
        InputStream inputStream = fileUrl.openStream();
        HtmlParser parser = new HtmlParser();
        parser.registerExtractor(new TextExtractor());
        String textContent = (String) parser.parseDocument("rsearch1.htm", inputStream);
        assertNotNull(textContent);
        System.out.println(textContent);
    }


}
