tableextension 50105 SalesHeaderExt extends "Sales Header"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "Type commande service"; Code[10])
        {
            TableRelation = "Service Order Type".Code;
        }
        field(50101; "Statut commande"; Enum "Service Document Status")
        {

        }
        field(50104; "Reference Supp."; Text[800])
        {
            Caption = 'Référence Supp.';
        }
        field(50102; "N° de l’intervention"; text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Service Header"."No." where("Sales Order Reference" = field("No."), "Document Type" = field("Document Type")));
        }
        field(50103; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien Unused';
            TableRelation = Resource.Name;
            ValidateTableRelation = false;
            obsoleteState = Pending;
            ObsoleteReason = 'replaced by Nom du technicien';

        }
        field(50105; "Nom du Proprietaire"; Blob)
        {
            Caption = 'Nom du Propriétaire';


        }
        field(50106; "TechnitianID"; Code[20])
        {
            Caption = 'TechnitianID_unused';
            FieldClass = FlowField;
            CalcFormula = lookup("Service Header".TechnitianID where("Sales Order Reference" = field("No."), "Document Type" = field("Document Type")));
            obsoleteState = Pending;
            ObsoleteReason = 'replaced by Nom du technicien';
        }

        field(50107; "Nom du technicien"; Code[100])
        {
            Caption = 'Nom du technicien';
            TableRelation = Resource.Name;
            ValidateTableRelation = false;

        }
        field(50108; "ELCA_Cust_Type"; Enum "Contact Type")
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Customer."Contact Type" where("No." = field("Sell-to Customer No.")));
            Editable = false;
        }

    }
    trigger OnInsert()
    begin
        if rec."Document Type" in ["Document Type"::Order, "Document Type"::"Credit Memo", "Document Type"::Quote, "Document Type"::Invoice] then begin
            rec."Assigned User ID" := Format(UserId);
            Rec.Validate("Assigned User ID");
        end;
    end;

    procedure SetNomduProprietaire(NewNomduProprietaire: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Nom du Proprietaire");
        "Nom du Proprietaire".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewNomduProprietaire);
        rec.Modify();
    end;

    procedure GetNomduProprietaire() NomduProprietaire: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Nom du Proprietaire");
        "Nom du Proprietaire".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Nom du Proprietaire")));
    end;
}