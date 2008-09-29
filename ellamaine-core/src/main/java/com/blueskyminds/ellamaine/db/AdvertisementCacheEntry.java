package com.blueskyminds.ellamaine.db;

import com.blueskyminds.homebyfive.framework.core.persistence.jdbc.PersistenceTools;

import java.util.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Connection;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * An Entry in the AdvertisementCache
 *
 * Implements Row Data Gateway (PoEAA)
 *
 * This class is used for READING from the Ellamaine AdvertisementCache
 *
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementCacheEntry {

    private static final Log LOG = LogFactory.getLog(AdvertisementCacheEntry.class);

    private Integer id;
    private Date dateEntered;
    private Date lastEncountered;
    private int saleOrRentalFlag;
    private String sourceName;
    private String sourceId;
    private String titleString;
    private AdvertisementRepositoryEntry repositoryEntry;

    /** Create a new entry */
    public AdvertisementCacheEntry(Integer id, Date dateEntered, Date lastEncountered, int saleOrRentalFlag, String sourceName, String sourceId, String titleString, AdvertisementRepositoryEntry repositoryEntry) {
        this.id = id;
        this.dateEntered = dateEntered;
        this.lastEncountered = lastEncountered;
        this.saleOrRentalFlag = saleOrRentalFlag;
        this.sourceName = sourceName;
        this.sourceId = sourceId;
        this.titleString = titleString;
        this.repositoryEntry = repositoryEntry;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AdvertisementCacheEntry with default attributes
     */
    private void init() {
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Date getDateEntered() {
        return dateEntered;
    }

    public void setDateEntered(Date dateEntered) {
        this.dateEntered = dateEntered;
    }

    public Date getLastEncountered() {
        return lastEncountered;
    }

    public void setLastEncountered(Date lastEncountered) {
        this.lastEncountered = lastEncountered;
    }

    public int getSaleOrRentalFlag() {
        return saleOrRentalFlag;
    }

    public void setSaleOrRentalFlag(int saleOrRentalFlag) {
        this.saleOrRentalFlag = saleOrRentalFlag;
    }

    public String getSourceName() {
        return sourceName;
    }

    public void setSourceName(String sourceName) {
        this.sourceName = sourceName;
    }

    public String getSourceId() {
        return sourceId;
    }

    public void setSourceId(String sourceId) {
        this.sourceId = sourceId;
    }

    public String getTitleString() {
        return titleString;
    }

    public void setTitleString(String titleString) {
        this.titleString = titleString;
    }

    public AdvertisementRepositoryEntry getRepositoryEntry() {
        return repositoryEntry;
    }

    public void setRepositoryEntry(AdvertisementRepositoryEntry repositoryEntry) {
        this.repositoryEntry = repositoryEntry;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Creates a new AdvertisementCacheEntry populated with the values from a ResultSet
     *
     * // dateEntered, saleOrRentalFlag, sourceName, sourceId, titleString, repositoryId
     * @param resultSet
     */
    protected static AdvertisementCacheEntry load(ResultSet resultSet) throws SQLException {
        AdvertisementCacheEntry entry = null;
        AdvertisementRepositoryEntry repositoryEntry = null;

        Integer id = resultSet.getInt(1);
        if ((id != null) && (id > 0)) {
            Date dateEntered = resultSet.getDate(2);
            Date lastEncountered = resultSet.getDate(3);
            int saleOrRental = resultSet.getInt(4);
            String sourceName = resultSet.getString(5);
            String sourceId = resultSet.getString(6);
            String titleString = resultSet.getString(7);
            Integer repositoryId = resultSet.getInt(8);

            if (repositoryId > 0) {
                Date repositoryDateEntered;
                String sourceUrl;

                repositoryDateEntered = resultSet.getDate(8);
                sourceUrl = resultSet.getString(9);

                repositoryEntry = new AdvertisementRepositoryEntry(repositoryId, repositoryDateEntered, sourceUrl);
            }

            entry = new AdvertisementCacheEntry(id, dateEntered, lastEncountered, saleOrRental, sourceName, sourceId, titleString, repositoryEntry);
        }

        return entry;
    }


    /** Insert this entry into the AdvertisementCache.
     *
     * @return the number of affected records
     *
     */
    public Integer insert(Connection connection) throws SQLException {
        PreparedStatement insertStatement;
        
        insertStatement = connection.prepareStatement(AdvertisementCacheFinder.INSERT_STATEMENT);
        insertStatement.setInt(1, getId());

        if (getDateEntered() != null) {
            insertStatement.setDate(2, new java.sql.Date(getDateEntered().getTime()));
        } else {
            insertStatement.setDate(2, null);
        }

        if (getDateEntered() != null) {
            insertStatement.setDate(3, new java.sql.Date(getLastEncountered().getTime()));
        } else {
            insertStatement.setDate(3, null);
        }

        insertStatement.setInt(4, getSaleOrRentalFlag());
        insertStatement.setString(5, getSourceName());
        insertStatement.setString(6, getSourceId());
        insertStatement.setString(7, getTitleString());
        if (getRepositoryEntry() != null) {
            insertStatement.setObject(8, getRepositoryEntry().getId());
        } else {
            insertStatement.setObject(8, null);
        }

        LOG.info(AdvertisementCacheFinder.INSERT_STATEMENT);

        return insertStatement.executeUpdate();
    }
}
