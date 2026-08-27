report 50100 EtiquettesReception
{
    Caption = 'Etiquettes réception';
    UsageCategory = Administration;
    // ApplicationArea = All;
    // DefaultLayout = RDLC;

    dataset
    {
        dataitem(DetailReceptionAchat; DetailReceptionAchat)
        {

            column(EntryNo; EntryNo)
            {

            }
            column(TechnicianName; TechnicianName)
            {

            }
            column(InterventionNo; "No de intervention")
            {

            }
            column(OrderGiverName; OrderGiverName)
            {

            }
            column(TenantName; TenantName)
            {

            }
            column(ItemNo; ItemNo)
            {

            }
            column(Quantity; Quantity)
            {

            }
            column(DocumentNo; DocumentNo)
            {

            }
            column(DocumentType; DocumentType)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Renamed to Phma document order type';
            }
            column(DisplayEttiquette; displayEttiquette())
            {

            }
            column(Phma_document_order_type; "Phma document order type")
            {

            }
            column(Posted_Purch_Receipt_No; "Posted Purch Receipt No")
            {

            }
            column(Assigned_User_ID; "Assigned User ID") { }
            column(Purchase_Order_No; "Purchase Order No") { }
            column(VendorNo; VendorNo) { }
            column(VendorName; VendorName) { }
            column(VendorSearchName; VendorSearchName) { }
            column(CustomerSearchName; CustomerSearchName) { }

            column(ReferenceLibre; "Reference Libre")
            {
            }
        }
    }


    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {

                }
            }
        }
    }

    procedure displayEttiquette(): Text
    var
        Ettiquette: Text;
    begin
        Ettiquette := DetailReceptionAchat.TechnicianName + ' - ' + DetailReceptionAchat."No de intervention" + ' - ' + DetailReceptionAchat.OrderGiverName + ' - ' + DetailReceptionAchat.TenantName;

        if DetailReceptionAchat."Reference Libre" <> '' then
            Ettiquette := Ettiquette + ' - ' + DetailReceptionAchat."Reference Libre";

        exit(Ettiquette);
    end;
}