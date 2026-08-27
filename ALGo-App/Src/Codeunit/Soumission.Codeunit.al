codeunit 50101 Soumission
{
    trigger OnRun()
    begin

    end;

    procedure validateSoumissionLine(var SoumissionLine: Record SoumissionLine)
    var

    begin
        this.TypeValidation(SoumissionLine);

    end;

    procedure TypeValidation(var SoumissionLine: Record SoumissionLine): Boolean
    begin
        this.IsArticle(SoumissionLine);

    end;

    procedure IsArticle(var SoumissionLine: Record SoumissionLine)
    begin
        if SoumissionLine.Type <> SoumissionLine.Type::Article then
            exit;
        // SoumissionLine.SetAutoCalcFields("Unit Price");

        this.CalPrixunitaire(SoumissionLine);
    end;

    procedure CalPrixunitaire(var soumissionLine: Record SoumissionLine)
    var
        // prixUnitaire: Decimal;
        // Prixremise: decimal;

        BaseAmount: Decimal;
        RemiseArticleAmount: Decimal;
        TotalDiscountedLine: Decimal;
        LineDiscountPercentage: Decimal;
    begin
        //FIXME:from VT02
        // prixUnitaire := soumissionLine."Unit Price";
        // Prixremise := prixUnitaire - (Round(prixUnitaire * (soumissionLine.Remise / 100), 0.01));

        // if soumissionLine."% OB" = 0 then begin
        //     soumissionLine."Prix Unitaire net" := Prixremise;
        // end
        // else begin
        //     soumissionLine."Prix Unitaire net" := Prixremise - (Round(prixUnitaire * (soumissionLine."% OB" / 100), 0.01));
        // end;

        // SoumissionLine."Montant net" := Round(SoumissionLine.Quantity * SoumissionLine."Prix Unitaire net");

        //FIX
        // if soumissionLine."Unit Price (base)" = 0 then begin
        //     if item.Get(soumissionLine.No) then begin
        //         soumissionLine."Unit Price (base)" := item."Unit Price";
        //     end;
        // end;

        BaseAmount := soumissionLine.Quantity * soumissionLine."Unit Price (base)";
        RemiseArticleAmount := BaseAmount - (BaseAmount * (soumissionLine.Remise / 100));
        TotalDiscountedLine := RemiseArticleAmount - (RemiseArticleAmount * (soumissionLine."% OB" / 100));
        if (TotalDiscountedLine <> 0) and (BaseAmount <> 0) then
            LineDiscountPercentage := (1 - (TotalDiscountedLine / BaseAmount)) * 100;

        if (soumissionLine.Remise = 100) or (soumissionLine."% OB" = 100) then
            soumissionLine."Prix Unitaire net" := 0
        else
            soumissionLine."Prix Unitaire net" := soumissionLine."Unit Price (base)" - (soumissionLine."Unit Price (base)" * (LineDiscountPercentage / 100));

        soumissionLine."Montant net" := soumissionLine."Prix Unitaire net" * soumissionLine.Quantity;
        if soumissionLine.Quantity > 0 then
            this.calculateItemAmountIncVat(soumissionLine)
        else
            soumissionLine."Amount Including Vat" := 0;
    end;

    procedure CreateSalesDocument(var soumission: Record SoumissionHeader)
    var
        salesOrder: Record "Sales Header";
        salesorderLine: Record "Sales Line";
        salesHeader: Record "Sales Header";
        SalesheaderCheck: Record "Sales Header";
        salesLine: record "Sales Line";
        soumissionLine: Record SoumissionLine;
        OBCalculator: Codeunit OBCalculator;
        ArchiveManagement: Codeunit ArchiveManagement;
        salesOrderPage: Page "Sales Order";
        lineno: Integer;
    begin

        if salesOrder.Get(soumission."Document Type", soumission.DocumentNo) then begin
            // ArchiveManagement.ArchiveSalesDocument(salesOrder);
            ArchiveManagement.AutoArchiveSalesDocument(salesOrder);

            salesorderLine.Reset();
            salesorderLine.SetRange("Document No.", salesOrder."No.");
            salesorderLine.SetRange("Document Type", salesOrder."Document Type");
            if salesorderLine.FindSet() then
                repeat
                    if salesorderLine.Delete() then;
                until salesorderLine.Next() = 0;
            if salesOrder.Delete() then;
        end;

        lineNo := 10000;
        salesHeader.Init();
        salesHeader."Document Type" := soumission."Document Type"::Order;
        salesHeader."Sell-to Customer No." := soumission."Customer ID";
        salesHeader."Gen. Bus. Posting Group" := soumission."VAT Bus. Posting Group";

        salesHeader.Validate("Sell-to Customer No.");

        SalesheaderCheck.Reset();
        SalesheaderCheck.SetRange("Document Type", soumission."Document Type"::Order);
        SalesheaderCheck.SetRange("Sell-to Customer No.", salesHeader."Sell-to Customer No.");
        if SalesheaderCheck.Count > 1 then
            if not ConfirmManagement.GetResponseOrDefault('Customer: ' + salesHeader."Sell-to Customer No." + ' already have a sales order, do you want to create a new order?', true) then
                exit;

        salesHeader.Insert(true);

        soumissionLine.Reset();
        soumissionLine.SetRange("Soumission ID", soumission."Soumission ID");
        if soumissionLine.FindSet() then
            repeat
                if soumissionLine.Type <> soumissionLine.Type::Article then
                    continue;
                salesLine.init();

                if salesline.FindLast() then begin
                    lineNo := lineNo + salesline."Line No.";
                    salesline."Line No." := lineNo;
                end
                else begin
                    salesline."Line No." := lineNo;
                end;

                salesLine."Document No." := salesHeader."No.";
                salesLine."Document Type" := salesHeader."Document Type";
                // salesLine.Validate("Document No.");
                salesLine.Type := salesLine.Type::Item;
                salesLine.Validate(Type);
                salesLine."No." := soumissionLine.No;
                salesLine.Validate("No.");
                salesLine.Description := soumissionLine.Designation;
                salesLine."Description Supp." := soumissionLine."Description Supp.";
                salesLine.Quantity := soumissionLine.Quantity;
                salesLine.Validate(Quantity);
                salesLine."% Remise articles" := soumissionLine.Remise;
                salesLine."% OB" := soumissionLine."% OB";
                OBCalculator.CalcOBLineAmount(salesLine);


                salesLine.Insert(true);
            until soumissionLine.Next() = 0;

        soumission.DocumentNo := salesHeader."No.";
        soumission."Document Type" := salesHeader."Document Type";
        soumission.Modify();

        if not ConfirmManagement.GetResponseOrDefault('Do you want to open the sales order?', false) then
            exit;
        salesOrderPage.SetRecord(salesHeader);
        salesOrderPage.Run();

    end;

    procedure ArchiveSoumission(SoumissionHeader: Record SoumissionHeader)
    var
        soumissionLine: Record SoumissionLine;
        soumissionHeaderArchive: record SoumissionHeaderArchive;
        soumissionLineArchive: Record SoumissionLineArchiveNew;
        SoumissionArchiveCard: Page SubmissionCardArchive;
        ArchiveType: Boolean;
    begin

        soumissionHeaderArchive.Init();
        soumissionHeaderArchive."Soumission ID" := SoumissionHeader."Soumission ID";
        soumissionHeaderArchive."Customer ID" := SoumissionHeader."Customer ID";
        soumissionHeaderArchive."Document Type" := SoumissionHeader."Document Type";
        soumissionHeaderArchive.Status := soumissionHeaderArchive.Status::Ouvert;
        soumissionHeaderArchive."Date de document" := CurrentDateTime.Date;
        soumissionHeaderArchive.DocumentNo := SoumissionHeader.DocumentNo;
        soumissionHeaderArchive."VAT Bus. Posting Group" := SoumissionHeader."VAT Bus. Posting Group";
        soumissionHeaderArchive.Insert();

        soumissionLine.Reset();
        soumissionLine.SetRange("Soumission ID", SoumissionHeader."Soumission ID");
        // soumissionLine.SetAutoCalcFields("Unit Price");
        if soumissionLine.FindSet(true) then
            repeat
                soumissionLineArchive.Init();
                soumissionLineArchive.PK := soumissionHeaderArchive.PK;
                soumissionLineArchive."Soumission ID" := soumissionLine."Soumission ID";
                soumissionLineArchive.No := soumissionLine.No;
                soumissionLineArchive."Code RPLP" := soumissionLine."Code RPLP";
                soumissionLineArchive."Line No" := soumissionLine."Line No";
                soumissionLineArchive.Type := soumissionLine.Type;
                soumissionLineArchive.Designation := soumissionLine.Designation;
                soumissionLineArchive."Description Supp." := soumissionLine."Description Supp.";
                soumissionLineArchive.Totalisation := soumissionLine.Totalisation;
                soumissionLineArchive.Quantity := soumissionLine.Quantity;
                soumissionLineArchive."Unit Price" := soumissionLine."Unit Price (base)";
                soumissionLineArchive.Remise := soumissionLine.Remise;
                soumissionLineArchive."% OB" := soumissionLine."% OB";
                soumissionLineArchive."Prix Unitaire net" := soumissionLine."Prix Unitaire net";
                soumissionLineArchive."Amount Including Vat" := soumissionLine."Amount Including Vat";

                soumissionLineArchive."Montant Totalisation" := soumissionLine."Montant Totalisation";
                soumissionLineArchive.Gras := soumissionLine.Gras;
                soumissionLineArchive.Italique := soumissionLine.Italique;
                soumissionLineArchive."Souligné" := soumissionLine."Souligné";

                soumissionLineArchive."Montant net" := soumissionLine."Montant net";
                soumissionLineArchive."Style Property" := soumissionLine."Style Property";
                soumissionHeaderArchive."VAT Bus. Posting Group" := soumissionLine."VAT Prod. Posting Group";

                if soumissionLineArchive.Insert() then;

            until soumissionLine.Next() = 0;

        ArchiveType := ConfirmManagement.GetResponseOrDefault('Do you want to Copy this soumission to Archive? \ Yes: Copy \ No: Move', true);
        if not ArchiveType then
            if SoumissionHeader.Delete() then;

        if not this.ConfirmManagement.GetResponseOrDefault('Do you want to open the archived Soumision?', false) then
            exit;
        SoumissionArchiveCard.SetRecord(soumissionHeaderArchive);
        SoumissionArchiveCard.Run();

    end;

    //archive to soumission function
    procedure ExtractSoumission(var soumissionHeaderArchive: record SoumissionHeaderArchive)//TODO:revert mapping
    var
        item: Record Item;
        soumissionLine: Record SoumissionLine;
        soumissionLineArchive: Record SoumissionLineArchiveNew;
        SoumissionHeader: Record SoumissionHeader;
        salesAndReceivablesSetup: Record "Sales & Receivables Setup";
        salesHeader: Record "Sales Header";
        NoSeriesMgt: Codeunit "No. Series";
        SoumissionCard: Page SubmissionCard;
        SoumissionID: code[20];
    begin
        salesAndReceivablesSetup.Get();

        salesHeader.Init();
        salesHeader."Document Type" := salesHeader."Document Type"::Quote;
        salesHeader."No." := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Quote Nos.", Today(), true);

        salesHeader.Validate("Sell-to Customer No.", soumissionHeaderArchive."Customer ID");
        salesHeader.Insert(true);

        //Achive to soumission
        SoumissionHeader.Init();
        SoumissionID := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Soumission Nos", Today(), false);
        SoumissionHeader."Soumission ID" := SoumissionID;
        SoumissionHeader."Document Type" := soumissionHeaderArchive."Document Type";
        SoumissionHeader."Customer ID" := soumissionHeaderArchive."Customer ID";
        SoumissionHeader.DocumentNo := salesHeader."No.";
        SoumissionHeader."VAT Bus. Posting Group" := soumissionHeaderArchive."VAT Bus. Posting Group";

        SoumissionHeader.Insert();

        soumissionLineArchive.Reset();
        soumissionLineArchive.SetRange(PK, soumissionHeaderArchive.PK);
        soumissionLineArchive.SetRange("Soumission ID", soumissionHeaderArchive."Soumission ID");

        if soumissionLineArchive.FindSet() then
            repeat
                soumissionLine.Init();
                // soumissionLineArchive.PK := soumissionHeaderArchive.PK;
                soumissionLine."Soumission ID" := SoumissionID;
                soumissionLine."Line No" := soumissionLineArchive."Line No";
                soumissionLine.Type := soumissionLineArchive.Type;
                soumissionLine.Validate(Type);
                soumissionLine.No := soumissionLineArchive.No;
                if soumissionLine.Type = soumissionLine.Type::Article then
                    soumissionLine.Validate(No);
                if item.Get(soumissionLine.No) then begin
                    soumissionLine."Code RPLP" := item."Code RPLP";
                    soumissionLine."VAT Prod. Posting Group" := item."VAT Prod. Posting Group";
                end;
                soumissionLine.Designation := soumissionLineArchive.Designation;
                soumissionLine."Description Supp." := soumissionLineArchive."Description Supp.";
                soumissionLine.Totalisation := soumissionLineArchive.Totalisation;
                soumissionLine.Quantity := soumissionLineArchive.Quantity;
                // soumissionLine.Remise := soumissionLineArchive.Remise;
                soumissionLine."% OB" := soumissionLineArchive."% OB";
                soumissionLine."Montant Totalisation" := soumissionLineArchive."Montant Totalisation";
                soumissionLine.Gras := soumissionLineArchive.Gras;
                soumissionLine.Italique := soumissionLineArchive.Italique;
                soumissionLine."Souligné" := soumissionLineArchive."Souligné";
                // soumissionLine."VAT Prod. Posting Group" := soumissionLineArchive."VAT Prod. Posting Group";

                if soumissionLine.Type = soumissionLine.Type::Formule then begin
                    soumissionLine."Montant net" := soumissionLine.CalculateTotalFromRange(soumissionLine.Totalisation, soumissionLine."Soumission ID");
                end
                else begin
                    // soumissionLine.CalcFields("Unit Price");
                    this.IsArticle(soumissionLine);
                end;
                soumissionLine."Style Property" := soumissionLineArchive."Style Property";

                soumissionLine.Insert();

            until soumissionLineArchive.Next() = 0;

        if not this.ConfirmManagement.GetResponseOrDefault('Do you want to open the Soumision?', true) then
            exit;
        SoumissionCard.SetRecord(SoumissionHeader);
        SoumissionCard.Run();

    end;

    procedure calculateItemAmountIncVat(var soumissionLine: Record SoumissionLine)
    var
        vatPostingSetup: Record "VAT Posting Setup";
        SoumissionHeader: record SoumissionHeader;
    begin
        if soumissionLine.No = '' then
            exit;
        SoumissionHeader.Get(soumissionLine."Soumission ID");
        vatPostingSetup.Get(SoumissionHeader."VAT Bus. Posting Group", soumissionLine."VAT Prod. Posting Group");

        soumissionLine."Amount Including Vat" := soumissionLine."Montant net" + (soumissionLine."Montant net" * (vatPostingSetup."VAT %" / 100));

    end;

    procedure SellingPriceAlert(var soumissionLine: Record SoumissionLine; Message: Boolean): Boolean
    var
        Item: Record Item;
    begin
        if not (soumissionLine.Type = soumissionLine.Type::Article) then
            exit;
        if not Item.Get(soumissionLine.No) then
            exit;

        if (Item."Unit Cost" * soumissionLine.Quantity) > soumissionLine."Montant net" then begin
            if Message then
                Message('Le prix de vente sur la ligne article est inférieure au prix d’achat');
            exit(true);
        end;
    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";

}