package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;
import org.cyberneko.html.parsers.DOMParser;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.apache.commons.collections.OrderedMap;
import org.apache.commons.collections.MapIterator;
import org.apache.commons.collections.map.LinkedMap;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.LinkedList;

/**
 * Extracts content from an HTML Document.
 *
 * Extraction is performed by one of the registered Extrators.
 * The Extractor to use is determined by the registered Selectors.
 *
 * Uses Xerces2 with the Neko HTML parser to create an HTMLDocument.  Provides helper methods to access
 *  nodes of the document. The HTMLDocument is passed to the extractor for processing of the result.
 *
 * <p/>
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2007 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlParser {

    /** Map of selectors and corresponding extractors */
    private OrderedMap selectorExtractorMap;

    public HtmlParser() throws IOException, SAXException {
        init();
    }

    /**
     * Initialise the HtmlParser with default attributes
     */
    private void init() {
        selectorExtractorMap = new LinkedMap();
    }

    /**
     * Register an extractor with this parser.  The extractor will be executed if a document is parsed
     * for which the selector matches true
     **/
    public void registerExtractor(Selector selector, Extractor extractor) {
        selectorExtractorMap.put(selector, extractor);
    }

    /**
     * Register a a composite selector/extractor with this parser.  The extractor will be executed if a
     * document is parsed for which the selector matches true
     **/
    public void registerExtractor(SelectorExtractor extractor) {
        selectorExtractorMap.put(extractor, extractor);
    }

    /**
     * Register a single extractor with this parser.  The extractor will be always be executed
     **/
    public void registerExtractor(Extractor extractor) {
        selectorExtractorMap.put(new DefaultSelector(true), extractor);
    }

    /**
     * Reads a HTML document from the input stream and uses an extractor to create a representive object.
     *
     * Reads the input stream and creates a HTMLDocument.  Fires the extractor for the document
     **/
    public Object parseDocument(String source, InputStream inputStream) throws IOException, SAXException, AmbiguousExtractorException {
        DOMParser parser = new DOMParser();
        parser.setFeature("http://xml.org/sax/features/namespaces", false);  // this is needed for xhtml       
        parser.parse(new InputSource(inputStream));

        HTMLDocumentDecorator document = new HTMLDocumentDecorator((HTMLDocument) parser.getDocument());
        return extractContent(source, document);
    }

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
    private Object extractContent(String source, HTMLDocumentDecorator document) throws AmbiguousExtractorException {

        Object result = null;
        Selector selector = evaluateSelector(source, document);

        if (selector != null) {
            result = extractContent(selector, source, document);
        }
        return result;
    }

    /**
     * Evaluate which selector matches the given document
     * @throws AmbiguousExtractorException if more than one selector matches the document 
     **/
    protected Selector evaluateSelector(String source, HTMLDocumentDecorator document) throws AmbiguousExtractorException {
        List<Selector> matches = new LinkedList<Selector>();
        Selector selector;
        Object result = null;
        MapIterator iterator = selectorExtractorMap.mapIterator();

        // evaluate which selectors match the document
        while (iterator.hasNext()) {
            selector = (Selector) iterator.next();
            if (selector.matches(source, document)) {
                matches.add(selector);
            }
        }

        if (matches.size() > 1) {
            // more than one selector matches this document - throw an exception
            throw new AmbiguousExtractorException(matches);
        } else {
            if (matches.size() == 1) {
                selector = matches.get(0);
            } else {
                selector = null;
            }
        }
        return selector;
    }

    /** Extract the content using the extractor for the specified selector */
    private Object extractContent(Selector selector, String source, HTMLDocumentDecorator document) {
        Object result = null;

        Extractor extractor = (Extractor) selectorExtractorMap.get(selector);
        if (extractor != null) {
            result = extractor.extractContent(source, document);
        }
        return result;
    }

}
