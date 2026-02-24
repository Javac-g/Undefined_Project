package com.denysov.essex.services;

import com.denysov.essex.model.MembershipPlan;

import java.math.BigDecimal;
import java.util.List;

public interface MembershipService {
    public BigDecimal calculateFee(Long planId, BigDecimal transactionAmount);
   public MembershipPlan getPlanByName(String name);
    public MembershipPlan getPlanById(Long id);
    public List<MembershipPlan> getAll();
}
