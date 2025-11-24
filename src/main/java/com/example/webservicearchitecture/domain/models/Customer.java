// src/main/java/com/example/webservicearchitecture/domain/models/Customer.java
package com.example.webservicearchitecture.domain.models;

public class Customer {
    private final String customerId;
    private final String name;

    public Customer(String customerId, String name) {
        this.customerId = customerId;
        this.name = name;
    }

    public String getCustomerId() { return customerId; }
    public String getName() { return name; }
}