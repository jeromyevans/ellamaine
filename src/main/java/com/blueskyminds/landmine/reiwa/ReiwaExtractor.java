package com.blueskyminds.landmine.reiwa;

import com.blueskyminds.ellamaine.html.Extractor;
import com.blueskyminds.ellamaine.html.HTMLDocumentDecorator;
import com.blueskyminds.property.PropertyAdvertisementTypes;

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

    private PropertyAdvertisementBean extractLegacyAdvertisement(String source, HTMLDocumentDecorator document) {
        PropertyAdvertisementBean advertisement = new PropertyAdvertisementBean();
        if (document.containsText("Rent")) {
            advertisement.setType(PropertyAdvertisementTypes.Lease);
        } else {
            advertisement.setType(PropertyAdvertisementTypes.PrivateTreaty);
        }

        return advertisement;
    }

    // ------------------------------------------------------------------------------------------------------
}
