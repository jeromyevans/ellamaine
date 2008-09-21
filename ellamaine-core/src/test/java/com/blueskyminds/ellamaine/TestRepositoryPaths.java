package com.blueskyminds.ellamaine;

import com.blueskyminds.ellamaine.repository.service.LocalRepositoryConfiguration;

import java.util.Properties;

import junit.framework.TestCase;

/**
 * Tests the lookup of repository paths to local a repository entry
 *
 * Date Started: 24/06/2007
 * <p/>
 * History:
 */
public class TestRepositoryPaths extends TestCase {


    public void testRepositoryPaths() {
        Properties p = new Properties();
        p.put("path.0-10000", "A:\\");
        p.put("path.10001-20000", "B:\\");
        p.put("path", "C:\\");

        LocalRepositoryConfiguration localRepositoryConfiguration = new LocalRepositoryConfiguration(p);
        localRepositoryConfiguration.setDefaultPath("D:\\");

        assertEquals("A:\\", localRepositoryConfiguration.getBasePath(0));
        assertEquals("A:\\", localRepositoryConfiguration.getBasePath(5000));
        assertEquals("A:\\", localRepositoryConfiguration.getBasePath(10000));
        assertEquals("B:\\", localRepositoryConfiguration.getBasePath(15000));
        assertEquals("B:\\", localRepositoryConfiguration.getBasePath(20000));
        assertEquals("C:\\", localRepositoryConfiguration.getBasePath(25000));
        assertEquals("C:\\", localRepositoryConfiguration.getBasePath(30000));
    }
}
