pageextension 50109 PostSalesInvoiceSubExtension extends "Posted Sales Invoice Subform"
{
    layout
    {
        addafter(Description)
        {
            field("Description Supp."; Rec."Description Supp.")
            {
                ApplicationArea = all;
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