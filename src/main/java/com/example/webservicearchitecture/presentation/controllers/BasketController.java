// src/main/java/com/example/webservicearchitecture/presentation/controllers/BasketController.java
package com.example.webservicearchitecture.presentation.controllers;

import com.example.webservicearchitecture.application.services.BasketService;
import com.example.webservicearchitecture.domain.models.Basket;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/baskets")
public class BasketController {
    private final BasketService basketService;

    @Autowired
    public BasketController(BasketService basketService) {
        this.basketService = basketService;
    }

    @PostMapping("/{customerId}")
    public ResponseEntity<Basket> createBasket(@PathVariable String customerId) {
        Basket basket = basketService.createBasket(customerId);
        return ResponseEntity.ok(basket);
    }

    @GetMapping("/{customerId}")
    public ResponseEntity<Basket> getBasket(@PathVariable String customerId) {
        Basket basket = basketService.getBasketByCustomerId(customerId);
        return ResponseEntity.ok(basket);
    }

    @PostMapping("/{customerId}/products/{productCode}")
    public ResponseEntity<Basket> addProductToBasket(
            @PathVariable String customerId,
            @PathVariable String productCode,
            @RequestParam(defaultValue = "1") int quantity) {
        Basket basket = basketService.addProductToBasket(customerId, productCode, quantity);
        return ResponseEntity.ok(basket);
    }

    @PostMapping("/{customerId}/discount")
    public ResponseEntity<Basket> applyDiscount(
            @PathVariable String customerId,
            @RequestParam String discountCode) {
        Basket basket = basketService.applyDiscount(customerId, discountCode);
        return ResponseEntity.ok(basket);
    }

    @DeleteMapping("/{customerId}")
    public ResponseEntity<Void> clearBasket(@PathVariable String customerId) {
        basketService.clearBasket(customerId);
        return ResponseEntity.ok().build();
    }
}