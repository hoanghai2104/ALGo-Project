tableextension 50131 SalesShipmentHeader extends "Sales Shipment Header"
{
    fields
    {
        // Add changes to table fields here
        field(50100; "ELCA_Cust_Type"; Enum "Contact Type")
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Customer."Contact Type" where("No." = field("Sell-to Customer No.")));
            Editable = false;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}