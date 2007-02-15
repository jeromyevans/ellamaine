package com.blueskyminds.ellamaine.db;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.sql.*;
import java.util.List;
import java.util.LinkedList;

import com.blueskyminds.ellamaine.EllamaineException;
import com.blueskyminds.tools.text.StringTools;
import com.blueskyminds.framework.persistence.jdbc.JdbcTools;

import javax.sql.rowset.serial.SerialArray;

/**
 * Accesses an entry in the AdvertisementRepository
 *
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementRepositoryFinder {

    private static final Log LOG = LogFactory.getLog(AdvertisementRepositoryFinder.class);

    private static final String TABLE_NAME = "AdvertisementRepository";

    private static final String COLUMNS = "id, dateEntered, sourceUrl";

    private static final String SELECT_BY_ID =
           "select "+COLUMNS+" from "+TABLE_NAME+
           " where id=?";

    private static final String SELECT_PAGE =
           "select "+COLUMNS+" from "+TABLE_NAME+
           " where id>=?";

    private static final String SELECT_MANY_BY_ID_PREFIX =
           "select "+COLUMNS+" from "+TABLE_NAME+
           " where id in (";
    private static final String SELECT_MANY_BY_ID_SUFFIX =
           ")";

    public static final String INSERT_STATEMENT =
        "insert into "+TABLE_NAME+" ("+COLUMNS+") values (?, ?, ?);";

    public static final String CREATE_STATEMENT =
        "create table "+TABLE_NAME+" ("+
        "ID INTEGER PRIMARY KEY , "+
        "DateEntered DATETIME NOT NULL, "+
        "sourceURL LONGVARCHAR)";


    private Connection connection;

    public AdvertisementRepositoryFinder(Connection connection) {
        this.connection = connection;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AdvertisementRepositoryFinder with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    // ------------------------------------------------------------------------------------------------------

    /**
     * Finds an entry in the AdvertisementRepository by Id
     *
     * There is no identity map.
     *
     * @param id of the AdvertisementRepositoryEntry
     * @return AdvertisementRepositoryEntry with the specified id, or null if not found
     * @throws com.blueskyminds.ellamaine.EllamaineException if there's a persistence access error
     */
    public AdvertisementRepositoryEntry findById(int id) throws EllamaineException {

        AdvertisementRepositoryEntry entry = null;
        PreparedStatement statement = null;
        try {
            statement = connection.prepareStatement(SELECT_BY_ID);
            statement.setInt(1, id);

            LOG.info(SELECT_BY_ID);
            ResultSet resultSet = statement.executeQuery();

            if (resultSet.next()) {
                entry = AdvertisementRepositoryEntry.load(resultSet);
            }
        } catch (SQLException e) {
            throw new EllamaineException(e);
        } finally {
            if (statement != null) {
                try {
                    statement.close();
                } catch (SQLException e) {
                    // ignore this one
                }
            }
        }
        return entry;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Finds an entry in the AdvertisementRepository by Id
     *
     * There is no identity map.
     *
     * @param fromId        starting from id
     * @param toId            to id
     * @return AdvertisementRepositoryEntry with the specified id, or null if not found
     * @throws com.blueskyminds.ellamaine.EllamaineException if there's a persistence access error
     */
    public List<AdvertisementRepositoryEntry> findPage(int fromId, int toId) throws EllamaineException {

        AdvertisementRepositoryEntry entry = null;
        PreparedStatement statement = null;
        List<AdvertisementRepositoryEntry> results = new LinkedList<AdvertisementRepositoryEntry>();

        int pageSize;
        try {
            pageSize = (toId-fromId)+1;

            statement = connection.prepareStatement(SELECT_PAGE);
            statement.setMaxRows(pageSize);

            LOG.info(SELECT_PAGE);
            ResultSet resultSet = statement.executeQuery();

            while (resultSet.next()) {
                entry = AdvertisementRepositoryEntry.load(resultSet);
                if (entry != null) {
                    results.add(entry);
                }
            }
        } catch (SQLException e) {
            throw new EllamaineException(e);
        } finally {
            if (statement != null) {
                try {
                    statement.close();
                } catch (SQLException e) {
                    // ignore this one
                }
            }
        }
        return results;
    }


    /**
     * Finds multiple entries in the AdvertisementRepository by their Ids
     *
     * There is no identity map.
     *
     * @param ids       of the entries in AdvertisementRepository
     * @return AdvertisementRepositoryEntry with the specified id, or null if not found
     * @throws com.blueskyminds.ellamaine.EllamaineException if there's a persistence access error
     */
    public List<AdvertisementRepositoryEntry> findManyById(Integer[] ids) throws EllamaineException {

        AdvertisementRepositoryEntry entry = null;
        PreparedStatement statement = null;
        List<AdvertisementRepositoryEntry> results = new LinkedList<AdvertisementRepositoryEntry>();

        try {
                    
            String queryString = SELECT_MANY_BY_ID_PREFIX+JdbcTools.createArrayParamater(ids.length)+SELECT_MANY_BY_ID_SUFFIX;
            statement = connection.prepareStatement(queryString.toString());

            JdbcTools.setArrayParameter(statement, 1, ids);

            LOG.info(queryString.toString());

            ResultSet resultSet = statement.executeQuery();

            while (resultSet.next()) {
                entry = AdvertisementRepositoryEntry.load(resultSet);
                if (entry != null) {
                    results.add(entry);
                }
            }
        } catch (SQLException e) {
            throw new EllamaineException(e);
        } finally {
            if (statement != null) {
                try {
                    statement.close();
                } catch (SQLException e) {
                    // ignore this one
                }
            }
        }
        return results;
    }
}
