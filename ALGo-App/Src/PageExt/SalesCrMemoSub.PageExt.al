pageextension 50105 SalesCrMemoSub extends "Sales Cr. Memo Subform"
{

    layout
    {
        addafter(Description)
        {
            field("Description Supp."; Rec."Description Supp.")
            {
                ApplicationArea = all;
            }

            field("Code RPLP"; Rec."Code RPLP")
            {
                ApplicationArea = all;
                Lookup = true;
                LookupPageId = RplpParametrageList;
            }
        }
        addafter("Unit Price")
        {
            field("% Remise articles"; Rec."% Remise articles")
            {
                ApplicationArea = all;
            }
            field("Remise article amount"; Rec."Remise article amount")
            {
                ApplicationArea = all;
            }
            field("% OB"; Rec."% OB")
            {
                ApplicationArea = All;
            }

            field("Montant OB ligne"; Rec."Montant OB ligne")
            {
                ApplicationArea = All;
            }
        }
    }
}