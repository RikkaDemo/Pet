// src/main/java/com/example/webservicearchitecture/infrastructure/persistence/InMemoryBasketRepository.java
package com.example.webservicearchitecture.infrastructure.persistence;

import com.example.webservicearchitecture.domain.models.Basket;
import com.example.webservicearchitecture.domain.repositories.BasketRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Repository
public class InMemoryBasketRepository implements BasketRepository {
    private final ConcurrentMap<String, Basket> baskets = new ConcurrentHashMap<>();

    @Override
    public Basket save(Basket basket) {
        baskets.put(basket.getBasketId(), basket);
        return basket;
    }

    @Override
    public Optional<Basket> findById(String basketId) {
        return Optional.ofNullable(baskets.get(basketId));
    }

    @Override
    public Optional<Basket> findByCustomerId(String customerId) {
        return baskets.values().stream()
                .filter(basket -> customerId.equals(basket.getCustomerId()))
                .findFirst();
    }

    @Override
    public List<Basket> findAll() {
        return List.copyOf(baskets.values());
    }

    @Override
    public void delete(String basketId) {
        baskets.remove(basketId);
    }
}