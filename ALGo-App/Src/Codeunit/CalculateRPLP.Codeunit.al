codeunit 50100 CalculateRPLP
{
    trigger OnRun()
    begin

    end;

    procedure CalculateRplp(SalesHeader: Record "Sales Header")
    var
        salesLine: Record "Sales Line";
        createSalesLine: Record "Sales Line";
        RPLP: Record RplpParametrage;
        TempCalculateRplp: Record CalculateRPLP temporary;
        MaxlineNoSalesLine: Record "Sales Line";
        Item: Record Item;
        count: Integer;
    begin

        MaxlineNoSalesLine.Reset();
        MaxlineNoSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        MaxlineNoSalesLine.SetRange("Document No.", SalesHeader."No.");
        MaxlineNoSalesLine.SetAscending("Line No.", false);
        if MaxlineNoSalesLine.FindFirst() then begin
            count := MaxlineNoSalesLine."Line No.";
        end;

        RPLP.Reset();
        salesLine.Reset();
        salesLine.SetRange("Document Type", SalesHeader."Document Type");
        salesLine.SetRange("Document No.", SalesHeader."No.");
        if salesLine.FindSet() then
            repeat

                if not RPLP.Get(salesLine."Code RPLP") then
                    continue;

                if not TempCalculateRplp.Get(RPLP."Code ID") then begin
                    TempCalculateRplp.Init();
                    TempCalculateRplp.Code := RPLP."Code ID";
                    TempCalculateRplp."Total RPLP Line Amount" += salesLine."Line Amount";
                    TempCalculateRplp.Insert();
                end else begin
                    TempCalculateRplp."Total RPLP Line Amount" += salesLine."Line Amount";
                    TempCalculateRplp.Modify();
                end;

            until salesLine.Next() = 0;

        RPLP.Reset();
        createSalesLine.Reset();


        if TempCalculateRplp.FindSet() then
            repeat
                createSalesLine.Init();
                createSalesLine."Document Type" := SalesHeader."Document Type";
                createSalesLine.Validate("Document Type");
                createSalesLine."Document No." := SalesHeader."No.";
                createSalesLine.Type := createSalesLine.type::Item;
                createSalesLine.Validate(Type);
                if not RPLP.Get(TempCalculateRplp.Code) then
                    continue;
                if RPLP.Article = '' then
                    continue;
                createSalesLine."No." := RPLP.Article;
                createSalesLine.Validate("No.");
                // createSalesLine.Quantity := TempCalculateRplp."Total RPLP Line Amount";
                createSalesLine.Quantity := 1;
                Item.Get(RPLP.Article);
                createSalesLine."Unit Price" := TempCalculateRplp."Total RPLP Line Amount" * Item."Unit Price";
                createSalesLine.validate(Quantity);
                createSalesLine.validate("Unit Price");
                count += 10000;
                createSalesLine."Line No." := count;
                createSalesLine.Validate("Line No.");

                salesLine.Reset();
                salesLine.SetRange("Document Type", SalesHeader."Document Type");
                salesLine.SetRange("Document No.", SalesHeader."No.");
                salesLine.SetRange("No.", RPLP.Article);
                if salesLine.Count() = 0 then
                    createSalesLine.Insert()
                else
                    if salesLine.FindFirst() then begin
                        salesLine.Quantity := 1;
                        salesLine."Unit Price" := TempCalculateRplp."Total RPLP Line Amount";
                        salesLine.Validate(Quantity);
                        salesLine.Validate("Unit Price");
                        salesLine.Modify();

                    end;

            until TempCalculateRplp.Next() = 0;
    end;

    procedure CalculateRplpSoumission(soumission: Record SoumissionHeader)
    var
        SoumissionLine: Record SoumissionLine;
        createSoumissionLine: Record SoumissionLine;
        RPLP: Record RplpParametrage;
        TempCalculateRplp: Record CalculateRPLP temporary;
        MaxlineNoSoumisionLine: Record SoumissionLine;
        Item: Record Item;
        count: Integer;
    begin

        MaxlineNoSoumisionLine.Reset();
        MaxlineNoSoumisionLine.SetRange("Soumission ID", soumission."Soumission ID");
        MaxlineNoSoumisionLine.SetAscending("Line No", false);
        if MaxlineNoSoumisionLine.FindFirst() then begin
            count := MaxlineNoSoumisionLine."Line No";
        end;

        RPLP.Reset();
        SoumissionLine.Reset();
        SoumissionLine.SetRange("Soumission ID", soumission."Soumission ID");
        if SoumissionLine.FindSet() then
            repeat

                if not RPLP.Get(SoumissionLine."Code RPLP") then
                    continue;

                if not TempCalculateRplp.Get(RPLP."Code ID") then begin
                    TempCalculateRplp.Init();
                    TempCalculateRplp.Code := RPLP."Code ID";
                    TempCalculateRplp."Total RPLP Line Amount" += SoumissionLine."Montant net";
                    TempCalculateRplp.Insert();
                end else begin
                    TempCalculateRplp."Total RPLP Line Amount" += SoumissionLine."Montant net";
                    TempCalculateRplp.Modify();
                end;

            until SoumissionLine.Next() = 0;

        RPLP.Reset();
        createSoumissionLine.Reset();


        if TempCalculateRplp.FindSet() then
            repeat
                createSoumissionLine.Init();
                createSoumissionLine."Soumission ID" := soumission."Soumission ID";
                if not RPLP.Get(TempCalculateRplp.Code) then
                    continue;
                if RPLP.Article = '' then
                    continue;
                createSoumissionLine.Type := createSoumissionLine.Type::Article;
                createSoumissionLine."No" := RPLP.Article;
                createSoumissionLine.Validate(No);
                createSoumissionLine.Quantity := 1;
                Item.Get(RPLP.Article);
                createSoumissionLine."Unit Price (base)" := TempCalculateRplp."Total RPLP Line Amount" * Item."Unit Price";

                count += 10000;
                createSoumissionLine."Line No" := count;
                // createSoumissionLine.CalcFields("Unit Price");
                createSoumissionLine."Prix Unitaire net" := createSoumissionLine."Unit Price (base)" * createSoumissionLine.Quantity;
                createSoumissionLine."Montant net" := createSoumissionLine."Unit Price (base)" * createSoumissionLine.Quantity;
                createSoumissionLine."Montant Totalisation" := createSoumissionLine."Unit Price (base)" * createSoumissionLine.Quantity;
                soumissionCodeunit.calculateItemAmountIncVat(createSoumissionLine);

                SoumissionLine.Reset();
                SoumissionLine.SetRange("Soumission ID", soumission."Soumission ID");
                SoumissionLine.SetRange("No", RPLP.Article);
                if SoumissionLine.Count() = 0 then
                    createSoumissionLine.Insert()
                else
                    if SoumissionLine.FindFirst() then begin
                        // SoumissionLine.Validate(No);
                        SoumissionLine.Quantity := 1;
                        createSoumissionLine."Unit Price (base)" := TempCalculateRplp."Total RPLP Line Amount" * Item."Unit Price";
                        // SoumissionLine.CalcFields("Unit Price");
                        soumissionLine."Prix Unitaire net" := SoumissionLine."Unit Price (base)" * SoumissionLine.Quantity;
                        SoumissionLine."Montant net" := SoumissionLine."Unit Price (base)" * SoumissionLine.Quantity;
                        SoumissionLine."Montant Totalisation" := SoumissionLine."Unit Price (base)" * SoumissionLine.Quantity;
                        soumissionCodeunit.calculateItemAmountIncVat(SoumissionLine);
                        SoumissionLine.Modify();

                    end;

            until TempCalculateRplp.Next() = 0;
    end;

    var
        soumissionCodeunit: Codeunit Soumission;
}