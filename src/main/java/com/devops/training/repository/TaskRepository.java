package com.devops.training.repository;

import com.devops.training.entity.Task;
import com.devops.training.entity.Task.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    
    List<Task> findByStatus(TaskStatus status);
    
    List<Task> findByTitleContainingIgnoreCase(String title);
    
    List<Task> findByStatusOrderByCreatedAtDesc(TaskStatus status);
}
