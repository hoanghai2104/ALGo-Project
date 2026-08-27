pageextension 50113 SalesQuote extends "Sales Quote"
{
    layout
    {
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
        // Add changes to page layout here
        addafter("Requested Delivery Date")
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
        // addlast(Category_Process)
        addafter("F&unctions")
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
            action("Créer Soumission")
            {
                ApplicationArea = all;
                Image = CreateDocument;

                trigger OnAction()
                var
                    Soummission: Record SoumissionHeader;
                    SoummissionHeaderCheck: Record SoumissionHeader;
                    salesAndReceivablesSetup: Record "Sales & Receivables Setup";
                    NoSeriesMgt: Codeunit "No. Series";
                    SoumissionDevisID: code[20];
                begin

                    SoummissionHeaderCheck.Reset();
                    SoummissionHeaderCheck.SetRange("Document Type", Rec."Document Type");
                    SoummissionHeaderCheck.SetRange(DocumentNo, Rec."No.");
                    if SoummissionHeaderCheck.FindFirst() then begin
                        createSoumissionLine(SoummissionHeaderCheck);

                        Page.Run(Page::SubmissionCard, SoummissionHeaderCheck);
                    end else begin
                        salesAndReceivablesSetup.Get();
                        SoumissionDevisID := NoSeriesMgt.GetNextNo(salesAndReceivablesSetup."Soumission Nos", Today(), false);
                        Soummission.Reset();
                        Soummission.Init();
                        Soummission."Soumission ID" := SoumissionDevisID;
                        Soummission."Customer ID" := Rec."Sell-to Customer No.";
                        Soummission."Document Type" := Rec."Document Type";
                        Soummission.DocumentNo := Rec."No.";
                        Soummission."VAT Bus. Posting Group" := Rec."VAT Bus. Posting Group";
                        Soummission.Insert();
                        createSoumissionLine(Soummission);

                        Soummission.Reset();
                        Soummission.Get(SoumissionDevisID);
                        Page.Run(Page::SubmissionCard, Soummission);
                    end;

                    this.createCommentLine(Rec);
                end;

            }
        }

        addlast(Category_Process)
        {
            actionref(Promoted_CalculateRPLP; "Calculate RPLP") { }
            actionref(Promoted_CreerSoumission; "Créer Soumission") { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;

    procedure createSoumissionLine(soumissionHeader: Record SoumissionHeader)
    var
        salesLine: Record "Sales Line";
        SoumissionLine: Record SoumissionLine;
        SoumissionLineNo: Record SoumissionLine;
    begin
        SoumissionLine.Reset();
        SoumissionLine.SetRange("Soumission ID", soumissionHeader."Soumission ID");

        salesLine.Reset();
        salesLine.SetRange("Document Type", Rec."Document Type");
        salesLine.SetRange("Document No.", Rec."No.");
        if salesLine.FindSet() then
            repeat
                if not (salesLine.Type in [salesLine.Type::Item, salesLine.Type::" "]) then
                    continue;

                SoumissionLine.Reset();
                SoumissionLine.SetRange("Soumission ID", soumissionHeader."Soumission ID");
                SoumissionLine.SetRange(SalesQuoteLineID, salesLine."Line No.");
                if SoumissionLine.FindFirst() then begin
                    if salesLine.Type = salesLine.Type::Item then begin
                        // update
                        SoumissionLine.No := salesLine."No.";
                        SoumissionLine.setIsHandledExtItem(true);
                        SoumissionLine.Validate(No);
                        SoumissionLine.Quantity := salesLine.Quantity;
                        // SoumissionLine.CalcFields("Unit Price");
                        SoumissionLine.Designation := salesLine.Description;
                        SoumissionLine."Description Supp." := salesLine."Description Supp.";
                        SoumissionLine."Unit Price (base)" := salesLine."Unit Price";
                        SoumissionLine."VAT Prod. Posting Group" := salesLine."VAT Prod. Posting Group";
                        SoumissionLine.Remise := salesLine."% Remise articles";
                        soumissionCodeunit.CalPrixunitaire(SoumissionLine);
                    end else begin
                        if salesLine.Description <> 'Soumission' then begin
                            SoumissionLine.Designation := salesLine.Description;
                            SoumissionLine."Description Supp." := salesLine."Description Supp.";

                        end;
                    end;

                    SoumissionLine.Modify(true);
                end
                else begin
                    //insert
                    SoumissionLine.Init();
                    SoumissionLineNo.Reset();
                    SoumissionLineNo.SetRange("Soumission ID", soumissionHeader."Soumission ID");
                    SoumissionLineNo.SetLoadFields("Line No");
                    if SoumissionLineNo.FindLast() then begin
                        if salesLine.Type = salesLine.Type::Item then begin
                            SoumissionLine."Line No" := SoumissionLineNo."Line No" + 10000;
                        end else begin
                            SoumissionLine."Line No" := SoumissionLineNo."Line No" + 10000;
                        end;
                    end else begin
                        SoumissionLine."Line No" := 10000;
                    end;
                    SoumissionLine.SalesQuoteLineID := salesLine."Line No.";
                    SoumissionLine."Soumission ID" := soumissionHeader."Soumission ID";
                    if salesLine.Type = salesLine.Type::Item then begin
                        SoumissionLine.Type := SoumissionLine.Type::Article;
                        SoumissionLine.No := salesLine."No.";
                        SoumissionLine.setIsHandledExtItem(false);
                        SoumissionLine.Validate(No);
                        SoumissionLine.Quantity := salesLine.Quantity;
                        SoumissionLine.Validate(Quantity);
                        // SoumissionLine.CalcFields("Unit Price");
                        SoumissionLine.Designation := salesLine.Description;
                        SoumissionLine."Description Supp." := salesLine."Description Supp.";
                        SoumissionLine."Unit Price (base)" := salesLine."Unit Price";
                        SoumissionLine."VAT Prod. Posting Group" := salesLine."VAT Prod. Posting Group";
                        SoumissionLine.Remise := salesLine."% Remise articles";
                        soumissionCodeunit.CalPrixunitaire(SoumissionLine);
                    end else begin
                        if salesLine.Description <> 'Soumission' then begin
                            SoumissionLine.Type := SoumissionLine.Type::Comment;
                            SoumissionLine.Designation := salesLine.Description;
                            SoumissionLine."Description Supp." := salesLine."Description Supp.";

                        end;
                    end;
                    if (SoumissionLine.type <> SoumissionLine.Type::Comment) and (SoumissionLine.Designation <> 'Soumission') then begin
                        SoumissionLine.Insert(true);

                    end;

                end;
            until salesLine.Next() = 0;
    end;

    procedure syncDeletedSalesLine(soumissionHeader: Record SoumissionHeader)
    var
        soumissionLineCheck: Record SoumissionLine;
    begin
        soumissionLineCheck.Reset();
        soumissionLineCheck.SetRange("Soumission ID", soumissionHeader."Soumission ID");
        if soumissionLineCheck.FindSet() then
            repeat

            until soumissionLineCheck.Next() = 0;
    end;

    local procedure createCommentLine(salesHeader: Record "Sales Header")
    var
        salesLine: Record "Sales Line";
    begin
        salesLine.Reset();
        salesLine.SetRange("Document Type", salesHeader."Document Type");
        salesLine.SetRange("Document No.", salesHeader."No.");
        if salesLine.IsEmpty then begin
            salesLine.Init();
            salesLine."Document Type" := salesHeader."Document Type";
            salesLine."Document No." := salesHeader."No.";
            salesLine.Type := salesLine.Type::" ";
            salesLine.Description := 'Soumission';
            salesLine.Insert();
        end;
    end;

    var
        soumissionCodeunit: Codeunit Soumission;
        NomDuProprietaire: Text;
}