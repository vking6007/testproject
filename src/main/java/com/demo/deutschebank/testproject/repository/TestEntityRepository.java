package com.demo.deutschebank.testproject.repository;

import com.demo.deutschebank.testproject.entity.TestEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TestEntityRepository extends JpaRepository<TestEntity, Long> {
    
    // Find entities by name
    List<TestEntity> findByName(String name);
    
    // Find entities by name containing (case insensitive)
    List<TestEntity> findByNameContainingIgnoreCase(String name);
    
    // Count total entities
    long count();
}


