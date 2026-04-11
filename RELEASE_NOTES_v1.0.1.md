## EduTrack v1.0.1 - Bug Fix and Security Update

Release date: 2026-04-12

### Fixes
- Updated admin portal dependencies to patched versions for known security advisories.
- Updated cloud functions dependencies to patched versions for known security advisories.
- Regenerated lockfiles after secure dependency resolution.
- Added targeted dependency overrides to resolve transitive vulnerabilities.

### Security
- Axios critical advisories fixed by upgrading to 1.15.0.
- Next.js advisories fixed by upgrading to 16.2.3.
- node-forge advisories fixed by upgrading to 1.4.0 via firebase-admin 13.8.0.
- fast-xml-parser advisories fixed by resolution to 5.5.11.
- brace-expansion advisories fixed by resolution to patched versions.
- path-to-regexp ReDoS fixed by resolving to 0.1.13.
- Remaining transitive proxy-chain advisories resolved by forcing teeny-request 10.1.2.

### Validation
- npm audit reports zero vulnerabilities in:
  - admin-portal
  - functions
- Build verification passed:
  - admin-portal: next build
  - functions: tsc

### Notes
- This is a patch release focused on dependency/security remediation and stability.
