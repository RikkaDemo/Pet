// src/main/java/com/example/webservicearchitecture/infrastructure/persistence/InMemoryProductRepository.java
package com.example.webservicearchitecture.infrastructure.persistence;

import com.example.webservicearchitecture.domain.models.Product;
import com.example.webservicearchitecture.domain.repositories.ProductRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Repository
public class InMemoryProductRepository implements ProductRepository {
    private final ConcurrentMap<String, Product> products = new ConcurrentHashMap<>();

    public InMemoryProductRepository() {
        // Initialize with sample products
        save(new Product("P001", "Laptop", new BigDecimal("999.99")));
        save(new Product("P002", "Mouse", new BigDecimal("29.99")));
        save(new Product("P003", "Keyboard", new BigDecimal("79.99")));
        save(new Product("P004", "Monitor", new BigDecimal("199.99")));
        save(new Product("P005", "Headphones", new BigDecimal("149.99")));
    }

    @Override
    public List<Product> findAll() {
        return List.copyOf(products.values());
    }

    @Override
    public Optional<Product> findByCode(String productCode) {
        return Optional.ofNullable(products.get(productCode));
    }

    @Override
    public void save(Product product) {
        products.put(product.getProductCode(), product);
    }
}