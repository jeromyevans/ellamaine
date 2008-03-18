package com.blueskyminds.ellamaine.repository;

import com.blueskyminds.framework.tools.text.StringTools;

import java.util.Date;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.text.DateFormat;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * This class contains information stored in/read from  the header of files in the repository
 *
 * Date Started: 16/02/2007
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class RepositoryFileHeaderReader {

    private static final Log LOG = LogFactory.getLog(RepositoryFileHeaderReader.class);

    private static final int SEEKING_HEADER = 0;
    private static final int IN_HEADER = 1;

    private static final int MAX_LINES_IN_HEADER = 10;
    private static final int MAX_BYTES_IN_HEADER = 1000;

    private static final String TOKEN_ORIGINATING_HTML = "OriginatingHTML";
    private static final String TOKEN_SOURCEURL = "sourceurl";
    private static final String TOKEN_LOCALTIME = "localtime";

    private static final DateFormat headerTimestampFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    private String sourceUrl;
    private Date timestamp;


    public RepositoryFileHeaderReader(BufferedInputStream inputStream) throws RepositoryHeaderException {
        readHeader(inputStream);
        LOG.info(sourceUrl);
        LOG.info(timestamp);
    }

    /**
     * Reads the header of the repository InputStream that identifies the URL and Timestamp
     *
     * This code is based directly on the algorithm in AdvertisementRepository.pm
     *
     * The header looks like:
     *
     *  <---- OriginatingHTML -----
     *  sourceurl='http://www.reiwa.com.au/lst/lst-ressale-details.cfm?prop_no=1'
     *  localtime='2006-08-21 13:43:35'
     *  --------------------------->
     *
     * It's possible for the file to contain multiple entries.  In this situation, the FIRST entry is used
     *  (NOTE: this may be different from the perl implementation which processes every line of the file
     * and uses the last encountered values)
     *
     * The header is always within the first 10 lines of the file.
     *
     * @param inputStream   stream from the file in the repository
     * @throws RepositoryHeaderException if the header can't be processed
     */
    private void readHeader(InputStream inputStream) throws RepositoryHeaderException {
        String thisLine;
        String line;
        int lineNo = 0;
        String sourceUrl = null;
        String timestamp = null;
        boolean thisLineIsHeader;
        int state = SEEKING_HEADER;
        boolean finshed = false;

        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));

        try {
            // Mark the starting position - we're going to reset to this position after processing the header
            //  so the input stream is unaffected
            inputStream.mark(MAX_BYTES_IN_HEADER);

            while (((thisLine = reader.readLine()) != null) && (lineNo < MAX_LINES_IN_HEADER) && (!finshed)) {

                line = StringUtils.chomp(thisLine);
                thisLineIsHeader = false;

                if (state == SEEKING_HEADER) {
                    if (StringTools.containsIgnoreCase(line, TOKEN_ORIGINATING_HTML)) {
                        state = IN_HEADER;
                        thisLineIsHeader = true;
                    }
                }

                if (state == IN_HEADER) {
                    if (StringTools.containsIgnoreCase(line, TOKEN_SOURCEURL)) {
                        // extract the sourceurl header element
                        sourceUrl = StringUtils.substringAfter(line, "=");

                        if (sourceUrl != null) {
                            sourceUrl = sourceUrl.replaceAll("\'", "");  // remove single quotes
                        }

                        thisLineIsHeader = true;
                    } else {
                        if (StringTools.containsIgnoreCase(line, TOKEN_LOCALTIME)) {
                            timestamp = StringUtils.substringAfter(line, "=");
                            if (timestamp != null) {
                                timestamp = timestamp.replaceAll("\'", ""); // remove single quotes
                            }
                            thisLineIsHeader = true;
                        } else {
                            if (line.contains("-->")) {
                                thisLineIsHeader = true;
                                state = SEEKING_HEADER;

                                // break out of the processing
                                finshed = true;
                            }
                        }
                    }
                }
                lineNo++;

            }

            this.sourceUrl = sourceUrl;
            if (timestamp != null) {
                this.timestamp = headerTimestampFormat.parse(timestamp);
            }

            // return to the marked position before the header
            inputStream.reset();

        } catch(IOException e) {
            throw new RepositoryHeaderException("Error parsing header of repository entry", e);
        } catch (ParseException e) {
            throw new RepositoryHeaderException("Failed to parse timestamp header of repository entry", e);
        }
    }

    public String getSourceUrl() {
        return sourceUrl;
    }

    public Date getTimestamp() {
        return timestamp;
    }
}
