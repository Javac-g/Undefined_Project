package com.denysov.essex.services.impl;

import com.denysov.essex.model.Apps;
import com.denysov.essex.repository.AppsRepository;
import com.denysov.essex.services.AppService;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
public class AppsServiceImpl implements AppService {

    private final AppsRepository appsRepository;
    private final List<Apps> dummy = Collections.emptyList();

    public AppsServiceImpl(AppsRepository appsRepository) {
        this.appsRepository = appsRepository;
    }


    @Override
    public List<Apps> findByUserId(Long userId) {
        List<Apps> list = appsRepository.findByUserId(userId);
        return list != null ? list : dummy;
    }

    @Override
    public List<Apps> findByUserUsername(String username) {
        List<Apps> list = appsRepository.findByUserUsername(username);
        return list != null ? list : dummy;
    }
}
