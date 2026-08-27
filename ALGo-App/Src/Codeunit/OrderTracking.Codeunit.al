codeunit 50109 OrderTracking
{
    trigger OnRun()
    begin

    end;

    //order tracking
    [EventSubscriber(ObjectType::Codeunit, Codeunit::OrderTrackingManagement, OnBeforeTempOrderTrackingEntryInsert, '', false, false)]
    local procedure OrderTrackingManagement_OnBeforeTempOrderTrackingEntryInsert(var TempOrderTrackingEntry: Record "Order Tracking Entry" temporary; ToItemLedgerEntry: Record "Item Ledger Entry"; FromItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TempOrderTrackingEntry."No de intervention" := FromItemLedgerEntry."No de intervention";
        TempOrderTrackingEntry."Technitian Name" := FromItemLedgerEntry."Technitian Name";

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemJnlLineOnBeforeCopyDocumentFields, '', false, false)]
    local procedure "Purch.-Post_OnPostItemJnlLineOnBeforeCopyDocumentFields"(var ItemJournalLine: Record "Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; WhseReceive: Boolean; WhseShip: Boolean; InvtPickPutaway: Boolean)
    begin
        ItemJournalLine."No de intervention" := PurchaseLine."No de intervention";
        ItemJournalLine."Technitian Name" := PurchaseLine."Technitian Name";
        ItemJournalLine."Phma source Document Order No" := PurchaseLine."Phma source Document Order No";
        ItemJournalLine."Phma Customer Name" := PurchaseLine."Phma Customer Name";
        ItemJournalLine."Phma document order type" := PurchaseLine."Phma document order type";
        ItemJournalLine.TenantName := PurchaseLine.TenantName;
        ItemJournalLine."Assigned User ID" := PurchaseHeader."Assigned User ID";
        ItemJournalLine.Instructions := PurchaseLine."Description 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInitItemLedgEntry, '', false, false)]
    local procedure "Item Jnl.-Post Line_OnAfterInitItemLedgEntry"(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    var
        DetailReceptionAchatPM: Record "DetailReceptionAchat";
        DetailReceptionAchatPMMaxEntry: Record "DetailReceptionAchat";
        Resource: Record Resource;
    begin


        NewItemLedgEntry."Technitian Name" := ItemJournalLine."Technitian Name";
        NewItemLedgEntry."No de intervention" := ItemJournalLine."No de intervention";
        NewItemLedgEntry."Phma source Document Order No" := ItemJournalLine."Phma source Document Order No";
        NewItemLedgEntry."Phma Customer Name" := ItemJournalLine."Phma Customer Name";
        NewItemLedgEntry."Phma document order type" := ItemJournalLine."Phma document order type";
        NewItemLedgEntry.TenantName := ItemJournalLine.TenantName;
        NewItemLedgEntry.Instructions := ItemJournalLine.Instructions;

        if not (NewItemLedgEntry."Document Type" in [NewItemLedgEntry."Document Type"::"Purchase Receipt"]) then
            exit;

        detailReceptionAchatPM.Reset();
        DetailReceptionAchatPM.Init();

        DetailReceptionAchatPMMaxEntry.Reset();
        DetailReceptionAchatPMMaxEntry.SetRange(EntryNo);

        if DetailReceptionAchatPMMaxEntry.IsEmpty() then
            DetailReceptionAchatPM.EntryNo := 1
        else
            if DetailReceptionAchatPMMaxEntry.FindLast() then
                DetailReceptionAchatPM.EntryNo := DetailReceptionAchatPMMaxEntry.EntryNo + 1;
        ;

        DetailReceptionAchatPM."ItemNo" := NewItemLedgEntry."Item No.";
        DetailReceptionAchatPM."Quantity" := NewItemLedgEntry.Quantity;
        DetailReceptionAchatPM.DocumentNo := NewItemLedgEntry."Phma source Document Order No";
        DetailReceptionAchatPM."Posted Purch Receipt No" := NewItemLedgEntry."Document No.";
        DetailReceptionAchatPM."Phma document order type" := NewItemLedgEntry."Phma document order type";
        DetailReceptionAchatPM."No de intervention" := NewItemLedgEntry."No de intervention";
        DetailReceptionAchatPM.CustomerSearchName := NewItemLedgEntry."Phma Customer Name";

        DetailReceptionAchatPM."TechnicianName" := NewItemLedgEntry."Technitian Name";

        DetailReceptionAchatPM.TenantName := NewItemLedgEntry.TenantName;
        DetailReceptionAchatPM.OrderGiverName := NewItemLedgEntry."Phma Customer Name";
        DetailReceptionAchatPM."Assigned User ID" := ItemJournalLine."Assigned User ID";
        DetailReceptionAchatPM.Instructions := NewItemLedgEntry.Instructions;

        if DetailReceptionAchatPM.Insert() then;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInitValueEntry, '', false, false)]
    local procedure "Item Jnl.-Post Line_OnAfterInitValueEntry"(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ValueEntryNo: Integer; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ValueEntry."Technitian Name" := ItemLedgEntry."Technitian Name";
        ValueEntry."No de intervention" := ItemLedgEntry."No de intervention";
    end;

}