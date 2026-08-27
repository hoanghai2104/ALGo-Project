tableextension 50107 SalesInvoiceHeaderExt extends "Sales Invoice Header"
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
        field(50105; "Nom du Proprietaire"; Blob)
        {
            Caption = 'Nom du Propriétaire';

        }
        field(50102; "ELCA_Cust_Type"; Enum "Contact Type")
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Customer."Contact Type" where("No." = field("Sell-to Customer No.")));
            Editable = false;
        }
    }

    procedure SetNomduProprietaire(NewNomduProprietaire: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Nom du Proprietaire");
        "Nom du Proprietaire".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewNomduProprietaire);
        // rec.Modify();
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