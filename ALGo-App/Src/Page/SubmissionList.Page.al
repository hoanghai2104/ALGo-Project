page 50101 SubmissionList
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = SoumissionHeader;
    RefreshOnActivate = true;
    CardPageId = SubmissionCard;
    Caption = 'Soumission List';
    ModifyAllowed = false;


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Soumission ID"; Rec."Soumission ID")
                {

                }
                field(DocumentNo; Rec.DocumentNo)
                {
                    Caption = 'Document No.';
                }
                field("Document Type"; Rec."Document Type") { }
                field("Customer ID"; Rec."Customer ID") { }
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
            action("Archive soumission")
            {
                Image = Archive;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    this.soumission.ArchiveSoumission(Rec);
                end;
            }
            action("View Archive Soumission")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = all;
                RunObject = page SoumissionListArchivage;
                RunPageMode = view;
            }
        }
    }
    var
        soumission: Codeunit Soumission;
}