package com.infy.travelease.admin.service.impl;

import com.infy.travelease.admin.audit.AdminAuditEvents;
import com.infy.travelease.common.event.AuditActionType;
import com.infy.travelease.common.event.AuditEntityType;
import com.infy.travelease.admin.dto.EmployeeManagerMappingRequest;
import com.infy.travelease.admin.dto.EmployeeManagerMappingResponse;
import com.infy.travelease.admin.entity.EmployeeManagerMapping;
import com.infy.travelease.admin.mapper.EmployeeManagerMappingMapper;
import com.infy.travelease.admin.repository.EmployeeManagerMappingRepository;
import com.infy.travelease.admin.repository.UserAccountRepository;
import com.infy.travelease.admin.service.EmployeeManagerMappingAdminService;
import com.infy.travelease.common.exception.ResourceNotFoundException;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Admin Employee→Manager mapping management business logic (tasks.md H-08;
 * spec.md FR-ADM-01, FR-TR-05).
 *
 * <p>{@code employeeId} is unique (data-model.md §5.3), so a single "create" request
 * for an employee who already has a mapping updates that mapping in place rather
 * than inserting a duplicate row (api-contract.md §4.3 upsert semantics).</p>
 */
@Service
public class EmployeeManagerMappingAdminServiceImpl implements EmployeeManagerMappingAdminService {

    private final EmployeeManagerMappingRepository mappingRepository;
    private final UserAccountRepository userAccountRepository;
    private final EmployeeManagerMappingMapper mappingMapper;

    private final AdminAuditEvents auditEvents;

    public EmployeeManagerMappingAdminServiceImpl(EmployeeManagerMappingRepository mappingRepository,
            UserAccountRepository userAccountRepository, EmployeeManagerMappingMapper mappingMapper,
            AdminAuditEvents auditEvents) {
        this.mappingRepository = mappingRepository;
        this.userAccountRepository = userAccountRepository;
        this.mappingMapper = mappingMapper;
        this.auditEvents = auditEvents;
    }

    @Override
    @Transactional
    public EmployeeManagerMappingResponse createOrUpdateMapping(EmployeeManagerMappingRequest request) {
        requireExistingUser(request.employeeId());
        if (request.managerId() != null) {
            requireExistingUser(request.managerId());
        }

        java.util.Optional<EmployeeManagerMapping> existingMapping =
                mappingRepository.findByEmployeeIdAndDeletedFalse(request.employeeId());
        String previousManager = existingMapping.map(m -> String.valueOf(m.getManagerId())).orElse("none");
        EmployeeManagerMapping mapping = existingMapping
                .map(existing -> applyRequest(existing, request))
                .orElseGet(() -> mappingMapper.toEntity(request));

        EmployeeManagerMapping saved = mappingRepository.save(mapping);
        // #13: reporting-line changes decide who approves whose travel
        auditEvents.publish(AuditEntityType.EMPLOYEE_MANAGER_MAPPING, saved.getId(),
                existingMapping.isPresent() ? AuditActionType.UPDATED : AuditActionType.CREATED, java.util.Map.of(
                        "employeeId", String.valueOf(saved.getEmployeeId()),
                        "fromManagerId", previousManager,
                        "toManagerId", String.valueOf(saved.getManagerId())));
        return mappingMapper.toResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<EmployeeManagerMappingResponse> listMappings(Pageable pageable) {
        return mappingRepository.findByDeletedFalse(pageable).map(mappingMapper::toResponse);
    }

    private EmployeeManagerMapping applyRequest(EmployeeManagerMapping mapping, EmployeeManagerMappingRequest request) {
        mapping.setManagerId(request.managerId());
        mapping.setEffectiveFrom(request.effectiveFrom());
        return mapping;
    }

    private void requireExistingUser(Long userId) {
        userAccountRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new ResourceNotFoundException("UserAccount", userId));
    }
}
