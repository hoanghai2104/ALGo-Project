pageextension 50132 PostedServiceCreditMemo extends "Posted Service Credit Memo"
{
    layout
    {
        // Add changes to page layout here
        addlast(General)
        {
            group("Nom du Proprietaire Group")
            {
                Caption = 'Nom du Propriétaire';
                field("Nom du Proprietaire"; NomDuProprietaire)
                {
                    ApplicationArea = all;
                    Importance = Additional;
                    MultiLine = true;
                    ShowCaption = false;
                    Editable = false;
                    trigger OnValidate()
                    var
                        NomDuProprietaire: Text;
                    begin
                        Rec.SetNomduProprietaire(NomDuProprietaire);
                    end;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }
    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;

    var
        NomDuProprietaire: Text;
}