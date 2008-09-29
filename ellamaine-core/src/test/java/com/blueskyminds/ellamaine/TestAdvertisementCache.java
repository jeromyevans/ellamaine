package com.blueskyminds.ellamaine;

import com.blueskyminds.homebyfive.framework.core.persistence.jdbc.PersistenceTools;
import com.blueskyminds.ellamaine.db.AdvertisementCacheFinder;
import com.blueskyminds.ellamaine.db.AdvertisementCacheEntry;
import com.blueskyminds.ellamaine.db.AdvertisementRepositoryFinder;
import com.blueskyminds.ellamaine.db.AdvertisementRepositoryEntry;

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

        PersistenceTools.executeUpdate(connection, AdvertisementCacheFinder.createStatement());
        PersistenceTools.executeUpdate(connection, AdvertisementRepositoryFinder.createStatement());

        AdvertisementCacheEntry entry1 = new AdvertisementCacheEntry(1, new Date(), new Date(), 0, "Test", "AAA", "Test 1", null);
        entry1.insert(connection);
        assertNotNull(entry1.getId());
        AdvertisementCacheEntry entry2 = new AdvertisementCacheEntry(2, new Date(), new Date(), 1, "Test1", "AAB", "Test 2", null);
        entry2.insert(connection);
        assertNotNull(entry2.getId());
        AdvertisementCacheEntry entry3 = new AdvertisementCacheEntry(3, new Date(), new Date(), 1, "Test2", "AAC", "Test 3", null);
        entry3.insert(connection);
        assertNotNull(entry3.getId());
        AdvertisementCacheEntry entry4 = new AdvertisementCacheEntry(4, new Date(), new Date(), 0, "Test3", "AAD", "Test 4", null);
        entry4.insert(connection);
        assertNotNull(entry4.getId());
    }

    private void loadSampleDataWithRepository(Connection connection) throws SQLException {

        PersistenceTools.executeUpdate(connection, AdvertisementCacheFinder.createStatement());
        PersistenceTools.executeUpdate(connection, AdvertisementRepositoryFinder.createStatement());

        AdvertisementRepositoryEntry repoEntry1 = new AdvertisementRepositoryEntry(1, new Date(), "http://localhost/1.html");
        repoEntry1.insert(connection);
        assertNotNull(repoEntry1.getId());
        AdvertisementRepositoryEntry repoEntry2 = new AdvertisementRepositoryEntry(2, new Date(), "http://localhost/3.html");
        repoEntry2.insert(connection);
        assertNotNull(repoEntry2.getId());
        AdvertisementRepositoryEntry repoEntry3 = new AdvertisementRepositoryEntry(3, new Date(), "http://localhost/2.html");
        repoEntry3.insert(connection);
        assertNotNull(repoEntry3.getId());
        AdvertisementRepositoryEntry repoEntry4 = new AdvertisementRepositoryEntry(4, new Date(), "http://localhost/4.html");
        repoEntry4.insert(connection);
        assertNotNull(repoEntry4.getId());

        AdvertisementCacheEntry entry1 = new AdvertisementCacheEntry(1, new Date(), new Date(), 0, "Test", "AAA", "Test 1", repoEntry1);
        entry1.insert(connection);
        assertNotNull(entry1.getId());
        AdvertisementCacheEntry entry2 = new AdvertisementCacheEntry(2, new Date(), new Date(), 1, "Test1", "AAB", "Test 2", repoEntry2);
        entry2.insert(connection);
        assertNotNull(entry2.getId());
        AdvertisementCacheEntry entry3 = new AdvertisementCacheEntry(3, new Date(), new Date(), 1, "Test2", "AAC", "Test 3", repoEntry3);
        entry3.insert(connection);
        assertNotNull(entry3.getId());
        AdvertisementCacheEntry entry4 = new AdvertisementCacheEntry(4, new Date(), new Date(), 0, "Test3", "AAD", "Test 4", repoEntry4);
        entry4.insert(connection);
        assertNotNull(entry4.getId());
    }

    public void testAdvertisementCacheFinderWithRepositiory() throws Exception {
       Connection connection = getConnection();
       loadSampleDataWithRepository(connection);
       AdvertisementCacheFinder finder = new AdvertisementCacheFinder(connection);

       AdvertisementCacheEntry entry = finder.findById(2);

       assertNotNull(entry);
       assertEquals(2, (int) entry.getId());
       assertNotNull(entry.getRepositoryEntry());
       assertEquals(2, (int) entry.getRepositoryEntry().getId());
       connection.close();
   }

}
