page 50100 RplpParametrageList
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = RplpParametrage;
    Caption = 'RPLP Paramétrage';
    RefreshOnActivate = true;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Code ID"; Rec."Code ID")
                {
                    ShowMandatory = true;
                }
                field(Article; Rec.Article)
                {
                    ShowMandatory = true;

                }
                field(Designation; Rec.Designation)
                {
                    Caption = 'Désignation';
                    ShowMandatory = true;

                }
                field(Description; Rec.Description)
                {

                }

                field("Pourcentage RPLP"; Rec."Pourcentage RPLP")
                {
                    ShowMandatory = true;

                }
                field("Date de debut"; Rec."Date de debut")
                {
                    Caption = 'Date de début';
                    ShowMandatory = true;

                }
                field("Date de fin"; Rec."Date de fin")
                {
                    ShowMandatory = true;

                }

            }
        }

    }

    actions
    {
        area(Processing)
        {
            action("View RPLP Change Log")
            {
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Change Log Entries";
                RunPageLink = "Table No." = filter(Database::RplpParametrage);
                RunPageMode = View;
            }
        }
    }
}