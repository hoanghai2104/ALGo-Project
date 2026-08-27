tableextension 50110 ServiceLine extends "Service Line"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; orderLineNo; Integer) { }
        field(50101; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }
        field(50102; "To Order PHM"; Boolean)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                RequisitionWorksheetMgt.CheckToOrderForItemType(Rec);
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

    trigger OnDelete()
    begin
        ClearReservedPurchaseLineFields();
    end;

    var
        RequisitionWorksheetMgt: Codeunit RequisitionWorksheet;

    local procedure ClearReservedPurchaseLineFields()
    var
        ServiceHeader: Record "Service Header";
    begin
        RequisitionWorksheetMgt.ClearReservedPurchaseLineFields("Document No.", ServiceHeader.TableName(), "Line No.");
    end;
}