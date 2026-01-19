# Codex Security Discovery Template

Use this template for security hardening analysis.

## Delegation Format

```
TASK: Analyze {GOAL_ID} for security vulnerabilities and hardening opportunities.

EXPECTED OUTCOME: Security assessment with HIPAA-aligned recommendations.

MODE: Advisory

CONTEXT:
- Goal: {GOAL_DESCRIPTION}
- Application: Healthcare companion app handling PHI
- Compliance: HIPAA (§164.312), SOC 2 Type II
- Architecture: Offline-first with encrypted local storage
- Threat model: Mobile device theft, network interception, insider threats

CONSTRAINTS:
- HIPAA compliance is non-negotiable
- All PHI must be encrypted at rest and in transit
- Audit trails required for PHI access
- Must support offline operation securely

MUST DO:
- Identify potential attack vectors
- Check OWASP Mobile Top 10 vulnerabilities
- Verify encryption implementation
- Assess authentication/authorization gaps
- Review input validation
- Check for information disclosure risks

MUST NOT DO:
- Recommend security through obscurity
- Ignore offline attack scenarios
- Suggest approaches that break usability for elderly users

OUTPUT FORMAT:
## Security Assessment

### Threat Summary
- **Risk Level**: [Critical/High/Medium/Low]
- **Primary Threats**: [list of threats]
- **Attack Surface**: [what's exposed]

### HIPAA Compliance Check
| Requirement | Status | Notes |
|-------------|--------|-------|
| §164.312(a)(1) Access Control | [PASS/FAIL/PARTIAL] | [notes] |
| §164.312(a)(2)(iv) Encryption | [PASS/FAIL/PARTIAL] | [notes] |
| §164.312(b) Audit Controls | [PASS/FAIL/PARTIAL] | [notes] |
| §164.312(c)(1) Integrity | [PASS/FAIL/PARTIAL] | [notes] |
| §164.312(d) Authentication | [PASS/FAIL/PARTIAL] | [notes] |
| §164.312(e)(1) Transmission | [PASS/FAIL/PARTIAL] | [notes] |

### Vulnerability Analysis

#### OWASP Mobile Top 10
1. **M1: Improper Platform Usage**: [finding]
2. **M2: Insecure Data Storage**: [finding]
3. **M3: Insecure Communication**: [finding]
4. **M4: Insecure Authentication**: [finding]
5. **M5: Insufficient Cryptography**: [finding]
6. **M6: Insecure Authorization**: [finding]
7. **M7: Client Code Quality**: [finding]
8. **M8: Code Tampering**: [finding]
9. **M9: Reverse Engineering**: [finding]
10. **M10: Extraneous Functionality**: [finding]

### Identified Vulnerabilities
| ID | Description | Severity | Remediation |
|----|-------------|----------|-------------|
| V1 | [description] | [CRITICAL/HIGH/MEDIUM/LOW] | [fix] |
| V2 | [description] | [severity] | [fix] |

## Hardening Recommendations

### Immediate (Must Fix)
1. [Recommendation 1]
   - Risk: [what could happen]
   - Fix: [how to fix]
   - Verification: [how to verify]

### Short-term (Should Fix)
1. [Recommendation]

### Defense in Depth
- [Layer 1 defense]
- [Layer 2 defense]
- [Layer 3 defense]

## Security Metrics to Verify
| Metric | Command | Expected | Tolerance |
|--------|---------|----------|-----------|
| PHI Exposure | `grep -rn 'password\|ssn\|dob' packages/` | 0 | 0 |
| Unencrypted Storage | `grep -rn 'AsyncStorage.setItem' packages/` | 0 | 0 |
| Hardcoded Secrets | `grep -rn 'api_key\|secret\|token' packages/` | 0 | 0 |

## Veto Conditions
If ANY of these are found, REJECT the goal completion:
- [ ] PHI stored unencrypted
- [ ] Credentials in source code
- [ ] Missing audit trail for PHI access
- [ ] Authentication bypass possible
- [ ] HIPAA violation identified
```

## Integration with ACIS

The Security response feeds into:
1. `consensus.verification_results[codex-security]`
2. `multi_perspective.discovery_results[codex-security]`
3. Security agent has veto_power = true
