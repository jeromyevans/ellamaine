package com.blueskyminds.ellamaine.html;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.w3c.dom.html.HTMLTableElement;
import org.w3c.dom.html.HTMLTableRowElement;
import org.w3c.dom.html.HTMLElement;
import org.w3c.dom.html.HTMLTableCellElement;
import org.apache.commons.lang.StringUtils;

import java.util.List;
import java.util.LinkedList;

import com.blueskyminds.framework.tools.text.StringTools;

/**
 * Date Started: 10/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class HtmlTools {

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

    public static final String TD = "td";
    public static final String TR = "tr";
    public static final String TABLE = "table";

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
    public static String getNextText(Node node) {
        return extractTextPattern(null, node);
    }

    /** Gets all the text that's a child of the given node */
    public static List<String> getText(Node node) {
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

    /** Recursive method that looks for the text matching the given pattern that'sa child of node
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

        return node;
    }

    /**
     * @param pattern
     * @return true if the node contains the given text pattern (exact match)
     */
    public static boolean containsText(Node node, String pattern) {
        return node.getTextContent().contains(pattern);
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
}
