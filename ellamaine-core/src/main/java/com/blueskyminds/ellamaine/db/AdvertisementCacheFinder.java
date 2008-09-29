package com.blueskyminds.ellamaine.db;

import com.blueskyminds.ellamaine.EllamaineException;
import com.blueskyminds.homebyfive.framework.core.tools.text.StringTools;

import java.sql.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.commons.lang.StringUtils;

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


    private static final String JOIN_COLUMNS = "repository.dateEntered, repository.sourceUrl";

    public static final String[] COLUMN_LIST = {"ID", "DateEntered", "LastEncountered", "SaleOrRentalFlag", "SourceName", "SourceID", "TitleString", "RepositoryID"};
    private static final String[] COLUMN_TYPE = {"integer primary key", "datetime", "datetime", "integer", "longvarchar", "varchar(20)", "longvarchar", "integer"};

    private static final String COLUMNS = StringUtils.join(COLUMN_LIST, ", ");

    public static final String INSERT_STATEMENT =
        "insert into "+TABLE_NAME+" ("+COLUMNS+") values ("+ StringTools.fill("?,", (StringUtils.countMatches(COLUMNS, ","))*2)+"?);";


    private static final String SELECT_BY_ID =
           "select "+COLUMNS+" from "+TABLE_NAME+
           " where id=?";

    private static final String SELECT_BY_ID_WITH_JOIN =
           "select "+COLUMNS+","+JOIN_COLUMNS+" from "+TABLE_NAME+" left outer join AdvertisementRepository repository on repositoryId=repository.id"+
           " where id=?";


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

    public static String createStatement() {
        StringBuilder statement = new StringBuilder("create table "+TABLE_NAME+" (");
        boolean first = true;
        for (int index = 0; index < COLUMN_LIST.length; index++) {
            if (!first) {
                statement.append(", ");
            } else {
                first = false;
            }

            statement.append(COLUMN_LIST[index]+" "+COLUMN_TYPE[index]);
        }
        statement.append(")");
        return statement.toString();
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
