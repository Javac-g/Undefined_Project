package com.denysov.essex.repository;

import com.denysov.essex.model.Domain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DomainRepository extends JpaRepository<Domain, Long> {
    List<Domain> findByUserId(Long userId);
    List<Domain> findByUserCredentialLogin(String username);
    long countByUserCredentialLogin(String login);
}
