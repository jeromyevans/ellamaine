package com.blueskyminds.ellamaine.repository;

import com.blueskyminds.homebyfive.framework.core.tools.FileTools;

import java.io.*;
import java.util.Date;

/**
 * Encapsulates content read from the repository
 *
 * Date Started: 13/06/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class RepositoryContent implements Serializable {

    private String sourceUrl;
    private Date timestamp;
    private byte[] content;

    public RepositoryContent() {
    }

    /**
     * Creates a RepositoryContent from an input stream.
     * The input stream is assumed to point to a repository entry.
     * The header of the entry is read to create the metadata for this content, and all bytes
     * are read into the content array.
     *
      * @param inputStream
     * @throws IOException
     * @throws RepositoryHeaderException
     */
    public RepositoryContent(InputStream inputStream) throws IOException, RepositoryHeaderException {
        BufferedInputStream bis = new BufferedInputStream(inputStream);

        RepositoryFileHeaderReader header = new RepositoryFileHeaderReader(bis);
        sourceUrl = header.getSourceUrl();
        timestamp = header.getTimestamp();

        content = FileTools.readInputStream(bis);
    }

    public byte[] getContent() {
        return content;
    }

    public int getContentLength() {
        if (content != null) {
            return content.length;
        } else {
            return 0;
        }
    }

    /**
     * Returns an input stream to the byte array of content
     *
     * @return
     */
    public InputStream getInputStream() {
        return new ByteArrayInputStream(content);
    }

    public String getSourceUrl() {
        return sourceUrl;
    }

    public Date getTimestamp() {
        return timestamp;
    }
}
