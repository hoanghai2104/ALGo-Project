pageextension 50103 SalesOrderSub extends "Sales Order Subform"
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
        addafter("No.")
        {
            field("To Order PHM"; Rec."To Order PHM")
            {
                Caption = 'To Order';
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
    actions
    {
        addlast("&Line")
        {
            group("To Order")
            {
                Caption = 'To Order';
                Image = Order;
                action("Enable selected lines")
                {
                    Caption = 'Enable selected lines';
                    ApplicationArea = All;
                    Image = CompleteLine;
                    trigger OnAction()
                    begin
                        PerformToOrderAction(true);
                    end;
                }
                action("Disable selected lines")
                {
                    Caption = 'Disable selected lines';
                    ApplicationArea = All;
                    Image = CancelAllLines;
                    trigger OnAction()
                    begin
                        PerformToOrderAction(false);
                    end;
                }
            }


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
        NoLinesSelectedToPerformActionLbl: Label 'No lines selected.';
        NoValidLinesFoundLbl: Label 'No valid lines were found for update (line type must be "Item" and To Order must be "%1")';
        SelectedLinesUpdatedLabel: Label '%1 of %2 selected lines have been updated.';

    local procedure PerformToOrderAction(Enable: Boolean)
    var
        SalesLine: Record "Sales Line";
        TotalCount, ToUpdateCount : Integer;
    begin
        CurrPage.SetSelectionFilter(SalesLine);

        if SalesLine.IsEmpty() then begin
            Message(NoLinesSelectedToPerformActionLbl);
            exit;
        end;
        TotalCount := SalesLine.Count();

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("To Order PHM", not Enable);
        if SalesLine.IsEmpty() then begin
            Message(NoValidLinesFoundLbl, SalesLine.GetFilter("To Order PHM"));
            exit;
        end;
        ToUpdateCount := SalesLine.Count();

        SalesLine.ModifyAll("To Order PHM", Enable);

        if TotalCount <> ToUpdateCount then
            Message(SelectedLinesUpdatedLabel, ToUpdateCount, TotalCount);
    end;

}