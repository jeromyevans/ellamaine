package com.blueskyminds.ellamaine.repository;

/**
 * Date Started: 15/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class RepositoryServiceException extends Exception {


    public RepositoryServiceException() {
    }

    public RepositoryServiceException(String message) {
        super(message);
    }

    public RepositoryServiceException(String message, Throwable cause) {
        super(message, cause);
    }

    public RepositoryServiceException(Throwable cause) {
        super(cause);
    }
}
