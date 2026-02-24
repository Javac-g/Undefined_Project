package com.denysov.essex.repository;

import com.denysov.essex.model.Hosting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HostingRepository extends JpaRepository<Hosting, Long> {
    List<Hosting> findByUserId(Long userId);
    List<Hosting> findByUserUsername(String username);
}
