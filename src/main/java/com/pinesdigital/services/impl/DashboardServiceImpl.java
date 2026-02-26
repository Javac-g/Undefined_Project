package com.denysov.essex.services.impl;

import com.denysov.essex.model.DashboardDTO;
import com.denysov.essex.services.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService{
    private final DomainService domainService;
    private final HostingService hostingService;
    private final SslService sslService;
    private final AppService appService;
    private final PrivateEmailService privateEmailService;

    public DashboardDTO buildDashboard(Long userId) {

        return DashboardDTO.builder()
                .domains(domainService.findByUserId(userId))
                .hostings(hostingService.findByUserId(userId))
                .ssls(sslService.findByUserId(userId))
                .apps(appService.findByUserId(userId))
                .emails(privateEmailService.findByUserId(userId))
                .build();
    }
}
