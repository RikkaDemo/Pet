// src/test/java/com/example/webservicearchitecture/application/services/OrderServiceTest.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Basket;
import com.example.webservicearchitecture.domain.models.Order;
import com.example.webservicearchitecture.domain.repositories.BasketRepository;
import com.example.webservicearchitecture.domain.repositories.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private BasketRepository basketRepository;

    @InjectMocks
    private OrderService orderService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void checkout_WithValidCard_ShouldCreateOrder() {
        // Arrange
        String customerId = "1234";
        String creditCardNumber = "4000056655665556";
        String expiryDate = "01/27";

        Basket basket = new Basket("basket1", customerId);
        basket.addProduct("P001", 1);
        basket.setTotalPrice(new BigDecimal("999.99"));

        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(basket));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Order result = orderService.checkout(customerId, creditCardNumber, expiryDate);

        // Assert
        assertNotNull(result);
        assertEquals(customerId, result.getCustomerId());
        assertEquals(new BigDecimal("999.99"), result.getTotalPrice());
        verify(orderRepository, times(1)).save(any(Order.class));
        verify(basketRepository, times(1)).delete(basket.getBasketId());
    }

    @Test
    void checkout_WithInvalidCard_ShouldThrowException() {
        // Arrange
        String customerId = "1234";
        String invalidCardNumber = "1234";
        String expiryDate = "01/27";

        Basket basket = new Basket("basket1", customerId);
        basket.addProduct("P001", 1);
        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(basket));

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                orderService.checkout(customerId, invalidCardNumber, expiryDate));
    }

    @Test
    void checkout_WithEmptyBasket_ShouldThrowException() {
        // Arrange
        String customerId = "1234";
        String creditCardNumber = "4000056655665556";
        String expiryDate = "01/27";

        Basket emptyBasket = new Basket("basket1", customerId);
        when(basketRepository.findByCustomerId(customerId)).thenReturn(Optional.of(emptyBasket));

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                orderService.checkout(customerId, creditCardNumber, expiryDate));
    }
}