package com.blueskyminds.ellamaine;

import junit.framework.TestCase;
import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.ellamaine.repository.service.RepositoryServiceClient;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.framework.persistence.paging.Page;

/**
 * Date Started: 16/03/2008
 * <p/>
 * History:
 */
public class TestRepositoryServiceClient extends TestCase {

    private RepositoryService repositoryService;

    /**
     * Sets up the fixture, for example, open a network connection.
     * This method is called before a test is executed.
     */
    @Override
    protected void setUp() throws Exception {
        super.setUp();

        repositoryService = new RepositoryServiceClient("http://clyde.blueskyminds-fw.com.au");
    }

    // todo: this needs to setup a mock service

    public void testReadContent() throws Exception {
        RepositoryContent content = repositoryService.getContent(1);
        assertNotNull(content);
    }

    public void testReadPage() throws Exception {
        Page page = repositoryService.findPage(0, 10);
        assertNotNull(page);
        assertEquals(10, page.getPageSize());
    }
}
