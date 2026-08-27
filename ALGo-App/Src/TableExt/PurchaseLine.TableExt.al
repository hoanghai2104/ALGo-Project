tableextension 50116 PurchaseLine extends "Purchase Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "N° de l’intervention"; Code[20])
        {
            // InitValue = '123';
            ObsoleteState = Removed;
            ObsoleteReason = 'Used in order tracking extension';
        }

        field(50101; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien';
            // InitValue = 'technitian';
            ObsoleteState = Removed;
            ObsoleteReason = 'Used in order tracking extension';

        }

        field(50102; "No de intervention"; Text[100])
        {
            Caption = 'N° de l’intervention';
        }

        ///<summary>
        /// used as Nom du technicien
        /// </summary>
        field(50103; "Technitian Name"; Text[100])
        {
            Caption = 'Nom du technicien';

        }
        field(50104; "Phma source Document Order No"; Code[20])
        {

        }
        field(50105; "Phma Customer Name"; Text[100])
        {

        }
        field(50106; "Phma document order type"; Text[100])
        {

        }
        field(50107; "TenantName"; Text[100])
        {
            Caption = 'Nom du Locataire';
            DataClassification = ToBeClassified;
        }
        field(50108; "Source Document Line No."; Integer)
        {
            Caption = 'Source Document Line No.';
            DataClassification = ToBeClassified;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                if "No." <> xRec."No." then
                    ClearSourceDocumentFields();
            end;
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                CheckQuantityExceedsSourceDocument();
            end;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        PurchaseQuantityExceedsSourceDocumentErr: Label 'Purchase quantity (%1) cannot exceed the quantity (%2) for this item in %3: %4, Line No.: %5';

    procedure ClearSourceDocumentFields()
    begin
        Clear("Phma source Document Order No");
        Clear("Phma document order type");
        Clear("Source Document Line No.");
        Clear("No de intervention");
        Clear("Technitian Name");
        Clear("Phma Customer Name");
        Clear("TenantName");
    end;

    local procedure CheckQuantityExceedsSourceDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";

        SourceDocumentNo: Code[20];
        SourceDocumentLineNo: Integer;
        MaxQuantity: Decimal;
    begin
        SourceDocumentNo := "Phma source Document Order No";
        if SourceDocumentNo = '' then
            exit;

        SourceDocumentLineNo := "Source Document Line No.";
        case "Phma document order type" of
            SalesHeader.TableName():
                begin
                    SalesLine.SetLoadFields(Quantity);
                    if not SalesLine.Get(SalesLine."Document Type"::Order, SourceDocumentNo, SourceDocumentLineNo) then
                        exit;

                    if SalesLine.Type <> SalesLine.Type::Item then
                        exit;

                    MaxQuantity := SalesLine.Quantity;
                end;
            ServiceHeader.TableName():
                begin
                    ServiceLine.SetLoadFields(Quantity);
                    if not ServiceLine.Get(ServiceLine."Document Type"::Order, SourceDocumentNo, SourceDocumentLineNo) then
                        exit;

                    if ServiceLine.Type <> ServiceLine.Type::Item then
                        exit;

                    MaxQuantity := ServiceLine.Quantity;
                end;
        end;

        if Quantity > MaxQuantity then
            Error(PurchaseQuantityExceedsSourceDocumentErr, Quantity, MaxQuantity, "Phma document order type", SourceDocumentNo, SourceDocumentLineNo);
    end;
}