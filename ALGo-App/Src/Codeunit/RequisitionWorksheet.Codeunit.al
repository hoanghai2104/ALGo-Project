codeunit 50116 RequisitionWorksheet
{
    trigger OnRun()
    begin

    end;

    var
        ReqWkshFilterState: Codeunit "Requisition Wksh. Filter State";
        InvalidForNotItemTypeErr: Label 'The line type must be Item';

    procedure CheckToOrderForItemType(Line: Variant)
    var
        RecRef: RecordRef;
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        IsValid: Boolean;
    begin
        RecRef.GetTable(Line);
        case RecRef.Number() of
            Database::"Sales Line":
                begin
                    RecRef.SetTable(SalesLine);
                    IsValid := SalesLine.Type = SalesLine.Type::Item;
                end;
            Database::"Service Line":
                begin
                    RecRef.SetTable(ServiceLine);
                    IsValid := ServiceLine.Type = ServiceLine.Type::Item;
                end;
        end;

        if not IsValid then
            Error(InvalidForNotItemTypeErr);
    end;

    procedure ClearReservedPurchaseLineFields(SourceDocumentNo: Code[20]; SourceDocumentType: Text[100]; SourceLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if SourceDocumentNo = '' then
            exit;

        PurchaseLine.SetRange("Phma source Document Order No", SourceDocumentNo);
        PurchaseLine.SetRange("Phma document order type", SourceDocumentType);
        PurchaseLine.SetRange("Source Document Line No.", SourceLineNo);

        if PurchaseLine.IsEmpty() then
            exit;

        PurchaseLine.FindSet();
        repeat
            PurchaseLine.ClearSourceDocumentFields();
            PurchaseLine.Modify();
        until PurchaseLine.Next() = 0;
    end;

    local procedure SetShouldProcess(ToOrder: Boolean; var ShouldProcess: Boolean)
    var
        RequisitionWkshToOrder: Enum "Requisition Wksh. To Order";
    begin
        RequisitionWkshToOrder := ReqWkshFilterState.GetToOrderMode();

        case RequisitionWkshToOrder of
            RequisitionWkshToOrder::" ":
                exit; //Skip the validation check for "To Order".
            RequisitionWkshToOrder::Yes:
                ShouldProcess := ShouldProcess and ToOrder;
            RequisitionWkshToOrder::No:
                ShouldProcess := ShouldProcess and not ToOrder;
        end;
    end;

    local procedure MarkItemWithHasToOrderSalesLine(var Item: Record Item; RequisitionWkshToOrder: Enum "Requisition Wksh. To Order")
    begin
        if RequisitionWkshToOrder = RequisitionWkshToOrder::Yes then
            Item.SetRange("Has To Order Sales Line", true)
        else
            Item.SetRange("Has Non-To Order Sales Line", true);

        if Item.FindSet() then
            repeat
                Item.Mark(true);
            until Item.Next() = 0;

        //Clear the filters to avoid affecting other reports or processes
        Item.SetRange("Has To Order Sales Line");
        Item.SetRange("Has Non-To Order Sales Line");
    end;

    local procedure MarkItemWithHasToOrderServiceLine(var Item: Record Item; RequisitionWkshToOrder: Enum "Requisition Wksh. To Order")
    begin
        if RequisitionWkshToOrder = RequisitionWkshToOrder::Yes then
            Item.SetRange("Has To Order Service Line", true)
        else
            Item.SetRange("Has Non-To Order Service Line", true);

        if Item.FindSet() then
            repeat
                Item.Mark(true);
            until Item.Next() = 0;

        //Clear the filters to avoid affecting other reports or processes
        Item.SetRange("Has To Order Service Line");
        Item.SetRange("Has Non-To Order Service Line");
    end;

    local procedure GetToOrderStateExpression(var RequisitionWkshToOrder: Enum "Requisition Wksh. To Order"; var FilterValue: Boolean): Boolean;
    begin
        RequisitionWkshToOrder := ReqWkshFilterState.GetToOrderMode();
        FilterValue := RequisitionWkshToOrder = RequisitionWkshToOrder::Yes;

        exit(RequisitionWkshToOrder <> RequisitionWkshToOrder::" ");
    end;

    local procedure GetCustomerName(CustomerNo: Code[20]): Text[100];
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("Search Name");
        if Customer.Get(CustomerNo) then
            exit(Customer."Search Name");
    end;

    local procedure GetInterventionNo(SalesHeader: Record "Sales Header"): Code[20];
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetLoadFields("No.");
        ServiceHeader.SetRange("Sales Order Reference", SalesHeader."No.");
        ServiceHeader.SetRange("Document Type", SalesHeader."Document Type");

        if ServiceHeader.FindFirst() then
            exit(ServiceHeader."No.");
    end;

    //Sales Order Line Inventory Profile Events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line Invt. Profile", OnAfterTransferInventoryProfileFromSalesLine, '', false, false)]
    local procedure "Sales Line Invt. Profile_OnAfterTransferInventoryProfileFromSalesLine"(var InventoryProfile: Record "Inventory Profile"; var SalesLine: Record "Sales Line")
    var
        salesHeader: Record "Sales Header";
        customer: Record Customer;
    begin
        if not salesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;
        if not (salesHeader."Document Type" in [salesHeader."Document Type"::Order]) then
            exit;
        salesHeader.CalcFields("N° de l’intervention");
        InventoryProfile."Phma source Document Order No" := SalesLine."Document No.";
        InventoryProfile."Source Document Line No." := SalesLine."Line No.";
        if customer.Get(salesHeader."Sell-to Customer No.") then
            InventoryProfile."Phma Customer Name" := customer."Search Name"; //search name
        InventoryProfile."Phma document order type" := Format(salesHeader.TableName);
        InventoryProfile."N° de l’intervention" := salesHeader."N° de l’intervention";
        // salesHeader.CalcFields(TechnitianID);
        // InventoryProfile.TechnitianName := salesHeader.TechnitianID;
        InventoryProfile."Nom du technicien" := salesHeader."Nom du technicien";
        InventoryProfile.TenantName := salesHeader."Ship-to Name";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnMaintainPlanningLineOnBeforeReqLineInsert, '', false, false)]
    local procedure "Inventory Profile Offsetting_OnMaintainPlanningLineOnBeforeReqLineInsert"(var RequisitionLine: Record "Requisition Line"; var SupplyInvtProfile: Record "Inventory Profile"; PlanToDate: Date; CurrentForecast: Code[10]; NewPhase: Option; Direction: Option; DemandInvtProfile: Record "Inventory Profile"; ExcludeForecastBefore: Date)
    begin
        RequisitionLine."Phma source Document Order No" := DemandInvtProfile."Phma source Document Order No";
        RequisitionLine."Source Document Line No." := DemandInvtProfile."Source Document Line No.";
        RequisitionLine."Phma Customer Name" := DemandInvtProfile."Phma Customer Name";
        RequisitionLine."N° de l’intervention" := DemandInvtProfile."N° de l’intervention";
        // RequisitionLine.TechnitianName := DemandInvtProfile.TechnitianName;
        RequisitionLine."Nom du technicien" := DemandInvtProfile."Nom du technicien";
        RequisitionLine.TenantName := DemandInvtProfile.TenantName;
        //RequisitionLine."Phma source Document Order No" := DemandInvtProfile."Phma source Document Order No";
        RequisitionLine."Phma document order type" := DemandInvtProfile."Phma document order type";
    end;


    //Service order to Requisition Line Events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Line Invt. Profile", OnAfterTransferInventoryProfileFromServiceLine, '', false, false)]
    local procedure "Service Line Invt. Profile_OnAfterTransferInventoryProfileFromServiceLine"(var InventoryProfile: Record "Inventory Profile"; var ServiceLine: Record "Service Line")
    var
        serviceHeader: Record "Service Header";
        customer: Record Customer;
    begin
        if not serviceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.") then
            exit;
        if not (serviceHeader."Document Type" in [serviceHeader."Document Type"::Order]) then
            exit;
        InventoryProfile."Phma source Document Order No" := ServiceLine."Document No.";
        InventoryProfile."Source Document Line No." := ServiceLine."Line No.";
        InventoryProfile."N° de l’intervention" := serviceHeader."No.";
        if customer.Get(serviceHeader."Customer No.") then
            InventoryProfile."Phma Customer Name" := customer."Search Name"; //search name
        // InventoryProfile.TechnitianName := serviceHeader.TechnitianID;
        InventoryProfile."Nom du technicien" := serviceHeader."Nom du technicien";
        InventoryProfile."Phma document order type" := Format(serviceHeader.TableName);
        InventoryProfile.TenantName := serviceHeader."Ship-to Name";
    end;

    //send requisition line info to purch order line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnBeforePurchOrderLineInsert, '', false, false)]
    local procedure "Req. Wksh.-Make Order_OnBeforePurchOrderLineInsert"(var PurchOrderHeader: Record "Purchase Header"; var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
        PurchOrderLine."Phma source Document Order No" := ReqLine."Phma source Document Order No";
        PurchOrderLine."Source Document Line No." := ReqLine."Source Document Line No.";
        PurchOrderLine."Phma Customer Name" := ReqLine."Phma Customer Name";
        PurchOrderLine."No de intervention" := ReqLine."N° de l’intervention";
        PurchOrderLine."Technitian Name" := ReqLine."Nom du technicien";
        PurchOrderLine."Phma document order type" := ReqLine."Phma document order type";
        PurchOrderLine.TenantName := ReqLine.TenantName;
        PurchOrderLine."Phma document order type" := ReqLine."Phma document order type";
    end;

    // if ettiquette should be added when it is inserted from requisition line to purch order line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Req. Wksh.-Make Order", OnAfterPurchOrderLineInsert, '', false, false)]
    local procedure "Req. Wksh.-Make Order_OnAfterPurchOrderLineInsert"(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Line Invt. Profile", 'OnTransSalesLineToProfileOnBeforeProcessLine', '', false, false)]
    local procedure OnTransSalesLineToProfileOnBeforeProcessLine(SalesLine: Record "Sales Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
        SetShouldProcess(SalesLine."To Order PHM", ShouldProcess);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Line Invt. Profile", 'OnTransServLineToProfileOnBeforeProcessLine', '', false, false)]
    local procedure OnTransServLineToProfileOnBeforeProcessLine(ServiceLine: Record "Service Line"; var ShouldProcess: Boolean; var Item: Record Item)
    begin
        SetShouldProcess(ServiceLine."To Order PHM", ShouldProcess);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Calculate Plan - Req. Wksh.", 'OnAfterItemOnPreDataItem', '', false, false)]
    local procedure OnAfterItemOnPreDataItem(var Item: Record Item)
    var
        RequisitionWkshToOrder: Enum "Requisition Wksh. To Order";
        FilterValue: Boolean;
    begin
        if not GetToOrderStateExpression(RequisitionWkshToOrder, FilterValue) then
            exit;

        MarkItemWithHasToOrderSalesLine(Item, RequisitionWkshToOrder);
        MarkItemWithHasToOrderServiceLine(Item, RequisitionWkshToOrder);

        Item.MarkedOnly(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterFilterLinesWithItemToPlan', '', false, false)]
    local procedure OnAfterFilterSalesLinesWithItemToPlan(var SalesLine: Record "Sales Line"; var Item: Record Item; DocumentType: Option)
    var
        RequisitionWkshToOrder: Enum "Requisition Wksh. To Order";
        FilterValue: Boolean;
    begin
        if not GetToOrderStateExpression(RequisitionWkshToOrder, FilterValue) then
            exit;

        SalesLine.SetRange("To Order PHM", FilterValue);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterFilterLinesWithItemToPlan', '', false, false)]
    local procedure OnAfterFilterServiceLinesWithItemToPlan(var ServiceLine: Record "Service Line"; var Item: Record Item)
    var
        RequisitionWkshToOrder: Enum "Requisition Wksh. To Order";
        FilterValue: Boolean;
    begin
        if not GetToOrderStateExpression(RequisitionWkshToOrder, FilterValue) then
            exit;

        ServiceLine.SetRange("To Order PHM", FilterValue);
    end;

    /// <summary>
    /// Set the source document information on the purchase line before creating a reservation entry.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Line-Reserve", 'OnCreateReservationOnBeforeCreateReservEntry', '', false, false)]
    local procedure OnCreateReservationOnBeforeCreateReservEntry(var PurchLine: Record "Purchase Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var IsHandled: Boolean; var FromTrackingSpecification: Record "Tracking Specification"; ExpectedReceiptDate: Date; var Description: Text[100]; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";

        PurchaseLine: Record "Purchase Line";
        PurchRef: RecordRef;

        SourceType, SourceSubType, LineNo : Integer;
        Condition: Boolean;

        TechnitianName, CustomerName : Code[100];
        DocumentType, TenantName : Text[100];
        DocumentNo, InterventionNo : Code[20];
    begin
        if QuantityBase = 0 then
            exit;

        SourceType := FromTrackingSpecification."Source Type";
        SourceSubType := FromTrackingSpecification."Source Subtype";

        Condition :=
            ((SourceType = Database::"Sales Line") and (SourceSubType = Enum::"Sales Document Type"::Order.AsInteger())) or
            ((SourceType = Database::"Service Line") and (SourceSubType = Enum::"Service Document Type"::Order.AsInteger()));

        if not Condition then
            exit;

        DocumentNo := FromTrackingSpecification."Source ID";
        LineNo := FromTrackingSpecification."Source Ref. No.";

        case SourceType of
            Database::"Sales Line":
                begin
                    DocumentType := SalesHeader.TableName();

                    SalesHeader.SetLoadFields(
                        "Sell-to Customer No.", "Nom du technicien", "Ship-to Name");

                    if SalesHeader.Get(Enum::"Sales Document Type"::Order, DocumentNo) then begin
                        CustomerName := GetCustomerName(SalesHeader."Sell-to Customer No.");
                        TechnitianName := SalesHeader."Nom du technicien";
                        TenantName := SalesHeader."Ship-to Name";
                        InterventionNo := GetInterventionNo(SalesHeader);
                    end;
                end;
            Database::"Service Line":
                begin
                    DocumentType := ServiceHeader.TableName();

                    ServiceHeader.SetLoadFields(
                        "Customer No.", "Nom du technicien", "N° de l’intervention", "Ship-to Name");

                    if ServiceHeader.Get(Enum::"Service Document Type"::Order, DocumentNo) then begin
                        CustomerName := GetCustomerName(ServiceHeader."Customer No.");
                        TechnitianName := ServiceHeader."Nom du technicien";
                        TenantName := ServiceHeader."Ship-to Name";
                        InterventionNo := ServiceHeader."N° de l’intervention";
                    end;
                end;
        end;

        if not PurchaseLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.") then
            exit;

        PurchaseLine."Phma source Document Order No" := DocumentNo;
        PurchaseLine."Phma document order type" := DocumentType;
        PurchaseLine."Source Document Line No." := LineNo;
        PurchaseLine."Phma Customer Name" := CustomerName;
        PurchaseLine."Technitian Name" := TechnitianName;
        PurchaseLine.TenantName := TenantName;
        PurchaseLine."No de intervention" := InterventionNo;

        PurchaseLine.Modify();

        PurchRef.GetTable(PurchaseLine);
        PurchRef.SetTable(PurchLine);
    end;

    /// <summary>
    /// Clear the source document information on the purchase line when the reservation is canceled.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnAfterCancelReservation', '', false, false)]
    local procedure OnAfterCancelReservation(ReservationEntry3: Record "Reservation Entry"; ReservationEntry: Record "Reservation Entry")
    var
        PurchaseLine: Record "Purchase Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        if ReservationEntry3."Quantity (Base)" > 0 then
            TempReservationEntry.Copy(ReservationEntry3)
        else if ReservationEntry."Quantity (Base)" > 0 then
            TempReservationEntry.Copy(ReservationEntry)
        else
            exit;

        //Check if not purchase order line, exit
        if not ((TempReservationEntry."Source Type" = Database::"Purchase Line") and (TempReservationEntry."Source Subtype" = Enum::"Purchase Document Type"::Order.AsInteger())) then
            exit;

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, TempReservationEntry."Source ID", TempReservationEntry."Source Ref. No.") then
            exit;

        if PurchaseLine."Phma source Document Order No" = '' then
            exit;

        PurchaseLine.ClearSourceDocumentFields();
        PurchaseLine.Modify();
    end;
}