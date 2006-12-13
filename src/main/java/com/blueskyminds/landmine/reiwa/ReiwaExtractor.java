package com.blueskyminds.landmine.reiwa;

import com.blueskyminds.ellamaine.html.Extractor;
import com.blueskyminds.ellamaine.html.HTMLDocumentDecorator;
import com.blueskyminds.ellamaine.html.HtmlTools;
import com.blueskyminds.property.PropertyAdvertisementTypes;
import org.w3c.dom.html.HTMLTableElement;
import org.w3c.dom.html.HTMLElement;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import java.util.List;

/**
 * Extracts the content from a REIWA advertisement
 *
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class ReiwaExtractor implements Extractor<PropertyAdvertisementBean> {

    private enum Versions {
        Legacy,
        Version2
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the ReiwaExtractor with default attributes
     */
    private void init() {
    }


    // ------------------------------------------------------------------------------------------------------

    /**
     *
     * @param sourceUrl the origin of the document
     * @param document the DOM
     * @return the Version of this extractor that can parse the document
     */
    public Enum isSupported(String sourceUrl, HTMLDocumentDecorator document) {
        if (new ReiwaLegacySelector().matches(sourceUrl, document)) {
            return Versions.Legacy;
        } else {
            if (new ReiwaSelector().matches(sourceUrl, document)) {
                return Versions.Version2;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------------------------------------------

    public PropertyAdvertisementBean extractContent(Enum version, String source, HTMLDocumentDecorator document) {
        PropertyAdvertisementBean advertisement = null;

        switch ((Versions) version) {
            case Legacy:
                advertisement = extractLegacyAdvertisement(source, document);
                break;
            case Version2:
                break;
        }

        return advertisement;
    }



    // ------------------------------------------------------------------------------------------------------

    public static final String TD = "td";
    public static final String TR = "tr";
    public static final String BLOCKQUOTE = "blockquote";

    private PropertyAdvertisementBean extractLegacyAdvertisement(String source, HTMLDocumentDecorator document) {
        PropertyAdvertisementBean advertisement = new PropertyAdvertisementBean();
        if (document.containsText("Rent")) {
            advertisement.setType(PropertyAdvertisementTypes.Lease);
        } else {
            advertisement.setType(PropertyAdvertisementTypes.PrivateTreaty);
        }

        HTMLTableElement table3 = document.getTable(2);
        String idSuburbPrice = HtmlTools.getTextContent(HtmlTools.getTableData(table3, 0, 0));
        String description = HtmlTools.getTextContent(HtmlTools.getTableData(table3, 1, 0));

        HTMLTableElement table4 = document.getTable(3);
        String type = HtmlTools.getNextText(table4);
        String bedrooms = HtmlTools.getNextTextContaining(table4, "Bedrooms");
        String bathrooms = HtmlTools.getNextTextContaining(table4, "Bath");
        String landArea = HtmlTools.getNextTextContaining(table4, "sqm");
        String yearBuilt = HtmlTools.getNextTextContaining(table4, "Age:");

        String address = null;
        HTMLTableElement table6 = document.getTable(5);
        if (HtmlTools.containsText(table6, "Address:")) {
            address = HtmlTools.getTextContent(HtmlTools.getTableData(table6, 0, 1));
        }

        NodeList blockQuotes = document.getElementsByTagName(BLOCKQUOTE);
        HTMLElement featuresBlock;
        List<String> features = null;
        if (blockQuotes.getLength() > 0) {
            featuresBlock = (HTMLElement) blockQuotes.item(0);
            features = HtmlTools.getText(featuresBlock);
        }

        // todo: extract details about the agent
        // cleanse the strings
        // add to advertisement bean
        // submit for processing

        return advertisement;
    }

    // ------------------------------------------------------------------------------------------------------
}
