package com.infy.travelease.admin.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;

import javax.crypto.spec.SecretKeySpec;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import com.infy.travelease.admin.dto.LoginRequest;
import com.infy.travelease.admin.entity.UserAccount;
import com.infy.travelease.admin.entity.UserRole;
import com.infy.travelease.admin.repository.UserAccountRepository;
import com.infy.travelease.admin.service.impl.AuthenticationServiceImpl;
import com.infy.travelease.common.security.DevJwtDecoders;
import com.infy.travelease.common.security.RoleType;

@ExtendWith(MockitoExtension.class)
class AuthenticationServiceTest {

    private static final String SECRET = "test-only-jwt-secret-never-deploy-0123456789abcdef";
    private static final String PASSWORD = "TravelEase123!";
    private static final String SQL_SEED_PASSWORD_HASH =
            "$2a$10$IKBiOJ9.jsjAWrH.YEbZTOTOgD3JWu4YApNgcM60m/Tv64hXSEJim";

    @Mock
    private UserAccountRepository userAccountRepository;

    private PasswordEncoder passwordEncoder;
    private AuthenticationServiceImpl authenticationService;

    @BeforeEach
    void setUp() {
        passwordEncoder = new BCryptPasswordEncoder();
        authenticationService = new AuthenticationServiceImpl(
                userAccountRepository,
                passwordEncoder,
                new NimbusJwtEncoder(new ImmutableSecret<>(
                        new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"))));
    }

    @Test
    void issuesCompatibleSignedTokenForValidCredentials() {
        UserAccount account = account(5L, "sam.admin@infy.com", true, RoleType.ADMIN, RoleType.FINANCE);
        account.setPasswordHash(passwordEncoder.encode(PASSWORD));
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("SAM.ADMIN@INFY.COM"))
                .thenReturn(Optional.of(account));

        String token = authenticationService.login(
                new LoginRequest("SAM.ADMIN@INFY.COM", PASSWORD)).orElseThrow().token();
        JwtDecoder decoder = DevJwtDecoders.hmacDecoder(SECRET);
        Jwt claims = decoder.decode(token);

        assertThat(claims.getSubject()).isEqualTo("5");
        assertThat(claims.getClaimAsStringList("roles")).containsExactly("ADMIN", "FINANCE");
        Instant issuedAt = Objects.requireNonNull(claims.getIssuedAt());
        assertThat(claims.getExpiresAt()).isAfter(Instant.now());
        assertThat(claims.getExpiresAt()).isEqualTo(issuedAt.plusSeconds(3600));
        verify(userAccountRepository).findByEmailIgnoreCaseAndDeletedFalse("SAM.ADMIN@INFY.COM");
    }

    @Test
    void verifiesThePasswordHashUsedByTheManualSeedScript() {
        assertThat(passwordEncoder.matches(PASSWORD, SQL_SEED_PASSWORD_HASH)).isTrue();
    }

    @Test
    void returnsEmptyForUnknownUsername() {
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("missing@infy.com"))
                .thenReturn(Optional.empty());

        assertThat(authenticationService.login(new LoginRequest("missing@infy.com", PASSWORD))).isEmpty();
    }

    @Test
    void returnsEmptyForWrongPassword() {
        UserAccount account = account(1L, "asha.rao@infy.com", true, RoleType.EMPLOYEE);
        account.setPasswordHash(passwordEncoder.encode(PASSWORD));
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("asha.rao@infy.com"))
                .thenReturn(Optional.of(account));

        assertThat(authenticationService.login(
                new LoginRequest("asha.rao@infy.com", "wrong-password"))).isEmpty();
    }

    @Test
    void returnsEmptyForInactiveAccount() {
        UserAccount account = account(1L, "asha.rao@infy.com", false, RoleType.EMPLOYEE);
        account.setPasswordHash(passwordEncoder.encode(PASSWORD));
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("asha.rao@infy.com"))
                .thenReturn(Optional.of(account));

        assertThat(authenticationService.login(
                new LoginRequest("asha.rao@infy.com", PASSWORD))).isEmpty();
    }

    private static UserAccount account(Long id, String email, boolean active, RoleType... roles) {
        UserAccount account = new UserAccount();
        account.setId(id);
        account.setEmail(email);
        account.setActive(active);
        for (RoleType roleType : roles) {
            UserRole role = new UserRole();
            role.setRole(roleType);
            account.addRole(role);
        }
        return account;
    }

    @org.junit.jupiter.api.Test
    void tokenCarriesTheCredentialsVersionClaim() {
        UserAccount account = account(5L, "sam.admin@infy.com", true, RoleType.ADMIN);
        account.setPasswordHash(passwordEncoder.encode(PASSWORD));
        account.bumpCredentialsVersion();
        account.bumpCredentialsVersion();
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("sam.admin@infy.com"))
                .thenReturn(Optional.of(account));

        String token = authenticationService.login(new LoginRequest("sam.admin@infy.com", PASSWORD)).orElseThrow().token();

        assertThat(DevJwtDecoders.hmacDecoder(SECRET).decode(token).<Number>getClaim("cv").intValue()).isEqualTo(2);
    }

    @org.junit.jupiter.api.Test
    void pendingResetBlocksTokenOnlyAfterTheCorrectPassword() {
        UserAccount account = account(5L, "reset.user@infy.com", true, RoleType.EMPLOYEE);
        account.setPasswordHash(passwordEncoder.encode(PASSWORD));
        account.setMustChangePassword(true);
        when(userAccountRepository.findByEmailIgnoreCaseAndDeletedFalse("reset.user@infy.com"))
                .thenReturn(Optional.of(account));

        // a wrong password learns nothing about the pending reset
        assertThat(authenticationService.login(new LoginRequest("reset.user@infy.com", "wrong"))).isEmpty();
        org.assertj.core.api.Assertions.assertThatThrownBy(() ->
                        authenticationService.login(new LoginRequest("reset.user@infy.com", PASSWORD)))
                .isInstanceOf(com.infy.travelease.admin.security.PasswordChangeRequiredException.class);
    }
}
