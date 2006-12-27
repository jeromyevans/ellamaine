package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.tools.Configuration;
import com.blueskyminds.ellamaine.html.HtmlParser;
import com.blueskyminds.ellamaine.html.TextExtractor;
import com.blueskyminds.landmine.reiwa.ReiwaExtractor;
import com.blueskyminds.landmine.advertisement.PropertyAdvertisementBean;

import java.net.URL;
import java.io.InputStream;

/**
 * Date Started: 8/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class TestHtmlParser extends BaseTestCase {
   
    public TestHtmlParser(String string) {
        super(string);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the TestHtmlParser with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public void testHtmlParser() throws Exception {
        URL fileUrl = Configuration.locateResource("rsearch1.htm");
        InputStream inputStream = fileUrl.openStream();
        HtmlParser parser = new HtmlParser();
        parser.registerExtractor(new TextExtractor());
        String textContent = (String) parser.parseDocument("rsearch1.htm", inputStream);
        assertNotNull(textContent);
        System.out.println(textContent);
    }

    // ------------------------------------------------------------------------------------------------------

    public void testHtmlParser2() throws Exception {
        HtmlParser parser = new HtmlParser();
        parser.registerExtractor(new ReiwaExtractor());

        InputStream inputStream = Configuration.locateResource("16670.html").openStream();        
        PropertyAdvertisementBean advertisement1 = (PropertyAdvertisementBean) parser.parseDocument("http://public.reiwa.com.au/res/searchdetails.cfm?CurrentRow=2&SD=", inputStream);
        inputStream = Configuration.locateResource("16671.html").openStream();
        PropertyAdvertisementBean advertisement2 = (PropertyAdvertisementBean) parser.parseDocument("http://public.reiwa.com.au/res/searchdetails.cfm?CurrentRow=2&SD=", inputStream);
        inputStream = Configuration.locateResource("16672.html").openStream();
        PropertyAdvertisementBean advertisement3 = (PropertyAdvertisementBean) parser.parseDocument("http://public.reiwa.com.au/res/searchdetails.cfm?CurrentRow=2&SD=", inputStream);
        inputStream = Configuration.locateResource("16673.html").openStream();
        PropertyAdvertisementBean advertisement4 = (PropertyAdvertisementBean) parser.parseDocument("http://public.reiwa.com.au/res/searchdetails.cfm?CurrentRow=2&SD=", inputStream);
        inputStream = Configuration.locateResource("16674.html").openStream();
        PropertyAdvertisementBean advertisement5 = (PropertyAdvertisementBean) parser.parseDocument("http://public.reiwa.com.au/res/searchdetails.cfm?CurrentRow=2&SD=", inputStream);

        assertNotNull(advertisement1);
    }
}
