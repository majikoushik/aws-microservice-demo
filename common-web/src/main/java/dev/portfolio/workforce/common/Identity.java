package dev.portfolio.workforce.common;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/** Authorization helpers. Ownership checks happen inside SERVICES, not only controllers. */
public final class Identity {
    private Identity() {}
    public static String subject() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !a.isAuthenticated()) throw new AccessDeniedException("Login required");
        return a.getName();
    }
    public static boolean hasRole(String name) {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getAuthorities().stream().anyMatch(x -> x.getAuthority().equals("ROLE_" + name));
    }
    public static void require(boolean permitted) {
        if (!permitted) throw new AccessDeniedException("You are not allowed to access this record");
    }
}
