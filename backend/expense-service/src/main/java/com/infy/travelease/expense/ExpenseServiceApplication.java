package com.infy.travelease.expense;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

import com.infy.travelease.common.outbox.OutboxConfiguration;

/** Bootstrap for expense-service (tasks.md A-01); scans common-lib's package for its shared @Component beans. */
@SpringBootApplication(scanBasePackages = {"com.infy.travelease.expense", "com.infy.travelease.common"})
// Transactional outbox (common-lib): events are stored with the business change and delivered with retries.
@EntityScan(basePackages = {"com.infy.travelease.expense", "com.infy.travelease.common.outbox"})
@EnableJpaRepositories(basePackages = {"com.infy.travelease.expense", "com.infy.travelease.common.outbox"})
@Import(OutboxConfiguration.class)
public class ExpenseServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(ExpenseServiceApplication.class, args);
    }
}
