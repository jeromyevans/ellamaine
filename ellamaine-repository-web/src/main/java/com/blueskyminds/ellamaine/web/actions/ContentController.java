package com.blueskyminds.ellamaine.web.actions;

import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.ellamaine.repository.RepositoryContent;
import com.blueskyminds.ellamaine.repository.RepositoryServiceException;
import com.google.inject.Inject;
import org.apache.struts2.rest.HttpHeaders;
import org.apache.struts2.rest.DefaultHttpHeaders;
import org.apache.struts2.config.Namespace;
import org.apache.struts2.config.Results;
import org.apache.struts2.config.Result;
import org.apache.struts2.dispatcher.StreamResult;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.io.InputStream;
import java.io.ByteArrayInputStream;

/**
 * Date Started: 15/03/2008
 * <p/>
 * History:
 */
@Results({
    @Result(name= "stream", type = StreamResult.class, value = "inputStream"),
    @Result(name= "error", value = "/notFound.jsp")
})
public class ContentController extends RESTControllerSupport {

    private static final Log LOG = LogFactory.getLog(ContentController.class);

    private RepositoryService repositoryService;
    private Integer id;
    private InputStream inputStream;
    private int contentSize;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public HttpHeaders show() {
        if (id != null) {
            try {
                RepositoryContent content = repositoryService.getContent(id);
                if (content != null) {
                    contentSize = content.getContentLength();
                    inputStream = new ByteArrayInputStream(content.getContent());
                    return new DefaultHttpHeaders("stream");
                }
            } catch (RepositoryServiceException e) {
                LOG.error(e);
            }
        }
        return new DefaultHttpHeaders("error").withStatus(404);        
    }

    public InputStream getInputStream() {
        return inputStream;
    }

    public int getContentSize() {
        return contentSize;
    }

    @Inject
    public void setRepositoryService(RepositoryService repositoryService) {
        this.repositoryService = repositoryService;
    }
}
