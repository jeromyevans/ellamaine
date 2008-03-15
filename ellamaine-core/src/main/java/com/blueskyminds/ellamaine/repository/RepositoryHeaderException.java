package com.blueskyminds.ellamaine.repository;

/**
 * Date Started: 16/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class RepositoryHeaderException extends Exception {

    public RepositoryHeaderException() {
    }

    public RepositoryHeaderException(String message) {
        super(message);
    }

    public RepositoryHeaderException(String message, Throwable cause) {
        super(message, cause);
    }

    public RepositoryHeaderException(Throwable cause) {
        super(cause);
    }
}
