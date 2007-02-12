package com.blueskyminds.ellamaine;

import com.blueskyminds.framework.test.BaseTestCase;
import com.blueskyminds.framework.test.DbTestCase;
import com.blueskyminds.framework.test.HypersonicTestCase;
import com.blueskyminds.framework.persistence.jdbc.PersistenceTools;
import com.blueskyminds.ellamaine.db.AdvertisementCacheFinder;
import com.blueskyminds.ellamaine.db.AdvertisementCacheEntry;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.SQLException;
import java.util.Date;

/**
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class TestAdvertisementCache extends HypersonicTestCase {

    public TestAdvertisementCache(String name) {
        super(name);
    }

    // ------------------------------------------------------------------------------------------------------

    public void testAdvertisementCacheFinder() throws Exception {
        Connection connection = getConnection();
        loadSampleData(connection);
        AdvertisementCacheFinder finder = new AdvertisementCacheFinder(connection);

        AdvertisementCacheEntry entry = finder.findById(2);

        assertNotNull(entry);
        assertEquals(2, (int) entry.getId());

        connection.close();
    }

    private void loadSampleData(Connection connection) throws SQLException {

        PersistenceTools.executeUpdate(connection, AdvertisementCacheFinder.CREATE_STATEMENT);

        AdvertisementCacheEntry entry1 = new AdvertisementCacheEntry(1, new Date(), 0, "Test", "AAA", "Test 1", null);
        entry1.insert(connection);
        assertNotNull(entry1.getId());
        AdvertisementCacheEntry entry2 = new AdvertisementCacheEntry(2, new Date(), 1, "Test1", "AAB", "Test 2", null);
        entry2.insert(connection);
        assertNotNull(entry2.getId());
        AdvertisementCacheEntry entry3 = new AdvertisementCacheEntry(3, new Date(), 1, "Test2", "AAC", "Test 3", null);
        entry3.insert(connection);
        assertNotNull(entry3.getId());
        AdvertisementCacheEntry entry4 = new AdvertisementCacheEntry(4, new Date(), 0, "Test3", "AAD", "Test 4", null);
        entry4.insert(connection);
        assertNotNull(entry4.getId());
    }
}
