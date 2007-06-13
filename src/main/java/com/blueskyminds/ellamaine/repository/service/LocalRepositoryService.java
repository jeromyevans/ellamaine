package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.framework.tools.FileTools;
import com.blueskyminds.framework.tools.PropertiesContext;
import com.blueskyminds.framework.persistence.spooler.SpoolerTask;
import com.blueskyminds.framework.persistence.paging.Page;
import com.blueskyminds.framework.persistence.paging.Pager;
import com.blueskyminds.framework.persistence.paging.QueryPager;
import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.dao.RepositoryDAO;
import com.blueskyminds.ellamaine.extractor.model.AdvertisementRepository;
import com.blueskyminds.ellamaine.extractor.spooler.AdvertisementRepositorySpooler;

import javax.persistence.EntityManager;
import java.io.*;

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

    private static final String DEFAULT_LOG_PATH = "./originatinghtml";
    private static final String ELLAMAINE_PROPERTIES = "ellamaine.properties";
    private static final String ORIGINATINGHTML_LOG_PATH_PROPERTY = "originatinghtml.log.path";

    private EntityManager em;
    private PropertiesContext ellamaineProperties;

    private String basePath;
    private boolean useFlatPath;

    public LocalRepositoryService(EntityManager em) {
        this.em = em;
        prepare();
    }

    public LocalRepositoryService() {
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the LocalRepositoryService with default attributes
     */
    protected void prepare() {
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

        try {
            is = new FileInputStream(sourceFile);
        } catch(FileNotFoundException e) {
            throw new RepositoryServiceException("Unable to find the repository entry in the local file system (id: "+repositoryEntryId+" sourcePath="+sourcePath+")",e);
        }

        return is;
    }

    /**
     * Create a spooler for paging entries from the AdvertisementRepository
     *
     * @param spoolerTask
     * @return
     */
    public AdvertisementRepositorySpooler createRepositorySpooler(SpoolerTask<AdvertisementRepository> spoolerTask) {
        return new AdvertisementRepositorySpooler(em, new RepositoryDAO(em), spoolerTask);
    }

    /** Load a page of AdvertisementRepository entries */
    public Page findPage(int pageNo, int pageSize) {
        QueryPager pager = new RepositoryDAO(em);
        return pager.findPage(pageNo, pageSize);
    }
}
