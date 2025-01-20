package com.myproject.projectapi.repository;

import org.bson.types.ObjectId;
import org.springframework.data.mongodb.repository.MongoRepository;

import com.myproject.projectapi.model.TaskEntity;

public interface TaskRepo  extends MongoRepository<TaskEntity, ObjectId> {
}
