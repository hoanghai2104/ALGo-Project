pageextension 50111 SalesCreditMemoExt extends "Sales Credit Memo"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            field("Reference Supp."; Rec."Reference Supp.")
            {
                ApplicationArea = All;
                Caption = 'Référence Supp.';
            }
            group("Nom du Proprietaire Group")
            {
                Caption = 'Nom du Propriétaire';
                field("Nom du Proprietaire"; NomDuProprietaire)
                {
                    ApplicationArea = all;
                    Importance = Additional;
                    MultiLine = true;
                    ShowCaption = false;
                    trigger OnValidate()
                    begin
                        Rec.SetNomduProprietaire(NomDuProprietaire);
                    end;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;

    var
        NomDuProprietaire: Text;
}