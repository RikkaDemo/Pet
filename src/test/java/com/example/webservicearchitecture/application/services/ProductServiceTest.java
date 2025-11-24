// src/test/java/com/example/webservicearchitecture/application/services/ProductServiceTest.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Product;
import com.example.webservicearchitecture.domain.repositories.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductService productService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getAllProducts_ShouldReturnAllProducts() {
        // Arrange
        List<Product> expectedProducts = Arrays.asList(
                new Product("P001", "Laptop", new BigDecimal("999.99")),
                new Product("P002", "Mouse", new BigDecimal("29.99"))
        );
        when(productRepository.findAll()).thenReturn(expectedProducts);

        // Act
        List<Product> result = productService.getAllProducts();

        // Assert
        assertEquals(2, result.size());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    void getProductByCode_WithExistingProduct_ShouldReturnProduct() {
        // Arrange
        String productCode = "P001";
        Product expectedProduct = new Product(productCode, "Laptop", new BigDecimal("999.99"));
        when(productRepository.findByCode(productCode)).thenReturn(Optional.of(expectedProduct));

        // Act
        Product result = productService.getProductByCode(productCode);

        // Assert
        assertNotNull(result);
        assertEquals(productCode, result.getProductCode());
        verify(productRepository, times(1)).findByCode(productCode);
    }

    @Test
    void getProductByCode_WithNonExistingProduct_ShouldThrowException() {
        // Arrange
        String productCode = "NON_EXISTENT";
        when(productRepository.findByCode(productCode)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(RuntimeException.class, () ->
                productService.getProductByCode(productCode));
    }
}