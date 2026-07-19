# Product asset tracker

Approval: `APPROVED_PHOTOREALISTIC_PRODUCT_ASSETS.md`  
Quality review: `PHOTOREALISTIC_ASSET_QUALITY_REVIEW.md`  
Regen queue: `PRODUCT_ASSETS_TO_REGENERATE.md`

---

## Coverage framing (2026-07-18 post B8 + B3A–B7D)

| Metric | Count |
|--------|------:|
| Total canonical products | **182** |
| Approved photorealistic product assets | **182** |
| Awaiting regeneration / first photoreal | **0** |
| Products on category fallback | **0** |

Full photorealistic catalog coverage complete after B7D.

---

## Phase status

| Phase | Status |
|-------|--------|
| A | Complete (tooling/resolver) |
| B1 | Reviewed — most kept; demotions fixed in B8 |
| B2 | Reviewed — most kept; demotions fixed in B8 |
| Cleanup | Complete (legacy imagesets removed) |
| Quality audit | Complete |
| B8 correction | **Complete** (10 installed + approved) |
| B3A dairy/refrigerated (10) | **Complete** |
| B4A pantry/sauces/oils (10) | **Complete** |
| B5A meat/seafood/frozen (10) | **Complete** |
| B5B meat/seafood/frozen (10) | **Complete** |
| B6A beverages/snacks (10) | **Complete** |
| B6B snacks/remaining beverages (10) | **Complete** |
| B7A household/care/health/baby (10) | **Complete** |
| B7B remaining household/pet/floral + queue fills (10) | **Complete** |
| B7C next remaining queue replacements (10) | **Complete** |
| B7D final remaining queue replacements (18) | **Complete** |
| B3B remaining dairy/bakery/eggs | Superseded by B7D |
| B4B remaining pantry | Superseded by B7D |
| B8 remaining produce | Superseded by B7D |

---

## Commands

```bash
python3 scripts/audit-product-assets.py
node scripts/verify-product-resolution.mjs
node scripts/export-ios-catalog.mjs
```

Contact sheets:
- B8: `DesignReferences/asset-audit/b8-quality-review/`
- B3A: `DesignReferences/asset-audit/b3a-dairy-replacements/`
- B4A: `DesignReferences/asset-audit/b4a-pantry-replacements/`
- B5A: `DesignReferences/asset-audit/b5a-meat-seafood-frozen-replacements/`
- B5B: `DesignReferences/asset-audit/b5b-meat-seafood-frozen-replacements/`
- B6A: `DesignReferences/asset-audit/b6a-beverages-snacks-replacements/`
- B6B: `DesignReferences/asset-audit/b6b-snacks-beverages-replacements/`
- B7A: `DesignReferences/asset-audit/b7a-household-care-health-replacements/`
- B7B: `DesignReferences/asset-audit/b7b-household-health-baby-pet-replacements/`
- B7C: `DesignReferences/asset-audit/b7c-remaining-replacements/`
- B7D: `DesignReferences/asset-audit/b7d-final-replacements/`
