package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.framework.tools.FileTools;
import com.blueskyminds.framework.tools.PropertiesContext;
import com.blueskyminds.framework.persistence.paging.Page;
import com.blueskyminds.framework.persistence.paging.QueryPager;
import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.RepositoryHeaderException;
import com.blueskyminds.ellamaine.repository.AdvertisementRepository;
import com.blueskyminds.ellamaine.repository.dao.RepositoryDAO;
import com.google.inject.Inject;

import javax.persistence.EntityManager;
import java.io.*;
import java.util.List;

import org.apache.commons.logging.LogFactory;
import org.apache.commons.logging.Log;

/**
 * Accesses the file repository on the local filesystem
 *
 * This implementation needs to be compatible with the functionality of Ellamain's AdvertisementRepository.pm
 *
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class LocalRepositoryService implements RepositoryService {

    private static final Log LOG = LogFactory.getLog(LocalRepositoryService.class);

    private static final String DEFAULT_LOG_PATH = "./originatinghtml";
    private static final String ELLAMAINE_PROPERTIES = "ellamaine.properties";
    private static final String ORIGINATINGHTML_LOG_PATH_PROPERTY = "originatinghtml.log.path";

    private EntityManager em;
    private PropertiesContext ellamaineProperties;

    //private String basePath;
    private boolean useFlatPath;
    private LocalRepositoryConfiguration localRepositoryConfiguration;

    /** Initialise with default properties read from the properties file */
    public LocalRepositoryService(EntityManager em) {
        this.em = em;
        ellamaineProperties = new PropertiesContext(ELLAMAINE_PROPERTIES);
        useFlatPath = false;
        localRepositoryConfiguration = new LocalRepositoryConfiguration(ellamaineProperties.getPropertiesStartingWith(ORIGINATINGHTML_LOG_PATH_PROPERTY));
        localRepositoryConfiguration.setDefaultPath(DEFAULT_LOG_PATH);       }

    /**
     * Don't forget to inject the EntityManager and LocalRepositoryPaths
     */
    public LocalRepositoryService() {
    }


    /**
    * returns the base path used for the AdvertisementRepository files
    */

    protected String getBasePath(int identifier) {
        return localRepositoryConfiguration.getBasePath(identifier);
    }

    /**
     * returns the path to be used for the AdvertisementRepository with the specified identifier
     */
    protected String getTargetPath(int identifier) {

        String targetPath;
        String basePath = getBasePath(identifier);

        if (!useFlatPath) {
            // this is the normal case - use subdirectories
            String targetDir = Integer.toString(identifier / 1000);
            targetPath = FileTools.concatenateCanonicalPath(basePath, targetDir);
        } else {
            targetPath = basePath;
        }

        return targetPath;
    }


    protected void useFlatPath() {
        this.useFlatPath = true;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Get an input stream to the specified Repository entry
     *
     * @param repositoryEntryId
     * @return
     */
    public InputStream getInputStream(Integer repositoryEntryId) throws RepositoryServiceException {
        InputStream is;

        String fileName = repositoryEntryId+".html";
        String sourcePath = FileTools.concatenateCanonicalPath(getTargetPath(repositoryEntryId), fileName);
        File sourceFile = new File(sourcePath);
        LOG.info("Reading: "+sourcePath);
        try {
            is = new FileInputStream(sourceFile);
        } catch(FileNotFoundException e) {
            throw new RepositoryServiceException("Unable to find the repository entry in the local file system (id: "+repositoryEntryId+" sourcePath="+sourcePath+")",e);
        }

        return is;
    }


    /**
     * Returns the content of the specified Repository entry
     *
     * @param repositoryEntryId
     * @return RepositoryContent containing all content of the entry
     */
    public RepositoryContent getContent(Integer repositoryEntryId) throws RepositoryServiceException {
        InputStream inputStream = getInputStream(repositoryEntryId);
        RepositoryContent content;

        try {
            content = new RepositoryContent(inputStream);
        } catch(IOException e) {
            throw new RepositoryServiceException(e);
        } catch(RepositoryHeaderException e) {
            throw new RepositoryServiceException(e);
        } finally {
            try {
                inputStream.close();
            } catch (IOException e) {
                //
            }
        }

        return content;
    }

    /** Load a page of AdvertisementRepository entries */   
    public Page findPage(int pageNo, int pageSize) {
        QueryPager pager = new RepositoryDAO(em);
        Page page = pager.findPage(pageNo, pageSize);
        if (page != null) {
            LOG.info("Found page");
            // we return a copy that's a simple serializable PageResult
            return page.asCopy();
        } else {
            LOG.info("Page not found - returning null");            
            return null;
        }
    }

    public List<AdvertisementRepository> listByDate(int year, int month, int day) {
        RepositoryDAO repositoryDAO= new RepositoryDAO(em);
        return repositoryDAO.listByDate(year, month, day);        
    }

    @Inject
    public void setEntityManager(EntityManager em) {
        this.em = em;
    }

    @Inject
    public void setLocalRepositoryPaths(LocalRepositoryConfiguration localRepositoryConfiguration) {
        this.localRepositoryConfiguration = localRepositoryConfiguration;
    }
}
