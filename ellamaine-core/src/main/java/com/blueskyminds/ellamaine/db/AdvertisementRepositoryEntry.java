package com.blueskyminds.ellamaine.db;

import org.apache.commons.logging.LogFactory;
import org.apache.commons.logging.Log;

import java.util.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Connection;
import java.sql.PreparedStatement;

/**
 * An entry in the AdvertisementRepository
 *
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementRepositoryEntry {

    private static final Log LOG = LogFactory.getLog(AdvertisementRepositoryEntry.class);

    private Integer id;
    private Date dateEntered;
    private String sourceUrl;

    public AdvertisementRepositoryEntry(Integer id, Date dateEntered, String sourceUrl) {
        this.id = id;
        this.dateEntered = dateEntered;
        this.sourceUrl = sourceUrl;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AdvertisementRepositoryEntry with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------


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

    public String getSourceUrl() {
        return sourceUrl;
    }

    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Creates a new AdvertisementCacheEntry populated with the values from a ResultSet
     *
     * // dateEntered, saleOrRentalFlag, sourceName, sourceId, titleString, repositoryId
     * @param resultSet
     */
    protected static AdvertisementRepositoryEntry load(ResultSet resultSet) throws SQLException {
        AdvertisementRepositoryEntry entry = null;

        Integer id = resultSet.getInt(1);
        if ((id != null) && (id > 0)) {
            Date dateEntered = resultSet.getDate(2);
            String sourceUrl = resultSet.getString(3);

            entry = new AdvertisementRepositoryEntry(id, dateEntered, sourceUrl);
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

        insertStatement = connection.prepareStatement(AdvertisementRepositoryFinder.INSERT_STATEMENT);
        insertStatement.setInt(1, getId());

        if (getDateEntered() != null) {
            insertStatement.setDate(2, new java.sql.Date(getDateEntered().getTime()));
        } else {
            insertStatement.setDate(2, null);
        }

        insertStatement.setString(3, getSourceUrl());

        //LOG.info(AdvertisementRepositoryFinder.INSERT_STATEMENT);

        return insertStatement.executeUpdate();
    }
}
