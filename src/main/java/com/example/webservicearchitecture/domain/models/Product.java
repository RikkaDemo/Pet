// src/main/java/com/example/webservicearchitecture/domain/models/Product.java
package com.example.webservicearchitecture.domain.models;

import java.math.BigDecimal;

public class Product {
    private final String productCode;
    private final String name;
    private final BigDecimal fullPrice;

    public Product(String productCode, String name, BigDecimal fullPrice) {
        this.productCode = productCode;
        this.name = name;
        this.fullPrice = fullPrice;
    }

    public String getProductCode() { return productCode; }
    public String getName() { return name; }
    public BigDecimal getFullPrice() { return fullPrice; }
}