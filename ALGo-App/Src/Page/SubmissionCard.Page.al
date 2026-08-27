page 50102 SubmissionCard
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = SoumissionHeader;
    Caption = 'Soumission';
    DataCaptionExpression = Rec.DocumentNo + ' · ' + Format(Rec."Document Type");

    layout
    {
        area(Content)
        {
            group(Soumission)
            {
                field("Soumission ID"; Rec."Soumission ID")
                {
                    Enabled = false;
                    Caption = 'Soumission ID';
                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    Caption = 'Document No.';
                    Enabled = false;

                }
                field("Document Type"; Rec."Document Type")
                {
                    Caption = 'Type document';
                    Enabled = false;

                }
                field("Customer ID"; Rec."Customer ID")
                {
                    Caption = 'N° client';
                    Lookup = true;
                    LookupPageId = "Customer List";
                    trigger OnValidate()
                    var
                        soumissionLine: Record SoumissionLine;
                    begin
                        soumissionLine.Reset();
                        soumissionLine.SetRange("Soumission ID", Rec."Soumission ID");
                        if soumissionLine.FindSet() then begin
                            repeat
                                soumissionLine.Validate(No);
                                soumissionLine.Modify();
                            until soumissionLine.Next() = 0;
                        end;
                    end;
                }
                field("Nom client"; Rec."Nom client")
                {
                    Editable = false;
                    Enabled = false;
                }
                field(Montant; Rec.Montant)
                {
                    Enabled = false;
                    Editable = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {

                }

            }
            part(SubmissionLine; SubmissionSubForm)
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "Soumission ID" = field("Soumission ID");
                Caption = 'Lines';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Create Sales Document")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = this.EnableCreateSalesBTN;
                trigger OnAction()
                begin
                    this.SoummissonCodeunit.CreateSalesDocument(Rec);
                end;
            }
            action("Archive soumission")
            {
                Image = Archive;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    this.SoummissonCodeunit.ArchiveSoumission(Rec);
                end;
            }
            action("Impression Soumission")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page SoumissionSummary;
                RunPageLink = "Soumission ID" = field("Soumission ID");
                RunPageMode = view;
                RunPageView = where(Type = filter(Titre | "Sous-titre" | Formule | article | section | Blank | Comment));
            }
            action("Calculate RPLP")
            {
                ApplicationArea = all;
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CalculateRPLP: Codeunit CalculateRPLP;
                begin
                    CalculateRPLP.CalculateRplpSoumission(Rec);
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.GetNextNumberSeries(Rec);
        if (Rec."Soumission ID" = '') and
             (Rec.DocumentNo = '') and
             (Rec."Customer ID" = '') then begin
            this.EnableCreateSalesBTN := false;
        end else begin
            this.EnableCreateSalesBTN := true;
        end;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if (Rec."Soumission ID" = '') and
             (Rec.DocumentNo = '') and
             (Rec."Customer ID" = '') then begin
            this.EnableCreateSalesBTN := false;
        end else begin
            this.EnableCreateSalesBTN := true;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        if (Rec."Soumission ID" = '') and
               (Rec.DocumentNo = '') and
               (Rec."Customer ID" = '') then begin
            this.EnableCreateSalesBTN := false;
        end else begin
            this.EnableCreateSalesBTN := true;
        end;
    end;

    var
        SoummissonCodeunit: Codeunit Soumission;
        EnableCreateSalesBTN: Boolean;
}