reportextension 50110 SalesShipment extends "Sales - Shipment"
{
    dataset
    {
        // Add changes to dataitems and columns here
        add("Sales Shipment Line")
        {
            column(Quantity; Quantity) { }
            column(Qty__Shipped_Not_Invoiced; "Qty. Shipped Not Invoiced") { }
            column(ELCA_Qty__to_Ship; "ELCA Qty. to Ship")
            {

            }
            column(ELCA_Qty__Shipped; "ELCA Qty. Shipped")
            {

            }
            column(Total_Quantity; "Total Quantity") { }
            column(Total_QuantityCaption; FieldCaption("Total Quantity")) { }
        }
        add("Sales Shipment Header")
        {
            column(Cust_Contact_Type; this.getCustType("Sell-to Customer No."))
            {

            }
        }
    }

    local procedure getCustType(CustNo: code[20]): Integer
    var
        customer: Record Customer;
    begin
        if customer.get(CustNo) then
            exit(customer."Contact Type".AsInteger());
    end;

}