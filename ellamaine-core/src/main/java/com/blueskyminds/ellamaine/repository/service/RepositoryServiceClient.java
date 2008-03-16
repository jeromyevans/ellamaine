package com.blueskyminds.ellamaine.repository.service;

import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.RepositoryHeaderException;
import com.blueskyminds.framework.persistence.paging.Page;
import com.thoughtworks.xstream.XStream;

import java.io.InputStream;
import java.io.IOException;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpState;
import org.apache.commons.httpclient.HttpException;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Date Started: 16/03/2008
 * <p/>
 * History:
 */
public class RepositoryServiceClient implements RepositoryService {

    private static final Log LOG = LogFactory.getLog(RepositoryServiceClient.class);
    private String hostname;

    public RepositoryServiceClient(String hostname) {
        this.hostname = hostname;
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
