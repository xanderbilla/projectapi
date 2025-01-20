package com.myproject.projectapi.service;
import java.util.List;

import org.bson.types.ObjectId;
import org.springframework.stereotype.Component;

import com.myproject.projectapi.model.TaskEntity;
import com.myproject.projectapi.repository.TaskRepo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
public class TaskService {

    private static final Logger logger = LoggerFactory.getLogger(TaskService.class);
    private TaskRepo taskRepo;

    public TaskService(TaskRepo taskRepo) {
        this.taskRepo = taskRepo;
    }

    public TaskEntity saveTask(TaskEntity task) {
        try {
            return taskRepo.save(task);
        } catch (Exception e) {
            logger.error("Error creating task", e);
            return null;
        }
    }

    public List<TaskEntity> getAllTasks() {
        try {
            return taskRepo.findAll();
        } catch (Exception e) {
            logger.error("Error retrieving all tasks", e);
            return null;
        }
    }

    public TaskEntity getTaskById(ObjectId id) {
        try {
            return taskRepo.findById(id).orElse(null);
        } catch (Exception e) {
            logger.error("Error retrieving task by id", e);
            return null;
        }
    }

    public boolean deleteTask(ObjectId id) {
        try {
            TaskEntity existingTask = taskRepo.findById(id).orElse(null);
            if (existingTask == null) {
                logger.warn("Task with id {} not found", id);
                return false;
            }
            taskRepo.delete(existingTask);
            return true;
        } catch (Exception e) {
            logger.error("Error deleting task", e);
            return false;
        }
    }
}
