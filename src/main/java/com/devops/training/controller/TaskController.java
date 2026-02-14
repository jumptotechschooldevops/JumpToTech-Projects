package com.devops.training.controller;

import com.devops.training.dto.ApiResponse;
import com.devops.training.dto.TaskDTO;
import com.devops.training.entity.Task.TaskStatus;
import com.devops.training.service.TaskService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/v1/tasks")
@RequiredArgsConstructor
@Slf4j
public class TaskController {

    private final TaskService taskService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<TaskDTO>>> getAllTasks() {
        log.info("GET /v1/tasks - Fetch all tasks");
        List<TaskDTO> tasks = taskService.getAllTasks();
        return ResponseEntity.ok(ApiResponse.success(tasks, "Tasks retrieved successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TaskDTO>> getTaskById(@PathVariable Long id) {
        log.info("GET /v1/tasks/{} - Fetch task by id", id);
        TaskDTO task = taskService.getTaskById(id);
        return ResponseEntity.ok(ApiResponse.success(task, "Task retrieved successfully"));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<TaskDTO>>> getTasksByStatus(@PathVariable TaskStatus status) {
        log.info("GET /v1/tasks/status/{} - Fetch tasks by status", status);
        List<TaskDTO> tasks = taskService.getTasksByStatus(status);
        return ResponseEntity.ok(ApiResponse.success(tasks, "Tasks retrieved by status"));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<TaskDTO>>> searchTasks(@RequestParam String title) {
        log.info("GET /v1/tasks/search?title={} - Search tasks", title);
        List<TaskDTO> tasks = taskService.searchTasksByTitle(title);
        return ResponseEntity.ok(ApiResponse.success(tasks, "Search results"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TaskDTO>> createTask(@Valid @RequestBody TaskDTO taskDTO) {
        log.info("POST /v1/tasks - Create new task: {}", taskDTO.getTitle());
        TaskDTO createdTask = taskService.createTask(taskDTO);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(createdTask, "Task created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<TaskDTO>> updateTask(
            @PathVariable Long id,
            @Valid @RequestBody TaskDTO taskDTO) {
        log.info("PUT /v1/tasks/{} - Update task", id);
        TaskDTO updatedTask = taskService.updateTask(id, taskDTO);
        return ResponseEntity.ok(ApiResponse.success(updatedTask, "Task updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteTask(@PathVariable Long id) {
        log.info("DELETE /v1/tasks/{} - Delete task", id);
        taskService.deleteTask(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Task deleted successfully"));
    }

    @GetMapping("/count")
    public ResponseEntity<ApiResponse<Long>> getTaskCount() {
        log.info("GET /v1/tasks/count - Get task count");
        long count = taskService.getTaskCount();
        return ResponseEntity.ok(ApiResponse.success(count, "Task count retrieved"));
    }
}
