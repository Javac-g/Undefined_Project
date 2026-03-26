package com.denysov.essex.model;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class DomainSummaryDTO {

    private Long id;
    private String name;
    private String status;
}
