package com.blueskyminds.ellamaine.web.actions;

import com.opensymphony.xwork2.ActionSupport;
import com.opensymphony.xwork2.ModelDriven;
import com.google.inject.Inject;
import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.homebyfive.framework.core.persistence.paging.Page;
import com.wideplay.warp.persist.Transactional;
import com.wideplay.warp.persist.TransactionType;
import org.apache.struts2.rest.DefaultHttpHeaders;
import org.apache.struts2.rest.HttpHeaders;

/**
 * Date Started: 14/03/2008
 * <p/>
 * History:
 */
public class PageController extends ActionSupport implements ModelDriven<Page> {

    private static final int DEFAULT_PAGE_SIZE = 20;

    private RepositoryService repositoryService;

    private int pageNo;
    private int pageSize;
    private Page page;
    private boolean next;
    private boolean previous;

    public void setPageNo(Integer pageNo) {
        this.pageNo = (pageNo != null ? pageNo : 0);
    }

    public void setPageSize(Integer pageSize) {
        this.pageSize = (pageSize != null ? pageSize : DEFAULT_PAGE_SIZE);
    }

    @Transactional(type = TransactionType.READ_ONLY)
    public HttpHeaders index() {
        if (pageSize == 0) {
            pageSize = DEFAULT_PAGE_SIZE;
        }
        page = repositoryService.findPage(pageNo, pageSize);

        next = page.hasNextPage();
        previous = page.hasPreviousPage();

        return new DefaultHttpHeaders("index");
    }

    public Page getModel() {
        return page;
    }

    public boolean isNext() {
        return next;
    }

    public boolean isPrevious() {
        return previous;
    }

    public Integer getNextPageNo() {
        if (page.hasNextPage()) {
            return page.getPageNo()+1;
        } else {
            return null;
        }
    }

    public Integer getPrevPageNo() {
        if (page.hasPreviousPage()) {
            return page.getPageNo()-1;
        } else {
            return null;
        }
    }

    @Inject
    public void setRepositoryService(RepositoryService repositoryService) {
        this.repositoryService = repositoryService;
    }
}
