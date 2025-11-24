// src/test/java/com/example/webservicearchitecture/application/services/BasketServiceTest.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Basket;
import com.example.webservicearchitecture.domain.models.Product;
import com.example.webservicearchitecture.domain.repositories.BasketRepository;
import com.example.webservicearchitecture.domain.repositories.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BasketServiceTest {

    @Mock
    private BasketRepository basketRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private BasketService basketService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createBasket_ShouldCreateNewBasket() {
        // Arrange
        String customerId = "1234";
        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.empty());
        when(basketRepository.save(any(Basket.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Basket result = basketService.createBasket(customerId);

        // Assert
        assertNotNull(result);
        assertEquals(customerId, result.getCustomerId());
        assertTrue(result.getProducts().isEmpty());
        verify(basketRepository, times(1)).save(any(Basket.class));
    }

    @Test
    void addProductToBasket_ShouldAddProduct() {
        // Arrange
        String customerId = "1234";
        String productCode = "P001";
        Product product = new Product(productCode, "Laptop", new BigDecimal("999.99"));
        Basket basket = new Basket("basket1", customerId);

        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(basket));
        when(productRepository.findByCode(productCode)).thenReturn(Optional.of(product));
        when(basketRepository.save(any(Basket.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Basket result = basketService.addProductToBasket(customerId, productCode, 2);

        // Assert
        assertNotNull(result);
        assertEquals(2, result.getProducts().get(productCode));
        assertEquals(new BigDecimal("1999.98"), result.getTotalPrice());
        verify(basketRepository, times(1)).save(basket);
    }

    @Test
    void applyDiscount_WithValidCode_ShouldApplyDiscount() {
        // Arrange
        String customerId = "1234";
        String productCode = "P001";
        Product product = new Product(productCode, "Laptop", new BigDecimal("100.00"));
        Basket basket = new Basket("basket1", customerId);
        basket.addProduct(productCode, 1);

        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(basket));
        when(productRepository.findByCode(productCode)).thenReturn(Optional.of(product));
        when(basketRepository.save(any(Basket.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Basket result = basketService.applyDiscount(customerId, "DISCOUNT10");

        // Assert
        assertNotNull(result);
        assertEquals("DISCOUNT10", result.getDiscountCode());
        assertEquals(new BigDecimal("90.00"), result.getTotalPrice());
    }

    @Test
    void applyDiscount_WithInvalidCode_ShouldThrowException() {
        // Arrange
        String customerId = "1234";
        Basket basket = new Basket("basket1", customerId);
        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(basket));

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                basketService.applyDiscount(customerId, "INVALID_CODE"));
    }
}