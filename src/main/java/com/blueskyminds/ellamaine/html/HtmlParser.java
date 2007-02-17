package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;
import org.cyberneko.html.parsers.DOMParser;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.LinkedList;

/**
 * Uses Xerces2 with the Neko HTML parser to create an HTMLDocument.  Provides helper methods to access
 *  nodes of the document
 * <p/>
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlParser {

    private List<Extractor> extractors;

    public HtmlParser() throws IOException, SAXException {
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the HtmlParser with default attributes
     */
    private void init() {
        extractors = new LinkedList<Extractor>();
    }

    // ------------------------------------------------------------------------------------------------------

    /** Register an extractor with this parser.  The extractor will be executed if a document is parsed
     * for which the extractor returns isSupported true */
    public void registerExtractor(Extractor extractor) {
        extractors.add(extractor);
    }

    // ------------------------------------------------------------------------------------------------------

    /** Reads a HTML document from the input stream and uses an extractor to create a representive object.
     *
     * Reads the input stream and creates a HTMLDocument.  Fires the extractor for the document */
    public Object parseDocument(String source, InputStream inputStream) throws IOException, SAXException, AmbiguousExtractorException {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml       
        parser.parse(new InputSource(inputStream));

        HTMLDocumentDecorator document = new HTMLDocumentDecorator((HTMLDocument) parser.getDocument());
        return extractContent(source, document);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Extract the content from the document using the appropriate extractor
     *
     * If no extractor can read the document then null will be returned
     *
     * If more than one extractor can read the document an AmbiguousExtractorException is thrown
     *
     * @param source
     * @param document
     * @return the extracted object graph, or null if no extractors can parse the document
     * @throws AmbiguousExtractorException if more than one extractor wants to process this document
     * */
    public Object extractContent(String source, HTMLDocumentDecorator document) throws AmbiguousExtractorException {

        Extractor candidateExtractor = null;
        Object result = null;
        Enum candidateVersion = null;
        Enum version;

        for (Extractor extractor : extractors) {
            version = extractor.isSupported(source, document);
            if (version != null) {
                if (candidateExtractor == null) {
                    candidateExtractor = extractor;
                    candidateVersion = version;
                } else {
                    // more than one extractor supports this document - throw an exception
                    throw new AmbiguousExtractorException(candidateExtractor, candidateVersion, extractor, version);
                }
            }
        }

        if (candidateExtractor != null) {
            result = candidateExtractor.extractContent(candidateVersion, source, document);
        }

        return result;
    }

}
