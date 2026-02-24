package com.denysov.essex.services;

import com.denysov.essex.model.PrivateEmail;

import java.util.List;

public interface PrivateEmailService {

    List<PrivateEmail> findByUserId(Long userId);

    // Alternative: by username
    List<PrivateEmail> findByUserUsername(String username);
}
