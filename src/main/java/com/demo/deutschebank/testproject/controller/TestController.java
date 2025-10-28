package com.demo.deutschebank.testproject.controller;

import com.demo.deutschebank.testproject.entity.TestEntity;
import com.demo.deutschebank.testproject.repository.TestEntityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/test")
@CrossOrigin(origins = "*")
public class TestController {
    
    @Autowired
    private TestEntityRepository testEntityRepository;
    
    // Test database connectivity
    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        try {
            long count = testEntityRepository.count();
            return ResponseEntity.ok("Database connection successful! Total records: " + count);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Database connection failed: " + e.getMessage());
        }
    }
    
    // Create a new test entity
    @PostMapping("/create")
    public ResponseEntity<TestEntity> createTestEntity(@RequestBody TestEntity testEntity) {
        try {
            TestEntity savedEntity = testEntityRepository.save(testEntity);
            return ResponseEntity.ok(savedEntity);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }
    
    // Get all test entities
    @GetMapping("/all")
    public ResponseEntity<List<TestEntity>> getAllTestEntities() {
        try {
            List<TestEntity> entities = testEntityRepository.findAll();
            return ResponseEntity.ok(entities);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }
    
    // Get test entity by ID
    @GetMapping("/{id}")
    public ResponseEntity<TestEntity> getTestEntityById(@PathVariable Long id) {
        try {
            Optional<TestEntity> entity = testEntityRepository.findById(id);
            return entity.map(ResponseEntity::ok)
                        .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }
    
    // Update test entity
    @PutMapping("/{id}")
    public ResponseEntity<TestEntity> updateTestEntity(@PathVariable Long id, @RequestBody TestEntity testEntity) {
        try {
            if (!testEntityRepository.existsById(id)) {
                return ResponseEntity.notFound().build();
            }
            testEntity.setId(id);
            TestEntity updatedEntity = testEntityRepository.save(testEntity);
            return ResponseEntity.ok(updatedEntity);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }
    
    // Delete test entity
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteTestEntity(@PathVariable Long id) {
        try {
            if (!testEntityRepository.existsById(id)) {
                return ResponseEntity.notFound().build();
            }
            testEntityRepository.deleteById(id);
            return ResponseEntity.ok("Test entity deleted successfully");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error deleting entity: " + e.getMessage());
        }
    }
    
    // Search entities by name
    @GetMapping("/search")
    public ResponseEntity<List<TestEntity>> searchByName(@RequestParam String name) {
        try {
            List<TestEntity> entities = testEntityRepository.findByNameContainingIgnoreCase(name);
            return ResponseEntity.ok(entities);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(null);
        }
    }
}


