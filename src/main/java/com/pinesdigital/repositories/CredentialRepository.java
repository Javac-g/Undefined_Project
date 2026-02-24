package com.denysov.essex.repository;

import com.denysov.essex.model.Credential;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CredentialRepository extends JpaRepository<Credential, Long> {
    Optional<Credential> findByLogin(String login);
    boolean existsByLogin(String login);
    boolean existsByEmail(String email);

}
