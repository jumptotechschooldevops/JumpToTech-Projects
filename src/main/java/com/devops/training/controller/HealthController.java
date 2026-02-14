package com.devops.training.controller;

import com.devops.training.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/health")
@RequiredArgsConstructor
public class HealthController {

    @Value("${app.version}")
    private String appVersion;

    @Value("${app.environment}")
    private String environment;

    @Value("${spring.application.name}")
    private String appName;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> healthCheck() {
        Map<String, Object> healthData = new HashMap<>();
        healthData.put("status", "UP");
        healthData.put("application", appName);
        healthData.put("version", appVersion);
        healthData.put("environment", environment);
        healthData.put("timestamp", System.currentTimeMillis());
        
        return ResponseEntity.ok(ApiResponse.success(healthData, "Application is healthy"));
    }
}
