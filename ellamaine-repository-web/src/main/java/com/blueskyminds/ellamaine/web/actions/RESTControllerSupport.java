package com.blueskyminds.ellamaine.web.actions;

import com.opensymphony.xwork2.*;
import com.opensymphony.xwork2.util.ValueStack;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.util.*;

/**
 * Provides a default implementation for the most common actions.
 * See the documentation for all the interfaces this class implements for more detailed information.
 */
public class RESTControllerSupport implements Validateable, ValidationAware, TextProvider, LocaleProvider {

    private static final Log LOG = LogFactory.getLog(RESTControllerSupport.class);

    private final TextProvider textProvider = new TextProviderFactory().createInstance(getClass(), this);
    private final ValidationAwareSupport validationAware = new ValidationAwareSupport();

    public void setActionErrors(Collection errorMessages) {
        validationAware.setActionErrors(errorMessages);
    }

    public Collection getActionErrors() {
        return validationAware.getActionErrors();
    }

    public void setActionMessages(Collection messages) {
        validationAware.setActionMessages(messages);
    }

    public Collection getActionMessages() {
        return validationAware.getActionMessages();
    }

    /**
     * @deprecated Use {@link #getActionErrors()}.
     */
    public Collection getErrorMessages() {
        return getActionErrors();
    }

    /**
     * @deprecated Use {@link #getFieldErrors()}.
     */
    public Map getErrors() {
        return getFieldErrors();
    }

    public void setFieldErrors(Map errorMap) {
        validationAware.setFieldErrors(errorMap);
    }

    public Map getFieldErrors() {
        return validationAware.getFieldErrors();
    }

    public Locale getLocale() {
        ActionContext ctx = ActionContext.getContext();
        if (ctx != null) {
            return ctx.getLocale();
        } else {
            LOG.debug("Action context not initialized");
            return null;
        }
    }

    public String getText(String aTextName) {
        return textProvider.getText(aTextName);
    }

    public String getText(String aTextName, String defaultValue) {
        return textProvider.getText(aTextName, defaultValue);
    }

    public String getText(String aTextName, String defaultValue, String obj) {
        return textProvider.getText(aTextName, defaultValue, obj);
    }

    public String getText(String aTextName, List args) {
        return textProvider.getText(aTextName, args);
    }

    public String getText(String key, String[] args) {
        return textProvider.getText(key, args);
    }

    public String getText(String aTextName, String defaultValue, List args) {
        return textProvider.getText(aTextName, defaultValue, args);
    }

    public String getText(String key, String defaultValue, String[] args) {
        return textProvider.getText(key, defaultValue, args);
    }

    public String getText(String key, String defaultValue, List args, ValueStack stack) {
        return textProvider.getText(key, defaultValue, args, stack);
    }

    public String getText(String key, String defaultValue, String[] args, ValueStack stack) {
        return textProvider.getText(key, defaultValue, args, stack);
    }

    public ResourceBundle getTexts() {
        return textProvider.getTexts();
    }

    public ResourceBundle getTexts(String aBundleName) {
        return textProvider.getTexts(aBundleName);
    }

    public void addActionError(String anErrorMessage) {
        validationAware.addActionError(anErrorMessage);
    }

    public void addActionMessage(String aMessage) {
        validationAware.addActionMessage(aMessage);
    }

    public void addFieldError(String fieldName, String errorMessage) {
        validationAware.addFieldError(fieldName, errorMessage);
    }

    public boolean hasActionErrors() {
        return validationAware.hasActionErrors();
    }

    public boolean hasActionMessages() {
        return validationAware.hasActionMessages();
    }

    public boolean hasErrors() {
        return validationAware.hasErrors();
    }

    public boolean hasFieldErrors() {
        return validationAware.hasFieldErrors();
    }

    /**
     * Clears field errors. Useful for Continuations and other situations
     * where you might want to clear parts of the state on the same action.
     */
    public void clearFieldErrors() {
        validationAware.clearFieldErrors();
    }

    /**
     * Clears action errors. Useful for Continuations and other situations
     * where you might want to clear parts of the state on the same action.
     */
    public void clearActionErrors() {
        validationAware.clearActionErrors();
    }

    /**
     * Clears messages. Useful for Continuations and other situations
     * where you might want to clear parts of the state on the same action.
     */
    public void clearMessages() {
        validationAware.clearMessages();
    }

    /**
     * Clears all errors. Useful for Continuations and other situations
     * where you might want to clear parts of the state on the same action.
     */
    public void clearErrors() {
        validationAware.clearErrors();
    }

    /**
     * Clears all errors and messages. Useful for Continuations and other situations
     * where you might want to clear parts of the state on the same action.
     */
    public void clearErrorsAndMessages() {
        validationAware.clearErrorsAndMessages();
    }

    /**
     * A default implementation that validates nothing.
     * Subclasses should override this method to provide validations.
     */
    public void validate() {
    }

    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

}
