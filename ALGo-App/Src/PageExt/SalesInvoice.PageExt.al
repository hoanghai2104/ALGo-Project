pageextension 50112 SalesInvoice extends "Sales Invoice"
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
                    trigger OnValidate()
                    begin
                        Rec.SetNomduProprietaire(NomDuProprietaire);
                    end;
                }
            }
        }
        addafter("Due Date")
        {
            field("Reference Supp."; Rec."Reference Supp.")
            {
                ApplicationArea = All;
                Caption = 'Référence Supp.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("P&osting")
        {

            action("Calculate RPLP")
            {
                ApplicationArea = all;
                Image = Calculate;

                trigger OnAction()
                var
                    CalculateRPLP: Codeunit CalculateRPLP;
                begin
                    CalculateRPLP.CalculateRplp(Rec);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(Promoted_CalculateRPLP; "Calculate RPLP") { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;

    var
        NomDuProprietaire: Text;
}