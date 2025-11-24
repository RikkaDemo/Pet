// src/main/java/com/example/webservicearchitecture/domain/models/Promotion.java
package com.example.webservicearchitecture.domain.models;

import java.math.BigDecimal;

public class Promotion {
    private final String discountCode;
    private final BigDecimal discountPercentage;

    public Promotion(String discountCode, BigDecimal discountPercentage) {
        this.discountCode = discountCode;
        this.discountPercentage = discountPercentage;
    }

    public String getDiscountCode() { return discountCode; }
    public BigDecimal getDiscountPercentage() { return discountPercentage; }
}