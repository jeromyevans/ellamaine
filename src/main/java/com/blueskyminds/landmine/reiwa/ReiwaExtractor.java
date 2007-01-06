package com.blueskyminds.landmine.reiwa;

import com.blueskyminds.ellamaine.html.Extractor;
import com.blueskyminds.ellamaine.html.HTMLDocumentDecorator;
import com.blueskyminds.ellamaine.html.HtmlTools;
import com.blueskyminds.property.PropertyAdvertisementTypes;
import com.blueskyminds.property.agent.RealEstateAgentBean;
import com.blueskyminds.property.advertisement.PropertyAdvertisementBean;
import com.blueskyminds.tools.text.StringTools;
import org.w3c.dom.html.HTMLTableElement;
import org.w3c.dom.html.HTMLElement;
import org.w3c.dom.NodeList;
import org.apache.commons.lang.StringUtils;

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
    public static final String FONT = "font";

    private PropertyAdvertisementBean extractLegacyAdvertisement(String source, HTMLDocumentDecorator document) {
        PropertyAdvertisementBean advertisement = new PropertyAdvertisementBean();

        if (document.containsText("Rent")) {
            advertisement.setType(PropertyAdvertisementTypes.Lease);
        } else {
            if (document.containsText("Auction")) {
                advertisement.setType(PropertyAdvertisementTypes.Auction);
            } else {
                advertisement.setType(PropertyAdvertisementTypes.PrivateTreaty);
            }
        }

        HTMLTableElement table3 = document.getTable(2);
        String idSuburbPrice = HtmlTools.getTextContent(HtmlTools.getTableData(table3, 0, 0));
        String description = HtmlTools.getTextContent(HtmlTools.getTableData(table3, 1, 0));

        advertisement.setDescription(description);

        String[] parts = StringUtils.split(idSuburbPrice, "-");
        String id = StringTools.extractInteger(parts[0]);
        String suburb = StringTools.strip(parts[1]);
        String state = "WA";
//        String priceLower = StringTools.extractReal(parts[2], 0);
//        String priceUpper = StringTools.extractReal(parts[2], 1);
//

        advertisement.setPrice(StringTools.strip(parts[2]));

        HTMLTableElement table4 = document.getTable(3);
        String type = HtmlTools.getNextText(table4);
        int bedrooms = StringTools.extractInt(HtmlTools.getNextTextContaining(table4, "Bedrooms"), -1);
        int bathrooms = StringTools.extractInt(HtmlTools.getNextTextContaining(table4, "Bath"), -1);
        float landArea = StringTools.extractFloat(HtmlTools.getNextTextContaining(table4, "sqm"), Float.NaN);
        String yearBuilt = StringTools.extractInteger(HtmlTools.getNextTextContaining(table4, "Age:"));

        advertisement.setPropertyType(type);
        advertisement.setBathrooms(bathrooms);
        advertisement.setBedrooms(bedrooms);
        advertisement.setLandArea(landArea);
        advertisement.setFloorArea(Float.NaN);
        advertisement.setConstructionDate(yearBuilt);

        String address = null;
        HTMLTableElement table6 = document.getTable(5);
        if (HtmlTools.containsText(table6, "Address:")) {
            address = HtmlTools.getTextContent(HtmlTools.getTableData(table6, 0, 1));
        }

        advertisement.setAddress1(address);
        advertisement.setSuburb(suburb);
        advertisement.setState(state);

        NodeList blockQuotes = document.getElementsByTagName(BLOCKQUOTE);
        HTMLElement featuresBlock;
        List<String> features = null;
        if (blockQuotes.getLength() > 0) {
            featuresBlock = (HTMLElement) blockQuotes.item(0);
            features = HtmlTools.getText(featuresBlock);
        }
        advertisement.setFeatures(features);

        RealEstateAgentBean agent = new RealEstateAgentBean();

        HTMLTableElement contactInfoTable = HtmlTools.getTableContainingText(document.getBody(), "For More Information Contact:");
        HTMLTableElement contactTable = HtmlTools.getTable(contactInfoTable, 0);

        NodeList contactLines = contactTable.getElementsByTagName(FONT);
        if (contactLines.getLength() > 0) {
            agent.setContactName(HtmlTools.getTextContent((HTMLElement) contactLines.item(0)));
        }
        if (contactLines.getLength() > 1) {
            agent.setAgencyName(HtmlTools.getNextText(contactLines.item(1)));
        }

        agent.setPhone(StringUtils.removeStart(HtmlTools.getNextTextContaining(contactTable, "Office:"), "Office:"));
        agent.setFax(StringUtils.removeStart(HtmlTools.getNextTextContaining(contactTable, "Fax:"), "Fax:"));
        agent.setMobile(StringUtils.removeStart(HtmlTools.getNextTextContaining(contactTable, "Mobile:"), "Mobile:"));
        agent.setEmail(HtmlTools.getNextTextContaining(contactTable, "@"));
        agent.setWebsite(HtmlTools.getNextTextContaining(contactTable, "www"));

        advertisement.setAgent(agent);


        // submit for processing

        return advertisement;
    }

    // ------------------------------------------------------------------------------------------------------
}
