package com.denysov.essex.model.pagination;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class SliceResponse<T> {

    private List<T> content;
    private boolean hasNext;
    private int page;
}
