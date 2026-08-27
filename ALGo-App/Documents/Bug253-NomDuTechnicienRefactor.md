# Bug 253 – Nom du Technicien Field Refactor

Related GitHub issue(s): #253  
Related Markdown file(s): [Bug253-NomDuTechnicienRefactor.md](./Bug253-NomDuTechnicienRefactor.md)  
Branch: `Bug/253`

---

## Overview

The old technician fields (`TechnitianName` / `TechnitianID`) used on Sales Orders, Service Orders, Inventory Profiles, and Requisition Lines were fragmented and inconsistent (one stored a Resource ID, one stored a name via lookup). This branch replaces them with a single, unified field **`"Nom du technicien"` (Code[100])** across all affected tables, pages, and codeunits. The old fields are marked `ObsoleteState = Pending` so they can be removed in a future version.

---

## Files Changed

### `Src/TableExt/`

| File | Change |
|---|---|
| `ServiceHeader.TableExt.al` | Added `field(50107; "Nom du technicien"; Code[100])` with `TableRelation = Resource.Name` and `OnValidate` that syncs the value to the linked Sales Order. Marked `TechnitianName` (50101) and `TechnitianID` (50106) as `ObsoleteState = Pending`. |
| `SalesHeaderExt.TableExt.al` | Added `field(50107; "Nom du technicien"; Code[100])` with `TableRelation = Resource.Name`. Marked `TechnitianName` (50104) and `TechnitianID` FlowField (50106) as `ObsoleteState = Pending`. |
| `InventoryProfile.TableExt.al` | Added `field(50105; "Nom du technicien"; Code[100])` to carry the technician name through the planning pipeline. |
| `RequisitionLine.TableExt.al` | Added `field(50105; "Nom du technicien"; Code[100])` to carry the technician name from the demand profile to purchase orders. |
| `PurchaseLine.TableExt.al` | Added XML-doc comment clarifying that `"Technitian Name"` (50103) is the persisted technician name on purchase lines (no field change, comment only). |

### `Src/PageExt/`

| File | Change |
|---|---|
| `SalesOrder.PageExt.al` | Replaced the `TechnitianName` field control with the new `"Nom du technicien"` field. Old control left as comments. |
| `ServiceOrderCard.PageExt.al` | Replaced the `TechnitianName` field control (which included a `Resource List` lookup trigger) with a simple `"Nom du technicien"` field. Old control left as comments. The lookup trigger (`OnAfterLookup` setting `TechnitianID`) was removed. |

### `Src/VirtualTable/`

| File | Change |
|---|---|
| `ServiceOrderVirtualTable.Page.al` | Changed the `nomDuTechnicien` virtual table field source from `Rec.TechnitianName` to `Rec."Nom du technicien"`. |

### `Src/Codeunit/`

| File | Change |
|---|---|
| `ServiceOrderManagement.codeunit.al` | When creating or updating a Service Order from a Sales Order, the new `"Nom du technicien"` field is now also copied alongside the legacy `TechnitianName`. |
| `RequisitionWorksheet.Codeunit.al` | All three propagation paths (Sales → Inventory Profile, Service → Inventory Profile, Inventory Profile → Requisition Line → Purchase Line) now use `"Nom du technicien"` instead of `TechnitianName` / `TechnitianID`. Old lines are commented out. |
| `OrderTracking.Codeunit.al` | When populating `DetailReceptionAchatPM`, the technician name is now copied directly from `ItemLedgerEntry."Technitian Name"` rather than doing a `Resource.Get()` lookup and using the `Search Name`. |
| `NomDuTechnitianUpgrade.codeunit.al` | New upgrade codeunit (50117, subtype Upgrade). Migrates existing data from the obsolete `TechnitianName` field to the new `"Nom du technicien"` field on both `Sales Header` and `Service Header`. See [Upgrade Codeunit](#upgrade-codeunit) below. |

---

## Behaviour Summary

| Scenario | Before | After |
|---|---|---|
| Sales Order – Technician field displayed | `TechnitianName` (Code[20]) | `"Nom du technicien"` (Code[100]) |
| Service Order Card – Technician field | `TechnitianName` with Resource List lookup that also set `TechnitianID` | `"Nom du technicien"` plain editable field |
| Service Order Virtual Table (`nomDuTechnicien`) | Source: `TechnitianName` | Source: `"Nom du technicien"` |
| Planning pipeline propagation | Used `TechnitianID` (Code[20]) / `TechnitianName` | Uses `"Nom du technicien"` (Code[100]) throughout |
| `DetailReceptionAchatPM` technician name | Resolved via `Resource.Get()` → `Search Name` | Copied directly from ledger entry `"Technitian Name"` |
| Old fields |  `ObsoleteState = Pending` – not shown in UI, retained for data migration| Active |

---

## Testing Notes

1. **Sales Order** – Open a Sales Order, verify the "Nom du technicien" field is visible and accepts a Resource name up to 100 characters.
2. **Service Order** – Create a Service Order linked to a Sales Order. Confirm `"Nom du technicien"` is populated from the Sales Order and is editable on the Service Order Card.
3. **Virtual Table** – Call the `ServiceOrderVirtualTable` endpoint and confirm the `nomDuTechnicien` property returns the value stored in the new field.
4. **Planning** – Run MRP/planning on an order that has a technician set. Verify the value flows: Sales/Service Header → Inventory Profile → Requisition Line → Purchase Line → `DetailReceptionAchatPM`.
5. **Obsolete fields** – Confirm `TechnitianName` and `TechnitianID` no longer appear on pages but their data is still present in the database (no data loss).
6. **Upgrade migration** – After publishing the extension upgrade, verify that the value from `TechnitianName` was copied into `"Nom du technicien"` on all existing `Sales Header` and `Service Header` records. The original `TechnitianName` value must remain unchanged (no data deleted from the obsolete field).

---

### Pass criteria

| Check | Expected result | Status |
|---|---|---|
| `"Nom du technicien"` visible on Sales Order & Service order | Field displayed, lookup opens Resource list | ✅ Passed |
| `"Nom du technicien"` populated on Service Order after **Create Service** | Value copied from Sales Order | ✅ Passed |
| Requisition line carries `"Nom du technicien"` | Value propagated during Calculate Plan | ✅ Passed |
| Purchase line carries technician name | Value propagated via Carry Out Action | ✅ Passed |
| `DetailReceptionAchat.TechnicianName` visible on Étiquettes page | Field 6 shows technician name on the **Etiquettes réception** page | ✅ Passed |
| Upgrade migration — `TechnitianName` → `"Nom du technicien"` on `Sales Header` | `"Nom du technicien"` populated from old field value; `TechnitianName` still holds original data | ✅ Passed |
| Upgrade migration — `TechnitianName` → `"Nom du technicien"` on `Service Header` | `"Nom du technicien"` populated from old field value; `TechnitianName` still holds original data | ✅ Passed |
| Field Service (Dataverse/FS) integration — `nomDuTechnicien` sync via virtual table | `"Nom du technicien"` propagated from FS Work Order via Dataverse virtual table mapping | ⚠️ Not tested — FS integration not configured in dev environment |

---

## Upgrade Codeunit

**File:** `Src/Codeunit/NomDuTechnitianUpgrade.codeunit.al`  
**Object:** `codeunit 50117 NomDuTechnitianUpgrade` — `subtype = Upgrade`

This codeunit runs automatically on extension upgrade via `OnUpgradePerCompany` and migrates existing database values from the deprecated `TechnitianName` field to the new `"Nom du technicien"` field on both `Sales Header` and `Service Header`.

### Logic

| Procedure | Source field | Target field | Guard condition |
|---|---|---|---|
| `UpgradeSalesHeader` | `Sales Header`.`TechnitianName` (50104, obsolete) | `Sales Header`.`"Nom du technicien"` (50107) | Only migrates when source is non-empty **and** target is still empty (idempotent) |
| `UpgradeServiceHeader` | `Service Header`.`TechnitianName` (50101, obsolete) | `Service Header`.`"Nom du technicien"` (50107) | Only migrates when source is non-empty **and** target is still empty (idempotent) |

Both procedures use `LoadFields` to avoid loading unneeded columns, `FindSet(true)` to enable `Modify()` inside the loop, and the idempotency guard to make the upgrade safe to re-run.

```al
codeunit 50117 NomDuTechnitianUpgrade
{
    subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeSalesHeader();
        UpgradeServiceHeader();
    end;

    local procedure UpgradeSalesHeader()
    var
        salesHeader: Record "Sales Header";
    begin
        salesHeader.Reset();
        salesHeader.LoadFields("No.", "Document Type", "Nom du technicien", TechnitianName);
        if salesHeader.FindSet(true) then
            repeat
                if (salesHeader.TechnitianName <> '') and (salesHeader."Nom du technicien" = '') then begin
                    salesHeader."Nom du technicien" := salesHeader.TechnitianName;
                    if salesHeader.Modify() then;
                end;
            until salesHeader.Next() = 0;
    end;

    local procedure UpgradeServiceHeader()
    var
        serviceHeader: Record "Service Header";
    begin
        serviceHeader.Reset();
        serviceHeader.LoadFields("No.", "Document Type", "Nom du technicien", TechnitianName);
        if serviceHeader.FindSet(true) then
            repeat
                if (serviceHeader.TechnitianName <> '') and (serviceHeader."Nom du technicien" = '') then begin
                    serviceHeader."Nom du technicien" := serviceHeader.TechnitianName;
                    if serviceHeader.Modify() then;
                end;
            until serviceHeader.Next() = 0;
    end;
}
```
