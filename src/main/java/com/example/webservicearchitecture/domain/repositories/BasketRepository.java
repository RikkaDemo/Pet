// src/main/java/com/example/webservicearchitecture/domain/repositories/BasketRepository.java
package com.example.webservicearchitecture.domain.repositories;

import com.example.webservicearchitecture.domain.models.Basket;
import java.util.List;
import java.util.Optional;

public interface BasketRepository {
    Basket save(Basket basket);
    Optional<Basket> findById(String basketId);
    Optional<Basket> findByCustomerId(String customerId);
    List<Basket> findAll();
    void delete(String basketId);
}