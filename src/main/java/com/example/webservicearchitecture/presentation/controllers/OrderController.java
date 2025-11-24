// src/main/java/com/example/webservicearchitecture/presentation/controllers/OrderController.java
package com.example.webservicearchitecture.presentation.controllers;

import com.example.webservicearchitecture.application.services.OrderService;
import com.example.webservicearchitecture.domain.models.Order;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderService orderService;

    @Autowired
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    // 只保留这个 checkout 方法，删除其他的
    @PostMapping("/checkout/{customerId}")
    public ResponseEntity<Order> checkout(
            @PathVariable String customerId,
            @RequestBody CheckoutRequest checkoutRequest) {

        Order order = orderService.checkout(
                customerId,
                checkoutRequest.getCreditCardNumber(),
                checkoutRequest.getExpiryDate()
        );
        return ResponseEntity.ok(order);
    }

    @GetMapping
    public ResponseEntity<List<Order>> getAllOrders() {
        List<Order> orders = orderService.getAllOrders();
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<Order>> getOrdersByCustomer(@PathVariable String customerId) {
        List<Order> orders = orderService.getOrdersByCustomerId(customerId);
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<Order> getOrderById(@PathVariable String orderId) {
        Order order = orderService.getOrderById(orderId);
        return ResponseEntity.ok(order);
    }
}