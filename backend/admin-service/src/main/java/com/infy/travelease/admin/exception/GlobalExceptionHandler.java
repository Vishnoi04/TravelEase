package com.infy.travelease.admin.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.infy.travelease.admin.security.PasswordChangeRequiredException;
import com.infy.travelease.common.error.ErrorResponse;
import com.infy.travelease.common.web.ApiExceptionHandler;

/**
 * HTTP error mapping for the admin service. Shared mappings come from {@link ApiExceptionHandler}
 * (api-contract.md §8); this adds the admin-specific password-change requirement.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ApiExceptionHandler {

    /** Correct credentials, but an administrator reset must be completed first (#14). */
    @ExceptionHandler(PasswordChangeRequiredException.class)
    public ResponseEntity<ErrorResponse> handlePasswordChangeRequired(PasswordChangeRequiredException ex) {
        return new ResponseEntity<>(ex.toErrorResponse(HttpStatus.FORBIDDEN.value()), HttpStatus.FORBIDDEN);
    }
}
