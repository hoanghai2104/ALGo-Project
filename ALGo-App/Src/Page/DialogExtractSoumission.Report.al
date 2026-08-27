report 50106 "DialogExtractSoumission"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Please select a Document';
    ProcessingOnly = true;
    AllowScheduling = false;


    requestpage
    {
        SourceTable = DialogExtractSoumissionTemp;
        layout
        {
            area(content)
            {
                group("General")
                {
                    field(SoummisionID; PK)
                    {
                        ApplicationArea = all;
                        Enabled = true;
                        Editable = true;
                        ShowMandatory = true;
                        Caption = 'Soummision archive ID';
                        Lookup = true;
                        LookupPageId = SoumissionListArchivage;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            SubmissionList: Record SoumissionHeaderArchive;
                        begin
                            SubmissionList.Reset();
                            if Page.RunModal(Page::SoumissionListArchivage, SubmissionList) = Action::LookupOK then begin
                                PK := SubmissionList.PK;
                                SoummisionID := SubmissionList."Soumission ID";
                                documentType := SubmissionList."Document Type";

                            end;

                        end;
                    }
                    field("Soummision ID"; SoummisionID)
                    {
                        ApplicationArea = all;
                    }
                    field(customerID; CustomerID)
                    {
                        ApplicationArea = all;
                        Enabled = true;
                        Editable = true;
                        ShowMandatory = true;
                        Caption = 'Customer ID';
                        Lookup = true;
                        LookupPageId = "Customer List";

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            customer: Record Customer;
                        begin
                            customer.Reset();
                            if Page.RunModal(Page::"Customer List", customer) = Action::LookupOK then
                                CustomerID := customer."No.";

                        end;
                    }
                }
            }
        }

    }

    trigger OnPreReport()
    begin
        CreateSoumision()
    end;

    trigger OnInitReport()
    begin
        // IsAssociateEditable := true;
        // IsAffiliateEditable := true;
        // IsMaxPayerEditable := true;
    end;

    local procedure CreateSoumision()
    var
        soumissionArchiveHeader: Record SoumissionHeaderArchive;
    begin
        soumissionArchiveHeader.Get(PK, SoummisionID);
        // soumission.ExtractSoumission();
        this.ReportExtractSoumission(soumissionArchiveHeader, CustomerID);

    end;

    local procedure ReportExtractSoumission(var soumissionHeaderArchive: record SoumissionHeaderArchive; CustomerID: code[20])
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
        salesHeader.Init();
        salesHeader."Document Type" := SoumissionHeader."Document Type"::Quote;
        salesHeader."No." := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Quote Nos.", Today(), true);
        salesHeader.Validate("Sell-to Customer No.", CustomerID);
        salesHeader.Insert(true);

        //Achive to soumission
        SoumissionHeader.Init();
        salesAndReceivablesSetup.Get();
        SoumissionID := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Soumission Nos", Today(), false);
        SoumissionHeader."Soumission ID" := SoumissionID;
        SoumissionHeader."Document Type" := soumissionHeaderArchive."Document Type";
        SoumissionHeader."Customer ID" := CustomerID;
        SoumissionHeader.DocumentNo := salesHeader."No.";
        SoumissionHeader."VAT Bus. Posting Group" := soumissionHeaderArchive."VAT Bus. Posting Group";

        SoumissionHeader.Insert();



        soumissionLineArchive.Reset();
        soumissionLineArchive.SetRange(PK, soumissionHeaderArchive.PK);
        soumissionLineArchive.SetRange("Soumission ID", soumissionHeaderArchive."Soumission ID");

        if soumissionLineArchive.FindSet() then
            repeat
                soumissionLine.Init();
                soumissionLine."Soumission ID" := SoumissionID;
                soumissionLine."Line No" := soumissionLineArchive."Line No";
                soumissionLine.Type := soumissionLineArchive.Type;
                soumissionLine.Validate(Type);
                soumissionLine.No := soumissionLineArchive.No;
                if soumissionLine.Type = soumissionLine.Type::Article then
                    soumissionLine.Validate(No);
                soumissionLine.Designation := soumissionLineArchive.Designation;
                soumissionLine."Description Supp." := soumissionLineArchive."Description Supp.";
                if item.Get(soumissionLine.No) then begin
                    soumissionLine."Code RPLP" := item."Code RPLP";
                    soumissionLine."VAT Prod. Posting Group" := item."VAT Prod. Posting Group";
                end;
                // soumissionLine."Code RPLP" := soumissionLineArchive."Code RPLP";
                soumissionLine.Totalisation := soumissionLineArchive.Totalisation;
                soumissionLine.Quantity := soumissionLineArchive.Quantity;
                soumissionLine."Montant Totalisation" := soumissionLineArchive."Montant Totalisation";
                soumissionLine.Gras := soumissionLineArchive.Gras;
                soumissionLine.Italique := soumissionLineArchive.Italique;
                soumissionLine."Souligné" := soumissionLineArchive."Souligné";
                // soumissionLine.Remise := soumissionLineArchive.Remise;// retrived from Sales Price list
                soumissionLine."% OB" := soumissionLineArchive."% OB";
                if soumissionLine.Type = soumissionLine.Type::Formule then begin
                    soumissionLine."Montant net" := soumissionLine.CalculateTotalFromRange(soumissionLine.Totalisation, soumissionLine."Soumission ID");
                end
                else begin
                    // soumissionLine.CalcFields("Unit Price");
                    this.soumission.IsArticle(soumissionLine);
                end;
                soumissionLine."Style Property" := soumissionLineArchive."Style Property";

                if not soumissionLine.Insert() then
                    soumissionLine.Modify();

            until soumissionLineArchive.Next() = 0;

        if not this.ConfirmManagement.GetResponseOrDefault('Do you want to open the Soumision?', true) then
            exit;
        SoumissionCard.SetRecord(SoumissionHeader);
        SoumissionCard.Run();

    end;

    var
        ConfirmManagement: Codeunit "Confirm Management";
        soumission: Codeunit Soumission;
        CustomerID, SoummisionID : code[20];
        documentType: Enum "Sales Document Type";
        PK: Integer;

}
