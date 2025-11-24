// src/main/java/com/example/webservicearchitecture/application/services/BasketService.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Basket;
import com.example.webservicearchitecture.domain.models.Product;
import com.example.webservicearchitecture.domain.repositories.BasketRepository;
import com.example.webservicearchitecture.domain.repositories.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
public class BasketService {
    private static final Logger logger = LoggerFactory.getLogger(BasketService.class);

    private final BasketRepository basketRepository;
    private final ProductRepository productRepository;

    @Autowired
    public BasketService(BasketRepository basketRepository, ProductRepository productRepository) {
        this.basketRepository = basketRepository;
        this.productRepository = productRepository;
    }

    public Basket createBasket(String customerId) {
        // Check if customer already has a basket
        basketRepository.findByCustomerId(customerId).ifPresent(basket -> {
            throw new RuntimeException("Customer " + customerId + " already has a basket");
        });

        String basketId = UUID.randomUUID().toString();
        Basket basket = new Basket(basketId, customerId);
        Basket savedBasket = basketRepository.save(basket);

        logger.info("Created new basket for customer: {}", customerId);
        return savedBasket;
    }

    public Basket getBasketByCustomerId(String customerId) {
        return basketRepository.findByCustomerId(customerId)
                .orElseThrow(() -> new RuntimeException("Basket not found for customer: " + customerId));
    }

    public Basket addProductToBasket(String customerId, String productCode, int quantity) {
        if (quantity <= 0) {
            throw new RuntimeException("Quantity must be positive");
        }

        Basket basket = getBasketByCustomerId(customerId);
        Product product = productRepository.findByCode(productCode)
                .orElseThrow(() -> new RuntimeException("Product not found: " + productCode));

        basket.addProduct(productCode, quantity);
        recalculateBasketTotal(basket);

        Basket updatedBasket = basketRepository.save(basket);
        logger.info("Added {} units of product {} to basket for customer {}", quantity, productCode, customerId);

        return updatedBasket;
    }

    public Basket applyDiscount(String customerId, String discountCode) {
        if (!discountCode.equals("DISCOUNT10") && !discountCode.equals("DISCOUNT20")) {
            throw new RuntimeException("Invalid discount code. Valid codes: DISCOUNT10, DISCOUNT20");
        }

        Basket basket = getBasketByCustomerId(customerId);
        basket.setDiscountCode(discountCode);
        recalculateBasketTotal(basket);

        Basket updatedBasket = basketRepository.save(basket);
        logger.info("Applied discount code {} to basket for customer {}", discountCode, customerId);

        return updatedBasket;
    }

    private void recalculateBasketTotal(Basket basket) {
        BigDecimal total = BigDecimal.ZERO;

        for (var entry : basket.getProducts().entrySet()) {
            String productCode = entry.getKey();
            int quantity = entry.getValue();

            Product product = productRepository.findByCode(productCode)
                    .orElseThrow(() -> new RuntimeException("Product not found: " + productCode));

            total = total.add(product.getFullPrice().multiply(BigDecimal.valueOf(quantity)));
        }

        // Apply discount if available
        if (basket.getDiscountCode() != null) {
            BigDecimal discountPercentage = basket.getDiscountCode().equals("DISCOUNT10") ?
                    new BigDecimal("0.10") : new BigDecimal("0.20");
            BigDecimal discountAmount = total.multiply(discountPercentage);
            total = total.subtract(discountAmount);
        }

        basket.setTotalPrice(total);
    }

    public void clearBasket(String customerId) {
        Basket basket = getBasketByCustomerId(customerId);
        basketRepository.delete(basket.getBasketId());
        logger.info("Cleared basket for customer: {}", customerId);
    }
}