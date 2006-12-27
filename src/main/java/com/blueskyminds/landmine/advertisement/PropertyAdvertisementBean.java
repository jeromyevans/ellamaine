package com.blueskyminds.landmine.advertisement;

import com.blueskyminds.property.PropertyAdvertisementTypes;
import com.blueskyminds.landmine.agent.RealEstateAgentBean;

import java.util.List;
import java.util.LinkedList;

/**
 * A very simple property advertisement bean with non-validated loosely-typed values
 * <p/> 
 * Date Started: 9/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class PropertyAdvertisementBean {

    private PropertyAdvertisementTypes type;
    private String address1;
    private String address2;
    private String suburb;
    private String state;
    private String postCode;

    private String propertyType;
    private int bedrooms;
    private int bathrooms;
    private float landArea;
    private float floorArea;

    private String price;
    private String description;
    private List<String> features;
    private RealEstateAgentBean agent;

    private String constructionDate;

    public PropertyAdvertisementBean() {
        init();
    }

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the PropertyAdvertisementBean with default attributes
     */
    private void init() {
        features = new LinkedList<String>();
    }

    // ------------------------------------------------------------------------------------------------------


    public String getAddress1() {
        return address1;
    }

    public void setAddress1(String address1) {
        this.address1 = address1;
    }

    public String getAddress2() {
        return address2;
    }

    public void setAddress2(String address2) {
        this.address2 = address2;
    }

    public String getSuburb() {
        return suburb;
    }

    public void setSuburb(String suburb) {
        this.suburb = suburb;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public String getPostCode() {
        return postCode;
    }

    public void setPostCode(String postCode) {
        this.postCode = postCode;
    }

    public int getBedrooms() {
        return bedrooms;
    }

    public void setBedrooms(int bedrooms) {
        this.bedrooms = bedrooms;
    }

    public int getBathrooms() {
        return bathrooms;
    }

    public void setBathrooms(int bathrooms) {
        this.bathrooms = bathrooms;
    }

    public float getLandArea() {
        return landArea;
    }

    public void setLandArea(float landArea) {
        this.landArea = landArea;
    }

    public float getFloorArea() {
        return floorArea;
    }

    public void setFloorArea(float floorArea) {
        this.floorArea = floorArea;
    }

    public String getPrice() {
        return price;
    }

    public void setPrice(String price) {
        this.price = price;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<String> getFeatures() {
        return features;
    }

    public void setFeatures(List<String> features) {
        this.features = features;
    }

    public void addFeature(String feature) {
        features.add(feature);
    }

    public PropertyAdvertisementTypes getType() {
        return type;
    }

    public void setType(PropertyAdvertisementTypes type) {
        this.type = type;
    }

    public String getPropertyType() {
        return propertyType;
    }

    public void setPropertyType(String propertyType) {
        this.propertyType = propertyType;
    }

    public RealEstateAgentBean getAgent() {
        return agent;
    }

    public void setAgent(RealEstateAgentBean agent) {
        this.agent = agent;
    }

    public String getConstructionDate() {
        return constructionDate;
    }

    public void setConstructionDate(String constructionDate) {
        this.constructionDate = constructionDate;
    }
}
