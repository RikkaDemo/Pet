// src/main/java/com/example/webservicearchitecture/domain/repositories/ProductRepository.java
package com.example.webservicearchitecture.domain.repositories;

import com.example.webservicearchitecture.domain.models.Product;
import java.util.List;
import java.util.Optional;

public interface ProductRepository {
    List<Product> findAll();
    Optional<Product> findByCode(String productCode);
    void save(Product product);
}