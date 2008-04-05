package com.blueskyminds.ellamaine.html;

import org.w3c.dom.html.HTMLDocument;
import org.w3c.dom.html.HTMLElement;
import org.w3c.dom.html.HTMLCollection;
import org.w3c.dom.html.HTMLTableElement;
import org.w3c.dom.*;
import org.apache.commons.lang.StringUtils;

import java.util.List;
import java.util.LinkedList;

import com.blueskyminds.framework.tools.filters.Filter;
import com.blueskyminds.ellamaine.html.filters.AttrValueFilter;

/**
 * Wraps an HTML document with helper methods
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HTMLDocumentDecorator implements HTMLDocument {

    public static final String TABLE = "table";
    public static final String ANCHOR = "a";
    public static final String IMG = "img";

    private HTMLDocument document;

    public HTMLDocumentDecorator(HTMLDocument document) {
        this.document = document;
    }

// ------------------------------------------------------------------------------------------------------

    /**
     * @param pattern
     * @return true if the document's body contains the given text pattern (exact match)
     */
    public boolean containsText(String pattern) {
        return document.getBody().getTextContent().contains(pattern);
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * @param patterns
     * @return true if the document's body contains any of the given text patterns (exact match)
     */
    public boolean containsAnyText(String... patterns) {
        String bodyText = document.getBody().getTextContent();
        boolean found = false;

        for (String pattern : patterns) {
            if (bodyText.contains(pattern)) {
                found = true;
                break;
            }
        }
        return found;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * @param patterns
     * @return true if the document's body contains all of the given text patterns (exact match)
     */
    public boolean containsAllText(String... patterns) {
        String bodyText = document.getBody().getTextContent();
        boolean okay = true;

        for (String pattern : patterns) {
            if (!bodyText.contains(pattern)) {
                okay = false;
                break;
            }
        }
        return okay;
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Get the index'th table in the document
     *
     * @return
     */
    public HTMLTableElement getTable(int index) {
        HTMLTableElement table = null;
        NodeList tableNodes = document.getElementsByTagName(TABLE);
        if (index < tableNodes.getLength()) {
            table = (HTMLTableElement) tableNodes.item(index);
        }
        return table;            
    }

    /** Returns all anchors containing the specified pattern in the anchor body */
    public List<HTMLElement> getAnchorsContainingPattern(String pattern) {
        NodeList anchorList = document.getElementsByTagName(ANCHOR);
        List<HTMLElement> anchors = new LinkedList<HTMLElement>();

        int index = 0;
        while (index < anchorList.getLength()) {
            HTMLElement anchor = (HTMLElement) anchorList.item(index);

            String bodyText = extractText(anchor);
            if (bodyText.contains(pattern)) {
                anchors.add(anchor);
            }
            index++;
        }

        return anchors;
    }

    /** Returns all anchors containing an image with the specified src */
    public List<HTMLElement> getAnchorsContainingImageSrc(String srcPattern) {
        NodeList anchorList = document.getElementsByTagName(ANCHOR);
        List<HTMLElement> anchors = new LinkedList<HTMLElement>();

        int index = 0;
        while (index < anchorList.getLength()) {
            HTMLElement anchor = (HTMLElement) anchorList.item(index);

            NodeList images = anchor.getElementsByTagName(IMG);
            for (int j = 0; j < images.getLength(); j++) {
                HTMLElement image = (HTMLElement) images.item(j);

                String src = image.getAttribute("src");
                if (src.contains(srcPattern)) {
                    anchors.add(anchor);
                    break;
                }
            }

            index++;
        }

        return anchors;
    }

    /** Extracts the text content (only) from a node */
    public String extractText(Node node) {
        StringBuilder sb = new StringBuilder();
        extractText(sb, node);
        return sb.toString();
    }

    /** Extracts the text content from a node */
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

    // ------------------------------------------------------------------------------------------------------


    public String getTitle() {
        return document.getTitle();
    }

    public void setTitle(String title) {
        document.setTitle(title);
    }

    public String getReferrer() {
        return document.getReferrer();
    }

    public String getDomain() {
        return document.getDomain();
    }

    public String getURL() {
        return document.getURL();
    }

    public HTMLElement getBody() {
        return document.getBody();
    }

    public void setBody(HTMLElement body) {
        document.setBody(body);
    }

    public HTMLCollection getImages() {
        return document.getImages();
    }

    public HTMLCollection getApplets() {
        return document.getApplets();
    }

    public HTMLCollection getLinks() {
        return document.getLinks();
    }

    public HTMLCollection getForms() {
        return document.getForms();
    }

    public HTMLCollection getAnchors() {
        return document.getAnchors();
    }

    public String getCookie() {
        return document.getCookie();
    }

    public void setCookie(String cookie) {
        document.setCookie(cookie);
    }

    public void open() {
        document.open();
    }

    public void close() {
        document.close();
    }

    public void write(String text) {
        document.write(text);
    }

    public void writeln(String text) {
        document.writeln(text);
    }

    public NodeList getElementsByName(String elementName) {
        return document.getElementsByName(elementName);
    }

    public DocumentType getDoctype() {
        return document.getDoctype();
    }

    public DOMImplementation getImplementation() {
        return document.getImplementation();
    }

    public Element getDocumentElement() {
        return document.getDocumentElement();
    }

    public Element createElement(String tagName) throws DOMException {
        return document.createElement(tagName);
    }

    public DocumentFragment createDocumentFragment() {
        return document.createDocumentFragment();
    }

    public Text createTextNode(String data) {
        return document.createTextNode(data);
    }

    public Comment createComment(String data) {
        return document.createComment(data);
    }

    public CDATASection createCDATASection(String data) throws DOMException {
        return document.createCDATASection(data);
    }

    public ProcessingInstruction createProcessingInstruction(String target, String data) throws DOMException {
        return document.createProcessingInstruction(target, data);
    }

    public Attr createAttribute(String name) throws DOMException {
        return document.createAttribute(name);
    }

    public EntityReference createEntityReference(String name) throws DOMException {
        return document.createEntityReference(name);
    }

    public NodeList getElementsByTagName(String tagname) {
        return document.getElementsByTagName(tagname);
    }

    public Node importNode(Node importedNode, boolean deep) throws DOMException {
        return document.importNode(importedNode, deep);
    }

    public Element createElementNS(String namespaceURI, String qualifiedName) throws DOMException {
        return document.createElementNS(namespaceURI, qualifiedName);
    }

    public Attr createAttributeNS(String namespaceURI, String qualifiedName) throws DOMException {
        return document.createAttributeNS(namespaceURI, qualifiedName);
    }

    public NodeList getElementsByTagNameNS(String namespaceURI, String localName) {
        return document.getElementsByTagNameNS(namespaceURI, localName);
    }

    public Element getElementById(String elementId) {
        return document.getElementById(elementId);
    }

    public String getInputEncoding() {
        return document.getInputEncoding();
    }

    public String getXmlEncoding() {
        return document.getXmlEncoding();
    }

    public boolean getXmlStandalone() {
        return document.getXmlStandalone();
    }

    public void setXmlStandalone(boolean xmlStandalone) throws DOMException {
        document.setXmlStandalone(xmlStandalone);
    }

    public String getXmlVersion() {
        return document.getXmlVersion();
    }

    public void setXmlVersion(String xmlVersion) throws DOMException {
        document.setXmlVersion(xmlVersion);
    }

    public boolean getStrictErrorChecking() {
        return document.getStrictErrorChecking();
    }

    public void setStrictErrorChecking(boolean strictErrorChecking) {
        document.setStrictErrorChecking(strictErrorChecking);
    }

    public String getDocumentURI() {
        return document.getDocumentURI();
    }

    public void setDocumentURI(String documentURI) {
        document.setDocumentURI(documentURI);
    }

    public Node adoptNode(Node source) throws DOMException {
        return document.adoptNode(source);
    }

    public DOMConfiguration getDomConfig() {
        return document.getDomConfig();
    }

    public void normalizeDocument() {
        document.normalizeDocument();
    }

    public Node renameNode(Node n, String namespaceURI, String qualifiedName) throws DOMException {
        return document.renameNode(n, namespaceURI, qualifiedName);
    }

    public String getNodeName() {
        return document.getNodeName();
    }

    public String getNodeValue() throws DOMException {
        return document.getNodeValue();
    }

    public void setNodeValue(String nodeValue) throws DOMException {
        document.setNodeValue(nodeValue);
    }

    public short getNodeType() {
        return document.getNodeType();
    }

    public Node getParentNode() {
        return document.getParentNode();
    }

    public NodeList getChildNodes() {
        return document.getChildNodes();
    }

    public Node getFirstChild() {
        return document.getFirstChild();
    }

    public Node getLastChild() {
        return document.getLastChild();
    }

    public Node getPreviousSibling() {
        return document.getPreviousSibling();
    }

    public Node getNextSibling() {
        return document.getNextSibling();
    }

    public NamedNodeMap getAttributes() {
        return document.getAttributes();
    }

    public Document getOwnerDocument() {
        return document.getOwnerDocument();
    }

    public Node insertBefore(Node newChild, Node refChild) throws DOMException {
        return document.insertBefore(newChild, refChild);
    }

    public Node replaceChild(Node newChild, Node oldChild) throws DOMException {
        return document.replaceChild(newChild, oldChild);
    }

    public Node removeChild(Node oldChild) throws DOMException {
        return document.removeChild(oldChild);
    }

    public Node appendChild(Node newChild) throws DOMException {
        return document.appendChild(newChild);
    }

    public boolean hasChildNodes() {
        return document.hasChildNodes();
    }

    public Node cloneNode(boolean deep) {
        return document.cloneNode(deep);
    }

    public void normalize() {
        document.normalize();
    }

    public boolean isSupported(String feature, String version) {
        return document.isSupported(feature, version);
    }

    public String getNamespaceURI() {
        return document.getNamespaceURI();
    }

    public String getPrefix() {
        return document.getPrefix();
    }

    public void setPrefix(String prefix) throws DOMException {
        document.setPrefix(prefix);
    }

    public String getLocalName() {
        return document.getLocalName();
    }

    public boolean hasAttributes() {
        return document.hasAttributes();
    }

    public String getBaseURI() {
        return document.getBaseURI();
    }

    public short compareDocumentPosition(Node other) throws DOMException {
        return document.compareDocumentPosition(other);
    }

    public String getTextContent() throws DOMException {
        return document.getTextContent();
    }

    public void setTextContent(String textContent) throws DOMException {
        document.setTextContent(textContent);
    }

    public boolean isSameNode(Node other) {
        return document.isSameNode(other);
    }

    public String lookupPrefix(String namespaceURI) {
        return document.lookupPrefix(namespaceURI);
    }

    public boolean isDefaultNamespace(String namespaceURI) {
        return document.isDefaultNamespace(namespaceURI);
    }

    public String lookupNamespaceURI(String prefix) {
        return document.lookupNamespaceURI(prefix);
    }

    public boolean isEqualNode(Node arg) {
        return document.isEqualNode(arg);
    }

    public Object getFeature(String feature, String version) {
        return document.getFeature(feature, version);
    }

    public Object setUserData(String key, Object data, UserDataHandler handler) {
        return document.setUserData(key, data, handler);
    }

    public Object getUserData(String key) {
        return document.getUserData(key);
    }
}
