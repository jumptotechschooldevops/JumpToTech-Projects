package com.devops.training.service;

import com.devops.training.dto.TaskDTO;
import com.devops.training.entity.Task;
import com.devops.training.entity.Task.TaskStatus;
import com.devops.training.exception.ResourceNotFoundException;
import com.devops.training.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class TaskService {

    private final TaskRepository taskRepository;

    @Cacheable(value = "tasks", key = "#id")
    public TaskDTO getTaskById(Long id) {
        log.info("Fetching task from database with id: {}", id);
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + id));
        return mapToDTO(task);
    }

    public List<TaskDTO> getAllTasks() {
        log.info("Fetching all tasks from database");
        List<Task> tasks = taskRepository.findAll();
        return tasks.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Cacheable(value = "tasksByStatus", key = "#status")
    public List<TaskDTO> getTasksByStatus(TaskStatus status) {
        log.info("Fetching tasks by status: {}", status);
        List<Task> tasks = taskRepository.findByStatusOrderByCreatedAtDesc(status);
        return tasks.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<TaskDTO> searchTasksByTitle(String title) {
        log.info("Searching tasks with title containing: {}", title);
        return taskRepository.findByTitleContainingIgnoreCase(title).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @CachePut(value = "tasks", key = "#result.id")
    @CacheEvict(value = "tasksByStatus", allEntries = true)
    public TaskDTO createTask(TaskDTO taskDTO) {
        log.info("Creating new task: {}", taskDTO.getTitle());
        Task task = mapToEntity(taskDTO);
        Task savedTask = taskRepository.save(task);
        log.info("Task created successfully with id: {}", savedTask.getId());
        return mapToDTO(savedTask);
    }

    @CachePut(value = "tasks", key = "#id")
    @CacheEvict(value = "tasksByStatus", allEntries = true)
    public TaskDTO updateTask(Long id, TaskDTO taskDTO) {
        log.info("Updating task with id: {}", id);
        Task existingTask = taskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + id));
        
        // update fields
        existingTask.setTitle(taskDTO.getTitle());
        existingTask.setDescription(taskDTO.getDescription());
        existingTask.setStatus(taskDTO.getStatus());
        existingTask.setPriority(taskDTO.getPriority());
        existingTask.setDueDate(taskDTO.getDueDate());
        
        Task updatedTask = taskRepository.save(existingTask);
        log.info("Task updated successfully with id: {}", updatedTask.getId());
        return mapToDTO(updatedTask);
    }

    @CacheEvict(value = {"tasks", "tasksByStatus"}, allEntries = true)
    public void deleteTask(Long id) {
        log.info("Deleting task with id: {}", id);
        if (!taskRepository.existsById(id)) {
            throw new ResourceNotFoundException("Task not found with id: " + id);
        }
        taskRepository.deleteById(id);
        log.info("Task deleted successfully with id: {}", id);
    }

    public long getTaskCount() {
        return taskRepository.count();
    }

    // helper methods for mapping
    private TaskDTO mapToDTO(Task task) {
        TaskDTO dto = new TaskDTO();
        dto.setId(task.getId());
        dto.setTitle(task.getTitle());
        dto.setDescription(task.getDescription());
        dto.setStatus(task.getStatus());
        dto.setPriority(task.getPriority());
        dto.setCreatedAt(task.getCreatedAt());
        dto.setUpdatedAt(task.getUpdatedAt());
        dto.setDueDate(task.getDueDate());
        return dto;
    }

    private Task mapToEntity(TaskDTO dto) {
        Task task = new Task();
        task.setTitle(dto.getTitle());
        task.setDescription(dto.getDescription());
        task.setStatus(dto.getStatus());
        task.setPriority(dto.getPriority());
        task.setDueDate(dto.getDueDate());
        return task;
    }
}
