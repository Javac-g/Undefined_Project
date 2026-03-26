package com.denysov.essex.services.impl;

import com.denysov.essex.model.Domain;
import com.denysov.essex.repository.DomainRepository;
import com.denysov.essex.services.DomainService;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
public class DomainServiceImpl implements DomainService {

    private final DomainRepository domainRepository;

    public DomainServiceImpl(DomainRepository domainRepository) {
        this.domainRepository = domainRepository;
    }

    public List<Domain> getDomainsByUserId(Long userId){
        List<Domain> domains = domainRepository.findByUserId(userId);

        return domains != null ? domains : Collections.emptyList();
    }
    public List<Domain> findByUserCredentialLogin(String username) {

        List<Domain> domains = domainRepository.findByUserCredentialLogin(username);

        return domains != null ? domains : Collections.emptyList();
    }

    public SliceResponse<DomainSummaryDTO> getSliceUserDomains(Long userId, int page, int size) {

    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());

    Slice<Domain> slice = domainRepository.findSliceByUserId(userId, pageable);

    List<DomainSummaryDTO> dtos = slice.getContent()
            .stream()
            .map(domain -> DomainSummaryDTO.builder()
                    .id(domain.getId())
                    .name(domain.getName())
                    .status(domain.getStatus().name())
                    .build())
            .toList();

    return SliceResponse.<DomainSummaryDTO>builder()
            .content(dtos)
            .hasNext(slice.hasNext())
            .page(slice.getNumber())
            .build();
    }

    public Page<Domain> getPageUserDomains(Long userId, int page, int size) {

    Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());

    return domainRepository.findByUserId(userId, pageable);
}

}
