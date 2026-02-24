package com.denysov.essex.services;

import com.denysov.essex.model.User;

public interface RegistrationService {
    User register(String login, String email, String password, String fullName);

}
