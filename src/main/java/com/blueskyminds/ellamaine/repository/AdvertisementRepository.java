package com.blueskyminds.ellamaine.repository;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.util.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import com.blueskyminds.ellamaine.db.AdvertisementRepositoryFinder;
import com.blueskyminds.framework.HasIdentity;
import com.blueskyminds.framework.persistence.jdbc.RowTableGateway;

import javax.persistence.*;

/**
 * An entry in the AdvertisementRepository
 *
 * This persistent entity needs be remain compatible with the Ellamaine AdvertismentRepository.pl so it
 *  also implements the RowTableGateway pattern (PoEAA) - it can be loaded and persisted using JDBC.
 * 
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
@Entity
public class AdvertisementRepository implements HasIdentity, RowTableGateway {

    private static final Log LOG = LogFactory.getLog(AdvertisementRepository.class);

    private Integer id;
    private Date dateEntered;
    private String sourceUrl;

    public AdvertisementRepository(Integer id, Date dateEntered, String sourceUrl) {
        this.id = id;
        this.dateEntered = dateEntered;
        this.sourceUrl = sourceUrl;
    }

    protected AdvertisementRepository() {
    }

    /**
     * The ID for this entry in the repository
     *
     * Note that the ID is not automatically generated and it is actually persisted as an Integer
     *
     * @return Long value of the Id
     */
    @Transient
    public Long getId() {
        if (id != null) {
            return id.longValue();
        } else {
            return null;
        }
    }

    public void setId(Long id) {
        if (id != null) {
            this.id = id.intValue();
        } else {
            this.id = null;
        }

    }

    /** Persistent getter/setter for the Id */
    @Id
    @Column(name="ID")
    public Integer getIdInt() {
        return id;
    }

    private void setIdInt(Integer id) {
        this.id = id;
    }

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "DateEntered")
    public Date getDateEntered() {
        return dateEntered;
    }

    public void setDateEntered(Date dateEntered) {
        this.dateEntered = dateEntered;
    }

    @Basic
    @Column(name="SourceURL")
    public String getSourceUrl() {
        return sourceUrl;
    }

    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Populates this insance with the values from a ResultSet
     *
     * @param resultSet
     */
    public void load(ResultSet resultSet) throws SQLException {
        setId(resultSet.getLong(AdvertisementRepositoryFinder.COLUMN_LIST[0]));
        setDateEntered(resultSet.getDate(AdvertisementRepositoryFinder.COLUMN_LIST[1]));
        setSourceUrl(resultSet.getString(AdvertisementRepositoryFinder.COLUMN_LIST[2]));
    }


    /**
     * Insert this entry into the AdvertisementRepository.
     *
     * @return the number of affected records
     *
     */
    public int insert(Connection connection) throws SQLException {
        PreparedStatement insertStatement;

        insertStatement = connection.prepareStatement(AdvertisementRepositoryFinder.INSERT_STATEMENT);
        insertStatement.setLong(1, getId());

        if (getDateEntered() != null) {
            insertStatement.setDate(2, new java.sql.Date(getDateEntered().getTime()));
        } else {
            insertStatement.setDate(2, null);
        }

        insertStatement.setString(3, getSourceUrl());

        return insertStatement.executeUpdate();
    }

}
