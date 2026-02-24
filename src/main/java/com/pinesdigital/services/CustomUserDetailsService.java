package com.denysov.essex.services;

import org.springframework.security.core.userdetails.UserDetails;

public interface CustomUserDetailsService {
    public UserDetails loadUserByUsername(String username);
}
