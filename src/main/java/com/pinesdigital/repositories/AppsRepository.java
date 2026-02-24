package com.denysov.essex.repository;

import com.denysov.essex.model.Apps;
import com.denysov.essex.model.Domain;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AppsRepository extends JpaRepository<Apps, Long> {
    List<Apps> findByUserId(Long userId);
    List<Apps> findByUserUsername(String username);
}
