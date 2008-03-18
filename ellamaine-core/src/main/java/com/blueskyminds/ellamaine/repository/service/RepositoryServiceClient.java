package com.blueskyminds.ellamaine.repository.service;

import java.util.Properties;
import java.io.IOException;
import java.io.InputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.commons.httpclient.HttpException;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.methods.GetMethod;
import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.RepositoryHeaderException;
import com.blueskyminds.framework.persistence.paging.Page;
import com.thoughtworks.xstream.XStream;
import com.google.inject.Inject;

/**
 * Date Started: 16/03/2008
 * <p/>
 * History:
 */
public class RepositoryServiceClient implements RepositoryService {

    private static final Log LOG = LogFactory.getLog(RepositoryServiceClient.class);

    private static final String DEFAULT_HOSTNAME = "localhost";
    private static final String REPOSITORY_HOSTNAME_PROPERTY = "repository.hostname";

    private String hostname;

    public RepositoryServiceClient(String hostname) {
        this.hostname = hostname;
    }

    @Inject
    public RepositoryServiceClient(@RepositoryProperties Properties properties) {

        if (properties != null) {
            this.hostname = (String) properties.get(REPOSITORY_HOSTNAME_PROPERTY);
        }

        if (hostname == null) {
            this.hostname = DEFAULT_HOSTNAME;
        }
    }

    public RepositoryServiceClient() {        
    }

    /**
     * Get an input stream to the specified Repository entry
     *
     * @param repositoryEntryId
     * @return
     */
    public InputStream getInputStream(Integer repositoryEntryId) throws RepositoryServiceException {
        HttpClient client = new HttpClient();
        InputStream stream = null;
        GetMethod method = new GetMethod(hostname+"/content/"+repositoryEntryId);

        try {
            client.executeMethod(method);
            stream = method.getResponseBodyAsStream();
        } catch (HttpException e) {
            throw new RepositoryServiceException(e);
        } catch (IOException e) {
            throw new RepositoryServiceException(e);
        }

        return stream;
    }

    /**
     * Returns the content of the specified Repository entry
     *
     * @param repositoryEntryId
     * @return RepositoryContent containing all content of the entry
     */
    public RepositoryContent getContent(Integer repositoryEntryId) throws RepositoryServiceException {
        try {
            return new RepositoryContent(getInputStream(repositoryEntryId));
        } catch (IOException e) {
            throw new RepositoryServiceException(e);
        } catch (RepositoryHeaderException e) {
            throw new RepositoryServiceException(e);
        }
    }

    /**
     * Lookup a page of AdvertisementRepository entries
     */
    public Page findPage(int pageNo, int pageSize) {
        HttpClient client = new HttpClient();
        String responseBody;
        GetMethod method = new GetMethod(hostname+"/page.xml?pageNo="+pageNo+"&pageSize="+pageSize);
        Page page = null;
        try {
            client.executeMethod(method);
            responseBody = method.getResponseBodyAsString();
            page = (Page) new XStream().fromXML(responseBody);
        } catch (HttpException e) {
            LOG.error(e);
        } catch (IOException e) {
            LOG.error(e);
        }
        return page;
    }

}
