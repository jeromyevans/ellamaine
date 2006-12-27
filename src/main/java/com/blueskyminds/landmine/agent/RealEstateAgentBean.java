package com.blueskyminds.landmine.agent;

/**
 * Simple representation of the details for a real estate agent with loosely typed values
 * <p/>
 * Date Started: 27/12/2006
 * <p/>
 * History:
 * <p/>
 * Copyright (c) 2006 Blue Sky Minds Pty Ltd<br/>
 */
public class RealEstateAgentBean {

    private String agencyName;
    private String contactName;
    private String phone;
    private String fax;
    private String mobile;
    private String website;
    private String email;

    // ------------------------------------------------------------------------------------------------------

    /**
     * Initialise the RealEstateAgentBean with default attributes
     */
    private void init() {
    }

    // ------------------------------------------------------------------------------------------------------


    public String getAgencyName() {
        return agencyName;
    }

    public void setAgencyName(String agencyName) {
        this.agencyName = agencyName;
    }

    public String getContactName() {
        return contactName;
    }

    public void setContactName(String contactName) {
        this.contactName = contactName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getFax() {
        return fax;
    }

    public void setFax(String fax) {
        this.fax = fax;
    }

    public String getMobile() {
        return mobile;
    }

    public void setMobile(String mobile) {
        this.mobile = mobile;
    }

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
