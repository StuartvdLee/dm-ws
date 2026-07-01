# Dunder Mifflin Shipping Policy

## Package conditions

| Condition | Meaning | Action |
|-----------|---------|--------|
| `OK` | Package is undamaged and on schedule | No action needed |
| `damaged` | Physical damage observed | Flag for inspection; do not deliver without approval |
| `unclear` | Condition cannot be determined remotely | Schedule inspection |
| `missing label` | Label absent or unreadable | Hold; contact sender |
| `wrong address` | Label address does not match manifest | Hold; contact sender |
| `needs inspection` | Requires manual check before next step | Route to inspection bay |

## Fragile packages
- Must not be stacked.
- Route R-2 has confirmed fragile handling.

## Approval-required actions
- Changing a package status from `in_transit` to any exception state.
- Rerouting a package that is already `in_transit`.
- Any action on packages marked `damaged`.