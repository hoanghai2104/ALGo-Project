page 50104 "SoumissionListArchivage"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = SoumissionHeaderArchive;
    Caption = 'Soumissions list Archivage';
    // Editable = false;
    InsertAllowed = false;
    // ModifyAllowed = false;
    CardPageId = SubmissionCardArchive;



    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(PK; Rec.PK)
                {
                    Caption = 'Archive No.';
                }
                field("Soumission ID"; Rec."Soumission ID")
                {
                    Editable = false;
                    Enabled = false;
                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    Caption = 'Document No.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    Editable = false;
                    Enabled = false;
                }
                field("Customer ID"; Rec."Customer ID")
                {
                    Editable = false;
                    Enabled = false;
                }
                field("Nom client"; Rec."Nom client")
                {
                    Editable = false;
                    Enabled = false;
                }

                field("Date de document"; Rec."Date de document")
                {
                    Editable = false;
                    Enabled = false;
                }

                field(Montant; Rec.Montant)
                {
                    Editable = false;
                    Enabled = false;
                }

            }
        }
        area(Factboxes)
        {

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
                trigger OnAction()
                begin
                    // soumission.ExtractSoumission(Rec);
                    Report.RunModal(Report::DialogExtractSoumission, true, false);

                end;
            }
        }
    }
}