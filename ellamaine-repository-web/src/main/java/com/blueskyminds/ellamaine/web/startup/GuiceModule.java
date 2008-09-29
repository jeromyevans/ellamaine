package com.blueskyminds.ellamaine.web.startup;

import com.blueskyminds.homebyfive.framework.core.ExtendedGuiceModule;
import com.blueskyminds.homebyfive.framework.core.tools.PropertiesContext;
import com.blueskyminds.ellamaine.repository.service.RepositoryService;
import com.blueskyminds.ellamaine.repository.service.LocalRepositoryService;
import com.blueskyminds.ellamaine.repository.service.LocalRepositoryConfiguration;
import com.blueskyminds.ellamaine.repository.service.RepositoryProperties;
import com.google.inject.name.Names;
import com.google.inject.matcher.Matcher;
import com.google.inject.matcher.Matchers;
import com.wideplay.warp.persist.UnitOfWork;
import com.wideplay.warp.persist.PersistenceService;
import com.wideplay.warp.persist.Transactional;
import com.wideplay.warp.jpa.JpaUnit;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.util.Map;
import java.util.Properties;

/**
 * Date Started: 14/03/2008
 * <p/>
 * History:
 */
public class GuiceModule extends ExtendedGuiceModule {
    private static final Log LOG = LogFactory.getLog(GuiceModule.class);

    protected void configure() {
        LOG.info("Setting up binding...");

        LOG.info("Setting warp-persist...");
        install(PersistenceService.usingJpa().across(UnitOfWork.TRANSACTION).buildModule());
        bindConstant().annotatedWith(JpaUnit.class).to("RepositoryDb");

        // setup the persistence unit when guice is initialised
        bind(PersistenceServiceInitializer.class).asEagerSingleton();

        bindConstants();

        bind(LocalRepositoryConfiguration.class).asEagerSingleton();
        bind(RepositoryService.class).to(LocalRepositoryService.class);
    }

    private void bindConstants() {
        // read the properties and bind them as constants
        Properties properties = PropertiesContext.loadPropertiesFile("ellamaine.properties");
        bind(Properties.class).annotatedWith(RepositoryProperties.class).toInstance(properties);

        for (Map.Entry entry : properties.entrySet()) {
            bindConstant().annotatedWith(Names.named((String) entry.getKey())).to((String) entry.getValue());
        }
    }
}
