page 50113 "Sales/Service Order Worksheet"
{
    Caption = 'Sales/Service Order Filter';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(SourceType; SourceType)
            {
                Caption = 'Source Type';
                trigger OnValidate()
                begin
                    InitBufferRecords();
                end;
            }
            field(ItemNo; ItemNo)
            {
                Caption = 'Item No.';
                Editable = false;
            }
            field(ItemDescription; ItemDescription)
            {
                Caption = 'Item Description';
                Editable = false;
            }
            part(SalesOrderBufferLookup; "Sales/Service Order Lookup")
            {
                Caption = 'Sales Order Buffer Lookup';
                ApplicationArea = All;
                Visible = SalesVisible;
            }
            part(ServiceOrderBufferLookup; "Sales/Service Order Lookup")
            {
                Caption = 'Service Order Buffer Lookup';
                ApplicationArea = All;
                Visible = not SalesVisible;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitBufferRecords();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean;
    begin
        if CloseAction <> CloseAction::OK then
            exit;

        UpdatePurchaseLine();
    end;

    var
        SourceType: Enum "Requisition Source Type";
        DocumentNo, SourceDocumentNo, ItemNo : Code[20];
        ItemDescription: Text[100];
        LineNo: Integer;
        SalesVisible: Boolean;
        SalesInitialized, ServiceInitialized : Boolean;
        ItemTypeRequiredErr: Label 'The type must be Item.';

    procedure SetPurchaseLineProfile(PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            Error(ItemTypeRequiredErr);

        DocumentNo := PurchaseLine."Document No.";
        SourceDocumentNo := PurchaseLine."Phma source Document Order No";
        LineNo := PurchaseLine."Line No.";
        ItemNo := PurchaseLine."No.";
        ItemDescription := PurchaseLine.Description;
    end;

    local procedure InitBufferRecords()
    begin
        case SourceType of
            SourceType::"Sales Order":
                begin
                    SalesVisible := true;

                    if SalesInitialized then
                        exit;

                    // Initialize Sales Order Buffer records
                    SalesInitialized := CurrPage.SalesOrderBufferLookup.Page.InitFromSalesOrder(ItemNo, SourceDocumentNo);
                end;
            SourceType::"Service Order":
                begin
                    Clear(SalesVisible);

                    if ServiceInitialized then
                        exit;

                    // Initialize Service Order Buffer records
                    ServiceInitialized := CurrPage.ServiceOrderBufferLookup.Page.InitFromServiceOrder(ItemNo, SourceDocumentNo);
                end;
        end;
    end;

    local procedure UpdatePurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
        CanModify: Boolean;
    begin
        if not PurchaseLine.Get(PurchaseLine."Document Type"::Order, DocumentNo, LineNo) then
            exit;

        if SourceType = SourceType::"Sales Order" then
            CanModify := CurrPage.SalesOrderBufferLookup.Page.TransferDataFromSalesOrderToPurchaseLine(PurchaseLine)
        else
            CanModify := CurrPage.ServiceOrderBufferLookup.Page.TransferDataFromServiceOrderToPurchaseLine(PurchaseLine);

        if not CanModify then
            exit;

        PurchaseLine.Validate(Quantity, 0);
        PurchaseLine.Modify();
    end;
}