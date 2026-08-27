table 50106 "SoumissionHeaderArchive"
{
    DataClassification = ToBeClassified;
    AllowInCustomizations = AsReadOnly;


    fields
    {
        field(4; PK; Integer)
        {
            AutoIncrement = true;
        }
        field(1; "Soumission ID"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'this is soumission ID';
            Caption = 'Soumission ID';
        }

        field(8; DocumentNo; Code[20])
        {
            Caption = 'Devis ID';
            TableRelation = "Sales Header"."No.";
        }

        field(2; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Type document';
        }
        field(3; "Customer ID"; Code[20])
        {
            Caption = 'N° client';
            TableRelation = Customer."No.";
        }
        field(5; "Nom client"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer ID")));
        }
        field(9; "Status"; Enum SoumissionArchiveStatus)
        {

        }
#pragma warning disable AA0232
        field(6; "Montant"; Decimal)
#pragma warning restore AA0232
        {
            FieldClass = FlowField;
            CalcFormula = sum(SoumissionLineArchiveNew."Amount Including Vat" where(pk = field(PK), Type = filter(Article)));
        }

        field(7; "Date de document"; Date)
        {

        }
        field(10; "VAT Bus. Posting Group"; Code[20])
        {
            TableRelation = "VAT Business Posting Group";
        }

    }

    keys
    {
        key(Key1; PK, "Soumission ID")
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
        // this.GetNextNumberSeries(Rec);
    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure GetNextNumberSeries(var submissionHeader: Record SoumissionHeader)
    var
        salesAndReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeriesMgt: Codeunit "No. Series";
    begin
        if not salesAndReceivablesSetup.get() then
            exit;
        salesAndReceivablesSetup.TestField("Soumission Nos");
        Rec."Soumission ID" := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Soumission Nos", Today(), true);
    end;

}