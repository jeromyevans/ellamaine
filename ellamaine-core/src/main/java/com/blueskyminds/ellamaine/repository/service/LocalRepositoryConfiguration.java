package com.blueskyminds.ellamaine.repository.service;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import java.util.*;

import com.blueskyminds.homebyfive.framework.core.tools.text.StringTools;
import com.google.inject.Inject;

/**
 * Identifies the locations to find repository entiries in the local filesystem based on their range
 *
 * Date Started: 24/06/2007
 * <p/>
 * History:
 */
public class LocalRepositoryConfiguration {

    private static final Log LOG = LogFactory.getLog(LocalRepositoryConfiguration.class);

    private String defaultPath = "";
    private List<RepositoryPathEntry> repositoryPaths;

    /** Create a list of repository paths using the ranges supplied via properties.
     *
     * The properties have a suffix of
     *   from-to
     * where from and to are identifier numbers inclusive
     *
     * The property value is the absolute base path
     *
     *  */
    @Inject
    public LocalRepositoryConfiguration(@RepositoryProperties Properties properties) {
        repositoryPaths = new LinkedList<RepositoryPathEntry>();
        for (Object key : properties.keySet()) {
            String suffix = StringUtils.substringAfterLast((String) key, ".");
            if (suffix.contains("-")) {
                String fromStr = StringUtils.substringBefore(suffix, "-");
                String toStr = StringUtils.substringAfter(suffix, "-");

                int from = StringTools.extractInt(fromStr, -1);
                int to = StringTools.extractInt(toStr, -1);

                if ((from >= 0) && (to >= 0)) {
                    repositoryPaths.add(new RepositoryPathEntry(from, to, (String) properties.get(key)));
                }
            } else {
                repositoryPaths.add(new RepositoryPathEntry(null, null, (String) properties.get(key)));
            }
        }

        // sort the entries
        Collections.sort(repositoryPaths);
    }

    public void setDefaultPath(String defaultPath) {
        this.defaultPath = defaultPath;
    }

    public String getBasePath(int identifier) {
        String basePath = defaultPath;
        for (RepositoryPathEntry entry : repositoryPaths) {
            if (entry.contains(identifier)) {
                basePath = entry.getPath();
                break;
            }
        }
        return basePath;
    }
}
