codeunit 50120 ReportCustomisationEvents
{
    ///<summary>
    /// this codeunit is used for customising report behaviours
    /// </summary>


    ///<summary>this event is for sales order</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnBeforeSalesHeaderSellTo, '', false, false)]
    local procedure "Format Address_OnBeforeSalesHeaderSellTo"(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
        if this.IsCustPerson(SalesHeader."Sell-to Customer No.") then
            SalesHeader."Sell-to Contact" := '';
    end;

    ///<summary>this event is for sales order</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnBeforeSalesHeaderBillTo, '', false, false)]
    local procedure "Format Address_OnBeforeSalesHeaderBillTo"(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
        if this.IsCustPerson(SalesHeader."Bill-to Customer No.") then
            SalesHeader."Bill-to Contact" := '';

    end;

    ///<summary>this event is for Posted sales Shipment</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnBeforeSalesShptShipTo, '', false, false)]
    local procedure "Format Address_OnBeforeSalesShptShipTo"(var AddrArray: array[8] of Text[100]; var SalesShipmentHeader: Record "Sales Shipment Header"; var Handled: Boolean)
    begin
        if this.IsCustPerson(SalesShipmentHeader."Bill-to Customer No.") then
            SalesShipmentHeader."Ship-to Contact" := '';

    end;

    ///<summary>this event is for Posted sales Inovice</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnBeforeSalesInvBillTo, '', false, false)]
    local procedure "Format Address_OnBeforeSalesInvBillTo"(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header"; var Handled: Boolean)
    begin
        if this.IsCustPerson(SalesInvHeader."Bill-to Customer No.") then
            SalesInvHeader."Bill-to Contact" := '';
    end;


    procedure IsCustPerson(CustNo: code[20]): Boolean
    var
        customer: Record Customer;
        IsPerson: Boolean;
    begin
        if customer.get(CustNo) then
            IsPerson := customer."Contact Type" = customer."Contact Type"::Person ? true : false;
        exit(IsPerson);
    end;
}