page 50114 "Sales/Service Order Lookup"
{
    Caption = 'Sales/Service Order Lookup';
    PageType = ListPart;
    SourceTable = "Sales/Service Order Buffer";
    Editable = false;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Document No."; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    Caption = 'Document Type';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    Caption = 'Customer Name';
                    ApplicationArea = All;
                }
                field("Technician Name"; Rec."Technician Name")
                {
                    Caption = 'Technician Name';
                    ApplicationArea = All;
                }
                field("Intervention No."; Rec."Intervention No.")
                {
                    Caption = 'Intervention No.';
                    ApplicationArea = All;
                }
                field("Tenant Name"; Rec."Tenant Name")
                {
                    Caption = 'Tenant Name';
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        GlobalSourceType: Enum "Requisition Source Type";
        SalesExist, ServiceExist : Boolean;

    procedure InitFromSalesOrder(ItemNo: Code[20]; ExcludedSourceDocNo: Code[20]): Boolean;
    var
        SalesHeader: Record "Sales Header";
        SalesOrderBufferLookup: Query "Sales Order Buffer Lookup";
        GroupedSalesList: List of [Code[20]];
    begin
        SalesOrderBufferLookup.SetRange(ItemNo, ItemNo);

        if ExcludedSourceDocNo <> '' then
            SalesOrderBufferLookup.SetFilter(No, '<>%1', ExcludedSourceDocNo);

        SalesOrderBufferLookup.Open();
        while SalesOrderBufferLookup.Read() do begin
            if GroupedSalesList.Contains(SalesOrderBufferLookup.No) then
                continue;

            Rec.Init();
            Rec."Document No." := SalesOrderBufferLookup.No;
            Rec."Document Type" := SalesHeader.TableName();
            Rec."Customer No." := SalesOrderBufferLookup.CustomerNo;
            Rec."Customer Name" := SalesOrderBufferLookup.CustomerName;
            Rec."Intervention No." := SalesOrderBufferLookup.InterventionNo;
            Rec."Technician Name" := SalesOrderBufferLookup.TechnicianName;
            Rec."Tenant Name" := SalesOrderBufferLookup.TenantName;
            Rec.Insert();

            GroupedSalesList.Add(SalesOrderBufferLookup.No);
        end;
        SalesOrderBufferLookup.Close();

        SalesExist := GroupedSalesList.Count() > 0;
        exit(true);
    end;

    procedure InitFromServiceOrder(ItemNo: Code[20]; ExcludedSourceDocNo: Code[20]): Boolean;
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderBufferLookup: Query "Service Order Buffer Lookup";
        GroupedServiceList: List of [Code[20]];
    begin
        ServiceOrderBufferLookup.SetRange(ItemNo, ItemNo);

        if ExcludedSourceDocNo <> '' then
            ServiceOrderBufferLookup.SetFilter(No, '<>%1', ExcludedSourceDocNo);

        ServiceOrderBufferLookup.Open();
        while ServiceOrderBufferLookup.Read() do begin
            if GroupedServiceList.Contains(ServiceOrderBufferLookup.No) then
                continue;

            Rec.Init();
            Rec."Document No." := ServiceOrderBufferLookup.No;
            Rec."Document Type" := ServiceHeader.TableName();
            Rec."Customer No." := ServiceOrderBufferLookup.CustomerNo;
            Rec."Customer Name" := ServiceOrderBufferLookup.CustomerName;
            Rec."Intervention No." := ServiceOrderBufferLookup.InterventionNo;
            Rec."Technician Name" := ServiceOrderBufferLookup.TechnicianName;
            Rec."Tenant Name" := ServiceOrderBufferLookup.TenantName;
            Rec.Insert();

            GroupedServiceList.Add(ServiceOrderBufferLookup.No);
        end;
        ServiceOrderBufferLookup.Close();

        ServiceExist := GroupedServiceList.Count() > 0;
        exit(true);
    end;

    procedure TransferDataFromSalesOrderToPurchaseLine(var PurchaseLine: Record "Purchase Line"): Boolean;
    begin
        exit(TransferDataToPurchaseLine(GlobalSourceType::"Sales Order", PurchaseLine));
    end;

    procedure TransferDataFromServiceOrderToPurchaseLine(var PurchaseLine: Record "Purchase Line"): Boolean;
    begin
        exit(TransferDataToPurchaseLine(GlobalSourceType::"Service Order", PurchaseLine));
    end;

    local procedure TransferDataToPurchaseLine(SourceType: Enum "Requisition Source Type"; var PurchaseLine: Record "Purchase Line"): Boolean;
    begin
        //No record found in the buffer, exit.
        if not CheckExistEntries(SourceType) then
            exit;

        // Skip if the Purchase Line already has the same source document information to avoid unnecessary updates.
        if (PurchaseLine."Phma source Document Order No" = Rec."Document No.") and (PurchaseLine."Phma document order type" = Rec."Document Type") then
            exit;

        PurchaseLine."Phma source Document Order No" := Rec."Document No.";
        PurchaseLine."Phma document order type" := Rec."Document Type";
        PurchaseLine."Phma Customer Name" := Rec."Customer Name";
        PurchaseLine."Technitian Name" := Rec."Technician Name";
        PurchaseLine.TenantName := Rec."Tenant Name";
        PurchaseLine."No de intervention" := Rec."Intervention No.";

        exit(true);
    end;

    local procedure CheckExistEntries(SourceType: Enum "Requisition Source Type"): Boolean;
    begin
        case SourceType of
            SourceType::"Sales Order":
                exit(SalesExist);
            SourceType::"Service Order":
                exit(ServiceExist);
        end;
    end;
}