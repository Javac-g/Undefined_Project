package com.denysov.essex.security;

import lombok.experimental.UtilityClass;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Objects;

@Component
public class CurrentUserProvider {

    public Long getUserId() {
        CustomUserDetails principal =
                (CustomUserDetails) Objects.requireNonNull(SecurityContextHolder
                                .getContext()
                                .getAuthentication())
                        .getPrincipal();

        assert principal != null;
        return principal.getUserId();
    }
}