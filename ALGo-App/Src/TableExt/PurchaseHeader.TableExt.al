tableextension 50115 PurchaseHeader extends "Purchase Header"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50102; "N° de l’intervention"; Code[20])
        {
            // FieldClass = FlowField;
            // CalcFormula = lookup("Service Header"."No." where("Sales Order Reference" = field("No."), "Document Type" = field("Document Type")));
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Text[100] field.';

        }
        field(50103; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien';
            // FieldClass = FlowField;
            // CalcFormula = lookup("Service Header".TechnitianName where("No." = field("N° de l’intervention")));
            TableRelation = Resource."No.";

        }
        field(50104; "No de intervention"; Text[100])
        {
            Caption = 'N° de l’intervention';
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

    trigger OnInsert()
    begin
        if rec."Document Type" in ["Document Type"::Order, "Document Type"::"Credit Memo", "Document Type"::Quote, "Document Type"::Invoice] then begin
            rec."Assigned User ID" := Format(UserId);
            Rec.Validate("Assigned User ID");
        end;
    end;

}