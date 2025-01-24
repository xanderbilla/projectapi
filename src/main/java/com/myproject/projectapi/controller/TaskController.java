package com.myproject.projectapi.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.bson.types.ObjectId;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.myproject.projectapi.model.TaskEntity;
import com.myproject.projectapi.service.TaskService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/tasks")
@CrossOrigin(origins = "*")
public class TaskController {

    private static final Logger logger = LoggerFactory.getLogger(TaskController.class);
    private TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TaskEntity createTask(@RequestBody TaskEntity task) {
        try {
            if (task == null || task.getTitle() == null || task.getTitle().isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task title is required");
            }
            task.setCreatedAt(LocalDateTime.now());
            return taskService.saveTask(task);
        } catch (Exception e) {
            logger.error("Error creating task", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error creating task");
        }
    }

    @GetMapping
    public List<TaskEntity> getAllTasks() {
        try {
            return taskService.getAllTasks();
        } catch (Exception e) {
            logger.error("Error fetching tasks", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error fetching tasks");
        }
    }

    @GetMapping("/{id}")
    public TaskEntity getTaskById(@PathVariable ObjectId id) {
        try {
            TaskEntity task = taskService.getTaskById(id);
            if (task == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found");
            }
            return task;
        } catch (Exception e) {
            logger.error("Error fetching task by id", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error fetching task by id");
        }
    }

    @PutMapping("/{id}")
    public TaskEntity updateTask(@PathVariable ObjectId id, @RequestBody TaskEntity task) {
        try {
            TaskEntity existingTask = taskService.getTaskById(id);
            if (existingTask == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found");
            }
            if (task == null || task.getTitle() == null || task.getTitle().isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task title is required");
            }
            existingTask.setTitle(task.getTitle());
            existingTask.setDescription(task.getDescription());
            existingTask.setStatus(task.getStatus());
            existingTask.setUpdatedAt(task.getUpdatedAt());
            return taskService.saveTask(existingTask);
        } catch (Exception e) {
            logger.error("Error updating task", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error updating task");
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<TaskEntity>> getTasksByStatus(@RequestParam(value = "status", required = true) String status) {
        try {
            if (status != null && !status.isEmpty()) {
                return ResponseEntity.ok(taskService.getTasksByStatus(status));
            } else {
                return ResponseEntity.noContent().build();
            }
        } catch (Exception e) {
            logger.error("Error fetching tasks by status", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Error fetching tasks"); // More generic
                                                                                                         // message
        }
    }
}
