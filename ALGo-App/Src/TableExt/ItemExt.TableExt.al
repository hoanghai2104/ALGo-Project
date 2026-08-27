tableextension 50100 "ItemExt" extends Item
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "Code RPLP"; Integer)
        {
            TableRelation = RplpParametrage."Code ID";
            BlankZero = true;
        }
        field(50101; "Has Sales Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any sales lines.';
            FieldClass = FlowField;
            CalcFormula = Exist("Sales Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No.")));
        }
        field(50102; "Has To Order Sales Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any sales lines that are marked to order.';
            FieldClass = FlowField;
            CalcFormula = Exist("Sales Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No."), "To Order PHM" = Const(true)));
        }
        field(50105; "Has Non-To Order Sales Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any sales lines that are not marked to order.';
            FieldClass = FlowField;
            CalcFormula = Exist("Sales Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No."), "To Order PHM" = Const(false)));
        }
        field(50103; "Has Service Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any service lines.';
            FieldClass = FlowField;
            CalcFormula = Exist("Service Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No.")));
        }
        field(50104; "Has To Order Service Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any service lines that are marked to order.';
            FieldClass = FlowField;
            CalcFormula = Exist("Service Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No."), "To Order PHM" = Const(true)));
        }
        field(50106; "Has Non-To Order Service Line"; Boolean)
        {
            Editable = false;
            ToolTip = 'Check if the item has any service lines that are not marked to order.';
            FieldClass = FlowField;
            CalcFormula = Exist("Service Line" Where("Document Type" = Const(Order), Type = Const(Item), "No." = Field("No."), "To Order PHM" = Const(false)));
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
}