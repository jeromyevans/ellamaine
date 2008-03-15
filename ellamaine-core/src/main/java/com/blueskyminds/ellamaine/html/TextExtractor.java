package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;
import org.w3c.dom.Node;
import org.w3c.dom.Text;
import org.apache.commons.lang.StringUtils;

import java.net.URL;

/**
 * Extracts all Text Content from HTMLDocument
 * <p/>
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class TextExtractor implements Extractor<String> {

    /**
     * Extracts the text content from the document.
     *
     * @param source
     * @param document
     * @return
     */
    public String extractContent(String source, HTMLDocumentDecorator document) {
        StringBuilder sb = new StringBuilder();
        Node body = document.getBody();
        extractText(sb, body);
        return sb.toString();
    }

    private void extractText(StringBuilder sb, Node node) {
        String text;

        Node child = node.getFirstChild();
        while (child != null) {
            if (child.getNodeType() == Node.TEXT_NODE) {
                text = child.getNodeValue();
                text = StringUtils.trimToEmpty(text);
                text = StringUtils.chomp(text);
                if (!StringUtils.isBlank(text)) {
                    sb.append(text+"\n");
                }
            } else {
                // recurse
                extractText(sb, child);
            }
            child = child.getNextSibling();
        }
    }

}
