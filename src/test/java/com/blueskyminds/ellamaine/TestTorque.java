package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.tools.ResourceLocator;
import org.apache.torque.Torque;
import org.apache.commons.configuration.Configuration;
import org.apache.commons.configuration.BaseConfiguration;
import org.apache.commons.configuration.PropertiesConfiguration;

/**
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class TestTorque extends BaseTestCase {

    public TestTorque(String string) {
        super(string);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the TestTorque with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    public void testInit() throws Exception {
        // setup an in-memory configuration 
        Configuration configuration = new PropertiesConfiguration(ResourceLocator.locateResource("torque/torque-gen-hsql.properties"));

        Torque.init(configuration);

    }
}
