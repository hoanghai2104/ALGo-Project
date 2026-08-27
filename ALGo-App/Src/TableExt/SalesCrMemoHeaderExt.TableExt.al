tableextension 50106 SalesCrMemoHeaderExt extends "Sales Cr.Memo Header"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50104; "Reference Supp."; Text[800])
        {
            Caption = 'Référence Supp.';
        }
        field(50105; "Nom du Proprietaire"; Blob)
        {
            Caption = 'Nom du Propriétaire';
        }
    }

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