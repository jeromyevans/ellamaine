package com.blueskyminds.ellamaine;

import java.sql.SQLException;

/**
 * Date Started: 12/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class EllamaineException extends Exception {
    
    public EllamaineException() {
    }

    public EllamaineException(String message) {
        super(message);
    }

    public EllamaineException(String message, Throwable cause) {
        super(message, cause);
    }

    public EllamaineException(Throwable cause) {
        super(cause);
    }

    // ------------------------------------------------------------------------------------------------------
}
