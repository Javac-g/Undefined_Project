package com.denysov.essex.repository;

import com.denysov.essex.model.PurchaseFee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PurchaseFeeRepository extends JpaRepository<PurchaseFee, Long> {
    List<PurchaseFee> findByPlanIdOrderByMinAmountAsc(Long planId);
}
