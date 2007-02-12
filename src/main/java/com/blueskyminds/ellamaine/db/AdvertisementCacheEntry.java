package com.blueskyminds.ellamaine.db;

import com.blueskyminds.framework.persistence.jdbc.PersistenceTools;

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
    private int saleOrRentalFlag;
    private String sourceName;
    private String sourceId;
    private String titleString;
    private Integer repositoryId;

    /** Create a new entry */
    public AdvertisementCacheEntry(Date dateEntered, int saleOrRentalFlag, String sourceName, String sourceId, String titleString, Integer repositoryId) {
        this.dateEntered = dateEntered;
        this.saleOrRentalFlag = saleOrRentalFlag;
        this.sourceName = sourceName;
        this.sourceId = sourceId;
        this.titleString = titleString;
        this.repositoryId = repositoryId;
    }

    public AdvertisementCacheEntry(Integer id, Date dateEntered, int saleOrRentalFlag, String sourceName, String sourceId, String titleString, Integer repositoryId) {
        this.id = id;
        this.dateEntered = dateEntered;
        this.saleOrRentalFlag = saleOrRentalFlag;
        this.sourceName = sourceName;
        this.sourceId = sourceId;
        this.titleString = titleString;
        this.repositoryId = repositoryId;
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

    public Integer getRepositoryId() {
        return repositoryId;
    }

    public void setRepositoryId(Integer repositoryId) {
        this.repositoryId = repositoryId;
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

        Integer id = resultSet.getInt(1);
        if ((id != null) && (id > 0)) {
            Date dateEntered = resultSet.getDate(2);
            int saleOrRental = resultSet.getInt(3);
            String sourceName = resultSet.getString(4);
            String sourceId = resultSet.getString(5);
            String titleString = resultSet.getString(6);
            Integer repositoryId = resultSet.getInt(7);
            if (repositoryId == 0) {
                repositoryId = null;
            }

            entry = new AdvertisementCacheEntry(id, dateEntered, saleOrRental, sourceName, sourceId, titleString, repositoryId);
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

        insertStatement.setInt(3, getSaleOrRentalFlag());
        insertStatement.setString(4, getSourceName());
        insertStatement.setString(5, getSourceId());
        insertStatement.setString(6, getTitleString());
        insertStatement.setObject(7, getRepositoryId());

        LOG.info(AdvertisementCacheFinder.INSERT_STATEMENT);

        return insertStatement.executeUpdate();
    }
}
