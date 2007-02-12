package com.blueskyminds.ellamaine.db;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.blueskyminds.ellamaine.EllamaineException;

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
}
