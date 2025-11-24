// src/main/java/com/example/webservicearchitecture/domain/models/Basket.java
package com.example.webservicearchitecture.domain.models;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

public class Basket {
    private final String basketId;
    private final String customerId;
    private final Map<String, Integer> products;
    private String discountCode;
    private BigDecimal totalPrice;

    public Basket(String basketId, String customerId) {
        this.basketId = basketId;
        this.customerId = customerId;
        this.products = new HashMap<>();
        this.totalPrice = BigDecimal.ZERO;
    }

    public String getBasketId() { return basketId; }
    public String getCustomerId() { return customerId; }
    public Map<String, Integer> getProducts() { return new HashMap<>(products); }
    public String getDiscountCode() { return discountCode; }
    public void setDiscountCode(String discountCode) { this.discountCode = discountCode; }
    public BigDecimal getTotalPrice() { return totalPrice; }
    public void setTotalPrice(BigDecimal totalPrice) { this.totalPrice = totalPrice; }

    public void addProduct(String productCode, int quantity) {
        products.put(productCode, products.getOrDefault(productCode, 0) + quantity);
    }

    public void removeProduct(String productCode) {
        products.remove(productCode);
    }

    public boolean isEmpty() {
        return products.isEmpty();
    }
}