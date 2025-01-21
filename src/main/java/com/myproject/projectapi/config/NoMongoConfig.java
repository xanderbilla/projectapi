package com.myproject.projectapi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.data.mongodb.core.MongoTemplate;

import com.mongodb.client.MongoClient;

@Configuration
@Profile("docker") // Active when the "docker" profile is active (during Docker build)
public class NoMongoConfig {

    @Bean
    public MongoClient mongoClient() {
        return null;
    }

    @Bean
    public MongoTemplate mongoTemplate() {
        return null;
    }
}