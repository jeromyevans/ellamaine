package com.blueskyminds.ellamaine.repository.service;

/**
 * Identifies the path to find repository entries within a particular range
 *
 * Date Started: 24/06/2007
 * <p/>
 * History:
 */
public class RepositoryPathEntry implements Comparable {

    private Integer fromInc;
    private Integer toInc;
    private String path;

    public RepositoryPathEntry(Integer fromInc, Integer toInc, String path) {
        this.fromInc = fromInc;
        this.toInc = toInc;
        this.path = path;
    }

    public Integer getFromInc() {
        return fromInc;
    }

    public Integer getToInc() {
        return toInc;
    }

    public String getPath() {
        return path;
    }

    public boolean isRange() {        
        return (fromInc != null) && (toInc != null);
    }


    public int compareTo(Object o) {
        RepositoryPathEntry other = (RepositoryPathEntry) o;
        if (fromInc != null) {
            if (other.getFromInc() != null) {
                return fromInc.compareTo(other.getFromInc());
            } else {
                return -1;
            }
        } else {
            if (other.getFromInc() != null) {
                return 1;
            } else {
                return 0;  // both null;
            }
        }
    }

    /** True if the identifier is in the range of this entry */
    public boolean contains(int identifier) {
        boolean contained = false;
        if (fromInc != null) {
            if (fromInc <= identifier) {
                if (toInc != null) {
                    if (toInc >= identifier) {
                        contained = true;
                    }
                } else {
                    contained = true;
                }
            }
        } else {
            if (toInc != null) {
                if (toInc >= identifier) {
                    contained = true;
                }
            } else {
                contained = true;
            }
        }

        return contained;
    }
}
