// src/main/java/com/example/webservicearchitecture/presentation/controllers/CheckoutRequest.java
package com.example.webservicearchitecture.presentation.controllers;

public class CheckoutRequest {
    private String creditCardNumber;
    private String expiryDate;

    // 默认构造函数
    public CheckoutRequest() {}

    // 全参构造函数
    public CheckoutRequest(String creditCardNumber, String expiryDate) {
        this.creditCardNumber = creditCardNumber;
        this.expiryDate = expiryDate;
    }

    // Getters and Setters
    public String getCreditCardNumber() { return creditCardNumber; }
    public void setCreditCardNumber(String creditCardNumber) { this.creditCardNumber = creditCardNumber; }

    public String getExpiryDate() { return expiryDate; }
    public void setExpiryDate(String expiryDate) { this.expiryDate = expiryDate; }
}