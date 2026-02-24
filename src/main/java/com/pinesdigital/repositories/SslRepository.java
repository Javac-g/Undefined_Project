package com.denysov.essex.repository;

import com.denysov.essex.model.Domain;
import com.denysov.essex.model.SslCertificate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SslRepository extends JpaRepository<SslCertificate, Long> {

    List<SslCertificate> findByUserId(Long userId);
    List<SslCertificate> findByUserUsername(String username);


}
