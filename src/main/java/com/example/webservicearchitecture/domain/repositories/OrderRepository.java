// src/main/java/com/example/webservicearchitecture/domain/repositories/OrderRepository.java
package com.example.webservicearchitecture.domain.repositories;

import com.example.webservicearchitecture.domain.models.Order;
import java.util.List;
import java.util.Optional;

public interface OrderRepository {
    Order save(Order order);
    List<Order> findAll();
    List<Order> findByCustomerId(String customerId);
    Optional<Order> findById(String orderId);
}