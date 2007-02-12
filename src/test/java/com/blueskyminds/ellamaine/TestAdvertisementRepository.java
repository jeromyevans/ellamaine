package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.HypersonicTestCase;
import com.blueskyminds.framework.persistence.jdbc.PersistenceTools;
import com.blueskyminds.ellamaine.db.AdvertisementCacheFinder;
import com.blueskyminds.ellamaine.db.AdvertisementCacheEntry;
import com.blueskyminds.ellamaine.db.AdvertisementRepositoryFinder;
import com.blueskyminds.ellamaine.db.AdvertisementRepositoryEntry;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Date;

/**
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class TestAdvertisementRepository extends HypersonicTestCase {

    public TestAdvertisementRepository(String name) {
        super(name);
    }

    // ------------------------------------------------------------------------------------------------------

    public void testAdvertisementRepositoryFinder() throws Exception {
        Connection connection = getConnection();
        loadSampleData(connection);
        AdvertisementRepositoryFinder finder = new AdvertisementRepositoryFinder(connection);

        AdvertisementRepositoryEntry entry = finder.findById(2);

        assertNotNull(entry);
        assertEquals(2, (int) entry.getId());

        connection.close();
    }

    private void loadSampleData(Connection connection) throws SQLException {

        PersistenceTools.executeUpdate(connection, AdvertisementRepositoryFinder.CREATE_STATEMENT);

        AdvertisementRepositoryEntry entry1 = new AdvertisementRepositoryEntry(1, new Date(), "http://localhost/1.html");
        entry1.insert(connection);
        assertNotNull(entry1.getId());
        AdvertisementRepositoryEntry entry2 = new AdvertisementRepositoryEntry(2, new Date(), "http://localhost/3.html");
        entry2.insert(connection);
        assertNotNull(entry2.getId());
        AdvertisementRepositoryEntry entry3 = new AdvertisementRepositoryEntry(3, new Date(), "http://localhost/2.html");
        entry3.insert(connection);
        assertNotNull(entry3.getId());
        AdvertisementRepositoryEntry entry4 = new AdvertisementRepositoryEntry(4, new Date(), "http://localhost/4.html");
        entry4.insert(connection);
        assertNotNull(entry4.getId());
    }

    // ------------------------------------------------------------------------------------------------------
}
