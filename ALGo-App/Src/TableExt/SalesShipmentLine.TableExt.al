tableextension 50130 SalesShipmentLineExt extends "Sales Shipment Line"
{
    fields
    {
        field(50110; "ELCA Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Line"."Qty. to Ship" where("Document Type" = const(Order), "Document No." = field("Order No."), "Line No." = field("Order Line No.")));
            Editable = false;
        }

        field(50111; "ELCA Qty. Shipped"; Decimal)
        {
            Caption = 'Qty. Shipped';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Line"."Quantity Shipped" where("Document Type" = const(Order), "Document No." = field("Order No."), "Line No." = field("Order Line No.")));
            Editable = false;
        }
        field(50112; "Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
            Editable = false;
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            CalcFormula = Lookup("Sales Line".Quantity Where("Document Type" = Const(Order), "Document No." = Field("Order No."), "Line No." = Field("Order Line No.")));
        }
    }
}
