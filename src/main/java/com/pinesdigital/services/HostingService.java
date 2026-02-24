package com.denysov.essex.services;

import com.denysov.essex.model.Apps;
import com.denysov.essex.model.Hosting;

import java.util.List;

public interface HostingService {
    List<Hosting> findByUserId(Long userId);
    List<Hosting> findByUserUsername(String username);
}
