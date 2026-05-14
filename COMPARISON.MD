# Custom Module vs Registry Module — Comparison

> Context: This comparison was written after completing Lab M4.05 (custom modules) and Lab M4.06 (Terraform Registry modules), both deploying equivalent AWS infrastructure.

---

## Custom Module (Lab M4.05)

**Pros:**
- Full control over implementation and abstractions
- Tailored exactly to the team's naming conventions and policies
- No external dependency — no upstream breaking changes
- Learning experience: forces deep understanding of underlying AWS resources

**Cons:**
- Time-consuming to develop from scratch
- Requires ongoing maintenance (new AWS features, provider upgrades)
- Easy to miss AWS best practices (e.g. encryption defaults, subnet group configuration)
- Requires writing and maintaining tests

---

## Registry Module (Lab M4.06)

**Pros:**
- Battle-tested (10M+ downloads for `terraform-aws-modules/vpc`)
- AWS best practices built-in by default (NAT HA, subnet grouping, encryption)
- Actively maintained by the community and HashiCorp partners
- Comprehensive documentation and examples
- Significantly faster to implement — entire multi-tier stack in one `main.tf`

**Cons:**
- Less fine-grained control; some abstractions require reading module internals to override
- Version pinning is mandatory — failing to pin can cause silent upgrades
- Modules may expose far more variables than needed, increasing cognitive overhead
- Vendor-lock on module maintainer's design decisions

---

## Practical Observations from the Labs

| Dimension | Custom Module | Registry Module |
|---|---|---|
| Time to first `apply` | Longer (write resource blocks manually) | Faster (configure inputs only) |
| Lines of Terraform code | More | Fewer |
| Debugging complexity | Easier (you own every line) | Harder (errors inside opaque module) |
| Security posture | Only what you explicitly add | Best practices included by default |
| Reproducibility | Stable (internal) | Depends on version pinning discipline |
| Onboarding new engineers | Steep (custom abstractions) | Easier (well-known public docs) |

---

## Recommendation

| Scenario | Approach |
|---|---|
| Common AWS patterns (VPC, EC2, RDS, S3) | Use Registry modules — proven, fast, best-practice defaults |
| Company-specific requirements (tagging strategy, internal naming, compliance guardrails) | Write custom modules wrapping Registry modules |
| Greenfield learning projects | Start with custom modules to understand the primitives |
| Production workloads | Registry modules as a base, custom wrappers for organisational standards |

**Bottom line:** Registry modules and custom modules are not mutually exclusive. The most effective pattern is to use Registry modules for the infrastructure primitives and layer thin custom modules on top to enforce company-specific conventions.
