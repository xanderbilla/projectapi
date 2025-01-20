package com.myproject.projectapi.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Component;

@Component
public class ApplicationStartupListener implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(ApplicationStartupListener.class);

    @Autowired
    private Environment environment;

    @Autowired(required = false)
    private MongoTemplate mongoTemplate;

    private int serverPort;

    @Override
    public void run(String... args) throws Exception {
        // This runs *before* the application is fully started.
        // We get the port here, but we don't log the "started" message yet.
        serverPort = Integer.parseInt(environment.getProperty("local.server.port"));
    }


    @EventListener(ApplicationReadyEvent.class)
    public void doSomethingAfterStartup() {
        logger.info("Server started on port {}", serverPort);

        try {
            if (mongoTemplate != null && mongoTemplate.getDb() != null) {
                mongoTemplate.getDb().listCollectionNames().first(); // Database check
                logger.info("Database connected");
            } else {
                logger.warn("Database not available"); // Use warn level
            }
        } catch (Exception e) {
            logger.error("Database check failed: {}", e.getMessage()); // Use error level and log the message
        }
    }
}
