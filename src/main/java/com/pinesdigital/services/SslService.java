package com.denysov.essex.services;

import com.denysov.essex.model.SslCertificate;

import java.util.List;

public interface SslService {

    List<SslCertificate> findByUserId(Long userId);
    List<SslCertificate> findByUserUsername(String username);
}
