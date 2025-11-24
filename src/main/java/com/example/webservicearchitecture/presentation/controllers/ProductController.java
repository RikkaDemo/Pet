// src/main/java/com/example/webservicearchitecture/presentation/controllers/ProductController.java
package com.example.webservicearchitecture.presentation.controllers;

import com.example.webservicearchitecture.application.services.ProductService;
import com.example.webservicearchitecture.domain.models.Product;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    private final ProductService productService;

    @Autowired
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        List<Product> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{productCode}")
    public ResponseEntity<Product> getProduct(@PathVariable String productCode) {
        Product product = productService.getProductByCode(productCode);
        return ResponseEntity.ok(product);
    }
}