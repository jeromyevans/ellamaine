package com.blueskyminds.ellamaine.web.actions;

import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.dispatcher.HttpHeaderResult;
import org.apache.struts2.convention.annotation.Result;

/**
 * Date Started: 17/03/2008
 * <p/>
 * History:
 */
@Result(name="success", type = "httpheader", params = {"error", "404"})
public class ExceptionController {

    public String index() {
        return execute();
    }
    public String execute() {
        return ActionSupport.SUCCESS;
    }
}
