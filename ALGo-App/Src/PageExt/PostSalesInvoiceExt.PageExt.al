pageextension 50115 PostSalesInvoiceExt extends "Posted Sales Invoice"
{
    layout
    {
        addbefore("Due Date")
        {
            field("Reference Supp."; Rec."Reference Supp.")
            {
                ApplicationArea = All;
                Caption = 'Référence Supp.';
            }
        }
        addlast(General)
        {
            field("Type commande service"; Rec."Type commande service")
            {
                ApplicationArea = all;
            }
            field("Statut commande"; Rec."Statut commande")
            {
                ApplicationArea = all;
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
                    Editable = false;
                    // trigger OnValidate()
                    // begin
                    //     Rec.SetNomduProprietaire(NomDuProprietaire);
                    // end;
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