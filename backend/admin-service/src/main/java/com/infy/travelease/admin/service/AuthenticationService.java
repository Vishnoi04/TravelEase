package com.infy.travelease.admin.service;

import java.util.Optional;

import com.infy.travelease.admin.dto.LoginRequest;
import com.infy.travelease.admin.dto.LoginResponse;

/** Authenticates persisted user accounts and issues compatible TravelEase JWTs. */
public interface AuthenticationService {

    Optional<LoginResponse> login(LoginRequest request);
}
