package com.blueskyminds.ellamaine.db;

import com.blueskyminds.ellamaine.EllamaineException;

import java.sql.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Used to find Entries in the AdvertisementCache
 *
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class AdvertisementCacheFinder {

    private static final Log LOG = LogFactory.getLog(AdvertisementCacheFinder.class);
    
    private static final String TABLE_NAME = "AdvertisementCache";

    private static final String COLUMNS = "id, dateEntered, saleOrRentalFlag, sourceName, sourceId, titleString, repositoryId";
    private static final String JOIN_COLUMNS = "repository.dateEntered, repository.sourceUrl";

    private static final String SELECT_BY_ID =
           "select "+COLUMNS+" from "+TABLE_NAME+
           " where id=?";

    private static final String SELECT_BY_ID_WITH_JOIN =
           "select "+COLUMNS+","+JOIN_COLUMNS+" from "+TABLE_NAME+" left outer join AdvertisementRepository repository on repositoryId=repository.id"+
           " where id=?";

    public static final String INSERT_STATEMENT = 
        "insert into "+TABLE_NAME+" ("+COLUMNS+") values (?, ?, ?, ?, ?, ?, ?);";

    public static final String CREATE_STATEMENT = 
        "create table "+TABLE_NAME+" ("+
        "ID INTEGER PRIMARY KEY , "+
        "DateEntered DATETIME NOT NULL, "+
        "LastEncountered DATETIME, "+
        "SaleOrRentalFlag INTEGER,"+
        "SourceName LONGVARCHAR, "+
        "SourceID VARCHAR(20), "+
        "TitleString LONGVARCHAR, "+
        "RepositoryID INTEGER)";


    private Connection connection;

    public AdvertisementCacheFinder(Connection connection) {
        this.connection = connection;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the AdvertisementCacheFinder with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Finds an entry in the AdvertisementCache by Id
     * Also performs an outer join to eagerly load te RepositoryEntry
     *
     * There is no identity map.
     *
     * @param id of the AdvertisementCacheEntry
     * @return AdvertisementCacheEntry with the specified id, or null if not found
     * @throws EllamaineException if there's a persistence access error
     */
    public AdvertisementCacheEntry findById(int id) throws EllamaineException {

        AdvertisementCacheEntry entry = null;
        PreparedStatement statement = null;
        try {
            statement = connection.prepareStatement(SELECT_BY_ID_WITH_JOIN);
            statement.setInt(1, id);

            LOG.info(SELECT_BY_ID_WITH_JOIN);
            ResultSet resultSet = statement.executeQuery();

            if (resultSet.next()) {
                entry = AdvertisementCacheEntry.load(resultSet);
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
