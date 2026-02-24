package com.denysov.essex.services.impl;

import com.denysov.essex.model.Credential;
import com.denysov.essex.repository.CredentialRepository;
import com.denysov.essex.services.CustomUserDetailsService;
import lombok.AllArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@AllArgsConstructor
public class CustomUserDetailsServiceImpl implements UserDetailsService, CustomUserDetailsService {

    private final CredentialRepository credentialRepo;

    @Override
    public UserDetails loadUserByUsername(String username) {

        Credential cred = credentialRepo.findByLogin(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return User.builder()
                .username(cred.getLogin())
                .password(cred.getPasswordHash())
                .roles(cred.getRole().getName())
                .build();
    }
}