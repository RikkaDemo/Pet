// src/main/java/com/example/webservicearchitecture/application/services/ProductService.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Product;
import com.example.webservicearchitecture.domain.repositories.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductService {
    private final ProductRepository productRepository;

    @Autowired
    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public Product getProductByCode(String productCode) {
        return productRepository.findByCode(productCode)
                .orElseThrow(() -> new RuntimeException("Product not found: " + productCode));
    }

    public boolean productExists(String productCode) {
        return productRepository.findByCode(productCode).isPresent();
    }
}