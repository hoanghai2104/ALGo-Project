pageextension 50123 "Posted Purchase Receipt" extends "Posted Purchase Receipt"
{
    actions
    {
        addlast(processing)
        {
            action("ImpressionEtiquettes")
            {
                ApplicationArea = All;
                Caption = 'View Impression d''étiquettes';
                Image = PrintReport;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Ouvrir la liste des détails de réception d''achat.';
                RunObject = page DetailReceptionAchat;
                RunPageLink = "Posted Purch Receipt No" = field("No.");
                RunPageMode = View;

            }
            // action("PrintImpressionEtiquettes")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Print Impression d''étiquettes';
            //     Image = PrintReport;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     Visible = false;
            //     ObsoleteState = Pending;
            //     ObsoleteReason = 'Use the new Print action in Detail Reception Achat page.';
            //     trigger OnAction()
            //     var
            //         ettiquettesReceptionRecord: Record DetailReceptionAchat;
            //         EtiquettesReceptionReport: Report EtiquettesReception;
            //     begin
            //         ettiquettesReceptionRecord.Reset();
            //         ettiquettesReceptionRecord.SetRange("DocumentNo", Rec."No.");
            //         ettiquettesReceptionRecord.SetRange("DocumentType", ettiquettesReceptionRecord."DocumentType"::"Purchase Receipt");
            //         EtiquettesReceptionReport.SetTableView(ettiquettesReceptionRecord);
            //         EtiquettesReceptionReport.Run();
            //     end;
            // }
        }
    }
}
