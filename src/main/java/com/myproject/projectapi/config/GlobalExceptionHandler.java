package com.myproject.projectapi.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.NoHandlerFoundException; // For 404

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<String> handleNotFoundError(NoHandlerFoundException ex) {
        return new ResponseEntity<>("Resource not found", HttpStatus.NOT_FOUND); // Custom 404 message
    }

    @ExceptionHandler(Exception.class) // Generic exception handler
    public ResponseEntity<String> handleGeneralException(Exception ex) {
        // Log the exception for debugging
        ex.printStackTrace(); // Or use a proper logger
        return new ResponseEntity<>("An error occurred", HttpStatus.INTERNAL_SERVER_ERROR); // 500
    }
}
