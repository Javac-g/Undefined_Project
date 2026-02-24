package com.denysov.essex.services;

import com.denysov.essex.model.Apps;

import java.util.List;

public interface AppService {
    List<Apps> findByUserId(Long userId);
    List<Apps> findByUserUsername(String username);
}
