pageextension 50131 ServiceContract extends "Service Contract"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
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
                    trigger OnValidate()
                    begin
                        Rec.SetNomduProprietaire(NomDuProprietaire);
                    end;
                }
            }
            field("Reference Supp."; Rec."Reference Supp.")
            {
                Caption = 'Référence Supp.';
                ApplicationArea = all;
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