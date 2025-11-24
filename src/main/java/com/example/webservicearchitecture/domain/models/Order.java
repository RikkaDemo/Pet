// src/main/java/com/example/webservicearchitecture/domain/models/Order.java
package com.example.webservicearchitecture.domain.models;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

public class Order {
    private final String orderId;
    private final String customerId;
    private final Map<String, Integer> products;
    private final BigDecimal totalPrice;
    private final String discountCode;
    private final LocalDateTime orderDate;
    private final String creditCardNumber;

    public Order(String orderId, String customerId, Map<String, Integer> products,
                 BigDecimal totalPrice, String discountCode, String creditCardNumber) {
        this.orderId = orderId;
        this.customerId = customerId;
        this.products = Map.copyOf(products);
        this.totalPrice = totalPrice;
        this.discountCode = discountCode;
        this.orderDate = LocalDateTime.now();
        this.creditCardNumber = creditCardNumber;
    }

    public String getOrderId() { return orderId; }
    public String getCustomerId() { return customerId; }
    public Map<String, Integer> getProducts() { return products; }
    public BigDecimal getTotalPrice() { return totalPrice; }
    public String getDiscountCode() { return discountCode; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public String getCreditCardNumber() { return creditCardNumber; }
}