package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.ellamaine.repository.service.LocalRepositoryPaths;

import java.util.Properties;

/**
 * Tests the lookup of repository paths to local a repository entry
 *
 * Date Started: 24/06/2007
 * <p/>
 * History:
 */
public class TestRepositoryPaths extends BaseTestCase {


    public void testRepositoryPaths() {
        Properties p = new Properties();
        p.put("path.0-10000", "A:\\");
        p.put("path.10001-20000", "B:\\");
        p.put("path", "C:\\");

        LocalRepositoryPaths localRepositoryPaths = new LocalRepositoryPaths(p, "D:\\");

        assertEquals("A:\\", localRepositoryPaths.getBasePath(0));
        assertEquals("A:\\", localRepositoryPaths.getBasePath(5000));
        assertEquals("A:\\", localRepositoryPaths.getBasePath(10000));
        assertEquals("B:\\", localRepositoryPaths.getBasePath(15000));
        assertEquals("B:\\", localRepositoryPaths.getBasePath(20000));
        assertEquals("C:\\", localRepositoryPaths.getBasePath(25000));
        assertEquals("C:\\", localRepositoryPaths.getBasePath(30000));
    }
}
