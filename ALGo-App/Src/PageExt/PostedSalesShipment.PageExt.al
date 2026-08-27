pageextension 50126 PostedSalesShipment extends "Posted Sales Shipment"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
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
                RunPageLink = DocumentNo = field("No."),
                              DocumentType = const("Item Ledger Document Type"::"Sales Shipment");
                RunPageMode = View;
                Visible = false;


            }

            action("PrintImpressionEtiquettes")
            {
                ApplicationArea = All;
                Caption = 'Print Impression d''étiquettes';
                Image = PrintReport;
                Promoted = true;
                PromotedCategory = Process;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Use the new Print action in Detail Reception Achat page.';
                trigger OnAction()
                var
                    ettiquettesReceptionRecord: Record DetailReceptionAchat;
                    EtiquettesReceptionReport: Report EtiquettesReception;
                begin
                    ettiquettesReceptionRecord.Reset();
                    ettiquettesReceptionRecord.SetRange("DocumentNo", Rec."No.");
                    ettiquettesReceptionRecord.SetRange("DocumentType", ettiquettesReceptionRecord."DocumentType"::"Sales Shipment");
                    EtiquettesReceptionReport.SetTableView(ettiquettesReceptionRecord);
                    EtiquettesReceptionReport.Run();
                end;
            }
        }
    }


}