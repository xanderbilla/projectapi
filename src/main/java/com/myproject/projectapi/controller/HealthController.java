package com.myproject.projectapi.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.myproject.projectapi.config.ApplicationStartupListener;

@RestController
@RequestMapping("/health")
@CrossOrigin(origins = "*")
public class HealthController {

    private static final Logger logger = LoggerFactory.getLogger(ApplicationStartupListener.class);

    @GetMapping
    public ResponseEntity<String> healthCheck() {
        logger.info("Health check passed");
        return new ResponseEntity<>("Service is active ✅", HttpStatus.OK);
    }
}
