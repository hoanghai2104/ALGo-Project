page 50106 SubmissionCardArchive
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = SoumissionHeaderArchive;
    Caption = 'Soumission Archive Card';
    InsertAllowed = false;
    // ModifyAllowed = false;
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
                    Enabled = false;

                }
                field("Nom client"; Rec."Nom client")
                {
                    Editable = false;
                    Enabled = false;
                }
                field(Status; Rec.Status)
                {

                }
                field("Date de document"; Rec."Date de document")
                {
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
            part(SubmissionLine; SubmissionSubFormArchive)
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = PK = field(PK);
                Caption = 'Lines';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Extraire Document")
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                Image = Copy;
                Visible = false;
                trigger OnAction()
                var
                    soumission: Codeunit Soumission;

                begin
                    soumission.ExtractSoumission(Rec);
                end;
            }
        }
    }


}