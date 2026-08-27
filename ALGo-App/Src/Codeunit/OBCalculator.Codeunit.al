codeunit 50102 OBCalculator
{
    procedure CalcOBLineAmount(var Rec: Record "Sales Line")
    var
        BaseAmount: Decimal;
        RemiseArticleAmount: Decimal;
        TotalDiscountedLine: Decimal;
        totaldiscounted: Decimal;
    begin
        BaseAmount := Rec.Quantity * Rec."Unit Price";
        Rec."Remise article amount" := (BaseAmount * (Rec."% Remise articles" / 100));
        RemiseArticleAmount := BaseAmount - (BaseAmount * (Rec."% Remise articles" / 100));
        TotalDiscountedLine := RemiseArticleAmount - (RemiseArticleAmount * (Rec."% OB" / 100));
        Rec."Montant OB ligne" := (RemiseArticleAmount * (Rec."% OB" / 100));
        if (TotalDiscountedLine <> 0) and (BaseAmount <> 0) then
            totaldiscounted := (1 - (TotalDiscountedLine / BaseAmount)) * 100;

        if (Rec."% Remise articles" = 100) or (Rec."% OB" = 100) then
            totaldiscounted := 100;
        Rec."Line Discount %" := totaldiscounted;
        Rec.Validate("Line Discount %");

    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnCopyFromItemOnAfterCheck, '', false, false)]
    local procedure "Sales Line_OnCopyFromItemOnAfterCheck"(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        SalesLine."Code RPLP" := item."Code RPLP";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterApplyPrice, '', false, false)]
    local procedure "Sales Line_OnAfterApplyPrice"(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallFieldNo: Integer; CurrentFieldNo: Integer)
    begin
        SalesLine."% Remise articles" := SalesLine."Line Discount %";
    end;

    procedure SellingPriceAlert(var salesLine: Record "Sales Line"; Message: Boolean): Boolean
    begin
        if not (salesLine."Document Type" in [salesLine."Document Type"::Invoice, salesLine."Document Type"::Order, salesLine."Document Type"::Quote]) then
            exit;
        if (salesLine."Unit Cost" * salesLine.Quantity) > salesLine."Line Amount" then begin
            if Message then
                Message('Le prix de vente sur la ligne article est inférieure au prix d’achat');
            exit(true);

        end;

    end;

}