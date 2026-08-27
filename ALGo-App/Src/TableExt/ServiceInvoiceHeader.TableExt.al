tableextension 50120 ServiceInvoiceHeader extends "Service Invoice Header"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here

        field(50103; "Nom du Proprietaire"; Blob)
        {
            Caption = 'Nom du Propriétaire';

        }
        field(50105; "Reference Supp."; Text[800])
        {
            Caption = 'Référence Supp.';
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

    procedure SetNomduProprietaire(NewNomduProprietaire: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Nom du Proprietaire");
        "Nom du Proprietaire".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewNomduProprietaire);
        if rec.Modify() then;
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