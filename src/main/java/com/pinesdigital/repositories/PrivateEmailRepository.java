package com.denysov.essex.repository;

import com.denysov.essex.model.PrivateEmail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PrivateEmailRepository extends JpaRepository<PrivateEmail, Long> {

    List<PrivateEmail> findByUserId(Long userId);
    List<PrivateEmail> findByUserUsername(String username);
}
