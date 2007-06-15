package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.framework.tools.FileTools;
import com.blueskyminds.framework.tools.PropertiesContext;
import com.blueskyminds.framework.persistence.spooler.SpoolerTask;
import com.blueskyminds.framework.persistence.paging.Page;
import com.blueskyminds.framework.persistence.paging.Pager;
import com.blueskyminds.framework.persistence.paging.QueryPager;
import com.blueskyminds.framework.persistence.paging.PageResult;
import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.RepositoryHeaderException;
import com.blueskyminds.ellamaine.repository.dao.RepositoryDAO;
import com.blueskyminds.ellamaine.extractor.model.AdvertisementRepository;
import com.blueskyminds.ellamaine.extractor.spooler.AdvertisementRepositorySpooler;

import javax.persistence.EntityManager;
import java.io.*;
import java.util.LinkedList;
import java.util.List;
import java.util.Date;

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

    protected EntityManager em;
    private PropertiesContext ellamaineProperties;

    private String basePath;
    private boolean useFlatPath;

    public LocalRepositoryService(EntityManager em) {
        this.em = em;
        init();
    }

    public LocalRepositoryService() {
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the LocalRepositoryService with default attributes
     */
    protected void init() {
        ellamaineProperties = new PropertiesContext(ELLAMAINE_PROPERTIES);
        useFlatPath = false;
        basePath = ellamaineProperties.getProperty(ORIGINATINGHTML_LOG_PATH_PROPERTY);
        if (basePath == null) {
            basePath = DEFAULT_LOG_PATH;
        }
    }

    /**
    * returns the base path used for the AdvertisementRepository files
    */

    protected String getBasePath() {
        return basePath;
    }

    /**
     * returns the path to be used for the AdvertisementRepository with the specified identifier
     */
    protected String getTargetPath(int identifier) {

        String targetPath;
        String basePath = getBasePath();

        if (!useFlatPath) {
            // this is the normal case - use subdirectories
            String targetDir = Integer.toString(identifier / 1000);
            targetPath = FileTools.concatenateCanonicalPath(basePath, targetDir);
        } else {
            targetPath = basePath;
        }

        return targetPath;
    }

    protected void overrideBasePath(String newBasePath) {
        this.basePath = newBasePath;
    }


    protected void useFlatPath() {
        this.useFlatPath = true;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Get the PersistenceService used to access the AdvertisementRepository
     * @return PersistenceService
     */
//    public PersistenceService getPersistenceService() {
//        return persistenceService;
//    }

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
        }

        return content;
    }

    /**
     * Create a spooler for paging entries from the AdvertisementRepository
     *
     * @param spoolerTask
     * @return
     */
//    public AdvertisementRepositorySpooler createRepositorySpooler(SpoolerTask<AdvertisementRepository> spoolerTask) {
//        return new AdvertisementRepositorySpooler(em, new RepositoryDAO(em), spoolerTask);
//    }

    /** Load a page of AdvertisementRepository entries */
    public Page findPage(int pageNo, int pageSize) {
        QueryPager pager = new RepositoryDAO(em);
        Page page = pager.findPage(pageNo, pageSize);
        if (page != null) {
            // we return a copy that's a simple serializable PageResult
            return page.asCopy();
        } else {
            return null;
        }
//        List<AdvertisementRepository> results = new LinkedList<AdvertisementRepository>();
//        for (int i = 1; i < 10; i++) {
//            results.add(new AdvertisementRepository(i, new Date(), "test"));
//        }
//        return new PageResult(0, 10, results);
    }

    public void setEntityManager(EntityManager em) {
        this.em = em;
    }
}
