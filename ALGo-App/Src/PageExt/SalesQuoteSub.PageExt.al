pageextension 50102 SalesQuoteSub extends "Sales Quote Subform"
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
        // addlast("Line Discount %")
        addafter("Unit of Measure Code")
        {
            field("% Remise articles"; Rec."% Remise articles")
            {
                ApplicationArea = all;
                Style = Attention;
                StyleExpr = PrixAlert;
            }
            field("Remise article amount"; Rec."Remise article amount")
            {
                ApplicationArea = all;

            }
            field("% OB"; Rec."% OB")
            {
                ApplicationArea = All;
                Style = Attention;
                StyleExpr = PrixAlert;
            }

            field("Montant OB ligne"; Rec."Montant OB ligne")
            {
                ApplicationArea = All;
            }
        }
        modify("Line Discount %")
        {
            Style = Attention;
            StyleExpr = PrixAlert;
        }
        modify("Line Amount")
        {
            Style = Attention;
            StyleExpr = PrixAlert;
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PrixAlert := false;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        PrixAlert := OBCalculator.SellingPriceAlert(Rec, true)
    end;

    trigger OnAfterGetRecord()
    begin
        PrixAlert := OBCalculator.SellingPriceAlert(Rec, false);
    end;

    var
        OBCalculator: Codeunit OBCalculator;
        PrixAlert: Boolean;
}