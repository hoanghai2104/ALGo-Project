codeunit 50104 SalesHeaderManagement
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnRunOnBeforeCheckAndUpdate, '', false, false)]
    local procedure "Sales-Post_OnRunOnBeforeCheckAndUpdate"(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.Invoice then begin
            if (SalesHeader."Type commande service" <> '') and (SalesHeader."Statut commande" <> SalesHeader."Statut commande"::Finished) then
                SalesHeader.FieldError("Statut commande", 'Invalid');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterSalesInvHeaderInsert, '', false, false)]
    local procedure "Sales-Post_OnAfterSalesInvHeaderInsert"(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header"; PreviewMode: Boolean)
    var
        NomDuProprietaire: Text;
    begin
        NomDuProprietaire := SalesHeader.GetNomduProprietaire();
        SalesInvHeader.SetNomduProprietaire(NomDuProprietaire);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnInsertInvoiceHeaderOnBeforeSalesInvHeaderTransferFields, '', false, false)]
    local procedure "Sales-Post_OnInsertInvoiceHeaderOnBeforeSalesInvHeaderTransferFields"(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.CalcFields("Nom du Proprietaire");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnInsertCrMemoHeaderOnBeforeSalesCrMemoHeaderTransferFields, '', false, false)]
    local procedure "Sales-Post_OnInsertCrMemoHeaderOnBeforeSalesCrMemoHeaderTransferFields"(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.CalcFields("Nom du Proprietaire");
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Order", OnAfterInsertSalesOrderHeader, '', false, false)]
    local procedure "Sales-Quote to Order_OnAfterInsertSalesOrderHeader"(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    var
        NomDuProprietaire: Text;
    begin
        NomDuProprietaire := SalesQuoteHeader.GetNomduProprietaire();
        SalesOrderHeader.SetNomduProprietaire(NomDuProprietaire);
    end;

}