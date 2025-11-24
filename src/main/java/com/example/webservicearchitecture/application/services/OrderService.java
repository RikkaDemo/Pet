// src/main/java/com/example/webservicearchitecture/application/services/OrderService.java
package com.example.webservicearchitecture.application.services;

import com.example.webservicearchitecture.domain.models.Basket;
import com.example.webservicearchitecture.domain.models.Order;
import com.example.webservicearchitecture.domain.repositories.BasketRepository;
import com.example.webservicearchitecture.domain.repositories.OrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
public class OrderService {
    private static final Logger logger = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;
    private final BasketRepository basketRepository;

    @Autowired
    public OrderService(OrderRepository orderRepository, BasketRepository basketRepository) {
        this.orderRepository = orderRepository;
        this.basketRepository = basketRepository;
    }

    public Order checkout(String customerId, String creditCardNumber, String expiryDate) {
        // Validate credit card
        if (!isValidCreditCard(creditCardNumber, expiryDate)) {
            throw new RuntimeException("Invalid credit card details. Please check card number and expiry date.");
        }

        Basket basket = basketRepository.findByCustomerId(customerId)
                .orElseThrow(() -> new RuntimeException("Basket not found for customer: " + customerId));

        if (basket.isEmpty()) {
            throw new RuntimeException("Cannot checkout empty basket");
        }

        // Create order
        String orderId = UUID.randomUUID().toString();
        Order order = new Order(
                orderId,
                customerId,
                basket.getProducts(),
                basket.getTotalPrice(),
                basket.getDiscountCode(),
                maskCreditCard(creditCardNumber)
        );

        // Save order
        Order savedOrder = orderRepository.save(order);

        // Clear basket
        basketRepository.delete(basket.getBasketId());

        // Log successful conversion
        logger.info("✅ Basket converted to Order successfully. Order ID: {}, Customer ID: {}, Total: ${}",
                savedOrder.getOrderId(), customerId, savedOrder.getTotalPrice());

        return savedOrder;
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public List<Order> getOrdersByCustomerId(String customerId) {
        return orderRepository.findByCustomerId(customerId);
    }

    public Order getOrderById(String orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
    }

    private boolean isValidCreditCard(String cardNumber, String expiryDate) {
        System.out.println("=== 信用卡验证调试 ===");
        System.out.println("卡号: " + cardNumber);
        System.out.println("有效期: " + expiryDate);

        // 基本卡号验证
        if (cardNumber == null || cardNumber.trim().isEmpty()) {
            System.out.println("失败: 卡号为空");
            return false;
        }

        // 清理卡号（移除空格和短横线）
        String cleanCardNumber = cardNumber.replaceAll("[\\s-]+", "");
        System.out.println("清理后卡号: " + cleanCardNumber);
        System.out.println("卡号长度: " + cleanCardNumber.length());

        // 检查卡号长度（通常为16位）
        if (cleanCardNumber.length() != 16) {
            System.out.println("失败: 卡号长度应为16位");
            return false;
        }

        // 检查卡号是否全为数字
        if (!cleanCardNumber.matches("\\d+")) {
            System.out.println("失败: 卡号应全为数字");
            return false;
        }

        // 验证有效期
        try {
            // 解析有效期 (MM/yy 格式)
            String[] expiryParts = expiryDate.split("/");
            if (expiryParts.length != 2) {
                System.out.println("失败: 有效期格式错误，应为 MM/yy 格式");
                return false;
            }

            int expiryMonth = Integer.parseInt(expiryParts[0]);
            int expiryYear = Integer.parseInt(expiryParts[1]) + 2000; // 转换为4位数年份

            // 验证月份范围
            if (expiryMonth < 1 || expiryMonth > 12) {
                System.out.println("失败: 月份应在1-12之间");
                return false;
            }

            // 获取当前日期
            LocalDate today = LocalDate.now();
            int currentMonth = today.getMonthValue();
            int currentYear = today.getYear();

            System.out.println("当前日期: " + today);
            System.out.println("有效期: " + expiryMonth + "/" + expiryYear);

            // 检查是否过期
            boolean isValid = (expiryYear > currentYear) ||
                    (expiryYear == currentYear && expiryMonth >= currentMonth);

            System.out.println("验证结果: " + isValid);
            System.out.println("=== 验证完成 ===\n");

            return isValid;

        } catch (Exception e) {
            System.out.println("失败: 解析有效期出错: " + e.getMessage());
            return false;
        }
    }

    private String maskCreditCard(String cardNumber) {
        String cleanCardNumber = cardNumber.replaceAll("[\\s-]+", "");
        if (cleanCardNumber.length() >= 4) {
            return "****-****-****-" + cleanCardNumber.substring(cleanCardNumber.length() - 4);
        }
        return "****-****-****-****";
    }
}