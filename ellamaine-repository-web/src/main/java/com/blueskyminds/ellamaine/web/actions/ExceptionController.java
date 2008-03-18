package com.blueskyminds.ellamaine.web.actions;

import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.config.Result;
import org.apache.struts2.dispatcher.HttpHeaderResult;

/**
 * Date Started: 17/03/2008
 * <p/>
 * History:
 */
@Result(name="success", type = HttpHeaderResult.class, value = "404")
public class ExceptionController {

    public String index() {
        return execute();
    }
    public String execute() {
        return ActionSupport.SUCCESS;
    }
}
