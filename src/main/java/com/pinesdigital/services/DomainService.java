package com.denysov.essex.services;

import com.denysov.essex.model.Domain;

import java.util.List;

public interface DomainService {
    List<Domain> getDomainsByUserId(Long id);
    List<Domain> findByUserCredentialLogin(String username);
    int countByUsername(String username);
    SliceResponse<DomainSummaryDTO> getUserDomains(Long userId, int page, int size);
}
