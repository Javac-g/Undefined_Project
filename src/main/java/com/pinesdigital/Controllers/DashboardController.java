package com.denysov.essex.controllers;

import com.denysov.essex.security.CurrentUserProvider;
import com.denysov.essex.services.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequiredArgsConstructor
@RequestMapping("/home/dashboard")
public class DashboardController {


    private final CurrentUserProvider currentUser;
    private final DashboardService dashboardService;

    @GetMapping
    public String dashboard(Model model) {

        Long userId = currentUser.getUserId();
        model.addAttribute("dashboard", dashboardService.buildDashboard(userId));

        return "dashboard";
    }



}
