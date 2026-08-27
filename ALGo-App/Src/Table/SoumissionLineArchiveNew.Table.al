table 50107 "SoumissionLineArchiveNew"
{
    DataClassification = CustomerContent;
    Caption = 'Soumission archive Line';
    AllowInCustomizations = AsReadOnly;

    fields
    {
        field(20; PK; Integer) { }
        field(1; "Soumission ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "No"; Code[20])
        {
            TableRelation = if (Type = const(Article)) Item."No.";
            trigger OnValidate()
            var
                item: Record Item;
            begin
                if Rec.Type <> Rec.Type::Article then
                    this.FieldError(No, 'Invalid');
                if item.Get(Rec.No) then
                    Rec.Designation := item.Description;
            end;
        }

        field(3; "Line No"; Integer)
        {
            Caption = 'No Ligne';
        }
        field(4; "Type"; Enum SubmissionType)
        {

        }
        field(5; "Designation"; Text[100])
        {
            Caption = 'Désignation';
            // FieldClass = FlowField;
            // CalcFormula = lookup(Item.Description where("No." = field(No)));
            // Editable = false;
        }
        field(6; "Totalisation"; Text[50])
        {

        }
        field(7; "Quantity"; Decimal)
        {
            Caption = 'Quantité';
            trigger OnValidate()
            begin

            end;
        }
        field(8; "Unit Price"; Decimal)
        {

        }
        field(9; "Remise"; Decimal)
        {
            Caption = '%remise';
        }
        field(10; "% OB"; Decimal)
        {

        }
        field(11; "Prix Unitaire net"; Decimal)
        {
            Editable = false;

        }
        field(12; "Montant net"; Decimal)
        {

        }
        field(13; "Style Property"; Enum StyleProperty) { }

        field(14; "Code RPLP"; Integer)
        {
            BlankZero = true;
        }
        field(15; "Montant Totalisation"; Decimal)
        {

        }
        field(16; Gras; Boolean)
        {

        }
        field(17; Italique; Boolean)
        {

        }
        field(18; Souligné; Boolean)
        {

        }
        field(19; "VAT Prod. Posting Group"; Code[20])
        {
            TableRelation = "VAT Product Posting Group";
        }

        field(21; "Amount Including Vat"; Decimal)
        {
            DecimalPlaces = 2;
        }
        field(22; DocumentNo; Code[20])
        {
            Caption = 'Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup(SoumissionHeaderArchive.DocumentNo where("Soumission ID" = field("Soumission ID")));
        }
        field(23; "Description Supp."; Text[500])
        {
            Caption = 'Description Supp.';
            //DataClassification = CustomerContent; // Utilise approprié: CustomerContent, ToBeClassified, etc.
        }

    }

    keys
    {
        key(Key1; PK, "Soumission ID", "Line No")
        {
            Clustered = true;

        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }


    trigger OnInsert()
    begin

    end;



    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;


}