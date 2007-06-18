package com.blueskyminds.ellamaine.html;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.w3c.dom.html.*;
import org.apache.commons.lang.StringUtils;

import java.util.List;
import java.util.LinkedList;

import com.blueskyminds.framework.tools.text.StringTools;
import com.blueskyminds.framework.tools.filters.Filter;
import com.blueskyminds.ellamaine.html.filters.AttrValueFilter;

/**
 * Date Started: 10/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlTools {

    public static final String HREF = "href";
    public static final String DIV = "div";
    public static final String CLASS = "class";
    public static final String H1 = "h1";
    public static final String H2 = "h2";
    public static final String UL = "ul";
    public static final String ANCHOR = "a";
    public static final String ID = "id";
    public static final String SPAN = "span";
    
    public static final String TABLE = "table";
    public static final String TD = "td";
    public static final String TR = "tr";
    public static final String BLOCKQUOTE = "blockquote";
    public static final String FONT = "font";
    public static final String DL = "dl";
    public static final String DT = "dt";
    public static final String P = "p";


    private enum SearchStartPoint {
        Exact,
        Child,
        Sibling,
        SiblingOrNextParent,
        TextSiblingOrNextParent
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the HtmlTools with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------

    /** Get a table row from a table */
    public static HTMLTableRowElement getTableRow(HTMLTableElement table, int rowNo) {
        HTMLTableRowElement tableRow = null;
        NodeList rows = table.getElementsByTagName(TR);
        if (rowNo < rows.getLength()) {
            tableRow = (HTMLTableRowElement) rows.item(rowNo);
        }

        return tableRow;
    }

    /** Get a table data from a table */
    public static HTMLTableCellElement getTableData(HTMLTableElement table, int rowNo, int columnNo) {
        HTMLTableRowElement tableRow = getTableRow(table, rowNo);
        HTMLTableCellElement tableData = null;

        if (tableRow != null) {
            NodeList data = tableRow.getElementsByTagName(TD);
            if (columnNo < data.getLength()) {
                tableData = (HTMLTableCellElement) data.item(columnNo);
            }
        }

        return tableData;
    }

    /** Removes spurious whitespace from the text, including end-of-line characters */
    public static String cleanseText(String text) {
        String cleansed = null;
        if (text != null) {
            String[] words = StringUtils.split(text, null);
            List<String> nonBlankWords = new LinkedList<String>();
            for (String word : words) {
                //word = StringUtils.deleteWhitespace(word);
                word = StringTools.strip(word);    // remove non-breaking spaces too
                if (!StringUtils.isBlank(word)) {
                    nonBlankWords.add(word);
                }
            }
            cleansed = StringUtils.join(nonBlankWords.iterator(), " ");
        }

        return cleansed;
    }

    /**
     * Gets the text content in an element.
     * @param element If it's null, then null is returned
     */
    public static String getTextContent(HTMLElement element) {
        if (element != null) {
            return cleanseText(element.getTextContent());
        } else {
            return null;
        }
    }

    /** Gets the next text node that's a child of the given node */
    public static String getNextTextChild(Node node) {
        return extractTextPattern(null, node);
    }
     
    /** Gets all the text that's a child of the given node */
    public static List<String> getTextList(Node node) {
        List<Node> textNodes = searchForNodes(Node.TEXT_NODE, node, SearchStartPoint.Child);
        String text;
        List<String> textValues = new LinkedList<String>();

        for (Node textNode: textNodes) {
            text = cleanseText(textNode.getNodeValue());
            if (StringUtils.isNotBlank(text)) {
                textValues.add(text);
            }
        }
        
        return textValues;
    }

    public static String getNextTextContaining(Node node, String pattern) {
        return extractTextPattern(pattern, node);
    }

    /** Returns the text content of the next text element after a text element containing the specified pattern
     * Starts searching from the first child of the node
     *
     * This is a slow implementation
     * */
    public static String getNextTextAfterPattern(Node node, String pattern) {
        List<String> allText = getTextList(node);
        boolean found = false;
        String nextText = null;

        for (String current : allText) {
            if (found) {
                nextText = current;
                break;
            } else {
                if (current.contains(pattern)) {
                    found = true;
                }
            }
        }
        return nextText;
    }

    /** Extracts ALL the text content (only) from a node */
    public static String getText(Node node) {
        StringBuilder sb = new StringBuilder();
        extractText(sb, node);
        return cleanseText(sb.toString());
    }

    /** Extracts the text content from a node */
    private static void extractText(StringBuilder sb, Node node) {
        String text;

        Node child = node.getFirstChild();
        while (child != null) {
            if (child.getNodeType() == Node.TEXT_NODE) {
                text = child.getNodeValue();
                text = StringUtils.trimToEmpty(text);
                text = StringUtils.chomp(text);
                if (!StringUtils.isBlank(text)) {
                    sb.append(text+" ");
                }
            } else {
                // recurse
                extractText(sb, child);
            }
            child = child.getNextSibling();
        }
    }


    // todo: this is disabled because TextSiblingOrNextParent doesn't work and is a bit dodgy - try to find
    // a better way to address the element you're arfter
//    public static String getNextTextAfterPattern(Node node, String pattern) {
//        String text = null;
//
//        Text textNode = searchForTextPattern(pattern, node, SearchStartPoint.Child);
//        if (textNode != null) {
//            Text nextText = searchForTextPattern(pattern, textNode, SearchStartPoint.TextSiblingOrNextParent);
//            if (nextText != null) {
//                text = cleanseText(nextText.getNodeValue());
//            }
//        }
//        return text;
//    }

    /** Recursive method that looks for the text matching the given pattern that'sa child of node
     * A null pattern will match any text (the next text) */
    private static String extractTextPattern(String pattern, Node parentNode) {
        String text = null;

        Text textNode = searchForTextPattern(pattern, parentNode, SearchStartPoint.Child);
        if (textNode != null) {
            text = cleanseText(textNode.getNodeValue());
        }

        return text;
    }

    /** Recursive method that looks for the text matching the given pattern that's a child of node
     * A null pattern will match any text (the next text)
     * @param startNode the starting point
     * @param childOrSibling whether to start at the starting node exactly, the first child of the startingNode, or the
     *  next sibling of the starting node
     * @param pattern
     * @return */
    private static Text searchForTextPattern(String pattern, Node startNode, SearchStartPoint childOrSibling) {
        Text text = null;
        String textValue;
        boolean found = false;
        Node node = calculateStartNode(startNode, childOrSibling);

        while ((node != null) && (!found)) {
            if (node.getNodeType() == Node.TEXT_NODE) {
                text = (Text) node;
                textValue = text.getNodeValue();
                if (pattern != null) {
                    // test the pattern
                    if (textValue.contains(pattern)) {
                        // found it
                        found = true;
                    }
                } else {
                    // match any non-blank text
                    if (StringUtils.isNotBlank(textValue)) {
                        found = true;
                    }
                }
            } else {
                // recurse
                text = searchForTextPattern(pattern, node, SearchStartPoint.Child);
                if (text != null) {
                    found = true;
                }
            }
            node = node.getNextSibling();
        }

        if (found) {
            return text;
        } else {
            return null;
        }
    }

    /** Recursive method that looks for all the nodes of a specified type
     * @param nodeType type of node to find
     * @param startNode the starting point
     * @param childOrSibling whether to start at the starting node exactly, the first child of the startingNode, or the
     *  next sibling of the starting node
     * @return */
    private static List<Node> searchForNodes(short nodeType, Node startNode, SearchStartPoint childOrSibling) {
        boolean found = false;
        List<Node> foundNodes = new LinkedList<Node>();
        Node node = calculateStartNode(startNode, childOrSibling);

        while ((node != null) && (!found)) {
            if (node.getNodeType() == nodeType) {
                foundNodes.add(node);
            }                        

            if (node.getFirstChild() != null) {
                // recurse into children
                foundNodes.addAll(searchForNodes(nodeType, node, SearchStartPoint.Child));
            }
            // check siblings
            node = node.getNextSibling();
        }

        return foundNodes;
    }

    /** Determines which node to start on given the SearchStartPoint value */
    private static Node calculateStartNode(Node startNode, SearchStartPoint childOrSibling) {
        Node node = null;

        if (startNode != null) {
            switch (childOrSibling) {
                case Child:
                    node = startNode.getFirstChild();
                    break;
                case Exact:
                    node = startNode;
                    break;
                case Sibling:
                    node = startNode.getNextSibling();
                    break;
                case SiblingOrNextParent:
                    node = startNode.getNextSibling();
                    if (node == null) {
                        // if there's no sibling, go to the parent and use their sibling
                        if (startNode.getParentNode() != null) {
                            node = startNode.getParentNode().getNextSibling();
                        }
                    }
                    break;
                case TextSiblingOrNextParent:
                    // uses the next non-blank TextNode sibling, otherwise the parent's sibling
                    boolean found = false;
                    String value;
                    node = startNode;

                    while (!found) {
                        // todo: this should be recurisve, searching the parent's siblings and above until the first non-null
                        node = node.getNextSibling();
                        if (node != null) {
                            if (node.getNodeType() == Node.TEXT_NODE) {
                                value = cleanseText(node.getTextContent());
                                if (StringUtils.isNotBlank(value)) {
                                    found = true;
                                }
                            }
                        } else {
                            // if there's text no sibling, go to the parent and use their sibling
                            if (startNode.getParentNode() != null) {
                                node = startNode.getParentNode().getNextSibling();
                            } else {
                                node = null;
                            }
                            found = true;
                        }
                    }
                    break;
            }
        }

        return node;
    }

    /**
     * @param pattern
     * @return true if the node contains the given text pattern (exact match)
     */
    public static boolean containsText(Node node, String pattern) {
        if (node != null) {
            String content = node.getTextContent();
            if (content != null) {
                return content.contains(pattern);
            }
        }
        return false;
    }

    /**
     *
     * @param element
     * @param tableIndex stating from 0
     * @return
     */
    public static HTMLTableElement getTable(HTMLElement element, int tableIndex) {
        NodeList tables = element.getElementsByTagName(TABLE);
        HTMLTableElement match = null;
        if (element instanceof HTMLTableElement) {
            // exclude self
            if (tables.getLength() > tableIndex+1) {
                match = (HTMLTableElement) tables.item(tableIndex+1);
            }
        } else {
            if (tables.getLength() > tableIndex) {
                match = (HTMLTableElement) tables.item(tableIndex);
            }
        }
        return match;
    }

    /** Locate the first HTML table element containing the text pattern */
    public static HTMLTableElement getTableContainingText(HTMLElement element, String pattern) {
        NodeList tables = element.getElementsByTagName(TABLE);
        HTMLTableElement match = null;
        int index = 0;
        while ((match == null) && (index < tables.getLength())) {
            if (tables.item(index).getTextContent().contains(pattern)) {
                match = (HTMLTableElement) tables.item(index);
            }
            index++;
        }
        return match;
    }

    /**
     * Prune all nodes from the element before the specified node.
     *
     * @return true if the target element was found, otherwise the result is false and the
     *  element will now be empty */
    public static boolean pruneBefore(HTMLElement parent, Node target) {
        boolean found = false;
        Node node = calculateStartNode(parent, SearchStartPoint.Child);
        while ((node != null) && (!found)) {
            if (node == target) {
                found = true;
            } else {
                if (!hasDescendant(node, target)) {
                    Node child = node;
                    // go to sibling
                    node = node.getNextSibling();
                    // now remove the child
                    parent.removeChild(child);
                } else {
                    // the target node is a descendant of this node - now search deeper
                    found = pruneBefore((HTMLElement) node, target);
                }
            }
        }
        return found;
    }

    /**
     * Prune all nodes within the element after the specified node.
     *
     * @param inclusive if true, the target will also be removed
     *
     * @return true if the target element was found, otherwise the result is false and the
     *  element will now be empty */
    public static boolean pruneAfter(HTMLElement parent, Node target, boolean inclusive) {
        boolean found = false;
        Node node = calculateStartNode(parent, SearchStartPoint.Child);
        while (node != null) {
            if (node == target) {
                found = true;
                // go to sibling and start pruning
                node = node.getNextSibling();

                if (inclusive) {
                    parent.removeChild(target);
                }
            } else {
                if (!found) {
                    if (hasDescendant(node, target)) {
                        // the target node is a descendant of this one - now search deeper
                        found = pruneAfter((HTMLElement) node, target, inclusive);
                    } else {
                        // go to sibling and keep searching
                        node = node.getNextSibling();
                    }
                } else {
                    // we're after the node now so we can prune
                    if (!hasDescendant(node, target)) {
                         Node child = node;
                        // go to sibling
                        node = node.getNextSibling();
                        // now remove the child
                        parent.removeChild(child);
                    } else {
                        // go to sibling
                        node = node.getNextSibling();
                    }
                }
            }
        }
        return found;
    }

    /**
     * Determines whether the specified node is a descendant of the ancestor (ie. a child or child's child)
     *
     * @return */
    public static boolean hasDescendant(Node ancestor, Node descendant) {
        boolean found = false;
        Node node = calculateStartNode(ancestor, SearchStartPoint.Child);

        while ((node != null) && (!found)) {
            if (node == descendant) {
                found = true;
            } else {
                if (node.hasChildNodes()) {
                    // recurse into children
                    found = hasDescendant(node, descendant);
                }
            }

            // check siblings
            node = node.getNextSibling();
        }

        return found;
    }

    public static NodeList getElementsByTagName(HTMLDocument document, String tagName) {
        return document.getElementsByTagName(tagName);
    }

    public static NodeList getElementsByTagName(HTMLElement element, String tagName) {
        return element.getElementsByTagName(tagName);
    }

    public static NodeList getElementsByTagName(Node node, String tagName) {
        if (node instanceof HTMLElement) {
            return getElementsByTagName((HTMLElement) node, tagName);
        } else {
            if (node instanceof HTMLDocument) {
                return getElementsByTagName((HTMLDocument) node, tagName);
            } else {
                return null;
            }
        }
    }

    // ------------------------------------------------------------------------------------------------------

    /** Return the first element of the specified tag with an attribute with the given name and value */
    public static HTMLElement getFirstElementByTagAndAttribute(Node elementOrDocument, String tagName, String attrName, String attrValue) {

        NodeList elements = getElementsByTagName(elementOrDocument, tagName);
        if (elements != null) {
            return filterFirst(elements, new AttrValueFilter(attrName, attrValue));
        } else {
            return null;
        }
    }

    /** Return the first element of the specified tag with an attribute with the given name and value */
    public static HTMLElement getFirstElementByTagName(Node elementOrDocument, String tagName) {
        NodeList elements = getElementsByTagName(elementOrDocument, tagName);
        if (elements != null) {
            if (elements.getLength() > 0) {
                return (HTMLElement) elements.item(0);
            }
        }
        return null;
    }

    /**
     * Filters HTMLElements from a node list
     * @return the list of accepted HTMLElements
     **/
    public static List<HTMLElement> filter(NodeList nodeList, Filter<HTMLElement> filter) {
        int index = 0;
        List<HTMLElement> accepted = new LinkedList<HTMLElement>();
        String attr;
        HTMLElement node;

        while (index < nodeList.getLength()) {
            node = (HTMLElement) nodeList.item(index);
            if (filter.accept(node)) {
                accepted.add(node);
            }
            index++;
        }
        return accepted;
    }

    /**
     * Filters HTMLElements from a node list and returns the first match
     * @return the first accepted HTMLElement, or null if not found
     **/
    public static HTMLElement filterFirst(NodeList nodeList, Filter<HTMLElement> filter) {
        int index = 0;
        List<HTMLElement> accepted = new LinkedList<HTMLElement>();
        HTMLElement node = null;
        boolean found = false;

        while ((index < nodeList.getLength()) && (!found)) {
            node = (HTMLElement) nodeList.item(index);
            if (filter.accept(node)) {
                found = true;
            }
            index++;
        }

        if (found) {
            return node;
        } else {
            return null;
        }
    }

    /**
     * Prints the entire element
     *
     * @param startNode the starting point
     * @return */
    public static void printOutline(Node startNode) {

        printOutline(startNode, 0);
    }

    /**
     * Prints the entire element showing tags and text but not attributes
     *
     * @param startNode the starting point
     * @return */
    private static void printOutline(Node startNode, int level) {
        boolean found = false;
        Node node = calculateStartNode(startNode, SearchStartPoint.Exact);

        while ((node != null) && (!found)) {
            if (node.getNodeType() == Node.TEXT_NODE) {

                String textValue = cleanseText(node.getNodeValue());
                if (StringUtils.isNotBlank(textValue)) {
                    System.out.println(StringTools.fill(" ", level)+textValue);
                }
            } else {

                if (node.getNodeType() == Node.ELEMENT_NODE) {
                    String nodeName = StringUtils.lowerCase(node.getNodeName());
                    if (node.hasChildNodes()) {
                        System.out.println(StringTools.fill(" ", level)+"<"+nodeName+">");
                        // recurse into children
                        printOutline(node.getFirstChild(), level+1);
                        System.out.println(StringTools.fill(" ", level)+"</"+nodeName+">");
                    } else {
                        System.out.println(StringTools.fill(" ", level)+"<"+nodeName+"/>");
                    }
                }

            }
            // check siblings
            node = node.getNextSibling();
        }
    }
}
