package com.denysov.essex.services.impl;

import com.denysov.essex.model.Hosting;
import com.denysov.essex.repository.HostingRepository;
import com.denysov.essex.services.HostingService;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
public class HostingServiceImpl implements HostingService {

    private final HostingRepository hostingRepository;
    private final List<Hosting> dummy = Collections.emptyList();


    public HostingServiceImpl(HostingRepository hostingRepository) {
        this.hostingRepository = hostingRepository;
    }

    @Override
    public List<Hosting> findByUserId(Long userId) {
        List<Hosting> list = hostingRepository.findByUserId(userId);
        return List.of();
    }

    @Override
    public List<Hosting> findByUserUsername(String username) {
        return List.of();
    }
}
